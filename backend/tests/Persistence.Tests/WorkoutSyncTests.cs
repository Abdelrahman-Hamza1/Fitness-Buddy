using System.Net;
using System.Text.Json;
using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.Modules.UserData.Infrastructure;
using FitnessBuddy.TestData;
using static FitnessBuddy.Persistence.Tests.SyncHttpSupport;
using Row = FitnessBuddy.Persistence.Tests.PersonalFoodHttp.Row;

namespace FitnessBuddy.Persistence.Tests;

// B21: the seven workout entities ride the entity-agnostic B05 storage (push/pull/history, LWW,
// receipts, retention fences, RLS, erasure) through the real authenticated host. Admission is the
// schema plus exactly W1–W5; aggregates are not a server concept, so children arrive in any order,
// under any parent, and a removed child revived with its ID is an ordinary newer version (D4, D5).
[Trait("Req", "WO-003")]
[Trait("Req", "WO-010")]
[Trait("Req", "WO-020")]
[Trait("Req", "WO-021")]
[Trait("Req", "AC-010")]
[Trait("Req", "AC-012")]
public sealed class WorkoutSyncTests(PostgresFixture database)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;
    private static readonly string[] Tables = ["documents", "row_history", "version_receipts"];

    // Neighbours and default rows avoid weeklyPlanDay: its row ID is fixed by the weekday (W5).
    private static readonly string[] FreeIdEntities = [.. WorkoutCases.Entities.Where(e => e != "weeklyPlanDay")];

    public static TheoryData<string> Entities() => new(WorkoutCases.Entities);

    private static Row NewRow(IdentityHarness h, string entity, string? raw = null, Guid? id = null, int counter = 0, DateTimeOffset? deleted = null) =>
        PersonalFoodHttp.NewRow(h, raw ?? PersonalFoodHttp.Fixture(entity), deleted, entity, id ?? WorkoutCases.NewId(entity)) with { Hlc = PersonalFoodHttp.Hlc(h, counter) };

    // A row of entity with its own ID: the plan day of ISO weekday n (its natural ID), any other
    // entity's fixture under a fresh UUIDv7.
    private static Row Distinct(IdentityHarness h, string entity, int n) => entity == "weeklyPlanDay"
        ? NewRow(h, entity, WorkoutCases.With(PersonalFoodHttp.Fixture(entity), "weekday", n), WorkoutPayloadValidator.PlanDayIds[n - 1])
        : NewRow(h, entity, id: Guid.CreateVersion7());

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

    private static JsonElement Pulled(JsonElement[] rows, Row row) =>
        rows.Single(r => r.GetProperty("entity").GetString() == row.Entity && r.GetProperty("id").GetGuid() == row.Id);

    [Fact, Trait("Rule", "05.5-payload-validation")]
    public async Task Batched_matrix_preserves_result_order_and_valid_neighbors_without_persisting_invalid_versions()
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync();
        var user = await PersonalFoodHttp.Register(h);
        await using var factory = new IdentityApiTests.IdentityApi(database, h);
        using var client = await PersonalFoodHttp.Client(factory, h, user);
        var dataset = await PersonalFoodHttp.Dataset(client);
        var invalid = new List<Row>(); var latest = new Dictionary<(string, Guid), Row>(); var batches = 0; var counter = 0;
        // Raw JSON keeps duplicate keys, number spellings and lone-surrogate escapes through HTTP binding.
        foreach (var group in ByteBoundedCases(WorkoutCases.All(), c => c.Raw))
        {
            batches++;
            var neighbor = NewRow(h, FreeIdEntities[batches % FreeIdEntities.Length], id: Guid.CreateVersion7(), counter: ++counter);
            var entries = group.Select(c => (Case: c, Row: NewRow(h, c.Entity, c.Raw, WorkoutCases.IdOf(c), ++counter, c.Deleted ? h.Clock.GetUtcNow() : null))).ToArray();
            latest[(neighbor.Entity, neighbor.Id)] = neighbor;
            using var response = await PersonalFoodHttp.Push(client, h, dataset, [neighbor, .. entries.Select(e => e.Row)]);
            Assert.Equal(HttpStatusCode.OK, response.StatusCode);
            var ack = await response.Content.ReadAsStringAsync(Ct);
            // Results carry no content: only id/entity/hlc/status/reason come back.
            foreach (var canary in new[] { "synthetic", "Incline", "Push", "bench_press", "shoulders" })
            { Assert.DoesNotContain(canary, ack, StringComparison.OrdinalIgnoreCase); }
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
                // HLCs only grow, so every valid case is a newer version of its (entity, id).
                Assert.True((test.Valid ? "accepted" : "invalid") == item.GetProperty("status").GetString(), test.Id);
                Assert.Equal(test.Valid ? null : "invalidPayload", item.GetProperty("reason").GetString());
                Assert.Equal(["entity", "hlc", "id", "reason", "status"], item.EnumerateObject().Select(p => p.Name).Order(StringComparer.Ordinal));
                if (test.Valid) { latest[(row.Entity, row.Id)] = row; } else { invalid.Add(row); }
            }
        }
        Assert.True(batches > 1);
        Assert.Equal(WorkoutCases.Entities.Order(StringComparer.Ordinal), invalid.Select(r => r.Entity).Distinct().Order(StringComparer.Ordinal));
        // Privileged inventory: no invalid (entity, id, hlc) reached any content or receipt table.
        await using var owner = DatabaseConfiguration.CreateSource(database.MigratorConnection);
        foreach (var table in Tables)
        {
            await using var query = owner.CreateCommand($"SELECT count(*) FROM userdata.{table} t JOIN unnest($2::text[], $3::uuid[], $4::text[]) AS v(entity, id, hlc) ON t.entity=v.entity AND t.id=v.id AND t.hlc=v.hlc WHERE t.user_id=$1");
            query.Parameters.AddWithValue(user.UserId); query.Parameters.AddWithValue(invalid.Select(r => r.Entity).ToArray());
            query.Parameters.AddWithValue(invalid.Select(r => r.Id).ToArray()); query.Parameters.AddWithValue(invalid.Select(r => r.Hlc).ToArray());
            Assert.Equal(0L, await query.ExecuteScalarAsync(Ct));
        }
        // Pull returns each document's newest accepted version exactly (plan-day cases share natural IDs).
        var rows = await PullAll(client, dataset);
        Assert.Equal(latest.Count, rows.Length);
        foreach (var row in latest.Values) { AssertSame(row, Pulled(rows, row)); }
        Assert.Equal(WorkoutCases.Entities.Order(StringComparer.Ordinal), rows.Select(r => r.GetProperty("entity").GetString()!).Distinct().Order(StringComparer.Ordinal));
        Assert.Contains(rows, r => r.GetProperty("deletedAt").ValueKind != JsonValueKind.Null);
    }

    // A content change per entity that keeps the row wire-valid.
    private static string Changed(Row row) => row.Entity switch
    {
        "customExercise" or "workoutTemplate" => WorkoutCases.With(row.Raw, "name", "Changed name"),
        "workoutSession" => WorkoutCases.With(row.Raw, "name", null),
        "sessionExercise" => WorkoutCases.With(row.Raw, "position", 1),
        "workoutSet" => WorkoutCases.With(row.Raw, "reps", 9),
        "workoutTemplateItem" => WorkoutCases.With(row.Raw, "targetSets", 4),
        "weeklyPlanDay" => WorkoutCases.With(row.Raw, "templateId", null),
        _ => throw new ArgumentOutOfRangeException(nameof(row), row.Entity, "not a workout entity"),
    };

    [Theory, MemberData(nameof(Entities)), Trait("Rule", "05.5-version-identity")]
    public async Task Lww_preserves_displaced_and_incoming_losers_and_replays_are_immutable(string entity)
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync(); var user = await PersonalFoodHttp.Register(h);
        await using var factory = new IdentityApiTests.IdentityApi(database, h); using var client = await PersonalFoodHttp.Client(factory, h, user);
        var dataset = await PersonalFoodHttp.Dataset(client); var first = NewRow(h, entity);
        var winner = first with { Hlc = PersonalFoodHttp.Hlc(h, 2), Raw = Changed(first) }; var stale = first with { Hlc = PersonalFoodHttp.Hlc(h, 1) };
        using (var push = await PersonalFoodHttp.Push(client, h, dataset, [first, winner, stale, winner]))
        { Assert.Equal(["accepted", "accepted", "stale", "accepted"], await Statuses(push)); }
        var history = Changes(await PersonalFoodHttp.Page(client, dataset, first.Id, entity));
        Assert.Equal(2, history.Length); Assert.Contains(history, r => r.GetProperty("hlc").GetString() == first.Hlc); Assert.Contains(history, r => r.GetProperty("hlc").GetString() == stale.Hlc);
        Assert.All(history, r => AssertSame(first, r, hlc: false));
        AssertSame(winner, Assert.Single(Changes(await PersonalFoodHttp.Page(client, dataset))));
        // A replay of an accepted (entity, id, hlc) with different content is a conflict, never an overwrite.
        using (var conflict = await PersonalFoodHttp.Push(client, h, dataset, [first with { Raw = Changed(first) }])) { Assert.Equal(["versionConflict"], await Statuses(conflict)); }
        Assert.Equal(2, Changes(await PersonalFoodHttp.Page(client, dataset, first.Id, entity)).Length);
        AssertSame(winner, Assert.Single(Changes(await PersonalFoodHttp.Page(client, dataset))));
    }

    // The scrubbed tombstone where the corpus has one (D10), else the full payload.
    private static string TombstoneRaw(string entity) => entity switch
    {
        "customExercise" or "workoutSession" or "workoutTemplate" => WorkoutCases.Raw($"{entity}-tombstone-scrubbed"),
        "workoutSet" => WorkoutCases.Raw("workoutSet-tombstone-scrubbed"),
        _ => PersonalFoodHttp.Fixture(entity),
    };

    [Theory, MemberData(nameof(Entities)), Trait("Rule", "05.5-retention")]
    public async Task Tombstones_compact_by_acceptance_time_and_fence_prevents_resurrection(string entity)
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync(); var user = await PersonalFoodHttp.Register(h);
        await using var factory = new IdentityApiTests.IdentityApi(database, h); using var client = await PersonalFoodHttp.Client(factory, h, user);
        var dataset = await PersonalFoodHttp.Dataset(client); var first = NewRow(h, entity);
        var tombstone = first with { Hlc = PersonalFoodHttp.Hlc(h, 1), DeletedAt = h.Clock.GetUtcNow().AddYears(-5), Raw = TombstoneRaw(entity) };
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

    // R14 / A37a D25 (D5): a removed session exercise or set restored with the same ID is the row's
    // current content at a newer HLC. Accepted before and after compaction; an older live version stays
    // stale; a revival under another session is accepted (no aggregate judgement on the server).
    [Theory, InlineData("sessionExercise", "sessionId"), InlineData("workoutSet", "sessionExerciseId"), Trait("Rule", "B21.revival")]
    public async Task Revived_children_are_newer_live_versions_before_and_after_compaction(string entity, string parentField)
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync(); var user = await PersonalFoodHttp.Register(h);
        await using var factory = new IdentityApiTests.IdentityApi(database, h); using var client = await PersonalFoodHttp.Client(factory, h, user);
        var dataset = await PersonalFoodHttp.Dataset(client);
        // Before compaction: live → tombstone (full payload) → revival; history keeps both earlier versions.
        var child = NewRow(h, entity, id: Guid.CreateVersion7(), counter: 10);
        var removed = child with { Hlc = PersonalFoodHttp.Hlc(h, 11), DeletedAt = h.Clock.GetUtcNow() };
        var revived = child with { Hlc = PersonalFoodHttp.Hlc(h, 12) };
        using (var push = await PersonalFoodHttp.Push(client, h, dataset, [child, removed, revived])) { Assert.Equal(["accepted", "accepted", "accepted"], await Statuses(push)); }
        AssertSame(revived, Assert.Single(Changes(await PersonalFoodHttp.Page(client, dataset))));
        var history = Changes(await PersonalFoodHttp.Page(client, dataset, child.Id, entity));
        Assert.Equal([child.Hlc, removed.Hlc], history.Select(r => r.GetProperty("hlc").GetString()).Order(StringComparer.Ordinal));
        Assert.Contains(history, r => r.GetProperty("deletedAt").ValueKind != JsonValueKind.Null);
        // An offline device's older live version can't displace the revival.
        using (var old = await PersonalFoodHttp.Push(client, h, dataset, [child with { Hlc = PersonalFoodHttp.Hlc(h, 5) }])) { Assert.Equal(["stale"], await Statuses(old)); }
        AssertSame(revived, Assert.Single(Changes(await PersonalFoodHttp.Page(client, dataset))));
        // After compaction: the revival replaces the fence; an older version is stale.
        var second = NewRow(h, entity, id: Guid.CreateVersion7(), counter: 20);
        var gone = second with { Hlc = PersonalFoodHttp.Hlc(h, 21), DeletedAt = h.Clock.GetUtcNow() };
        using (var push = await PersonalFoodHttp.Push(client, h, dataset, [second, gone])) { Assert.Equal(["accepted", "accepted"], await Statuses(push)); }
        await AgeAndCleanup(database, h, user.UserId, entity, second.Id, expireHistory: true);
        Assert.True(Pulled(await PullAll(client, dataset), second).GetProperty("compacted").GetBoolean());
        using (var stale = await PersonalFoodHttp.Push(client, h, dataset, [second])) { Assert.Equal(["stale"], await Statuses(stale)); }
        var back = second with { Hlc = PersonalFoodHttp.Hlc(h, 22) };
        using (var push = await PersonalFoodHttp.Push(client, h, dataset, [back])) { Assert.Equal(["accepted"], await Statuses(push)); }
        AssertSame(back, Pulled(await PullAll(client, dataset), back));
        // A revival under another parent: admitted as is (the handler and the read projection own integrity).
        var moved = revived with { Hlc = PersonalFoodHttp.Hlc(h, 13), Raw = WorkoutCases.With(revived.Raw, parentField, Guid.CreateVersion7().ToString()) };
        using (var push = await PersonalFoodHttp.Push(client, h, dataset, [moved])) { Assert.Equal(["accepted"], await Statuses(push)); }
        AssertSame(moved, Pulled(await PullAll(client, dataset), moved));
    }

    // D4: the server never reads other rows. Children before their parent, after the parent's
    // tombstone, re-parented, or pointing at unknown exercises and templates are admitted; no cascade.
    [Fact, Trait("Rule", "B21.no-cross-row-validation")]
    public async Task Aggregate_children_are_admitted_in_any_order_and_across_aggregates()
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync(); var user = await PersonalFoodHttp.Register(h);
        await using var factory = new IdentityApiTests.IdentityApi(database, h); using var client = await PersonalFoodHttp.Client(factory, h, user);
        var dataset = await PersonalFoodHttp.Dataset(client);
        Guid sessionId = Guid.CreateVersion7(), otherSession = Guid.CreateVersion7(), exerciseId = Guid.CreateVersion7(), templateId = Guid.CreateVersion7();
        string Under(string entity, string field, Guid parent) => WorkoutCases.With(PersonalFoodHttp.Fixture(entity), field, parent.ToString());
        var setFirst = NewRow(h, "workoutSet", Under("workoutSet", "sessionExerciseId", exerciseId), Guid.CreateVersion7());
        var exercise = NewRow(h, "sessionExercise", Under("sessionExercise", "sessionId", sessionId), exerciseId);
        var session = NewRow(h, "workoutSession", id: sessionId);
        var sessionGone = session with { Hlc = PersonalFoodHttp.Hlc(h, 1), DeletedAt = h.Clock.GetUtcNow() };
        var afterTombstone = NewRow(h, "sessionExercise", Under("sessionExercise", "sessionId", sessionId), Guid.CreateVersion7(), counter: 2);
        var reparented = exercise with { Hlc = PersonalFoodHttp.Hlc(h, 3), Raw = Under("sessionExercise", "sessionId", otherSession) };
        var unknownExercise = NewRow(h, "workoutTemplateItem", WorkoutCases.With(Under("workoutTemplateItem", "templateId", templateId), "exerciseId", Guid.NewGuid().ToString()), Guid.CreateVersion7());
        var missingTemplateDay = NewRow(h, "weeklyPlanDay", WorkoutCases.With(PersonalFoodHttp.Fixture("weeklyPlanDay"), "templateId", Guid.NewGuid().ToString()));
        var unknownTemplateSession = NewRow(h, "workoutSession", WorkoutCases.With(PersonalFoodHttp.Fixture("workoutSession"), "templateId", templateId.ToString()), Guid.CreateVersion7());
        Row[] batch = [setFirst, exercise, session, sessionGone, afterTombstone, reparented, unknownExercise, missingTemplateDay, unknownTemplateSession];
        using (var push = await PersonalFoodHttp.Push(client, h, dataset, batch)) { Assert.All(await Statuses(push), s => Assert.Equal("accepted", s)); }
        var pulled = await PullAll(client, dataset);
        Assert.Equal(7, pulled.Length);
        AssertSame(sessionGone, Pulled(pulled, sessionGone));
        // The children stay live: the session's tombstone doesn't cascade.
        foreach (var row in new[] { setFirst, afterTombstone, reparented, unknownExercise, missingTemplateDay, unknownTemplateSession }) { AssertSame(row, Pulled(pulled, row)); }
    }

    [Theory, MemberData(nameof(Entities)), Trait("Rule", "04.6-rls")]
    public async Task Another_owner_cannot_read_live_history_or_fence_and_same_id_is_independently_owned(string entity)
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync();
        var a = await PersonalFoodHttp.Register(h); var b = await PersonalFoodHttp.Register(h);
        await using var factory = new IdentityApiTests.IdentityApi(database, h);
        using var ca = await PersonalFoodHttp.Client(factory, h, a); using var cb = await PersonalFoodHttp.Client(factory, h, b);
        // weeklyPlanDay uses the shared natural ID: the same for every user, still per-user documents.
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
        Row[] rows = [.. WorkoutCases.Entities.Select(e => NewRow(h, e))];
        using (var response = await PersonalFoodHttp.Push(client, h, Guid.NewGuid(), rows)) { Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode); }
        foreach (var path in WorkoutCases.Entities.Select(e => $"/v1/sync/history/{e}/{WorkoutCases.NewId(e)}?cursor=0&limit=10").Prepend("/v1/sync/pull?cursor=0&limit=10"))
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
    public async Task Delete_account_erases_workout_live_history_fences_and_receipts_and_preserves_second_owner()
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync();
        var user = await PersonalFoodHttp.Register(h); var other = await PersonalFoodHttp.Register(h);
        await using var factory = new IdentityApiTests.IdentityApi(database, h);
        using var client = await PersonalFoodHttp.Client(factory, h, user); using var otherClient = await PersonalFoodHttp.Client(factory, h, other);
        var dataset = await PersonalFoodHttp.Dataset(client);
        var fences = new List<Row>(); var lives = new List<Row>();
        foreach (var entity in WorkoutCases.Entities)
        {
            // Per entity: a live row with a displaced version, and a compacted fence (two plan days).
            var fence = Distinct(h, entity, 1); var live = Distinct(h, entity, 2);
            Row[] batch = [fence, fence with { Hlc = PersonalFoodHttp.Hlc(h, 1), DeletedAt = h.Clock.GetUtcNow() }, live, live with { Hlc = PersonalFoodHttp.Hlc(h, 1) }];
            using (var push = await PersonalFoodHttp.Push(client, h, dataset, batch)) { Assert.All(await Statuses(push), s => Assert.Equal("accepted", s)); }
            using (var push = await PersonalFoodHttp.Push(otherClient, h, dataset, [live])) { Assert.Equal(["accepted"], await Statuses(push)); }
            fences.Add(fence); lives.Add(live);
        }
        foreach (var fence in fences) { await AgeAndCleanup(database, h, user.UserId, fence.Entity, fence.Id, expireHistory: false); }
        var before = await PullAll(client, dataset);
        Assert.Equal(14, before.Length); Assert.Equal(7, before.Count(r => r.GetProperty("compacted").GetBoolean()));
        foreach (var live in lives) { Assert.NotEmpty(Changes(await PersonalFoodHttp.Page(client, dataset, live.Id, live.Entity))); }
        await using var owner = DatabaseConfiguration.CreateSource(database.MigratorConnection);
        // documents / row_history / version_receipts per entity: compaction keeps history (only expiry
        // removes it), and every version has an immutable receipt.
        Assert.Equal(Enumerable.Repeat(new long[] { 2, 2, 4 }, 7).SelectMany(x => x), await Inventory(user.UserId));
        using (var erased = await client.DeleteAsync("/v1/me", Ct)) { Assert.Equal(HttpStatusCode.NoContent, erased.StatusCode); }
        using (var revoked = await client.GetAsync("/v1/sync/pull?cursor=0&limit=10", Ct)) { Assert.Equal(HttpStatusCode.Unauthorized, revoked.StatusCode); }
        Assert.Equal(new long[21], await Inventory(user.UserId));
        foreach (var table in Tables)
        {
            await using var query = owner.CreateCommand($"SELECT count(*) FROM userdata.{table} WHERE user_id=$1"); query.Parameters.AddWithValue(user.UserId);
            Assert.Equal(0L, await query.ExecuteScalarAsync(Ct));
        }
        var preserved = await PullAll(otherClient, dataset);
        Assert.Equal(lives.Count, preserved.Length);
        foreach (var row in lives) { AssertSame(row, Pulled(preserved, row)); }
        Assert.Equal(Enumerable.Repeat(new long[] { 1, 0, 1 }, 7).SelectMany(x => x), await Inventory(other.UserId));

        // documents / row_history / version_receipts, per entity.
        async Task<long[]> Inventory(Guid id)
        {
            var counts = new List<long>();
            foreach (var entity in WorkoutCases.Entities)
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
