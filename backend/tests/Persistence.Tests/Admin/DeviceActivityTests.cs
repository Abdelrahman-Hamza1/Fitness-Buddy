using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.Modules.Identity.Infrastructure;

namespace FitnessBuddy.Persistence.Tests.Admin;

// B23 WP4: device activity feeds the console's install counts; at most one write per device per hour; only the console login reads counts.
[Trait("Req", "AD-010")]
[Trait("Req", "AD-006")]
public sealed class DeviceActivityTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    [Fact]
    public async Task Touch_is_throttled_to_hourly_or_a_version_change_and_counts_reach_only_the_console_login()
    {
        await using var h = new IdentityHarness(postgres); await h.InitializeAsync();
        var guest = await h.GuestAsync();
        var version = "9." + Random.Shared.Next(1000, 9999) + ".0";
        await h.Store.TouchAsync(guest.UserId, guest.SessionId, version, "android", Ct);
        var first = await LastSeenAsync(guest.UserId);
        Assert.NotNull(first);

        h.Clock.Advance(TimeSpan.FromMinutes(10));
        await h.Store.TouchAsync(guest.UserId, guest.SessionId, version, "android", Ct);
        Assert.Equal(first, await LastSeenAsync(guest.UserId));

        var newer = "9." + Random.Shared.Next(10000, 99999) + ".1";
        await h.Store.TouchAsync(guest.UserId, guest.SessionId, newer, "android", Ct);
        Assert.NotEqual(first, await LastSeenAsync(guest.UserId));

        // Another user's session id can't touch this device.
        var other = await h.GuestAsync();
        h.Clock.Advance(TimeSpan.FromHours(2));
        var before = await LastSeenAsync(guest.UserId);
        await h.Store.TouchAsync(guest.UserId, other.SessionId, "9.9.9", "android", Ct);
        Assert.Equal(before, await LastSeenAsync(guest.UserId));

        await using var adminSource = DatabaseConfiguration.CreateSource(postgres.AdminConnection);
        var installs = await new PostgresIdentityAdminReads(adminSource).InstallsAsync(h.Clock.GetUtcNow().AddDays(-1), Ct);
        Assert.Contains(installs, row => row.AppVersion == newer && row.Platform == "android" && row.Installs == 1);
        Assert.DoesNotContain(installs, row => row.AppVersion == version);

        // The application login can't run the console's count.
        await using var app = postgres.App.CreateCommand("SELECT count(*) FROM identity.admin_installs(now())");
        var denied = await Assert.ThrowsAsync<Npgsql.PostgresException>(async () => await app.ExecuteScalarAsync(Ct));
        Assert.Equal(Npgsql.PostgresErrorCodes.InsufficientPrivilege, denied.SqlState);
    }

    private async Task<DateTimeOffset?> LastSeenAsync(Guid user)
    {
        await using var owner = DatabaseConfiguration.CreateSource(postgres.MigratorConnection);
        await using var command = owner.CreateCommand("SELECT last_seen_at FROM identity.devices WHERE user_id=$1");
        command.Parameters.AddWithValue(user);
        return await command.ExecuteScalarAsync(Ct) is DateTime value ? new DateTimeOffset(value, TimeSpan.Zero) : null;
    }
}
