using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using FitnessBuddy.BuildingBlocks.Ids;
using FitnessBuddy.Modules.Identity.Contracts;
using FitnessBuddy.Modules.UserData.Domain;
using FitnessBuddy.Modules.UserData.Infrastructure;

namespace FitnessBuddy.Persistence.Tests;

[Trait("Req", "AC-010")]
[Trait("Req", "AC-011")]
[Trait("Req", "AC-012")]
public sealed class ProductionSyncTests(PostgresFixture database)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;
    private static JsonElement Fixtures => JsonDocument.Parse(File.ReadAllText(Path.Combine(AppContext.BaseDirectory, "entity-payloads.json"))).RootElement;
    private static SyncVersion Row(IdentityHarness h, string entity = "weighIn", Guid? id = null, int counter = 0) =>
        new(entity, id ?? Guid.NewGuid(), 1, $"{h.Clock.GetUtcNow().ToUnixTimeMilliseconds():D13}-{counter:D5}-{h.Device}", h.Device, null, Fixtures.GetProperty(entity).Clone());
    private static async Task<IdentitySession> Registered(IdentityHarness h) =>
        (await h.Store.GoogleSignInAsync(new("valid-" + Guid.NewGuid(), "synthetic@example.invalid"), Guid.NewGuid(), h.Material(), Ct))!;
    private PostgresSyncStore Store(IdentityHarness h) => new(database.App, h.Store, h.Clock, new UuidV7IdGenerator(h.Clock));
    private async Task<Guid> Dataset(IdentityHarness h, IdentitySession principal) =>
        (await Store(h).PullForSessionAsync(principal, null, 0, 1, false, null, null, Ct))!.DatasetId;

    [Fact]
    public async Task Every_current_entity_round_trips_and_unsupported_payloads_are_per_change_without_partial_failure()
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync(); var principal = await Registered(h); var store = Store(h); var dataset = await Dataset(h, principal);
        var rows = Fixtures.EnumerateObject().Select(p => Row(h, p.Name)).ToArray();
        var bad = Row(h) with { Payload = JsonSerializer.SerializeToElement(new { note = "private-canary" }) };
        var outcome = await store.PushForSessionAsync(principal, dataset, [.. rows, bad, Row(h) with { Entity = "progressPhoto" }, Row(h) with { SchemaVersion = 999 }], h.Clock.GetUtcNow(), Ct);
        Assert.Equal(rows.Length, outcome!.Results.Count(r => r.Status == "accepted"));
        Assert.Equal(["invalidPayload", "unsupported", "unsupported"], outcome.Results.TakeLast(3).Select(r => r.Reason));
        var page = await store.PullForSessionAsync(principal, dataset, 0, 500, false, null, null, Ct);
        Assert.Equal(rows.Length, page!.Changes.Count);
        foreach (var row in rows) { Assert.True(JsonElement.DeepEquals(row.Payload, page.Changes.Single(r => r.Version.Id == row.Id).Version.Payload)); }
    }

    [Fact, Trait("Rule", "05.5-dataset")]
    public async Task Unbound_and_wrong_dataset_never_write_or_acknowledge_and_impossible_cursor_is_explicit()
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync(); var user = await Registered(h); var store = Store(h); var row = Row(h);
        foreach (var dataset in new Guid?[] { null, Guid.NewGuid() })
        {
            var result = await store.PushForSessionAsync(user, dataset, [row], h.Clock.GetUtcNow(), Ct);
            Assert.Equal("datasetMismatch", Assert.Single(result!.Results).Reason);
        }
        var first = await store.PullForSessionAsync(user, null, 0, 500, false, null, null, Ct); Assert.Empty(first!.Changes);
        Assert.Equal("datasetMismatch", (await store.PullForSessionAsync(user, Guid.NewGuid(), 0, 1, false, null, null, Ct))!.Reason);
        Assert.Equal("datasetMismatch", (await store.PullForSessionAsync(user, null, 1, 1, false, null, null, Ct))!.Reason);
        Assert.Equal("cursorInvalid", (await store.PullForSessionAsync(user, first.DatasetId, long.MaxValue, 1, false, null, null, Ct))!.Reason);
        Assert.Equal("accepted", Assert.Single((await store.PushForSessionAsync(user, first.DatasetId, [row], h.Clock.GetUtcNow(), Ct))!.Results).Status);
    }

    [Fact, Trait("Rule", "04.6-rls")]
    public async Task Guest_revoked_and_cross_user_access_fail_even_after_http_auth_would_have_completed()
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync(); var a = await Registered(h); var b = await Registered(h); var guest = await h.GuestAsync(); var store = Store(h); var dataset = await Dataset(h, a);
        var row = Row(h); await store.PushForSessionAsync(a, dataset, [row, row with { Hlc = row.Hlc.Replace("-00000-", "-00001-", StringComparison.Ordinal) }], h.Clock.GetUtcNow(), Ct);
        Assert.Null(await store.PushForSessionAsync(guest, dataset, [Row(h)], h.Clock.GetUtcNow(), Ct));
        Assert.Empty((await store.PullForSessionAsync(b, dataset, 0, 500, true, row.Entity, row.Id, Ct))!.Changes);
        await using (var session = await database.SessionAsync(b.UserId))
        {
            foreach (var table in new[] { "documents", "row_history", "version_receipts" })
            {
                await using var count = session.Command($"SELECT count(*) FROM userdata.{table} WHERE user_id=$1"); count.Parameters.AddWithValue(a.UserId); Assert.Equal(0L, await count.ExecuteScalarAsync(Ct));
            }
        }
        await h.Store.RevokeAsync(a.UserId, a.SessionId, Ct);
        Assert.Null(await store.PushForSessionAsync(a, dataset, [Row(h)], h.Clock.GetUtcNow(), Ct));
        Assert.Null(await store.PullForSessionAsync(a, dataset, 0, 500, false, null, null, Ct));
    }

    [Fact, Trait("Rule", "05.5-retention")]
    public async Task History_expiry_keeps_retry_identity_and_delete_fence_without_renewing_recovery_payload()
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync(); var user = await Registered(h); var store = Store(h); var dataset = await Dataset(h, user);
        var first = Row(h); var tombstone = first with { Hlc = first.Hlc.Replace("-00000-", "-00001-", StringComparison.Ordinal), DeletedAt = h.Clock.GetUtcNow().AddYears(-5) };
        await store.PushForSessionAsync(user, dataset, [first, tombstone], h.Clock.GetUtcNow(), Ct);
        await Cleanup(h, user.UserId); Assert.False(Assert.Single((await store.PullAsync(user.UserId, 0, 500, false, Ct)).Changes).Compacted);
        h.Clock.Advance(TimeSpan.FromDays(30)); await Cleanup(h, user.UserId);
        Assert.Empty((await store.PullAsync(user.UserId, 0, 500, true, Ct)).Changes);
        var fence = Assert.Single((await store.PullAsync(user.UserId, 0, 500, false, Ct)).Changes);
        Assert.True(fence.Compacted); Assert.Equal("{}", fence.Version.Payload.GetRawText()); Assert.Equal(tombstone.Hlc, fence.Version.Hlc);
        // Storage-level assertions remain valid after the absolute session expiry.
        var replay = await store.PushAsync(user.UserId, [first, first with { Payload = JsonSerializer.SerializeToElement(new { changed = true }) }], h.Clock.GetUtcNow(), Ct);
        Assert.Equal("stale", replay[0].Status); Assert.Equal("versionConflict", replay[1].Reason);
        Assert.Empty((await store.PullAsync(user.UserId, 0, 500, true, Ct)).Changes);
        var restored = tombstone with { Hlc = $"{h.Clock.GetUtcNow().ToUnixTimeMilliseconds():D13}-00000-{h.Device}", DeletedAt = null };
        Assert.Equal("accepted", Assert.Single(await store.PushAsync(user.UserId, [restored], h.Clock.GetUtcNow(), Ct)).Status);
        Assert.False(Assert.Single((await store.PullAsync(user.UserId, 0, 500, false, Ct)).Changes).Compacted);
    }

    private async Task Cleanup(IdentityHarness h, Guid user)
    {
        await using var session = await database.SessionAsync(user);
        await new SyncRetentionJob(h.Clock, new UuidV7IdGenerator(h.Clock)).HandleAsync(new(Guid.NewGuid(), "userdata.cleanup", "{}", user, 1), session, Ct);
        await session.CommitAsync(Ct);
    }

    [Fact, Trait("Rule", "05.5-version-identity")]
    public void Canonical_fingerprints_treat_object_order_and_numeric_spelling_equally()
    {
        var a = new SyncVersion("weighIn", Guid.NewGuid(), 1, "unused", Guid.NewGuid(), null, JsonDocument.Parse("{\"a\":1.0,\"b\":[0.00,2]}").RootElement);
        var b = a with { Payload = JsonDocument.Parse("{\"b\":[0,2.00],\"a\":1}").RootElement };
        Assert.Equal(SyncPayloads.Fingerprint(a), SyncPayloads.Fingerprint(b));
        Assert.NotEqual(SyncPayloads.Fingerprint(a), SyncPayloads.Fingerprint(b with { SchemaVersion = 2 }));
        var expanded = a with { Payload = JsonDocument.Parse("{\"value\":1" + new string('0', 100_000) + "}").RootElement };
        var scientific = a with { Payload = JsonDocument.Parse("{\"value\":1e100000}").RootElement };
        Assert.Equal(SyncPayloads.Fingerprint(expanded), SyncPayloads.Fingerprint(scientific));
    }

    [Fact, Trait("Rule", "05.5-payload-validation")]
    public async Task Jsonb_invalid_or_ambiguous_payloads_are_rejected_before_sql_and_valid_neighbor_is_committed()
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync(); var user = await Registered(h); var store = Store(h); var dataset = await Dataset(h, user);
        var valid = Row(h);
        var raw = valid.Payload.GetRawText();
        var nullByte = valid with { Id = Guid.NewGuid(), Payload = JsonDocument.Parse(raw.Replace("synthetic", "CANARY-SYNC-\\u0000", StringComparison.Ordinal)).RootElement };
        var huge = valid with { Id = Guid.NewGuid(), Payload = JsonDocument.Parse(raw.Replace("\"kg\": 1.0", "\"kg\": 1e10000", StringComparison.Ordinal)).RootElement };
        var tiny = valid with { Id = Guid.NewGuid(), Payload = JsonDocument.Parse(raw.Replace("\"kg\": 1.0", "\"kg\": 1e-10000", StringComparison.Ordinal)).RootElement };
        var duplicate = valid with { Id = Guid.NewGuid(), Payload = JsonDocument.Parse(raw.Replace("\"kg\": 1.0", "\"kg\": 1.0, \"kg\": 2.0", StringComparison.Ordinal)).RootElement };
        var result = await store.PushForSessionAsync(user, dataset, [nullByte, huge, tiny, duplicate, valid], h.Clock.GetUtcNow(), Ct);
        Assert.All(result!.Results.Take(4), row => Assert.Equal("invalidPayload", row.Reason)); Assert.Equal("accepted", result.Results[^1].Status);
        Assert.Single((await store.PullForSessionAsync(user, dataset, 0, 500, false, null, null, Ct))!.Changes);
        Assert.DoesNotContain("CANARY-SYNC", await database.LogsAsync(), StringComparison.Ordinal);
    }

    [Fact, Trait("Rule", "05.5-dataset")]
    public async Task Dataset_survives_restart_and_migration_but_operator_rotation_invalidates_old_binding()
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync(); var user = await Registered(h); var before = await Dataset(h, user);
        await database.Runner.RunAsync(database.MigratorConnection, Ct); Assert.Equal(before, await Dataset(h, user));
        await FitnessBuddy.Modules.UserData.UserDataModule.RotateDatasetAsync(database.MigratorConnection, Ct);
        var after = await Dataset(h, user); Assert.NotEqual(before, after);
        var result = await Store(h).PushForSessionAsync(user, before, [Row(h)], h.Clock.GetUtcNow(), Ct);
        Assert.Equal("datasetMismatch", Assert.Single(result!.Results).Reason);
        await using var denied = database.App.CreateCommand("UPDATE userdata.dataset SET id=gen_random_uuid()");
        var error = await Assert.ThrowsAsync<Npgsql.PostgresException>(() => denied.ExecuteNonQueryAsync(Ct)); Assert.Equal("42501", error.SqlState);
    }

    [Fact, Trait("Rule", "05.6-lifecycle")]
    public async Task Revocation_while_sync_waits_for_user_lock_is_observed_before_any_write()
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync(); var user = await Registered(h); var dataset = await Dataset(h, user);
        await using var held = await database.SessionAsync(user.UserId);
        await FitnessBuddy.BuildingBlocks.Persistence.UserLifecycleLock.AcquireAsync(held, user.UserId, Ct);
        var pending = Store(h).PushForSessionAsync(user, dataset, [Row(h)], h.Clock.GetUtcNow(), Ct);
        var blocked = false;
        for (var i = 0; i < 100; i++)
        {
            await using var probe = database.App.CreateCommand("SELECT EXISTS(SELECT 1 FROM pg_locks WHERE locktype='advisory' AND NOT granted)");
            if ((bool)(await probe.ExecuteScalarAsync(Ct))!) { blocked = true; break; }
            await Task.Delay(10, Ct);
        }
        Assert.True(blocked); await h.Store.RevokeAsync(user.UserId, user.SessionId, Ct); await held.CommitAsync(Ct);
        Assert.Null(await pending); Assert.Empty((await Store(h).PullAsync(user.UserId, 0, 500, false, Ct)).Changes);
    }

    [Fact, Trait("Rule", "04.4-contract-envelope")]
    public async Task Real_host_requires_registered_identity_and_rejects_null_batches_before_any_write()
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync();
        await using var factory = new IdentityApiTests.IdentityApi(database, h);
        using var client = factory.CreateClient(); client.DefaultRequestHeaders.Add("X-App-Version", "0.1.0"); client.DefaultRequestHeaders.Add("X-Platform", "android"); client.DefaultRequestHeaders.Add("X-Device-Id", h.Device.ToString());
        using var absent = await client.GetAsync("/v1/sync/pull?cursor=0&limit=100", Ct); Assert.Equal(HttpStatusCode.Unauthorized, absent.StatusCode);
        var guest = await h.GuestAsync(); client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", await h.Tokens.SignAsync(guest, Ct));
        using var forbidden = await client.GetAsync("/v1/sync/pull?cursor=0&limit=100", Ct); Assert.Equal(HttpStatusCode.Forbidden, forbidden.StatusCode);
        var user = await Registered(h); client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", await h.Tokens.SignAsync(user, Ct));
        foreach (var changes in new object?[][] { [null], [Row(h), null] })
        {
            using var response = await client.PostAsJsonAsync("/v1/sync/push", new { changes }, Ct); Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
            var problem = await response.Content.ReadFromJsonAsync<JsonElement>(Ct); Assert.True(problem.GetProperty("errors").TryGetProperty("changes", out _));
        }
        using var discovery = await client.GetAsync("/v1/sync/pull?cursor=0&limit=100", Ct);
        Assert.Equal(HttpStatusCode.OK, discovery.StatusCode); Assert.True(discovery.Headers.CacheControl!.NoStore);
        var page = await discovery.Content.ReadFromJsonAsync<JsonElement>(Ct); Assert.Empty(page.GetProperty("changes").EnumerateArray());
        using var push = await client.PostAsJsonAsync("/v1/sync/push", new { changes = new[] { Row(h) }, datasetId = page.GetProperty("datasetId").GetGuid() }, Ct);
        Assert.Equal(HttpStatusCode.OK, push.StatusCode); Assert.Equal("accepted", (await push.Content.ReadFromJsonAsync<JsonElement>(Ct)).GetProperty("results")[0].GetProperty("status").GetString());
    }
}
