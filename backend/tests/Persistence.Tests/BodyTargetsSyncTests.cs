using System.Net;
using System.Text.Json;
using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.TestData;
using static FitnessBuddy.Persistence.Tests.SyncHttpSupport;
using Row = FitnessBuddy.Persistence.Tests.PersonalFoodHttp.Row;

namespace FitnessBuddy.Persistence.Tests;

// B19: profile, goalPhase, targetSettings and weighIn (v1 and v2) ride the entity-agnostic B05
// storage (push/pull/history, LWW, receipts, retention fences, RLS, erasure) through the real
// authenticated host, each version under its own schemaVersion.
[Trait("Req", "AC-010")]
[Trait("Req", "AC-012")]
[Trait("Req", "TG-040")]
[Trait("Req", "WB-003")]
public sealed class BodyTargetsSyncTests(PostgresFixture database)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;
    private static readonly string[] Tables = ["documents", "row_history", "version_receipts"];

    public static TheoryData<string, int> Pairs()
    {
        var pairs = new TheoryData<string, int>();
        foreach (var (entity, version) in BodyTargetsCases.Pairs) { pairs.Add(entity, version); }
        return pairs;
    }

    // One valid synthetic payload per entity and schema version (contracts/testdata/README.md).
    private static string Fixture(string entity, int version)
    {
        if (version == 1) { return PersonalFoodHttp.Fixture(entity); }
        using var fixture = JsonDocument.Parse(File.ReadAllText(Path.Combine(AppContext.BaseDirectory, $"entity-payloads-v{version}.json")));
        return fixture.RootElement.GetProperty(entity).GetRawText();
    }

    private static Row NewRow(IdentityHarness h, string entity, int version, string? raw = null, Guid? id = null, int counter = 0, DateTimeOffset? deleted = null) =>
        PersonalFoodHttp.NewRow(h, raw ?? Fixture(entity, version), deleted, entity, id ?? BodyTargetsCases.NewId(entity), version) with { Hlc = PersonalFoodHttp.Hlc(h, counter) };

    private static async Task<string[]> Statuses(HttpResponseMessage response)
    {
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        return [.. (await PersonalFoodHttp.Json(response)).GetProperty("results").EnumerateArray().Select(r => r.GetProperty("reason").GetString() ?? r.GetProperty("status").GetString()!)];
    }

    // Owner reads return the exact payload under the version's own schemaVersion.
    private static void AssertSame(Row row, JsonElement change, bool hlc = true)
    {
        Assert.Equal(row.Entity, change.GetProperty("entity").GetString());
        Assert.Equal(row.Id, change.GetProperty("id").GetGuid());
        Assert.Equal(row.SchemaVersion, change.GetProperty("schemaVersion").GetInt32());
        if (hlc) { Assert.Equal(row.Hlc, change.GetProperty("hlc").GetString()); }
        Assert.Equal(row.DeletedAt is null, change.GetProperty("deletedAt").ValueKind == JsonValueKind.Null);
        Assert.False(change.GetProperty("compacted").GetBoolean());
        using var expected = JsonDocument.Parse(row.Raw);
        Assert.True(JsonElement.DeepEquals(expected.RootElement, change.GetProperty("payload")), $"{row.Entity} {row.Id} {row.Hlc}");
    }

    private static JsonElement[] Changes(JsonElement page) => [.. page.GetProperty("changes").EnumerateArray()];

    [Fact, Trait("Rule", "05.5-payload-validation")]
    public async Task Batched_matrix_preserves_result_order_and_valid_neighbors_without_persisting_invalid_versions()
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync();
        var user = await PersonalFoodHttp.Register(h);
        await using var factory = new IdentityApiTests.IdentityApi(database, h);
        using var client = await PersonalFoodHttp.Client(factory, h, user);
        var dataset = await PersonalFoodHttp.Dataset(client);
        var invalid = new List<Row>(); var accepted = new List<(Row Row, int Counter)>(); var batches = 0; var counter = 0;
        string[] neighbors = ["goalPhase", "targetSettings", "weighIn"];
        // D10: every profile case shares the natural ID, so each case gets HLC counter = its index and
        // same-ID versions strictly increase. Raw JSON keeps duplicate keys, number spellings and
        // lone-surrogate escapes through HTTP binding.
        foreach (var group in ByteBoundedCases(BodyTargetsCases.All(), c => c.Raw))
        {
            batches++;
            var entries = group.Select(c =>
            {
                counter++;
                return (Case: c, Counter: counter, Row: NewRow(h, c.Entity, c.SchemaVersion, c.Raw, BodyTargetsCases.IdOf(c), counter, c.Deleted ? h.Clock.GetUtcNow() : null));
            }).ToArray();
            var neighborEntity = neighbors[batches % neighbors.Length];
            var neighbor = NewRow(h, neighborEntity, neighborEntity == "weighIn" ? 1 + batches % 2 : 1); accepted.Add((neighbor, 0));
            using var response = await PersonalFoodHttp.Push(client, h, dataset, [neighbor, .. entries.Select(e => e.Row)]);
            Assert.Equal(HttpStatusCode.OK, response.StatusCode);
            var ack = await response.Content.ReadAsStringAsync(Ct);
            // Results carry no content: only id/entity/hlc/status/reason come back.
            Assert.DoesNotContain("synthetic", ack, StringComparison.OrdinalIgnoreCase);
            using var result = JsonDocument.Parse(ack);
            var results = result.RootElement.GetProperty("results").EnumerateArray().ToArray();
            Assert.Equal(entries.Length + 1, results.Length);
            Assert.Equal("accepted", results[0].GetProperty("status").GetString());
            for (var i = 0; i < entries.Length; i++)
            {
                var (test, index, row) = entries[i]; var item = results[i + 1];
                Assert.Equal(row.Id, item.GetProperty("id").GetGuid());
                Assert.Equal(row.Entity, item.GetProperty("entity").GetString());
                Assert.Equal(row.Hlc, item.GetProperty("hlc").GetString());
                Assert.True((test.Valid ? "accepted" : "invalid") == item.GetProperty("status").GetString(), test.Id);
                Assert.Equal(test.Valid ? null : "invalidPayload", item.GetProperty("reason").GetString());
                Assert.Equal(["entity", "hlc", "id", "reason", "status"], item.EnumerateObject().Select(p => p.Name).Order(StringComparer.Ordinal));
                if (test.Valid) { accepted.Add((row, index)); } else { invalid.Add(row); }
            }
        }
        Assert.True(batches > 1);
        Assert.Contains(invalid, r => r.Entity == "profile"); Assert.Contains(invalid, r => r.Entity == "weighIn" && r.SchemaVersion == 2);
        // Privileged inventory: no invalid (entity, id, hlc) reached any content or receipt table.
        await using var owner = DatabaseConfiguration.CreateSource(database.MigratorConnection);
        foreach (var table in Tables)
        {
            await using var query = owner.CreateCommand($"SELECT count(*) FROM userdata.{table} t JOIN unnest($2::text[], $3::uuid[], $4::text[]) AS v(entity, id, hlc) ON t.entity=v.entity AND t.id=v.id AND t.hlc=v.hlc WHERE t.user_id=$1");
            query.Parameters.AddWithValue(user.UserId); query.Parameters.AddWithValue(invalid.Select(r => r.Entity).ToArray());
            query.Parameters.AddWithValue(invalid.Select(r => r.Id).ToArray()); query.Parameters.AddWithValue(invalid.Select(r => r.Hlc).ToArray());
            Assert.Equal(0L, await query.ExecuteScalarAsync(Ct));
        }
        // Pull returns exactly the latest accepted version of each (entity, id).
        var latest = accepted.GroupBy(a => (a.Row.Entity, a.Row.Id)).Select(g => g.MaxBy(a => a.Counter).Row).ToArray();
        var rows = await PullAll(client, dataset);
        Assert.Equal(latest.Length, rows.Length);
        foreach (var row in latest) { AssertSame(row, rows.Single(r => r.GetProperty("entity").GetString() == row.Entity && r.GetProperty("id").GetGuid() == row.Id)); }
        Assert.Contains(rows, r => r.GetProperty("entity").GetString() == "weighIn" && r.GetProperty("schemaVersion").GetInt32() == 1);
        Assert.Contains(rows, r => r.GetProperty("entity").GetString() == "weighIn" && r.GetProperty("schemaVersion").GetInt32() == 2);
        Assert.Single(rows, r => r.GetProperty("entity").GetString() == "profile");
    }

    [Fact, Trait("Rule", "05.5-version-identity"), Trait("Rule", "B19.weighIn-versions")]
    public async Task WeighIn_v1_and_v2_coexist_in_pull_history_and_lww()
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync(); var user = await PersonalFoodHttp.Register(h);
        await using var factory = new IdentityApiTests.IdentityApi(database, h); using var client = await PersonalFoodHttp.Client(factory, h, user);
        var dataset = await PersonalFoodHttp.Dataset(client);
        var first = NewRow(h, "weighIn", 1);
        var upgraded = NewRow(h, "weighIn", 2, id: first.Id, counter: 2);
        var stale = NewRow(h, "weighIn", 1, id: first.Id, counter: 1);
        // An old client's newer v1 replaces the v2: LWW by HLC, never an upgrade or downgrade (D6).
        var downgraded = NewRow(h, "weighIn", 1, id: first.Id, counter: 3);
        var other = NewRow(h, "weighIn", 2);
        using (var push = await PersonalFoodHttp.Push(client, h, dataset, [first, upgraded, stale]))
        { Assert.Equal(["accepted", "accepted", "stale"], await Statuses(push)); }
        AssertSame(upgraded, Assert.Single(Changes(await PersonalFoodHttp.Page(client, dataset))));
        var history = Changes(await PersonalFoodHttp.Page(client, dataset, first.Id, "weighIn"));
        Assert.Equal(2, history.Length);
        AssertSame(first, history.Single(c => c.GetProperty("hlc").GetString() == first.Hlc));
        AssertSame(stale, history.Single(c => c.GetProperty("hlc").GetString() == stale.Hlc));
        using (var push = await PersonalFoodHttp.Push(client, h, dataset, [downgraded, other]))
        { Assert.Equal(["accepted", "accepted"], await Statuses(push)); }
        // One pull, mixed versions, each under its own schemaVersion.
        var pulled = await PullAll(client, dataset);
        Assert.Equal(2, pulled.Length);
        AssertSame(downgraded, pulled.Single(c => c.GetProperty("id").GetGuid() == first.Id));
        AssertSame(other, pulled.Single(c => c.GetProperty("id").GetGuid() == other.Id));
        history = Changes(await PersonalFoodHttp.Page(client, dataset, first.Id, "weighIn"));
        Assert.Equal(3, history.Length);
        AssertSame(upgraded, history.Single(c => c.GetProperty("hlc").GetString() == upgraded.Hlc));
        Assert.Equal([1, 1, 2], history.Select(c => c.GetProperty("schemaVersion").GetInt32()).Order());
        // The fingerprint includes schemaVersion: the same (entity, id, hlc) as v2 is a conflict, never an overwrite.
        using (var conflict = await PersonalFoodHttp.Push(client, h, dataset, [first with { SchemaVersion = 2, Raw = upgraded.Raw }]))
        { Assert.Equal(["versionConflict"], await Statuses(conflict)); }
        // A v1 payload sent as 2 and a v2 payload sent as 1 are invalid; version 3 is unsupported.
        using (var mismatch = await PersonalFoodHttp.Push(client, h, dataset,
            [first with { SchemaVersion = 2, Hlc = PersonalFoodHttp.Hlc(h, 9) }, upgraded with { SchemaVersion = 1, Hlc = PersonalFoodHttp.Hlc(h, 10) }, upgraded with { SchemaVersion = 3, Hlc = PersonalFoodHttp.Hlc(h, 11) }]))
        { Assert.Equal(["invalidPayload", "invalidPayload", "unsupported"], await Statuses(mismatch)); }
        Assert.Equal(3, Changes(await PersonalFoodHttp.Page(client, dataset, first.Id, "weighIn")).Length);
        AssertSame(downgraded, (await PullAll(client, dataset)).Single(c => c.GetProperty("id").GetGuid() == first.Id));
    }

    [Fact, Trait("Rule", "B19.no-cross-row-validation")]
    public async Task Cross_row_overlapping_phases_and_same_date_settings_are_admitted_and_pulled()
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync(); var user = await PersonalFoodHttp.Register(h);
        await using var factory = new IdentityApiTests.IdentityApi(database, h); using var client = await PersonalFoodHttp.Client(factory, h, user);
        var dataset = await PersonalFoodHttp.Dataset(client);
        // TD-089: overlapping phases and two settings versions on one date are the app's read projection.
        var weekly = BodyTargetsCases.Raw("goalPhase-base-weekly");
        var settings = BodyTargetsCases.Raw("targetSettings-base");
        var rows = new[]
        {
            NewRow(h, "goalPhase", 1, weekly),
            NewRow(h, "goalPhase", 1, BodyTargetsCases.With(BodyTargetsCases.With(weekly, "startDate", "2026-10-01"), "endDate", "2026-12-31")),
            NewRow(h, "goalPhase", 1, BodyTargetsCases.Raw("goalPhase-base-targetDate")),
            NewRow(h, "targetSettings", 1, settings),
            NewRow(h, "targetSettings", 1, BodyTargetsCases.With(settings, "baseKcal", 1800.5m)),
            NewRow(h, "targetSettings", 1, BodyTargetsCases.Raw("targetSettings-manual-acknowledged-fixed")),
        };
        using (var push = await PersonalFoodHttp.Push(client, h, dataset, rows)) { Assert.All(await Statuses(push), s => Assert.Equal("accepted", s)); }
        var pulled = await PullAll(client, dataset);
        Assert.Equal(rows.Length, pulled.Length);
        foreach (var row in rows) { AssertSame(row, pulled.Single(r => r.GetProperty("id").GetGuid() == row.Id)); }
    }

    [Theory, MemberData(nameof(Pairs)), Trait("Rule", "05.5-version-identity")]
    public async Task Lww_preserves_displaced_and_incoming_losers_and_replays_are_immutable(string entity, int version)
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync(); var user = await PersonalFoodHttp.Register(h);
        await using var factory = new IdentityApiTests.IdentityApi(database, h); using var client = await PersonalFoodHttp.Client(factory, h, user);
        var dataset = await PersonalFoodHttp.Dataset(client); var first = NewRow(h, entity, version);
        var winner = first with { Hlc = PersonalFoodHttp.Hlc(h, 2) }; var stale = first with { Hlc = PersonalFoodHttp.Hlc(h, 1) };
        using (var push = await PersonalFoodHttp.Push(client, h, dataset, [first, winner, stale, winner]))
        { Assert.Equal(["accepted", "accepted", "stale", "accepted"], await Statuses(push)); }
        var history = Changes(await PersonalFoodHttp.Page(client, dataset, first.Id, entity));
        Assert.Equal(2, history.Length); Assert.Contains(history, r => r.GetProperty("hlc").GetString() == first.Hlc); Assert.Contains(history, r => r.GetProperty("hlc").GetString() == stale.Hlc);
        Assert.All(history, r => AssertSame(first, r, hlc: false));
        AssertSame(winner, Assert.Single(Changes(await PersonalFoodHttp.Page(client, dataset))));
        // A replay of an accepted (entity, id, hlc) with different content is a conflict, never an overwrite.
        var changed = first with
        {
            Raw = entity switch
            {
                "profile" => BodyTargetsCases.With(first.Raw, "birthYear", 1991),
                "weighIn" => BodyTargetsCases.With(first.Raw, "note", "Changed note"),
                _ => BodyTargetsCases.With(first.Raw, "revision", 2),
            },
        };
        using (var conflict = await PersonalFoodHttp.Push(client, h, dataset, [changed])) { Assert.Equal(["versionConflict"], await Statuses(conflict)); }
        Assert.Equal(2, Changes(await PersonalFoodHttp.Page(client, dataset, first.Id, entity)).Length);
        AssertSame(winner, Assert.Single(Changes(await PersonalFoodHttp.Page(client, dataset))));
    }

    [Theory, MemberData(nameof(Pairs)), Trait("Rule", "05.5-retention")]
    public async Task Tombstones_compact_by_acceptance_time_and_fence_prevents_resurrection(string entity, int version)
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync(); var user = await PersonalFoodHttp.Register(h);
        await using var factory = new IdentityApiTests.IdentityApi(database, h); using var client = await PersonalFoodHttp.Client(factory, h, user);
        var dataset = await PersonalFoodHttp.Dataset(client); var first = NewRow(h, entity, version);
        // Tombstones carry the full payload; weighIn v2 sends the scrubbed one (D11).
        var raw = entity == "weighIn" && version == 2 ? BodyTargetsCases.Raw("weighIn2-tombstone-scrubbed") : first.Raw;
        var tombstone = first with { Hlc = PersonalFoodHttp.Hlc(h, 1), DeletedAt = h.Clock.GetUtcNow().AddYears(-5), Raw = raw };
        using (var push = await PersonalFoodHttp.Push(client, h, dataset, [first, tombstone])) { Assert.Equal(["accepted", "accepted"], await Statuses(push)); }
        // Compaction is by acceptance time, not by the client's deletedAt.
        await Cleanup(database, h, user.UserId);
        AssertSame(tombstone, Assert.Single(Changes(await PersonalFoodHttp.Page(client, dataset))));
        Assert.Equal(1L, await HistoryCount(database, user.UserId, entity, first.Id));
        await AgeAndCleanup(database, h, user.UserId, entity, first.Id, expireHistory: true);
        Assert.Equal(0L, await HistoryCount(database, user.UserId, entity, first.Id));
        var fence = Assert.Single(Changes(await PersonalFoodHttp.Page(client, dataset)));
        Assert.True(fence.GetProperty("compacted").GetBoolean()); Assert.Empty(fence.GetProperty("payload").EnumerateObject());
        Assert.Equal(tombstone.Hlc, fence.GetProperty("hlc").GetString());
        Assert.Equal(version, fence.GetProperty("schemaVersion").GetInt32());
        Assert.Empty(Changes(await PersonalFoodHttp.Page(client, dataset, first.Id, entity)));
        // An older version (a stale device re-uploading) cannot resurrect the row.
        using (var old = await PersonalFoodHttp.Push(client, h, dataset, [first])) { Assert.Equal(["stale"], await Statuses(old)); }
        Assert.True(Assert.Single(Changes(await PersonalFoodHttp.Page(client, dataset))).GetProperty("compacted").GetBoolean());
        var restore = first with { Hlc = PersonalFoodHttp.Hlc(h, 2) };
        using (var response = await PersonalFoodHttp.Push(client, h, dataset, [restore])) { Assert.Equal(["accepted"], await Statuses(response)); }
        AssertSame(restore, Assert.Single(Changes(await PersonalFoodHttp.Page(client, dataset))));
    }

    [Theory, MemberData(nameof(Pairs)), Trait("Rule", "04.6-rls")]
    public async Task Another_owner_cannot_read_live_history_or_fence_and_same_id_is_independently_owned(string entity, int version)
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync();
        var a = await PersonalFoodHttp.Register(h); var b = await PersonalFoodHttp.Register(h);
        await using var factory = new IdentityApiTests.IdentityApi(database, h);
        using var ca = await PersonalFoodHttp.Client(factory, h, a); using var cb = await PersonalFoodHttp.Client(factory, h, b);
        // profile: both owners use the one natural ID, the real-world case.
        var dataset = await PersonalFoodHttp.Dataset(ca); var row = NewRow(h, entity, version);
        using (var push = await PersonalFoodHttp.Push(ca, h, dataset, [row, row with { Hlc = PersonalFoodHttp.Hlc(h, 1) }])) { Assert.Equal(["accepted", "accepted"], await Statuses(push)); }
        Assert.Empty(Changes(await PersonalFoodHttp.Page(cb, dataset)));
        Assert.Empty(Changes(await PersonalFoodHttp.Page(cb, dataset, row.Id, entity)));
        Assert.Single(Changes(await PersonalFoodHttp.Page(ca, dataset, row.Id, entity)));
        using (var tombstone = await PersonalFoodHttp.Push(ca, h, dataset, [row with { Hlc = PersonalFoodHttp.Hlc(h, 2), DeletedAt = h.Clock.GetUtcNow() }])) { Assert.Equal(["accepted"], await Statuses(tombstone)); }
        await AgeAndCleanup(database, h, a.UserId, entity, row.Id, expireHistory: false);
        Assert.True(Assert.Single(Changes(await PersonalFoodHttp.Page(ca, dataset))).GetProperty("compacted").GetBoolean());
        Assert.Empty(Changes(await PersonalFoodHttp.Page(cb, dataset)));
        Assert.Empty(Changes(await PersonalFoodHttp.Page(cb, dataset, row.Id, entity)));
        // B's same (entity, id) is its own document: A's fence neither blocks nor reveals it.
        using (var own = await PersonalFoodHttp.Push(cb, h, dataset, [row])) { Assert.Equal(["accepted"], await Statuses(own)); }
        AssertSame(row, Assert.Single(Changes(await PersonalFoodHttp.Page(cb, dataset))));
        Assert.True(Assert.Single(Changes(await PersonalFoodHttp.Page(ca, dataset))).GetProperty("compacted").GetBoolean());
        // Forced RLS under B's database identity: none of A's rows are visible.
        await using var session = await database.SessionAsync(b.UserId);
        foreach (var table in Tables)
        {
            await using var count = session.Command($"SELECT count(*) FROM userdata.{table} WHERE user_id=$1"); count.Parameters.AddWithValue(a.UserId);
            Assert.Equal(0L, await count.ExecuteScalarAsync(Ct));
        }
    }

    // S1: one request per path covers the entities; the paths don't depend on the entity.
    [Fact, Trait("Rule", "04.6-authz")]
    public async Task Guests_get_403_for_push_pull_and_item_history_and_unauthenticated_get_401()
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync();
        await using var factory = new IdentityApiTests.IdentityApi(database, h); using var client = await PersonalFoodHttp.Client(factory, h, await h.GuestAsync());
        Row[] rows = [.. BodyTargetsCases.Pairs.Select(p => NewRow(h, p.Entity, p.Version))];
        using (var response = await PersonalFoodHttp.Push(client, h, Guid.NewGuid(), rows)) { Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode); }
        foreach (var path in new[] { "/v1/sync/pull?cursor=0&limit=10", $"/v1/sync/history/profile/{SyncTestIds.ProfileRowId}?cursor=0&limit=10", $"/v1/sync/history/goalPhase/{Guid.CreateVersion7()}?cursor=0&limit=10" })
        {
            using (var response = await client.GetAsync(path, Ct)) { Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode); }
            var token = client.DefaultRequestHeaders.Authorization; client.DefaultRequestHeaders.Authorization = null;
            using (var response = await client.GetAsync(path, Ct)) { Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode); }
            client.DefaultRequestHeaders.Authorization = token;
        }
        client.DefaultRequestHeaders.Authorization = null;
        using (var response = await PersonalFoodHttp.Push(client, h, Guid.NewGuid(), rows)) { Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode); }
    }

    [Fact, Trait("Req", "AC-031")]
    public async Task Delete_account_erases_body_and_targets_live_history_fences_and_receipts_and_preserves_second_owner()
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync();
        var user = await PersonalFoodHttp.Register(h); var other = await PersonalFoodHttp.Register(h);
        await using var factory = new IdentityApiTests.IdentityApi(database, h);
        using var client = await PersonalFoodHttp.Client(factory, h, user); using var otherClient = await PersonalFoodHttp.Client(factory, h, other);
        var dataset = await PersonalFoodHttp.Dataset(client);
        var kept = new List<Row>(); var fences = new List<Row>(); var lives = new List<Row>();
        foreach (var (entity, version) in BodyTargetsCases.Pairs)
        {
            // There is one profile row per account: it is the fence; every other pair has a live row and a fence.
            var fence = NewRow(h, entity, version);
            var batch = new List<Row> { fence, fence with { Hlc = PersonalFoodHttp.Hlc(h, 1), DeletedAt = h.Clock.GetUtcNow() } };
            if (entity != "profile")
            {
                var live = NewRow(h, entity, version);
                batch.AddRange([live, live with { Hlc = PersonalFoodHttp.Hlc(h, 1) }]);
                lives.Add(live);
            }
            using (var push = await PersonalFoodHttp.Push(client, h, dataset, batch)) { Assert.All(await Statuses(push), s => Assert.Equal("accepted", s)); }
            var survivor = entity == "profile" ? fence : lives[^1];
            using (var push = await PersonalFoodHttp.Push(otherClient, h, dataset, [survivor])) { Assert.Equal(["accepted"], await Statuses(push)); }
            kept.Add(survivor); fences.Add(fence);
        }
        foreach (var fence in fences) { await AgeAndCleanup(database, h, user.UserId, fence.Entity, fence.Id, expireHistory: false); }
        var before = await PullAll(client, dataset);
        Assert.Equal(9, before.Length); Assert.Equal(5, before.Count(r => r.GetProperty("compacted").GetBoolean()));
        foreach (var live in lives) { Assert.NotEmpty(Changes(await PersonalFoodHttp.Page(client, dataset, live.Id, live.Entity))); }
        await using var owner = DatabaseConfiguration.CreateSource(database.MigratorConnection);
        // documents / row_history / version_receipts per entity: compaction keeps history (only expiry
        // removes it), every version has an immutable receipt; weighIn holds the v1 and the v2 pair.
        Assert.Equal(new long[] { 1, 1, 2, 2, 2, 4, 2, 2, 4, 4, 4, 8 }, await Inventory(user.UserId));
        foreach (var version in new[] { 1, 2 })
        {
            foreach (var table in new[] { "documents", "row_history" })
            {
                await using var query = owner.CreateCommand($"SELECT count(*) FROM userdata.{table} WHERE user_id=$1 AND entity='weighIn' AND schema_version=$2");
                query.Parameters.AddWithValue(user.UserId); query.Parameters.AddWithValue(version);
                Assert.Equal(2L, await query.ExecuteScalarAsync(Ct));
            }
        }
        using (var erased = await client.DeleteAsync("/v1/me", Ct)) { Assert.Equal(HttpStatusCode.NoContent, erased.StatusCode); }
        using (var revoked = await client.GetAsync("/v1/sync/pull?cursor=0&limit=10", Ct)) { Assert.Equal(HttpStatusCode.Unauthorized, revoked.StatusCode); }
        Assert.Equal(new long[12], await Inventory(user.UserId));
        foreach (var table in Tables)
        {
            await using var query = owner.CreateCommand($"SELECT count(*) FROM userdata.{table} WHERE user_id=$1"); query.Parameters.AddWithValue(user.UserId);
            Assert.Equal(0L, await query.ExecuteScalarAsync(Ct));
        }
        var preserved = await PullAll(otherClient, dataset);
        Assert.Equal(kept.Count, preserved.Length);
        foreach (var row in kept) { AssertSame(row, preserved.Single(r => r.GetProperty("entity").GetString() == row.Entity && r.GetProperty("id").GetGuid() == row.Id)); }
        Assert.Equal(new long[] { 1, 0, 1, 1, 0, 1, 1, 0, 1, 2, 0, 2 }, await Inventory(other.UserId));

        // documents / row_history / version_receipts, per entity.
        async Task<long[]> Inventory(Guid id)
        {
            var counts = new List<long>();
            foreach (var entity in new[] { "profile", "goalPhase", "targetSettings", "weighIn" })
            {
                foreach (var table in Tables)
                {
                    await using var query = owner.CreateCommand($"SELECT count(*) FROM userdata.{table} WHERE user_id=$1 AND entity=$2");
                    query.Parameters.AddWithValue(id); query.Parameters.AddWithValue(entity);
                    counts.Add((long)(await query.ExecuteScalarAsync(Ct))!);
                }
            }
            return [.. counts];
        }
    }
}
