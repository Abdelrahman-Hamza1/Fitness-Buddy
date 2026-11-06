using System.Net;
using System.Net.Http.Headers;
using System.Text.Json;
using FitnessBuddy.BuildingBlocks.Ids;
using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.Modules.Admin.Application;
using FitnessBuddy.Modules.Admin.Domain;
using FitnessBuddy.Modules.Admin.Infrastructure;
using FitnessBuddy.Modules.Identity.Infrastructure;
using FitnessBuddy.Modules.Usage.Infrastructure;
using FitnessBuddy.Modules.UserData.Domain;
using FitnessBuddy.Modules.UserData.Infrastructure;
using Microsoft.Extensions.Logging.Abstractions;
using Npgsql;

namespace FitnessBuddy.Persistence.Tests.Admin;

// B24 review follow-ups: a disable that commits while a sync or Buddy request is already past bearer validation (R#8), and
// a control whose audit row can't be written changes nothing (AD-005: change and audit row in one transaction).
[Trait("Req", "AD-011")]
[Trait("Req", "AD-005")]
public sealed class AccountControlsRaceTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;
    private const string LifecycleLockWait = "hashtextextended($1, 4603912)";
    private readonly PostgresIdentityAdminControls controls = new();

    private async Task<DatabaseSession> HoldDisableAsync(NpgsqlDataSource admin, Guid user, DateTimeOffset now)
    {
        // The console's disable holds the account's lifecycle lock until it commits.
        var session = new DatabaseSession();
        await session.BeginAsync(admin, null, Ct);
        Assert.NotNull(await controls.SetDisabledAsync(session, user, true, now, Ct));
        return session;
    }

    [Fact]
    [Trait("Rule", "B24.R8-sync-disable-race")]
    public async Task A_sync_push_past_authentication_is_refused_when_a_disable_commits_first_and_writes_nothing()
    {
        await using var h = new IdentityHarness(postgres); await h.InitializeAsync();
        await using var admin = DatabaseConfiguration.CreateSource(postgres.AdminConnection);
        var user = (await h.Store.GoogleSignInAsync(new("valid-" + Guid.NewGuid(), Guid.NewGuid() + "@example.invalid"), Guid.NewGuid(), h.Material(), Ct))!;
        var sync = new PostgresSyncStore(postgres.App, h.Store, h.Clock, new UuidV7IdGenerator(h.Clock));
        var dataset = (await sync.PullForSessionAsync(user, null, 0, 1, false, null, null, Ct))!.DatasetId;
        var payload = JsonDocument.Parse(File.ReadAllText(Path.Combine(AppContext.BaseDirectory, "entity-payloads.json"))).RootElement.GetProperty("weighIn").Clone();
        SyncVersion[] versions = [new("weighIn", Guid.NewGuid(), 1, $"{h.Clock.GetUtcNow().ToUnixTimeMilliseconds():D13}-00000-{h.Device}", h.Device, null, payload)];

        // The principal was validated before the disable; the push then waits on the lifecycle lock the disable holds.
        await using var disable = await HoldDisableAsync(admin, user.UserId, h.Clock.GetUtcNow());
        var push = sync.PushForSessionAsync(user, dataset, versions, h.Clock.GetUtcNow(), Ct);
        await LockWaits.UntilWaitingAsync(postgres, LifecycleLockWait);
        await disable.CommitAsync(Ct);

        Assert.Null(await push);
        Assert.Equal(0L, await CountAsync("SELECT count(*) FROM userdata.documents WHERE user_id=$1", user.UserId));
        Assert.Equal(0L, await CountAsync("SELECT count(*) FROM userdata.version_receipts WHERE user_id=$1", user.UserId));
    }

    [Fact]
    [Trait("Rule", "B24.R8-buddy-disable-race")]
    public async Task A_buddy_request_past_bearer_validation_is_refused_when_a_disable_commits_first_and_sends_nothing()
    {
        await using var h = new IdentityHarness(postgres); await h.InitializeAsync();
        await using var admin = DatabaseConfiguration.CreateSource(postgres.AdminConnection);
        using var wire = new BuddyApiTests.BuddyWire();
        await using var api = new BuddyApiTests.BuddyApi(postgres, h, wire); using var client = api.CreateClient(); BuddyApiTests.Headers(client, h);
        var tokens = (await h.Service.GuestAsync(h.Device, Ct))!;
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", tokens.AccessToken);
        using (var warm = await client.GetAsync("/v1/me", Ct)) { Assert.Equal(HttpStatusCode.OK, warm.StatusCode); }

        // Bearer validation reads the session without the lifecycle lock, so the request gets past it and then waits in the
        // ledger behind the uncommitted disable.
        await using var disable = await HoldDisableAsync(admin, tokens.UserId, h.Clock.GetUtcNow());
        var send = BuddyApiTests.Send(client, h, Guid.CreateVersion7());
        await LockWaits.UntilWaitingAsync(postgres, LifecycleLockWait);
        await disable.CommitAsync(Ct);

        using var response = await send;
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
        Assert.Equal(0, wire.Calls);
        Assert.Equal(0L, await CountAsync("SELECT count(*) FROM buddy.attempts WHERE user_id=$1", tokens.UserId));
        Assert.Equal(0L, await CountAsync("SELECT count(*) FROM usage.daily WHERE user_id=$1", tokens.UserId));
    }

    [Fact]
    [Trait("Rule", "B24.P5-audit-same-transaction")]
    public async Task A_control_whose_audit_row_fails_rolls_its_change_back()
    {
        await using var h = new IdentityHarness(postgres); await h.InitializeAsync();
        await using var admin = DatabaseConfiguration.CreateSource(postgres.AdminConnection);
        var user = await h.GuestAsync();
        var runner = new AccountControlRunner(new AdminDatabase(admin), new FailingAudit(), h.Clock, NullLogger<AccountControlRunner>.Instance);
        var principal = new AdminPrincipal(Guid.NewGuid(), "owner", "sub-owner", ConsoleRole.Operator, h.Clock.GetUtcNow());

        await Assert.ThrowsAsync<PostgresException>(() =>
            new SetAccountDisabled(runner, controls).HandleAsync(principal, user.UserId, true, "support", user.UserId.ToString(), Ct));
        await Assert.ThrowsAsync<PostgresException>(() =>
            new SetBuddyLimit(runner, controls, new PostgresUsageAdminControls()).HandleAsync(principal, user.UserId, "0", "support", Ct));
        await Assert.ThrowsAsync<PostgresException>(() =>
            new RequestAccountDeletion(runner, controls).HandleAsync(principal, user.UserId, "support", user.UserId.ToString(), Ct));

        Assert.NotNull(await h.Store.ReadSessionAsync(user.UserId, user.SessionId, Ct));
        await using (var read = new DatabaseSession())
        {
            await read.BeginAsync(admin, null, Ct);
            var state = (await controls.StateAsync(read, user.UserId, Ct))!;
            Assert.Null(state.DisabledAt); Assert.False(state.DeletionPending);
        }
        Assert.Equal(0L, await CountAsync("SELECT count(*) FROM usage.limit_overrides WHERE user_id=$1", user.UserId));
        Assert.Equal(0L, await CountAsync("SELECT count(*) FROM admin.audit_log WHERE target=$1", "account " + user.UserId));
    }

    /// <summary>The audit insert fails in the database, after the module's change in the same transaction.</summary>
    private sealed class FailingAudit : IAuditLog
    {
        public async Task AppendAsync(DatabaseSession session, AuditEntry entry, DateTimeOffset occurredAt, CancellationToken cancellationToken)
        {
            await using var command = session.Command("SELECT 1/0");
            await command.ExecuteNonQueryAsync(cancellationToken);
        }
    }

    private async Task<long> CountAsync(string sql, object value)
    {
        await using var owner = DatabaseConfiguration.CreateSource(postgres.MigratorConnection);
        await using var command = owner.CreateCommand(sql);
        command.Parameters.AddWithValue(value);
        return (long)(await command.ExecuteScalarAsync(Ct))!;
    }
}
