using System.Net;
using System.Text.Json;
using FitnessBuddy.TestData;
using static FitnessBuddy.Persistence.Tests.SyncHttpSupport;
using Row = FitnessBuddy.Persistence.Tests.PersonalFoodHttp.Row;

namespace FitnessBuddy.Persistence.Tests;

// A62a: diaryEntry and savedMealItem v1 and v2 through the real authenticated host (A62b: dayMark
// v2 joins the downgrade refusal). v2 adds the
// estimate flags (W1–W3), and the server refuses a lower schema version over a stored v2 whatever
// its HLC (TD-114, A62 D23), so an old build editing its v1 copy can't erase an estimate.
[Trait("Req", "DY-005")]
[Trait("Req", "AC-010")]
[Trait("Req", "AC-012")]
public sealed class DiaryEstimateSyncTests(PostgresFixture database)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    public static TheoryData<string> Entities() => new(DiaryEstimateCases.Entities);

    // A62b: dayMark (v2 estimateKcal) is downgrade-protected too; its old edit flips `incomplete`.
    public static TheoryData<string> DowngradeProtected() => new(DiaryEstimateCases.DowngradeProtected);

    private static Row NewRow(IdentityHarness h, string entity, int version, Guid id, int counter, string? raw = null, DateTimeOffset? deleted = null) =>
        PersonalFoodHttp.NewRow(h, raw ?? DiaryEstimateCases.Fixture(entity, version), deleted, entity, id, version) with { Hlc = PersonalFoodHttp.Hlc(h, counter) };

    private static string EditedV1(string entity) => DiaryEstimateCases.EditedV1(entity);

    private static async Task<string[]> Statuses(HttpResponseMessage response)
    {
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadAsStringAsync(Ct);
        // Results carry no content, never a refused value.
        Assert.DoesNotContain("synthetic", body, StringComparison.OrdinalIgnoreCase);
        Assert.DoesNotContain("Estimate", body, StringComparison.Ordinal);
        using var document = JsonDocument.Parse(body);
        return [.. document.RootElement.GetProperty("results").EnumerateArray().Select(r => r.GetProperty("reason").GetString() ?? r.GetProperty("status").GetString()!)];
    }

    private static async Task<string[]> Push(HttpClient client, IdentityHarness h, Guid dataset, params Row[] rows)
    {
        using var response = await PersonalFoodHttp.Push(client, h, dataset, rows);
        return await Statuses(response);
    }

    private static void AssertSame(Row row, JsonElement change)
    {
        Assert.Equal(row.Entity, change.GetProperty("entity").GetString());
        Assert.Equal(row.Id, change.GetProperty("id").GetGuid());
        Assert.Equal(row.SchemaVersion, change.GetProperty("schemaVersion").GetInt32());
        Assert.Equal(row.Hlc, change.GetProperty("hlc").GetString());
        Assert.Equal(row.DeletedAt is null, change.GetProperty("deletedAt").ValueKind == JsonValueKind.Null);
        using var expected = JsonDocument.Parse(row.Raw);
        Assert.True(JsonElement.DeepEquals(expected.RootElement, change.GetProperty("payload")), $"{row.Entity} {row.Hlc}");
    }

    private static async Task<JsonElement[]> History(HttpClient client, Guid dataset, Row row) =>
        [.. (await PersonalFoodHttp.Page(client, dataset, row.Id, row.Entity)).GetProperty("changes").EnumerateArray()];

    [Fact, Trait("Rule", "A62.shared-vectors")]
    public async Task Corpus_over_http_is_admitted_exactly_when_serverAccepts_and_rejected_rows_are_not_stored()
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync(); var user = await PersonalFoodHttp.Register(h);
        await using var factory = new IdentityApiTests.IdentityApi(database, h); using var client = await PersonalFoodHttp.Client(factory, h, user);
        var dataset = await PersonalFoodHttp.Dataset(client);
        var accepted = new List<Row>(); var batches = 0;
        foreach (var group in ByteBoundedCases(DiaryEstimateCases.Corpus(), c => c.Raw))
        {
            batches++;
            var rows = group.Select(c => NewRow(h, c.Entity, c.SchemaVersion, Guid.CreateVersion7(), 0, c.Raw)).ToArray();
            var statuses = await Push(client, h, dataset, rows);
            Assert.Equal(rows.Length, statuses.Length);
            for (var i = 0; i < rows.Length; i++)
            {
                Assert.True((group[i].Valid ? "accepted" : "invalidPayload") == statuses[i], group[i].Id);
                if (group[i].Valid) { accepted.Add(rows[i]); }
            }
        }
        Assert.True(batches >= 1);
        var pulled = await PullAll(client, dataset);
        Assert.Equal(accepted.Count, pulled.Length);
        foreach (var row in accepted) { AssertSame(row, pulled.Single(c => c.GetProperty("id").GetGuid() == row.Id)); }
    }

    [Theory, MemberData(nameof(DowngradeProtected)), Trait("Rule", "A62.downgrade-refusal"), Trait("Req", "DY-006")]
    public async Task A_v1_write_over_a_stored_v2_is_refused_whatever_its_hlc_and_kept_in_history(string entity)
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync(); var user = await PersonalFoodHttp.Register(h);
        await using var factory = new IdentityApiTests.IdentityApi(database, h); using var client = await PersonalFoodHttp.Client(factory, h, user);
        var dataset = await PersonalFoodHttp.Dataset(client);
        var id = Guid.CreateVersion7();
        var existing = NewRow(h, entity, 1, id, 1);
        var estimate = NewRow(h, entity, 2, id, 2);
        Assert.Equal(["accepted", "accepted"], await Push(client, h, dataset, existing, estimate));
        // The old client edits (newer HLC), replays an older copy and deletes: all refused, nothing replaced.
        var oldEdit = NewRow(h, entity, 1, id, 3, EditedV1(entity));
        var oldOlder = NewRow(h, entity, 1, id, 0, EditedV1(entity));
        var oldDelete = NewRow(h, entity, 1, id, 4, deleted: h.Clock.GetUtcNow());
        Assert.Equal(["unsupported", "unsupported", "unsupported"], await Push(client, h, dataset, oldEdit, oldOlder, oldDelete));
        AssertSame(estimate, Assert.Single(await PullAll(client, dataset)));
        // No loss server-side: the refused versions are in history next to the replaced v1.
        var history = await History(client, dataset, estimate);
        Assert.Equal(4, history.Length);
        foreach (var row in new[] { existing, oldEdit, oldOlder, oldDelete })
        { AssertSame(row, history.Single(c => c.GetProperty("hlc").GetString() == row.Hlc)); }
        // A replay gets the same answer, also after the cleanup job, and the same HLC with other content conflicts.
        Assert.Equal(["unsupported"], await Push(client, h, dataset, oldEdit));
        await Cleanup(database, h, user.UserId);
        Assert.Equal(["unsupported", "versionConflict"], await Push(client, h, dataset, oldEdit, oldEdit with { Raw = DiaryEstimateCases.Fixture(entity, 1) }));
        AssertSame(estimate, Assert.Single(await PullAll(client, dataset)));
        // v2 over v2 stays ordinary last-write-wins, tombstones included.
        var newer = NewRow(h, entity, 2, id, 5, deleted: h.Clock.GetUtcNow());
        Assert.Equal(["accepted"], await Push(client, h, dataset, newer));
        AssertSame(newer, Assert.Single(await PullAll(client, dataset)));
        Assert.Equal(["unsupported"], await Push(client, h, dataset, NewRow(h, entity, 1, id, 6)));
    }

    [Theory, MemberData(nameof(DowngradeProtected)), Trait("Rule", "A62.downgrade-refusal"), Trait("Req", "DY-006")]
    public async Task An_old_edit_that_arrives_first_wins_by_hlc_because_no_v2_was_stored(string entity)
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync(); var user = await PersonalFoodHttp.Register(h);
        await using var factory = new IdentityApiTests.IdentityApi(database, h); using var client = await PersonalFoodHttp.Client(factory, h, user);
        var dataset = await PersonalFoodHttp.Dataset(client);
        var id = Guid.CreateVersion7();
        var existing = NewRow(h, entity, 1, id, 1);
        var oldEdit = NewRow(h, entity, 1, id, 3, EditedV1(entity));
        Assert.Equal(["accepted", "accepted"], await Push(client, h, dataset, existing, oldEdit));
        // D23 order (b): the upgraded device's v2 has an older HLC than the stored v1: stale, never a refusal.
        var estimate = NewRow(h, entity, 2, id, 2);
        Assert.Equal(["stale"], await Push(client, h, dataset, estimate));
        AssertSame(oldEdit, Assert.Single(await PullAll(client, dataset)));
        Assert.Contains(await History(client, dataset, estimate), c => c.GetProperty("hlc").GetString() == estimate.Hlc);
        // A newer v2 over the stored v1 is an ordinary upgrade; from then on v1 is refused.
        var upgraded = NewRow(h, entity, 2, id, 4);
        Assert.Equal(["accepted", "unsupported"], await Push(client, h, dataset, upgraded, NewRow(h, entity, 1, id, 5, EditedV1(entity))));
        AssertSame(upgraded, Assert.Single(await PullAll(client, dataset)));
    }

    [Fact, Trait("Rule", "B19.weighIn-versions")]
    public async Task WeighIn_is_not_downgrade_protected()
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync(); var user = await PersonalFoodHttp.Register(h);
        await using var factory = new IdentityApiTests.IdentityApi(database, h); using var client = await PersonalFoodHttp.Client(factory, h, user);
        var dataset = await PersonalFoodHttp.Dataset(client);
        var id = Guid.NewGuid();
        var v1 = PersonalFoodHttp.Fixture("weighIn");
        using var v2Fixture = DiaryEstimateCases.Read("entity-payloads-v2.json");
        var v2 = v2Fixture.RootElement.GetProperty("weighIn").GetRawText();
        Assert.Equal(["accepted", "accepted"], await Push(client, h, dataset,
            PersonalFoodHttp.NewRow(h, v2, null, "weighIn", id, 2) with { Hlc = PersonalFoodHttp.Hlc(h, 1) },
            PersonalFoodHttp.NewRow(h, v1, null, "weighIn", id, 1) with { Hlc = PersonalFoodHttp.Hlc(h, 2) }));
    }
}
