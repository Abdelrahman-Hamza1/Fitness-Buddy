using System.Net;
using System.Text.Json;
using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.TestData;
using static FitnessBuddy.Persistence.Tests.SyncHttpSupport;
using Row = FitnessBuddy.Persistence.Tests.PersonalFoodHttp.Row;

namespace FitnessBuddy.Persistence.Tests;

// B20: measurementType and measurement ride the entity-agnostic B05 storage (push/pull/history,
// LWW, receipts, retention fences, RLS, erasure) through the real authenticated host; admission is
// the schema plus exactly M1–M3, and a measurement's type reference is never checked across rows.
[Trait("Req", "WB-040")]
[Trait("Req", "WB-042")]
[Trait("Req", "AC-010")]
[Trait("Req", "AC-012")]
public sealed class MeasurementSyncTests(PostgresFixture database)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;
    private static readonly string[] Tables = ["documents", "row_history", "version_receipts"];

    public static TheoryData<string> Entities() => new(MeasurementCases.Entities);

    private static Row NewRow(IdentityHarness h, string entity, string? raw = null, Guid? id = null, int counter = 0, DateTimeOffset? deleted = null) =>
        PersonalFoodHttp.NewRow(h, raw ?? PersonalFoodHttp.Fixture(entity), deleted, entity, id ?? MeasurementCases.NewId(entity)) with { Hlc = PersonalFoodHttp.Hlc(h, counter) };

    private static async Task<string[]> Statuses(HttpResponseMessage response)
    {
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        return [.. (await PersonalFoodHttp.Json(response)).GetProperty("results").EnumerateArray().Select(r => r.GetProperty("reason").GetString() ?? r.GetProperty("status").GetString()!)];
    }

    // Owner reads return the exact payload.
    private static void AssertSame(Row row, JsonElement change, bool hlc = true)
    {
        Assert.Equal(row.Entity, change.GetProperty("entity").GetString());
        Assert.Equal(row.Id, change.GetProperty("id").GetGuid());
        Assert.Equal(1, change.GetProperty("schemaVersion").GetInt32());
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
        var invalid = new List<Row>(); var accepted = new List<Row>(); var batches = 0; var counter = 0;
        // Raw JSON keeps duplicate keys, number spellings and lone-surrogate escapes through HTTP binding.
        foreach (var group in ByteBoundedCases(MeasurementCases.All(), c => c.Raw))
        {
            batches++;
            var entries = group.Select(c =>
            {
                counter++;
                return (Case: c, Row: NewRow(h, c.Entity, c.Raw, MeasurementCases.IdOf(c), counter, c.Deleted ? h.Clock.GetUtcNow() : null));
            }).ToArray();
            var neighbor = NewRow(h, MeasurementCases.Entities[batches % 2]); accepted.Add(neighbor);
            using var response = await PersonalFoodHttp.Push(client, h, dataset, [neighbor, .. entries.Select(e => e.Row)]);
            Assert.Equal(HttpStatusCode.OK, response.StatusCode);
            var ack = await response.Content.ReadAsStringAsync(Ct);
            // Results carry no content: only id/entity/hlc/status/reason come back.
            Assert.DoesNotContain("synthetic", ack, StringComparison.OrdinalIgnoreCase);
            Assert.DoesNotContain("Left arm", ack, StringComparison.OrdinalIgnoreCase);
            using var result = JsonDocument.Parse(ack);
            var results = result.RootElement.GetProperty("results").EnumerateArray().ToArray();
            Assert.Equal(entries.Length + 1, results.Length);
            Assert.Equal("accepted", results[0].GetProperty("status").GetString());
            for (var i = 0; i < entries.Length; i++)
            {
                var (test, row) = entries[i]; var item = results[i + 1];
                Assert.Equal(row.Id, item.GetProperty("id").GetGuid());
                Assert.Equal(row.Entity, item.GetProperty("entity").GetString());
                Assert.Equal(row.Hlc, item.GetProperty("hlc").GetString());
                Assert.True((test.Valid ? "accepted" : "invalid") == item.GetProperty("status").GetString(), test.Id);
                Assert.Equal(test.Valid ? null : "invalidPayload", item.GetProperty("reason").GetString());
                Assert.Equal(["entity", "hlc", "id", "reason", "status"], item.EnumerateObject().Select(p => p.Name).Order(StringComparer.Ordinal));
                if (test.Valid) { accepted.Add(row); } else { invalid.Add(row); }
            }
        }
        Assert.True(batches > 1);
        Assert.Contains(invalid, r => r.Entity == "measurement"); Assert.Contains(invalid, r => r.Entity == "measurementType");
        // Privileged inventory: no invalid (entity, id, hlc) reached any content or receipt table.
        await using var owner = DatabaseConfiguration.CreateSource(database.MigratorConnection);
        foreach (var table in Tables)
        {
            await using var query = owner.CreateCommand($"SELECT count(*) FROM userdata.{table} t JOIN unnest($2::text[], $3::uuid[], $4::text[]) AS v(entity, id, hlc) ON t.entity=v.entity AND t.id=v.id AND t.hlc=v.hlc WHERE t.user_id=$1");
            query.Parameters.AddWithValue(user.UserId); query.Parameters.AddWithValue(invalid.Select(r => r.Entity).ToArray());
            query.Parameters.AddWithValue(invalid.Select(r => r.Id).ToArray()); query.Parameters.AddWithValue(invalid.Select(r => r.Hlc).ToArray());
            Assert.Equal(0L, await query.ExecuteScalarAsync(Ct));
        }
        // Every accepted case has its own ID: pull returns each exactly.
        var rows = await PullAll(client, dataset);
        Assert.Equal(accepted.Count, rows.Length);
        foreach (var row in accepted) { AssertSame(row, rows.Single(r => r.GetProperty("entity").GetString() == row.Entity && r.GetProperty("id").GetGuid() == row.Id)); }
        Assert.Contains(rows, r => r.GetProperty("entity").GetString() == "measurementType");
        Assert.Contains(rows, r => r.GetProperty("deletedAt").ValueKind != JsonValueKind.Null);
    }

    [Theory, MemberData(nameof(Entities)), Trait("Rule", "05.5-version-identity")]
    public async Task Lww_preserves_displaced_and_incoming_losers_and_replays_are_immutable(string entity)
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync(); var user = await PersonalFoodHttp.Register(h);
        await using var factory = new IdentityApiTests.IdentityApi(database, h); using var client = await PersonalFoodHttp.Client(factory, h, user);
        var dataset = await PersonalFoodHttp.Dataset(client); var first = NewRow(h, entity);
        var winner = first with { Hlc = PersonalFoodHttp.Hlc(h, 2) }; var stale = first with { Hlc = PersonalFoodHttp.Hlc(h, 1) };
        using (var push = await PersonalFoodHttp.Push(client, h, dataset, [first, winner, stale, winner]))
        { Assert.Equal(["accepted", "accepted", "stale", "accepted"], await Statuses(push)); }
        var history = Changes(await PersonalFoodHttp.Page(client, dataset, first.Id, entity));
        Assert.Equal(2, history.Length); Assert.Contains(history, r => r.GetProperty("hlc").GetString() == first.Hlc); Assert.Contains(history, r => r.GetProperty("hlc").GetString() == stale.Hlc);
        Assert.All(history, r => AssertSame(first, r, hlc: false));
        AssertSame(winner, Assert.Single(Changes(await PersonalFoodHttp.Page(client, dataset))));
        // A replay of an accepted (entity, id, hlc) with different content is a conflict, never an overwrite.
        var changed = first with { Raw = entity == "measurement" ? MeasurementCases.With(first.Raw, "value", 93.5m) : MeasurementCases.With(first.Raw, "name", "Changed name") };
        using (var conflict = await PersonalFoodHttp.Push(client, h, dataset, [changed])) { Assert.Equal(["versionConflict"], await Statuses(conflict)); }
        Assert.Equal(2, Changes(await PersonalFoodHttp.Page(client, dataset, first.Id, entity)).Length);
        AssertSame(winner, Assert.Single(Changes(await PersonalFoodHttp.Page(client, dataset))));
    }

    [Theory, MemberData(nameof(Entities)), Trait("Rule", "05.5-retention")]
    public async Task Tombstones_compact_by_acceptance_time_and_fence_prevents_resurrection(string entity)
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync(); var user = await PersonalFoodHttp.Register(h);
        await using var factory = new IdentityApiTests.IdentityApi(database, h); using var client = await PersonalFoodHttp.Client(factory, h, user);
        var dataset = await PersonalFoodHttp.Dataset(client); var first = NewRow(h, entity);
        // The scrubbed tombstone (D8): a type name "", a measurement's values 0 with its pairing kept.
        var raw = MeasurementCases.Raw(entity == "measurement" ? "measurement-tombstone-scrubbed-waist" : "measurementType-tombstone-scrubbed");
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
        Assert.Empty(Changes(await PersonalFoodHttp.Page(client, dataset, first.Id, entity)));
        // An older version (a stale device re-uploading) cannot resurrect the row.
        using (var old = await PersonalFoodHttp.Push(client, h, dataset, [first])) { Assert.Equal(["stale"], await Statuses(old)); }
        Assert.True(Assert.Single(Changes(await PersonalFoodHttp.Page(client, dataset))).GetProperty("compacted").GetBoolean());
        var restore = first with { Hlc = PersonalFoodHttp.Hlc(h, 2) };
        using (var response = await PersonalFoodHttp.Push(client, h, dataset, [restore])) { Assert.Equal(["accepted"], await Statuses(response)); }
        AssertSame(restore, Assert.Single(Changes(await PersonalFoodHttp.Page(client, dataset))));
    }

    [Theory, MemberData(nameof(Entities)), Trait("Rule", "04.6-rls")]
    public async Task Another_owner_cannot_read_live_history_or_fence_and_same_id_is_independently_owned(string entity)
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync();
        var a = await PersonalFoodHttp.Register(h); var b = await PersonalFoodHttp.Register(h);
        await using var factory = new IdentityApiTests.IdentityApi(database, h);
        using var ca = await PersonalFoodHttp.Client(factory, h, a); using var cb = await PersonalFoodHttp.Client(factory, h, b);
        var dataset = await PersonalFoodHttp.Dataset(ca); var row = NewRow(h, entity);
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

    // One request per path; the paths don't depend on the entity.
    [Fact, Trait("Rule", "04.6-authz")]
    public async Task Guests_get_403_for_push_pull_and_item_history_and_unauthenticated_get_401()
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync();
        await using var factory = new IdentityApiTests.IdentityApi(database, h); using var client = await PersonalFoodHttp.Client(factory, h, await h.GuestAsync());
        Row[] rows = [.. MeasurementCases.Entities.Select(e => NewRow(h, e))];
        using (var response = await PersonalFoodHttp.Push(client, h, Guid.NewGuid(), rows)) { Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode); }
        foreach (var path in new[] { "/v1/sync/pull?cursor=0&limit=10", $"/v1/sync/history/measurementType/{Guid.CreateVersion7()}?cursor=0&limit=10", $"/v1/sync/history/measurement/{Guid.CreateVersion7()}?cursor=0&limit=10" })
        {
            using (var response = await client.GetAsync(path, Ct)) { Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode); }
            var token = client.DefaultRequestHeaders.Authorization; client.DefaultRequestHeaders.Authorization = null;
            using (var response = await client.GetAsync(path, Ct)) { Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode); }
            client.DefaultRequestHeaders.Authorization = token;
        }
        client.DefaultRequestHeaders.Authorization = null;
        using (var response = await PersonalFoodHttp.Push(client, h, Guid.NewGuid(), rows)) { Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode); }
    }

    // D9 (A15b D25): the server never reads other rows, so a measurement before its type, after the
    // type's tombstone, or pointing at another owner's type ID is admitted and pulled; no cascade.
    [Fact, Trait("Rule", "B20.no-cross-row-validation")]
    public async Task Orphan_and_tombstoned_type_references_are_admitted_and_pulled()
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync();
        var a = await PersonalFoodHttp.Register(h); var b = await PersonalFoodHttp.Register(h);
        await using var factory = new IdentityApiTests.IdentityApi(database, h);
        using var ca = await PersonalFoodHttp.Client(factory, h, a); using var cb = await PersonalFoodHttp.Client(factory, h, b);
        var dataset = await PersonalFoodHttp.Dataset(ca);
        var custom = MeasurementCases.Raw("measurement-base-custom-cm");
        string Pointing(Guid type) => MeasurementCases.With(custom, "customTypeId", type.ToString());
        var typeId = Guid.CreateVersion7(); var othersType = Guid.CreateVersion7();
        using (var push = await PersonalFoodHttp.Push(cb, h, dataset, [NewRow(h, "measurementType", id: othersType)])) { Assert.Equal(["accepted"], await Statuses(push)); }
        var before = NewRow(h, "measurement", Pointing(typeId));
        var type = NewRow(h, "measurementType", id: typeId);
        var typeTombstone = type with { Hlc = PersonalFoodHttp.Hlc(h, 1), DeletedAt = h.Clock.GetUtcNow() };
        var after = NewRow(h, "measurement", Pointing(typeId), counter: 2);
        var foreign = NewRow(h, "measurement", Pointing(othersType));
        var neverCreated = NewRow(h, "measurement", Pointing(Guid.NewGuid()));
        using (var push = await PersonalFoodHttp.Push(ca, h, dataset, [before, type, typeTombstone, after, foreign, neverCreated]))
        { Assert.All(await Statuses(push), s => Assert.Equal("accepted", s)); }
        var pulled = await PullAll(ca, dataset);
        Assert.Equal(5, pulled.Length);
        AssertSame(typeTombstone, pulled.Single(r => r.GetProperty("id").GetGuid() == typeId));
        // The measurements stay live: the type's tombstone doesn't cascade.
        foreach (var row in new[] { before, after, foreign, neverCreated }) { AssertSame(row, pulled.Single(r => r.GetProperty("id").GetGuid() == row.Id)); }
        // B's type is untouched and still invisible to A.
        Assert.DoesNotContain(pulled, r => r.GetProperty("id").GetGuid() == othersType);
        Assert.Single(Changes(await PersonalFoodHttp.Page(cb, dataset)));
    }

    [Fact, Trait("Req", "AC-031")]
    public async Task Delete_account_erases_measurement_live_history_fences_and_receipts_and_preserves_second_owner()
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync();
        var user = await PersonalFoodHttp.Register(h); var other = await PersonalFoodHttp.Register(h);
        await using var factory = new IdentityApiTests.IdentityApi(database, h);
        using var client = await PersonalFoodHttp.Client(factory, h, user); using var otherClient = await PersonalFoodHttp.Client(factory, h, other);
        var dataset = await PersonalFoodHttp.Dataset(client);
        var kept = new List<Row>(); var fences = new List<Row>(); var lives = new List<Row>();
        foreach (var entity in MeasurementCases.Entities)
        {
            // Per entity: a live row with a displaced version, and a compacted fence.
            var fence = NewRow(h, entity); var live = NewRow(h, entity);
            Row[] batch = [fence, fence with { Hlc = PersonalFoodHttp.Hlc(h, 1), DeletedAt = h.Clock.GetUtcNow() }, live, live with { Hlc = PersonalFoodHttp.Hlc(h, 1) }];
            using (var push = await PersonalFoodHttp.Push(client, h, dataset, batch)) { Assert.All(await Statuses(push), s => Assert.Equal("accepted", s)); }
            using (var push = await PersonalFoodHttp.Push(otherClient, h, dataset, [live])) { Assert.Equal(["accepted"], await Statuses(push)); }
            kept.Add(live); fences.Add(fence); lives.Add(live);
        }
        foreach (var fence in fences) { await AgeAndCleanup(database, h, user.UserId, fence.Entity, fence.Id, expireHistory: false); }
        var before = await PullAll(client, dataset);
        Assert.Equal(4, before.Length); Assert.Equal(2, before.Count(r => r.GetProperty("compacted").GetBoolean()));
        foreach (var live in lives) { Assert.NotEmpty(Changes(await PersonalFoodHttp.Page(client, dataset, live.Id, live.Entity))); }
        await using var owner = DatabaseConfiguration.CreateSource(database.MigratorConnection);
        // documents / row_history / version_receipts per entity: compaction keeps history (only expiry
        // removes it), and every version has an immutable receipt.
        Assert.Equal(new long[] { 2, 2, 4, 2, 2, 4 }, await Inventory(user.UserId));
        using (var erased = await client.DeleteAsync("/v1/me", Ct)) { Assert.Equal(HttpStatusCode.NoContent, erased.StatusCode); }
        using (var revoked = await client.GetAsync("/v1/sync/pull?cursor=0&limit=10", Ct)) { Assert.Equal(HttpStatusCode.Unauthorized, revoked.StatusCode); }
        Assert.Equal(new long[6], await Inventory(user.UserId));
        foreach (var table in Tables)
        {
            await using var query = owner.CreateCommand($"SELECT count(*) FROM userdata.{table} WHERE user_id=$1"); query.Parameters.AddWithValue(user.UserId);
            Assert.Equal(0L, await query.ExecuteScalarAsync(Ct));
        }
        var preserved = await PullAll(otherClient, dataset);
        Assert.Equal(kept.Count, preserved.Length);
        foreach (var row in kept) { AssertSame(row, preserved.Single(r => r.GetProperty("entity").GetString() == row.Entity && r.GetProperty("id").GetGuid() == row.Id)); }
        Assert.Equal(new long[] { 1, 0, 1, 1, 0, 1 }, await Inventory(other.UserId));

        // documents / row_history / version_receipts, per entity.
        async Task<long[]> Inventory(Guid id)
        {
            var counts = new List<long>();
            foreach (var entity in MeasurementCases.Entities)
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
