using System.Net;
using System.Net.Http.Headers;
using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.Modules.Identity.Infrastructure;
using FitnessBuddy.Modules.Usage.Infrastructure;
using Npgsql;

namespace FitnessBuddy.Persistence.Tests.Admin;

// B24 WP2: the operator's per-account Buddy daily limit (AD-011). A zero limit allows no physical send, even on a fresh day
// with no usage row (R#4; a label read since interpret's retirement, B26); other limits replace the default; only the console login can set it; the app login sees only its own.
[Trait("Req", "AD-011")]
[Trait("Req", "MN-005")]
public sealed class BuddyLimitOverrideTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    private async Task SetLimitAsync(Guid user, int? calls)
    {
        await using var admin = DatabaseConfiguration.CreateSource(postgres.AdminConnection);
        await using var session = new DatabaseSession();
        await session.BeginAsync(admin, null, Ct);
        Assert.NotNull(await new PostgresIdentityAdminControls().LockAsync(session, user, Ct));
        await new PostgresUsageAdminControls().SetDailyLimitAsync(session, user, calls, DateTimeOffset.UtcNow, Ct);
        await session.CommitAsync(Ct);
    }

    [Fact]
    [Trait("Rule", "B24.R4-zero-limit")]
    public async Task A_zero_limit_sends_nothing_on_a_fresh_day_and_reports_the_override_in_the_headers()
    {
        await using var h = new IdentityHarness(postgres); await h.InitializeAsync();
        using var wire = new BuddyApiTests.BuddyWire();
        await using var api = new BuddyApiTests.BuddyApi(postgres, h, wire); using var client = api.CreateClient(); BuddyApiTests.Headers(client, h);
        var tokens = (await h.Service.GuestAsync(h.Device, Ct))!;
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", tokens.AccessToken);
        await SetLimitAsync(tokens.UserId, 0);

        for (var day = 0; day < 2; day++)
        {
            using var limited = await BuddyApiTests.SendLabel(client);
            Assert.Equal(HttpStatusCode.TooManyRequests, limited.StatusCode);
            Assert.Contains("q=0", string.Join(",", limited.Headers.GetValues("RateLimit-Policy")), StringComparison.Ordinal);
            Assert.Equal(0, api.Label.Calls);
            Assert.Equal(0L, await DailyRowsAsync(tokens.UserId));
            h.Clock.Advance(TimeSpan.FromDays(1)); // UTC rollover: still no row, still nothing sent.
            tokens = (await h.Service.RefreshAsync(tokens.RefreshToken, Ct))!;
            client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", tokens.AccessToken);
        }

        await SetLimitAsync(tokens.UserId, null);
        using var allowed = await BuddyApiTests.SendLabel(client);
        Assert.Equal(HttpStatusCode.OK, allowed.StatusCode);
        Assert.Equal(1, api.Label.Calls);
    }

    [Fact]
    public async Task An_override_replaces_the_default_until_cleared_and_only_the_owner_can_read_it()
    {
        await using var h = new IdentityHarness(postgres); await h.InitializeAsync();
        var user = await h.GuestAsync(); var other = await h.GuestAsync();
        var recorder = new PostgresUsageRecorder(h.Clock);
        var day = DateOnly.FromDateTime(h.Clock.GetUtcNow().UtcDateTime);
        await SetLimitAsync(user.UserId, 2);

        await using (var session = await postgres.SessionAsync(user.UserId))
        {
            Assert.Equal(new(true, 2), await recorder.ReserveAsync(session, "m", 5, day, true, Ct));
            Assert.Equal(new(true, 2), await recorder.ReserveAsync(session, "m", 5, day, true, Ct));
            Assert.Equal(new(false, 2), await recorder.ReserveAsync(session, "m", 5, day, true, Ct));
            await session.CommitAsync(Ct);
        }
        await using (var peek = await postgres.SessionAsync(other.UserId))
        {
            await using var count = peek.Command("SELECT count(*) FROM usage.limit_overrides");
            Assert.Equal(0L, await count.ExecuteScalarAsync(Ct));
            await using var set = peek.Command("SELECT usage.admin_set_daily_limit($1, 1000, now())");
            set.Parameters.AddWithValue(other.UserId);
            Assert.Equal(PostgresErrorCodes.InsufficientPrivilege, (await Assert.ThrowsAsync<PostgresException>(() => set.ExecuteScalarAsync(Ct))).SqlState);
        }

        await SetLimitAsync(user.UserId, null);
        await using (var session = await postgres.SessionAsync(user.UserId))
        {
            Assert.Equal(new(true, 5), await recorder.ReserveAsync(session, "m", 5, day, true, Ct));
            await session.CommitAsync(Ct);
        }
    }

    [Fact]
    [Trait("Rule", "B24.P3-override-erasure-only")]
    public async Task The_app_login_cannot_clear_an_override_of_an_account_that_is_not_being_deleted()
    {
        await using var h = new IdentityHarness(postgres); await h.InitializeAsync();
        await using var admin = DatabaseConfiguration.CreateSource(postgres.AdminConnection);
        var user = await h.GuestAsync(); var disabled = await h.GuestAsync();
        await SetLimitAsync(user.UserId, 0);
        await SetLimitAsync(disabled.UserId, 0);
        await using (var console = new DatabaseSession())
        {
            await console.BeginAsync(admin, null, Ct);
            Assert.NotNull(await new PostgresIdentityAdminControls().SetDisabledAsync(console, disabled.UserId, true, DateTimeOffset.UtcNow, Ct));
            await console.CommitAsync(Ct);
        }

        foreach (var (owner, target) in new[] { (user.UserId, user.UserId), (disabled.UserId, disabled.UserId), (disabled.UserId, user.UserId) })
        {
            // No direct write, whatever the RLS context.
            await using (var direct = await postgres.SessionAsync(owner))
            {
                await using var delete = direct.Command("DELETE FROM usage.limit_overrides WHERE user_id=$1");
                delete.Parameters.AddWithValue(target);
                Assert.Equal(PostgresErrorCodes.InsufficientPrivilege, (await Assert.ThrowsAsync<PostgresException>(() => delete.ExecuteNonQueryAsync(Ct))).SqlState);
            }
            // The erasure capability refuses an active or disabled account, and anyone else's.
            await using (var erase = await postgres.SessionAsync(owner))
            {
                await using var call = erase.Command("SELECT usage.erase_limit_override($1)");
                call.Parameters.AddWithValue(target);
                Assert.Equal(PostgresErrorCodes.InsufficientPrivilege, (await Assert.ThrowsAsync<PostgresException>(() => call.ExecuteNonQueryAsync(Ct))).SqlState);
            }
        }
        // And Identity's predicate isn't callable by the app login at all.
        await using (var probe = await postgres.SessionAsync(user.UserId))
        {
            await using var call = probe.Command("SELECT identity.erasure_in_progress($1)");
            call.Parameters.AddWithValue(user.UserId);
            Assert.Equal(PostgresErrorCodes.InsufficientPrivilege, (await Assert.ThrowsAsync<PostgresException>(() => call.ExecuteScalarAsync(Ct))).SqlState);
        }
        Assert.Equal(1L, await OverrideRowsAsync(user.UserId));
        Assert.Equal(1L, await OverrideRowsAsync(disabled.UserId));
    }

    [Fact]
    [Trait("Rule", "B24.P3-override-erasure-only")]
    public async Task Erasing_waits_for_a_concurrent_account_creation_and_then_refuses_its_override()
    {
        // A creation with an operator override, holding the account's lifecycle lock like every creation path, not yet committed.
        var user = Guid.NewGuid();
        await using var owner = DatabaseConfiguration.CreateSource(postgres.MigratorConnection);
        await using var creation = new DatabaseSession();
        await creation.BeginAsync(owner, null, Ct);
        await UserLifecycleLock.AcquireAsync(creation, user, Ct);
        await using (var insert = creation.Command("INSERT INTO identity.users VALUES($1,true,'active',now())"))
        { insert.Parameters.AddWithValue(user); await insert.ExecuteNonQueryAsync(Ct); }
        await using (var insert = creation.Command("INSERT INTO usage.limit_overrides VALUES($1,0,now())"))
        { insert.Parameters.AddWithValue(user); await insert.ExecuteNonQueryAsync(Ct); }

        // The app login's erasure call can't decide on the uncommitted state: it waits for the lock, then sees an active account.
        await using var erase = await postgres.SessionAsync(user);
        await using var call = erase.Command("SELECT usage.erase_limit_override($1)");
        call.Parameters.AddWithValue(user);
        var erasing = call.ExecuteNonQueryAsync(Ct);
        await LockWaits.UntilWaitingAsync(postgres, "erase_limit_override");
        await creation.CommitAsync(Ct);

        Assert.Equal(PostgresErrorCodes.InsufficientPrivilege, (await Assert.ThrowsAsync<PostgresException>(() => erasing)).SqlState);
        Assert.Equal(1L, await OverrideRowsAsync(user));
    }

    private async Task<long> OverrideRowsAsync(Guid user)
    {
        await using var owner = DatabaseConfiguration.CreateSource(postgres.MigratorConnection);
        await using var command = owner.CreateCommand("SELECT count(*) FROM usage.limit_overrides WHERE user_id=$1");
        command.Parameters.AddWithValue(user);
        return (long)(await command.ExecuteScalarAsync(Ct))!;
    }

    private async Task<long> DailyRowsAsync(Guid user)
    {
        await using var owner = DatabaseConfiguration.CreateSource(postgres.MigratorConnection);
        await using var command = owner.CreateCommand("SELECT count(*) FROM usage.daily WHERE user_id=$1");
        command.Parameters.AddWithValue(user);
        return (long)(await command.ExecuteScalarAsync(Ct))!;
    }
}
