using System.Net;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using FitnessBuddy.BuildingBlocks.Ids;
using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.Modules.Identity.Contracts;
using FitnessBuddy.Modules.UserData.Infrastructure;
using FitnessBuddy.TestData;
using Microsoft.AspNetCore.Mvc.Testing;

namespace FitnessBuddy.Persistence.Tests;

[Trait("Req", "FD-071")]
[Trait("Req", "AC-010")]
[Trait("Req", "AC-012")]
public sealed class PersonalFoodSyncTests(PostgresFixture database)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    [Fact, Trait("Rule", "05.5-payload-validation")]
    public async Task Batched_matrix_preserves_result_order_and_valid_neighbors_without_persisting_invalid_versions()
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync();
        var user = await PersonalFoodHttp.Register(h);
        await using var factory = new IdentityApiTests.IdentityApi(database, h);
        using var client = await PersonalFoodHttp.Client(factory, h, user);
        var dataset = await PersonalFoodHttp.Dataset(client);
        var invalidIds = new List<Guid>(); var accepted = new List<PersonalFoodHttp.Row>();
        // Raw JSON preserves duplicate keys and lone-surrogate escapes through
        // HTTP binding. Small byte/count bounds include 16 KiB hostile cases.
        foreach (var group in ByteBoundedCases(PersonalFoodCases.All()))
        {
            var entries = group.Select(c => (Case: c, Row: PersonalFoodHttp.NewRow(h, c.Raw, deleted: c.Deleted ? h.Clock.GetUtcNow() : null))).ToArray();
            var neighbor = PersonalFoodHttp.NewRow(h); accepted.Add(neighbor);
            using var response = await PersonalFoodHttp.Push(client, h, dataset, [neighbor, .. entries.Select(e => e.Row)]);
            Assert.Equal(HttpStatusCode.OK, response.StatusCode);
            var result = await PersonalFoodHttp.Json(response);
            var results = result.GetProperty("results").EnumerateArray().ToArray();
            Assert.Equal(entries.Length + 1, results.Length);
            Assert.Equal("accepted", results[0].GetProperty("status").GetString());
            for (var i = 0; i < entries.Length; i++)
            {
                var (test, row) = entries[i]; var item = results[i + 1];
                Assert.Equal(row.Id, item.GetProperty("id").GetGuid());
                Assert.Equal(row.Hlc, item.GetProperty("hlc").GetString());
                Assert.Equal(test.Valid ? "accepted" : "invalid", item.GetProperty("status").GetString());
                Assert.Equal(test.Valid ? null : "invalidPayload", item.GetProperty("reason").GetString());
                Assert.Equal(["entity", "hlc", "id", "reason", "status"], item.EnumerateObject().Select(p => p.Name).Order(StringComparer.Ordinal));
                if (test.Valid) { accepted.Add(row); } else { invalidIds.Add(row.Id); }
            }
        }
        // Privileged assertions prove invalid inputs never reached any content or
        // immutable receipt table; HTTP pull proves every accepted owner row.
        await using var owner = DatabaseConfiguration.CreateSource(database.MigratorConnection);
        foreach (var table in new[] { "documents", "row_history", "version_receipts" })
        {
            await using var query = owner.CreateCommand($"SELECT count(*) FROM userdata.{table} WHERE user_id=$1 AND entity='personalFood' AND id=ANY($2)");
            query.Parameters.AddWithValue(user.UserId); query.Parameters.AddWithValue(invalidIds.ToArray());
            Assert.Equal(0L, await query.ExecuteScalarAsync(Ct));
        }
        var page = await PersonalFoodHttp.Page(client, dataset);
        var rows = page.GetProperty("changes").EnumerateArray().ToArray();
        Assert.Equal(accepted.Count, rows.Length);
        foreach (var row in accepted)
        {
            using var expected = JsonDocument.Parse(row.Raw);
            Assert.True(JsonElement.DeepEquals(expected.RootElement, rows.Single(r => r.GetProperty("id").GetGuid() == row.Id).GetProperty("payload")));
        }
    }

    [Fact, Trait("Rule", "04.6-rls")]
    public async Task Another_owner_cannot_read_live_history_or_fence_and_same_id_is_independently_owned()
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync();
        var a = await PersonalFoodHttp.Register(h); var b = await PersonalFoodHttp.Register(h);
        await using var factory = new IdentityApiTests.IdentityApi(database, h);
        using var ca = await PersonalFoodHttp.Client(factory, h, a); using var cb = await PersonalFoodHttp.Client(factory, h, b);
        var dataset = await PersonalFoodHttp.Dataset(ca); var row = PersonalFoodHttp.NewRow(h);
        using (var push = await PersonalFoodHttp.Push(ca, h, dataset, [row, row with { Hlc = PersonalFoodHttp.Hlc(h, 1) }])) { Assert.Equal(HttpStatusCode.OK, push.StatusCode); }
        Assert.Empty((await PersonalFoodHttp.Page(cb, dataset)).GetProperty("changes").EnumerateArray());
        Assert.Empty((await PersonalFoodHttp.Page(cb, dataset, row.Id)).GetProperty("changes").EnumerateArray());
        using (var tombstone = await PersonalFoodHttp.Push(ca, h, dataset, [row with { Hlc = PersonalFoodHttp.Hlc(h, 2), DeletedAt = h.Clock.GetUtcNow() }])) { Assert.Equal(HttpStatusCode.OK, tombstone.StatusCode); }
        await AgeAndCleanup(h, a.UserId, row.Id, expireHistory: false);
        Assert.True(Assert.Single((await PersonalFoodHttp.Page(ca, dataset)).GetProperty("changes").EnumerateArray()).GetProperty("compacted").GetBoolean());
        Assert.Empty((await PersonalFoodHttp.Page(cb, dataset)).GetProperty("changes").EnumerateArray());
        Assert.Empty((await PersonalFoodHttp.Page(cb, dataset, row.Id)).GetProperty("changes").EnumerateArray());
        using (var own = await PersonalFoodHttp.Push(cb, h, dataset, [row])) { Assert.Equal("accepted", (await PersonalFoodHttp.Json(own)).GetProperty("results")[0].GetProperty("status").GetString()); }
        Assert.False(Assert.Single((await PersonalFoodHttp.Page(cb, dataset)).GetProperty("changes").EnumerateArray()).GetProperty("compacted").GetBoolean());
        Assert.True(Assert.Single((await PersonalFoodHttp.Page(ca, dataset)).GetProperty("changes").EnumerateArray()).GetProperty("compacted").GetBoolean());
    }

    [Fact, Trait("Rule", "05.5-version-identity")]
    public async Task Lww_preserves_displaced_and_incoming_losers_and_replays_are_immutable()
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync(); var user = await PersonalFoodHttp.Register(h);
        await using var factory = new IdentityApiTests.IdentityApi(database, h); using var client = await PersonalFoodHttp.Client(factory, h, user);
        var dataset = await PersonalFoodHttp.Dataset(client); var first = PersonalFoodHttp.NewRow(h);
        var winner = first with { Hlc = PersonalFoodHttp.Hlc(h, 2) }; var stale = first with { Hlc = PersonalFoodHttp.Hlc(h, 1) };
        using (var push = await PersonalFoodHttp.Push(client, h, dataset, [first, winner, stale, winner]))
        {
            Assert.Equal(HttpStatusCode.OK, push.StatusCode);
            Assert.Equal(["accepted", "accepted", "stale", "accepted"], (await PersonalFoodHttp.Json(push)).GetProperty("results").EnumerateArray().Select(r => r.GetProperty("status").GetString()));
        }
        var history = (await PersonalFoodHttp.Page(client, dataset, first.Id)).GetProperty("changes").EnumerateArray().ToArray();
        Assert.Equal(2, history.Length); Assert.Contains(history, r => r.GetProperty("hlc").GetString() == first.Hlc); Assert.Contains(history, r => r.GetProperty("hlc").GetString() == stale.Hlc);
        Assert.Equal(winner.Hlc, Assert.Single((await PersonalFoodHttp.Page(client, dataset)).GetProperty("changes").EnumerateArray()).GetProperty("hlc").GetString());
        var changed = first with { Raw = first.Raw.Replace("Synthetic food", "Changed food", StringComparison.OrdinalIgnoreCase).Replace("synthetic", "changed", StringComparison.Ordinal) };
        using var conflict = await PersonalFoodHttp.Push(client, h, dataset, [changed]);
        Assert.Equal("versionConflict", (await PersonalFoodHttp.Json(conflict)).GetProperty("results")[0].GetProperty("reason").GetString());
        Assert.Equal(2, (await PersonalFoodHttp.Page(client, dataset, first.Id)).GetProperty("changes").GetArrayLength());
    }

    [Fact, Trait("Rule", "05.5-retention")]
    public async Task Tombstones_compact_by_acceptance_time_history_expires_and_fence_prevents_resurrection()
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync(); var user = await PersonalFoodHttp.Register(h);
        await using var factory = new IdentityApiTests.IdentityApi(database, h); using var client = await PersonalFoodHttp.Client(factory, h, user);
        var dataset = await PersonalFoodHttp.Dataset(client); var first = PersonalFoodHttp.NewRow(h);
        var tombstone = first with { Hlc = PersonalFoodHttp.Hlc(h, 1), DeletedAt = h.Clock.GetUtcNow().AddYears(-5) };
        using (var push = await PersonalFoodHttp.Push(client, h, dataset, [first, tombstone])) { Assert.Equal(HttpStatusCode.OK, push.StatusCode); }
        await Cleanup(h, user.UserId);
        Assert.False(Assert.Single((await PersonalFoodHttp.Page(client, dataset)).GetProperty("changes").EnumerateArray()).GetProperty("compacted").GetBoolean());
        var inWindow = PersonalFoodHttp.NewRow(h);
        using (var push = await PersonalFoodHttp.Push(client, h, dataset, [inWindow, inWindow with { Hlc = PersonalFoodHttp.Hlc(h, 1) }]))
        { Assert.Equal(HttpStatusCode.OK, push.StatusCode); }
        Assert.Equal(1L, await HistoryCount(user.UserId, first.Id));
        Assert.Equal(1L, await HistoryCount(user.UserId, inWindow.Id));
        await AgeAndCleanup(h, user.UserId, first.Id, expireHistory: true);
        // API cutoff alone cannot prove physical deletion; inspect as the schema owner.
        Assert.Equal(0L, await HistoryCount(user.UserId, first.Id));
        Assert.Equal(1L, await HistoryCount(user.UserId, inWindow.Id));
        var compactedRows = (await PersonalFoodHttp.Page(client, dataset)).GetProperty("changes").EnumerateArray().ToArray();
        Assert.Equal(2, compactedRows.Length);
        var fence = Assert.Single(compactedRows, row => row.GetProperty("id").GetGuid() == first.Id);
        Assert.True(fence.GetProperty("compacted").GetBoolean()); Assert.Empty(fence.GetProperty("payload").EnumerateObject());
        Assert.Equal(tombstone.Hlc, fence.GetProperty("hlc").GetString());
        Assert.Empty((await PersonalFoodHttp.Page(client, dataset, first.Id)).GetProperty("changes").EnumerateArray());
        using (var old = await PersonalFoodHttp.Push(client, h, dataset, [first])) { Assert.Equal("stale", (await PersonalFoodHttp.Json(old)).GetProperty("results")[0].GetProperty("status").GetString()); }
        Assert.Empty((await PersonalFoodHttp.Page(client, dataset, first.Id)).GetProperty("changes").EnumerateArray());
        var restore = first with { Hlc = PersonalFoodHttp.Hlc(h, 2) };
        using (var response = await PersonalFoodHttp.Push(client, h, dataset, [restore])) { Assert.Equal("accepted", (await PersonalFoodHttp.Json(response)).GetProperty("results")[0].GetProperty("status").GetString()); }
        var restoredRows = (await PersonalFoodHttp.Page(client, dataset)).GetProperty("changes").EnumerateArray().ToArray();
        Assert.Equal(2, restoredRows.Length);
        var restored = Assert.Single(restoredRows, row => row.GetProperty("id").GetGuid() == first.Id);
        Assert.False(restored.GetProperty("compacted").GetBoolean()); Assert.Equal(restore.Hlc, restored.GetProperty("hlc").GetString());
    }

    [Fact, Trait("Rule", "04.6-authz")]
    public async Task Guests_get_403_for_push_pull_and_item_history_and_unauthenticated_get_401()
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync();
        await using var factory = new IdentityApiTests.IdentityApi(database, h); using var client = await PersonalFoodHttp.Client(factory, h, await h.GuestAsync());
        using (var response = await PersonalFoodHttp.Push(client, h, Guid.NewGuid(), [PersonalFoodHttp.NewRow(h)])) { Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode); }
        foreach (var path in new[] { "/v1/sync/pull?cursor=0&limit=10", $"/v1/sync/history/personalFood/{Guid.NewGuid()}?cursor=0&limit=10" })
        {
            using (var response = await client.GetAsync(path, Ct)) { Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode); }
            var token = client.DefaultRequestHeaders.Authorization; client.DefaultRequestHeaders.Authorization = null;
            using (var response = await client.GetAsync(path, Ct)) { Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode); }
            client.DefaultRequestHeaders.Authorization = token;
        }
    }

    [Fact, Trait("Req", "AC-031")]
    public async Task Delete_account_erases_personal_food_live_history_fences_and_receipts_and_preserves_second_owner()
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync();
        var user = await PersonalFoodHttp.Register(h); var other = await PersonalFoodHttp.Register(h);
        await using var factory = new IdentityApiTests.IdentityApi(database, h);
        using var client = await PersonalFoodHttp.Client(factory, h, user); using var otherClient = await PersonalFoodHttp.Client(factory, h, other);
        var dataset = await PersonalFoodHttp.Dataset(client); var live = PersonalFoodHttp.NewRow(h); var fence = PersonalFoodHttp.NewRow(h);
        using (var push = await PersonalFoodHttp.Push(client, h, dataset, [live, live with { Hlc = PersonalFoodHttp.Hlc(h, 1) }, fence, fence with { Hlc = PersonalFoodHttp.Hlc(h, 1), DeletedAt = h.Clock.GetUtcNow() }])) { Assert.Equal(HttpStatusCode.OK, push.StatusCode); }
        using (var push = await PersonalFoodHttp.Push(otherClient, h, dataset, [live])) { Assert.Equal(HttpStatusCode.OK, push.StatusCode); }
        await AgeAndCleanup(h, user.UserId, fence.Id, expireHistory: false);
        var before = (await PersonalFoodHttp.Page(client, dataset)).GetProperty("changes").EnumerateArray().ToArray();
        Assert.Equal(2, before.Length); Assert.Contains(before, r => r.GetProperty("compacted").GetBoolean()); Assert.Contains(before, r => !r.GetProperty("compacted").GetBoolean());
        Assert.NotEmpty((await PersonalFoodHttp.Page(client, dataset, live.Id)).GetProperty("changes").EnumerateArray());
        await using var owner = DatabaseConfiguration.CreateSource(database.MigratorConnection);
        await using (var receipt = owner.CreateCommand("SELECT count(*) FROM userdata.version_receipts WHERE user_id=$1 AND entity='personalFood'"))
        { receipt.Parameters.AddWithValue(user.UserId); Assert.Equal(4L, await receipt.ExecuteScalarAsync(Ct)); }
        using (var erased = await client.DeleteAsync("/v1/me", Ct)) { Assert.Equal(HttpStatusCode.NoContent, erased.StatusCode); }
        using (var revoked = await client.GetAsync("/v1/sync/pull?cursor=0&limit=10", Ct)) { Assert.Equal(HttpStatusCode.Unauthorized, revoked.StatusCode); }
        foreach (var table in new[] { "documents", "row_history", "version_receipts" })
        {
            await using var query = owner.CreateCommand($"SELECT count(*) FROM userdata.{table} WHERE user_id=$1"); query.Parameters.AddWithValue(user.UserId);
            Assert.Equal(0L, await query.ExecuteScalarAsync(Ct));
        }
        var preserved = await PersonalFoodHttp.Page(otherClient, dataset);
        Assert.Equal(live.Id, Assert.Single(preserved.GetProperty("changes").EnumerateArray()).GetProperty("id").GetGuid());
        Assert.Equal(dataset, preserved.GetProperty("datasetId").GetGuid());
        await using var otherReceipt = owner.CreateCommand("SELECT count(*) FROM userdata.version_receipts WHERE user_id=$1 AND entity='personalFood'");
        otherReceipt.Parameters.AddWithValue(other.UserId); Assert.Equal(1L, await otherReceipt.ExecuteScalarAsync(Ct));
    }

    private static IEnumerable<IReadOnlyList<PersonalFoodCase>> ByteBoundedCases(IReadOnlyList<PersonalFoodCase> cases)
    {
        var batch = new List<PersonalFoodCase>(); var bytes = 0;
        foreach (var item in cases)
        {
            var size = Encoding.UTF8.GetByteCount(item.Raw) + 512;
            if (batch.Count > 0 && (bytes + size > 128 * 1024 || batch.Count == 100)) { yield return batch.ToArray(); batch.Clear(); bytes = 0; }
            batch.Add(item); bytes += size;
        }
        if (batch.Count > 0) { yield return batch.ToArray(); }
    }

    private async Task<long> HistoryCount(Guid user, Guid id)
    {
        await using var owner = DatabaseConfiguration.CreateSource(database.MigratorConnection);
        await using var query = owner.CreateCommand("SELECT count(*) FROM userdata.row_history WHERE user_id=$1 AND entity='personalFood' AND id=$2");
        query.Parameters.AddWithValue(user); query.Parameters.AddWithValue(id);
        return (long)(await query.ExecuteScalarAsync(Ct))!;
    }

    private async Task AgeAndCleanup(IdentityHarness h, Guid user, Guid id, bool expireHistory)
    {
        // Synthetic aging is operator-only: the API intentionally has no UPDATE
        // privilege on row_history. Do not widen production grants for tests.
        await using (var owner = DatabaseConfiguration.CreateSource(database.MigratorConnection))
        {
            await using var age = owner.CreateCommand("UPDATE userdata.documents SET accepted_at=$3 WHERE user_id=$1 AND id=$2 AND entity='personalFood'");
            age.Parameters.AddWithValue(user); age.Parameters.AddWithValue(id); age.Parameters.AddWithValue(h.Clock.GetUtcNow().AddDays(-31)); await age.ExecuteNonQueryAsync(Ct);
            if (expireHistory)
            {
                await using var history = owner.CreateCommand("UPDATE userdata.row_history SET replaced_at=$3 WHERE user_id=$1 AND id=$2 AND entity='personalFood'");
                history.Parameters.AddWithValue(user); history.Parameters.AddWithValue(id); history.Parameters.AddWithValue(h.Clock.GetUtcNow().AddDays(-31)); await history.ExecuteNonQueryAsync(Ct);
            }
        }
        await Cleanup(h, user);
    }

    private async Task Cleanup(IdentityHarness h, Guid user)
    {
        await using var session = await database.SessionAsync(user);
        await new SyncRetentionJob(h.Clock, new UuidV7IdGenerator(h.Clock)).HandleAsync(new(Guid.NewGuid(), "userdata.cleanup", "{}", user, 1), session, Ct);
        await session.CommitAsync(Ct);
    }
}

internal static class PersonalFoodHttp
{
    // B18 D12: Entity defaults to personalFood, so B17 call sites are unchanged.
    // B19 D10: SchemaVersion defaults to 1, so B17/B18 call sites are unchanged.
    internal sealed record Row(Guid Id, string Hlc, string Raw, DateTimeOffset? DeletedAt = null, string Entity = "personalFood", int SchemaVersion = 1);
    private static CancellationToken Ct => TestContext.Current.CancellationToken;
    public static async Task<IdentitySession> Register(IdentityHarness h) =>
        (await h.Store.GoogleSignInAsync(new("valid-" + Guid.NewGuid(), Guid.NewGuid() + "@example.invalid"), Guid.NewGuid(), h.Material(), Ct))!;
    public static string Hlc(IdentityHarness h, int counter = 0) => $"{h.Clock.GetUtcNow().ToUnixTimeMilliseconds():D13}-{counter:D5}-{h.Device}";
    public static Row NewRow(IdentityHarness h, string? raw = null, DateTimeOffset? deleted = null, string entity = "personalFood", Guid? id = null, int schemaVersion = 1) =>
        new(id ?? Guid.NewGuid(), Hlc(h), raw ?? Fixture(entity), deleted, entity, schemaVersion);
    public static string Fixture(string entity = "personalFood")
    {
        using var fixture = JsonDocument.Parse(File.ReadAllText(Path.Combine(AppContext.BaseDirectory, "entity-payloads.json")));
        return fixture.RootElement.GetProperty(entity).GetRawText();
    }
    public static async Task<HttpClient> Client(WebApplicationFactory<Program> factory, IdentityHarness h, IdentitySession user)
    {
        var client = factory.CreateClient();
        client.DefaultRequestHeaders.Add("X-App-Version", "0.1.0"); client.DefaultRequestHeaders.Add("X-Platform", "android"); client.DefaultRequestHeaders.Add("X-Device-Id", h.Device.ToString());
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", await h.Tokens.SignAsync(user, Ct));
        return client;
    }
    public static string Body(IdentityHarness h, Guid dataset, IReadOnlyList<Row> rows)
    {
        var changes = rows.Select(row => JsonSerializer.Serialize(new { entity = row.Entity, row.Id, schemaVersion = row.SchemaVersion, row.Hlc, deviceId = h.Device, row.DeletedAt }, JsonSerializerOptions.Web)[..^1] + ",\"payload\":" + row.Raw + "}");
        return "{\"datasetId\":\"" + dataset + "\",\"changes\":[" + string.Join(',', changes) + "]}";
    }
    public static async Task<HttpResponseMessage> Push(HttpClient client, IdentityHarness h, Guid dataset, IReadOnlyList<Row> rows)
    {
        using var content = new StringContent(Body(h, dataset, rows), Encoding.UTF8, "application/json");
        return await client.PostAsync("/v1/sync/push", content, Ct);
    }
    public static async Task<JsonElement> Json(HttpResponseMessage response)
    {
        using var document = JsonDocument.Parse(await response.Content.ReadAsStringAsync(Ct)); return document.RootElement.Clone();
    }
    public static async Task<Guid> Dataset(HttpClient client)
    {
        using var response = await client.GetAsync("/v1/sync/pull?cursor=0&limit=500", Ct);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode); return (await Json(response)).GetProperty("datasetId").GetGuid();
    }
    public static async Task<JsonElement> Page(HttpClient client, Guid dataset, Guid? historyId = null, string entity = "personalFood")
    {
        var path = historyId.HasValue ? $"/v1/sync/history/{entity}/{historyId.Value}" : "/v1/sync/pull";
        using var response = await client.GetAsync($"{path}?cursor=0&limit=500&datasetId={dataset}", Ct);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode); return await Json(response);
    }
}
