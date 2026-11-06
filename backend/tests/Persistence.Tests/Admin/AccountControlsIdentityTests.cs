using System.Security.Cryptography;
using FitnessBuddy.BuildingBlocks.Jobs;
using FitnessBuddy.BuildingBlocks.Ids;
using FitnessBuddy.BuildingBlocks.Messaging;
using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.Modules.Identity.Application;
using FitnessBuddy.Modules.Identity.Contracts;
using FitnessBuddy.Modules.Identity.Infrastructure;
using Microsoft.Extensions.Logging.Abstractions;
using Npgsql;

namespace FitnessBuddy.Persistence.Tests.Admin;

// B24 WP1: Identity's operator controls on the console login (fb_admin): revoke one device or all, disable/enable, the deletion
// intent; the disable gate in every session and sign-in path; and the database-side proof for operator deletion (R#1).
[Trait("Req", "AD-011")]
[Trait("Req", "AD-007")]
public sealed class AccountControlsIdentityTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;
    private readonly PostgresIdentityAdminControls controls = new();

    private static SessionMaterial On(Guid device) => new(Guid.NewGuid(), device, RandomNumberGenerator.GetBytes(32));

    private static async Task<DatabaseSession> ConsoleAsync(NpgsqlDataSource source)
    {
        var session = new DatabaseSession();
        await session.BeginAsync(source, null, Ct);
        return session;
    }

    [Fact]
    public async Task Revoking_one_device_ends_only_its_sessions_and_refresh_and_revoking_all_ends_the_rest()
    {
        await using var h = new IdentityHarness(postgres); await h.InitializeAsync();
        await using var admin = DatabaseConfiguration.CreateSource(postgres.AdminConnection);
        var subject = "valid-" + Guid.NewGuid();
        var deviceA = Guid.NewGuid(); var deviceB = Guid.NewGuid();
        var a = On(deviceA); var b = On(deviceB);
        var first = (await h.Store.GoogleSignInAsync(new(subject, Guid.NewGuid() + "@example.invalid"), Guid.NewGuid(), a, Ct))!;
        var second = (await h.Store.GoogleSignInAsync(new(subject, "unused@example.invalid"), Guid.NewGuid(), b, Ct))!;
        Assert.Equal(first.UserId, second.UserId);

        IReadOnlyList<ControlDevice> devices;
        await using (var read = await ConsoleAsync(admin)) { devices = await controls.DevicesAsync(read, first.UserId, h.Clock.GetUtcNow(), Ct); }
        Assert.Equal(2, devices.Count);
        Assert.All(devices, device => Assert.Matches("^[0-9a-f]{32}$", device.Key));
        // The key is account-scoped and opaque: neither device id appears in it.
        Assert.DoesNotContain(devices, device => device.Key.Contains(deviceA.ToString("N")[..8], StringComparison.Ordinal)
            || device.Key.Contains(deviceB.ToString("N")[..8], StringComparison.Ordinal));
        var keyA = Key(first.UserId, deviceA);
        Assert.Contains(devices, device => device.Key == keyA);

        await using (var revoke = await ConsoleAsync(admin))
        {
            Assert.Equal(new RevokeOutcome(false, 0), await controls.RevokeAsync(revoke, first.UserId, new string('0', 32), h.Clock.GetUtcNow(), Ct));
            Assert.Equal(new RevokeOutcome(true, 1), await controls.RevokeAsync(revoke, first.UserId, keyA, h.Clock.GetUtcNow(), Ct));
            await revoke.CommitAsync(Ct);
        }
        Assert.Null(await h.Store.ReadSessionAsync(first.UserId, first.SessionId, Ct));
        Assert.Null(await h.Store.RotateAsync(a.RefreshHash, RandomNumberGenerator.GetBytes(32), Ct));
        Assert.NotNull(await h.Store.ReadSessionAsync(second.UserId, second.SessionId, Ct));

        await using (var all = await ConsoleAsync(admin))
        {
            Assert.Equal(new RevokeOutcome(true, 1), await controls.RevokeAsync(all, first.UserId, null, h.Clock.GetUtcNow(), Ct));
            await all.CommitAsync(Ct);
        }
        Assert.Null(await h.Store.ReadSessionAsync(second.UserId, second.SessionId, Ct));
        Assert.Null(await h.Store.RotateAsync(b.RefreshHash, RandomNumberGenerator.GetBytes(32), Ct));
    }

    [Fact]
    [Trait("Rule", "B24.P2-disable-gates")]
    public async Task A_disabled_account_has_no_session_refresh_sign_in_or_link_and_enable_needs_a_new_sign_in()
    {
        await using var h = new IdentityHarness(postgres); await h.InitializeAsync();
        await using var admin = DatabaseConfiguration.CreateSource(postgres.AdminConnection);
        var subject = "valid-" + Guid.NewGuid();
        var material = h.Material();
        var user = (await h.Store.GoogleSignInAsync(new(subject, Guid.NewGuid() + "@example.invalid"), Guid.NewGuid(), material, Ct))!;
        // An email account with a challenge issued before the disable.
        var address = Guid.NewGuid() + "@example.invalid";
        var start = await h.Service.StartEmailAsync(address, "signIn", null, Guid.NewGuid().ToString(), Ct);
        var emailUser = (await h.Service.VerifyEmailAsync(start.Id, h.Email.Code, h.Device, Ct))!;
        h.Clock.Advance(TimeSpan.FromSeconds(61)); // the per-address gap
        var pending = await h.Service.StartEmailAsync(address, "signIn", null, Guid.NewGuid().ToString(), Ct);
        var pendingCode = h.Email.Code;
        // A guest with an email-link challenge and a Google link attempt pending.
        var guest = await h.GuestAsync();
        var linkStart = await h.Service.StartEmailAsync(Guid.NewGuid() + "@example.invalid", "link", guest, Guid.NewGuid().ToString(), Ct);
        var linkCode = h.Email.Code;

        await using (var disable = await ConsoleAsync(admin))
        {
            var outcome = (await controls.SetDisabledAsync(disable, user.UserId, true, h.Clock.GetUtcNow(), Ct))!;
            Assert.False(outcome.WasDisabled); Assert.Equal(1, outcome.RevokedSessions);
            Assert.NotNull(await controls.SetDisabledAsync(disable, emailUser.UserId, true, h.Clock.GetUtcNow(), Ct));
            Assert.NotNull(await controls.SetDisabledAsync(disable, guest.UserId, true, h.Clock.GetUtcNow(), Ct));
            await disable.CommitAsync(Ct);
        }

        Assert.Null(await h.Store.ReadSessionAsync(user.UserId, user.SessionId, Ct));
        Assert.Null(await h.Store.RotateAsync(material.RefreshHash, RandomNumberGenerator.GetBytes(32), Ct));
        Assert.Null(await h.Store.GoogleSignInAsync(new(subject, "again@example.invalid"), Guid.NewGuid(), h.Material(), Ct));
        Assert.Null(await h.Service.VerifyEmailAsync(pending.Id, pendingCode, h.Device, Ct));
        // Gated before any challenge effect: the code still unused, no attempt counted, no verified audit row (review minor 1).
        Assert.Equal(1L, await CountAsync("SELECT count(*) FROM identity.email_challenges WHERE id=$1 AND NOT consumed AND attempts=0", pending.Id));
        Assert.Equal(1L, await CountAsync("SELECT count(*) FROM identity.audit WHERE user_id=$1 AND event='email-verified'", emailUser.UserId));
        // And a disabled account gets no new code: nothing sent, no challenge created.
        var sent = h.Email.Count;
        h.Clock.Advance(TimeSpan.FromSeconds(61));
        var refused = await h.Service.StartEmailAsync(address, "signIn", null, Guid.NewGuid().ToString(), Ct);
        Assert.Equal(sent, h.Email.Count);
        Assert.Equal(0L, await CountAsync("SELECT count(*) FROM identity.email_challenges WHERE id=$1", refused.Id));
        Assert.Null(await h.Store.LinkGoogleAsync(guest, new("valid-" + Guid.NewGuid(), "link@example.invalid"), h.Material(), Ct));
        Assert.Null(await h.Service.LinkAsync(guest, "email", null, linkStart.Id, linkCode, h.Device, Ct));
        Assert.Equal(0L, await CountAsync("SELECT count(*) FROM identity.identities WHERE user_id=$1", guest.UserId));
        Assert.Equal(0L, await CountAsync("SELECT count(*) FROM identity.sessions WHERE user_id=$1 AND NOT revoked", user.UserId));

        // Disable is not a lifecycle status: workers still see the user as active, sessions don't.
        await using (var check = await postgres.SessionAsync(user.UserId))
        {
            Assert.True(await h.Store.IsActiveAsync(check, null, Ct));
            Assert.False(await h.Store.CheckActiveAsync(check, user.UserId, user.SessionId, false, Ct));
        }

        await using (var enable = await ConsoleAsync(admin))
        {
            Assert.Equal(new DisableOutcome(true, 0, false), await controls.SetDisabledAsync(enable, user.UserId, false, h.Clock.GetUtcNow(), Ct));
            await enable.CommitAsync(Ct);
        }
        Assert.Null(await h.Store.ReadSessionAsync(user.UserId, user.SessionId, Ct));
        var again = await h.Store.GoogleSignInAsync(new(subject, "again@example.invalid"), Guid.NewGuid(), h.Material(), Ct);
        Assert.Equal(user.UserId, again?.UserId);
    }

    [Fact]
    [Trait("Rule", "B24.P0-disable-keeps-jobs")]
    public async Task A_disabled_users_job_still_runs_and_its_queue_rows_survive()
    {
        await using var h = new IdentityHarness(postgres); await h.InitializeAsync();
        await using var admin = DatabaseConfiguration.CreateSource(postgres.AdminConnection);
        var user = await h.GuestAsync();
        var ids = new UuidV7IdGenerator(h.Clock);
        await using (var seed = await postgres.SessionAsync(user.UserId))
        {
            var writer = new QueueWriter(seed, h.Clock, ids);
            // Earliest due job in the shared database, so one processor run claims exactly this one.
            await writer.EnqueueAsync("test.b24-marker", new { }, DateTimeOffset.UnixEpoch.AddDays(1), Ct);
            await writer.ScheduleUserAsync("test.b24-schedule:" + user.UserId, "0 3 * * *", "test.b24-marker", h.Clock.GetUtcNow().AddDays(1), Ct);
            await seed.CommitAsync(Ct);
        }
        await using (var disable = await ConsoleAsync(admin))
        {
            Assert.NotNull(await controls.SetDisabledAsync(disable, user.UserId, true, h.Clock.GetUtcNow(), Ct));
            await disable.CommitAsync(Ct);
        }
        var handler = new CountingJob();
        var processor = new QueueProcessor(postgres.App, h.Clock, [], [handler], new QueuePolicy(), NullLogger<QueueProcessor>.Instance, h.Store, postgres.Recovery);
        Assert.True(await processor.RunJobAsync(Ct));
        Assert.Contains(user.UserId, handler.Users);
        Assert.Equal(1L, await CountAsync("SELECT count(*) FROM ops.schedules WHERE user_id=$1", user.UserId));
    }

    [Fact]
    public async Task Controls_on_a_missing_account_write_nothing()
    {
        await using var admin = DatabaseConfiguration.CreateSource(postgres.AdminConnection);
        var missing = Guid.NewGuid();
        await using var session = await ConsoleAsync(admin);
        var now = DateTimeOffset.UtcNow;
        Assert.Null(await controls.StateAsync(session, missing, Ct));
        Assert.Null(await controls.LockAsync(session, missing, Ct));
        Assert.Null(await controls.RevokeAsync(session, missing, null, now, Ct));
        Assert.Null(await controls.SetDisabledAsync(session, missing, true, now, Ct));
        Assert.Null(await controls.RequestDeletionAsync(session, missing, now, Ct));
        await session.CommitAsync(Ct);
        Assert.Equal(0L, await CountAsync("SELECT count(*) FROM identity.audit WHERE user_id=$1", missing));
        Assert.Equal(0L, await CountAsync("SELECT count(*) FROM identity.operator_deletions WHERE user_id=$1", missing));
    }

    [Fact]
    public async Task A_deletion_request_disables_at_once_is_idempotent_and_blocks_enable()
    {
        await using var h = new IdentityHarness(postgres); await h.InitializeAsync();
        await using var admin = DatabaseConfiguration.CreateSource(postgres.AdminConnection);
        var user = await h.GuestAsync();
        await using (var request = await ConsoleAsync(admin))
        {
            Assert.Equal(new DeletionRequestOutcome(false, 1, true), await controls.RequestDeletionAsync(request, user.UserId, h.Clock.GetUtcNow(), Ct));
            Assert.Equal(new DeletionRequestOutcome(true, 0, false), await controls.RequestDeletionAsync(request, user.UserId, h.Clock.GetUtcNow(), Ct));
            await request.CommitAsync(Ct);
        }
        Assert.Null(await h.Store.ReadSessionAsync(user.UserId, user.SessionId, Ct));
        await using var check = await ConsoleAsync(admin);
        var state = (await controls.StateAsync(check, user.UserId, Ct))!;
        Assert.True(state.DeletionPending); Assert.NotNull(state.DisabledAt); Assert.Equal("active", state.Status);
        Assert.Equal(new DisableOutcome(true, 0, true), await controls.SetDisabledAsync(check, user.UserId, false, h.Clock.GetUtcNow(), Ct));
        await check.CommitAsync(Ct);
        await using var after = await ConsoleAsync(admin);
        Assert.NotNull((await controls.StateAsync(after, user.UserId, Ct))!.DisabledAt);
    }

    [Fact]
    [Trait("Rule", "B24.R3-enable-race")]
    public async Task Enable_waiting_behind_a_deletion_request_is_refused_after_it_commits()
    {
        await using var h = new IdentityHarness(postgres); await h.InitializeAsync();
        await using var admin = DatabaseConfiguration.CreateSource(postgres.AdminConnection);
        var user = await h.GuestAsync();
        await using (var disable = await ConsoleAsync(admin))
        {
            await controls.SetDisabledAsync(disable, user.UserId, true, h.Clock.GetUtcNow(), Ct); await disable.CommitAsync(Ct);
        }
        await using var request = await ConsoleAsync(admin);
        Assert.NotNull(await controls.RequestDeletionAsync(request, user.UserId, h.Clock.GetUtcNow(), Ct));
        await using var enable = await ConsoleAsync(admin);
        var enabling = controls.SetDisabledAsync(enable, user.UserId, false, h.Clock.GetUtcNow(), Ct);
        await LockWaits.UntilWaitingAsync(postgres, "admin_set_disabled");
        await request.CommitAsync(Ct);
        Assert.True((await enabling)!.DeletionPending);
        await enable.CommitAsync(Ct);
        await using var check = await ConsoleAsync(admin);
        Assert.NotNull((await controls.StateAsync(check, user.UserId, Ct))!.DisabledAt);
    }

    [Fact]
    [Trait("Rule", "B24.R8-refresh-race")]
    public async Task A_refresh_waiting_behind_a_disable_gets_nothing_after_it_commits()
    {
        await using var h = new IdentityHarness(postgres); await h.InitializeAsync();
        await using var admin = DatabaseConfiguration.CreateSource(postgres.AdminConnection);
        var material = h.Material();
        var user = (await h.Store.CreateGuestAsync(Guid.NewGuid(), material, Ct))!;
        await using var disable = await ConsoleAsync(admin);
        Assert.NotNull(await controls.SetDisabledAsync(disable, user.UserId, true, h.Clock.GetUtcNow(), Ct));
        var refresh = h.Store.RotateAsync(material.RefreshHash, RandomNumberGenerator.GetBytes(32), Ct);
        await LockWaits.UntilWaitingAsync(postgres, "rotate_refresh");
        await disable.CommitAsync(Ct);
        Assert.Null(await refresh);
    }

    [Fact]
    [Trait("Rule", "B24.R1-operator-capability")]
    public async Task The_operator_deletion_capability_needs_a_committed_due_intent_that_only_the_console_can_create()
    {
        await using var h = new IdentityHarness(postgres); await h.InitializeAsync();
        await using var admin = DatabaseConfiguration.CreateSource(postgres.AdminConnection);
        var user = await h.GuestAsync(); var other = await h.GuestAsync();
        var erasure = new IdentityErasure(Microsoft.Extensions.Options.Options.Create(h.Options), h.Clock);
        var operatorDeletions = new PostgresOperatorDeletions(postgres.App, h.Clock);

        // No intent: nothing changes.
        await using (var session = await postgres.SessionAsync(user.UserId))
        {
            Assert.False(await erasure.BeginOperatorAsync(session, Ct));
            Assert.False(await operatorDeletions.RecordFailureAsync(session, "failed", Ct));
            await session.CommitAsync(Ct);
        }
        await AssertUntouchedAsync(h, user);

        // The application login can't create an intent, neither through the console's function nor directly.
        await using (var direct = await postgres.SessionAsync(user.UserId))
        {
            await using var call = direct.Command("SELECT * FROM identity.admin_request_deletion($1, now())");
            call.Parameters.AddWithValue(user.UserId);
            Assert.Equal(PostgresErrorCodes.InsufficientPrivilege, (await Assert.ThrowsAsync<PostgresException>(() => call.ExecuteNonQueryAsync(Ct))).SqlState);
        }
        await using (var direct = await postgres.SessionAsync(user.UserId))
        {
            await using var insert = direct.Command("INSERT INTO identity.operator_deletions(user_id,requested_at,available_at) VALUES($1,now(),now())");
            insert.Parameters.AddWithValue(user.UserId);
            Assert.Equal(PostgresErrorCodes.InsufficientPrivilege, (await Assert.ThrowsAsync<PostgresException>(() => insert.ExecuteNonQueryAsync(Ct))).SqlState);
        }
        // And the console login can't run the capability.
        await using (var console = await ConsoleAsync(admin))
        {
            await using var call = console.Command("SELECT identity.begin_operator_deletion($1, now())");
            call.Parameters.AddWithValue(user.UserId);
            Assert.Equal(PostgresErrorCodes.InsufficientPrivilege, (await Assert.ThrowsAsync<PostgresException>(() => call.ExecuteNonQueryAsync(Ct))).SqlState);
        }

        // An intent that isn't due yet, or a caller whose GUC is another user: still nothing.
        await using (var request = await ConsoleAsync(admin))
        {
            Assert.NotNull(await controls.RequestDeletionAsync(request, user.UserId, h.Clock.GetUtcNow(), Ct)); await request.CommitAsync(Ct);
        }
        await using (var owner = DatabaseConfiguration.CreateSource(postgres.MigratorConnection))
        await using (var later = owner.CreateCommand("UPDATE identity.operator_deletions SET available_at=$2 WHERE user_id=$1"))
        {
            later.Parameters.AddWithValue(user.UserId); later.Parameters.AddWithValue(h.Clock.GetUtcNow().AddHours(1));
            await later.ExecuteNonQueryAsync(Ct);
        }
        await using (var early = await postgres.SessionAsync(user.UserId)) { Assert.False(await erasure.BeginOperatorAsync(early, Ct)); await early.CommitAsync(Ct); }
        await using (var crafted = await postgres.SessionAsync(other.UserId))
        {
            await using var call = crafted.Command("SELECT identity.begin_operator_deletion($1,$2)");
            call.Parameters.AddWithValue(user.UserId); call.Parameters.AddWithValue(h.Clock.GetUtcNow().AddHours(2));
            Assert.False((bool)(await call.ExecuteScalarAsync(Ct))!);
            await crafted.CommitAsync(Ct);
        }
        Assert.Equal("active", await StatusAsync(user.UserId));
        Assert.Equal(0L, await CountAsync("SELECT count(*) FROM identity.audit WHERE user_id=$1 AND event='deletion-pending'", user.UserId));

        // Due: the capability starts the deletion; a recorded failure then backs off.
        h.Clock.Advance(TimeSpan.FromHours(2));
        await using (var due = await postgres.SessionAsync(user.UserId))
        {
            Assert.True(await operatorDeletions.RecordFailureAsync(due, "recovery-unavailable", Ct));
            await due.CommitAsync(Ct);
        }
        Assert.DoesNotContain(user.UserId, await operatorDeletions.DueAsync(h.Clock.GetUtcNow(), 50, Ct));
        h.Clock.Advance(TimeSpan.FromMinutes(3));
        Assert.Contains(user.UserId, await operatorDeletions.DueAsync(h.Clock.GetUtcNow(), 50, Ct));
        await using (var begin = await postgres.SessionAsync(user.UserId)) { Assert.True(await erasure.BeginOperatorAsync(begin, Ct)); await begin.CommitAsync(Ct); }
        Assert.Equal("deleting", await StatusAsync(user.UserId));
    }

    private async Task AssertUntouchedAsync(IdentityHarness h, IdentitySession user)
    {
        Assert.Equal("active", await StatusAsync(user.UserId));
        Assert.NotNull(await h.Store.ReadSessionAsync(user.UserId, user.SessionId, Ct));
        Assert.Equal(0L, await CountAsync("SELECT count(*) FROM identity.audit WHERE user_id=$1 AND event='deletion-pending'", user.UserId));
    }

    private static string Key(Guid user, Guid device) =>
        Convert.ToHexStringLower(SHA256.HashData(System.Text.Encoding.UTF8.GetBytes(user + ":" + device)))[..32];

    private async Task<string> StatusAsync(Guid user)
    {
        await using var owner = DatabaseConfiguration.CreateSource(postgres.MigratorConnection);
        await using var command = owner.CreateCommand("SELECT status FROM identity.users WHERE id=$1");
        command.Parameters.AddWithValue(user);
        return (string)(await command.ExecuteScalarAsync(Ct))!;
    }

    private async Task<long> CountAsync(string sql, Guid user)
    {
        await using var owner = DatabaseConfiguration.CreateSource(postgres.MigratorConnection);
        await using var command = owner.CreateCommand(sql);
        command.Parameters.AddWithValue(user);
        return (long)(await command.ExecuteScalarAsync(Ct))!;
    }

    private sealed class CountingJob : IJobHandler
    {
        public System.Collections.Concurrent.ConcurrentBag<Guid> Users { get; } = [];
        public string JobType => "test.b24-marker";
        public Task HandleAsync(QueueMessage message, DatabaseSession session, CancellationToken cancellationToken)
        {
            if (message.UserId is Guid user) { Users.Add(user); }
            return Task.CompletedTask;
        }
    }
}

/// <summary>Deterministic race steps: wait until a backend running <c>query</c> is blocked on a lock.</summary>
internal static class LockWaits
{
    public static async Task UntilWaitingAsync(PostgresFixture postgres, string queryFragment)
    {
        await using var owner = NpgsqlDataSource.Create(postgres.SuperuserConnection);
        for (var i = 0; i < 500; i++)
        {
            await using var command = owner.CreateCommand(
                "SELECT count(*) FROM pg_stat_activity WHERE wait_event_type='Lock' AND query LIKE $1 AND pid<>pg_backend_pid()");
            command.Parameters.AddWithValue("%" + queryFragment + "%");
            if ((long)(await command.ExecuteScalarAsync(TestContext.Current.CancellationToken))! > 0) { return; }
            await Task.Delay(10, TestContext.Current.CancellationToken);
        }
        Assert.Fail("The expected lock wait didn't happen: " + queryFragment);
    }
}
