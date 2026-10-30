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
}
