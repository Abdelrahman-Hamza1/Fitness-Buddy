using System.Security.Cryptography;
using FitnessBuddy.BuildingBlocks.Messaging;
using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.Modules.Identity.Application;
using FitnessBuddy.Modules.Identity.Infrastructure;
using Npgsql;

namespace FitnessBuddy.Persistence.Tests;

// R1 security audit: abandoned sign-ins, idle throttles and dead session families don't stay forever. The clock starts in 2001,
// so the (global) cleanup can only reach this test's rows, never another test's.
[Trait("Rule", "09.4-identity-retention")]
public sealed class IdentityRetentionTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    [Fact]
    public async Task Cleanup_removes_expired_challenges_idle_throttles_and_expired_families_but_keeps_live_reuse_evidence()
    {
        var clock = new TestClock(new DateTimeOffset(2001, 1, 1, 0, 0, 0, TimeSpan.Zero));
        var store = new PostgresIdentityStore(postgres.App, clock);
        var old = (await store.CreateGuestAsync(Guid.NewGuid(), Material(), Ct))!;
        var (oldChallenge, oldAddress, oldIp) = (Guid.NewGuid(), Bytes(), Bytes());
        Assert.True(await store.StartEmailAsync(oldChallenge, oldAddress, Bytes(), "signIn", null, oldIp, Ct));

        clock.Advance(TimeSpan.FromDays(31));
        var liveMaterial = Material();
        var live = (await store.CreateGuestAsync(Guid.NewGuid(), liveMaterial, Ct))!;
        var rotated = Bytes();
        Assert.NotNull(await store.RotateAsync(liveMaterial.RefreshHash, rotated, Ct));
        var (freshChallenge, freshAddress, freshIp) = (Guid.NewGuid(), Bytes(), Bytes());
        Assert.True(await store.StartEmailAsync(freshChallenge, freshAddress, Bytes(), "signIn", null, freshIp, Ct));

        await using (var denied = postgres.App.CreateCommand("SELECT identity.cleanup(now(), 1)"))
        { Assert.Equal(PostgresErrorCodes.InsufficientPrivilege, (await Assert.ThrowsAsync<PostgresException>(() => denied.ExecuteNonQueryAsync(Ct))).SqlState); }
        await using (var session = await postgres.WorkerSessionAsync())
        {
            await new IdentityCleanupJob(clock).HandleAsync(new QueueMessage(Guid.NewGuid(), IdentityCleanupJob.Type, "{}", null, 1), session, Ct);
            await session.CommitAsync(Ct);
        }

        await using var source = DatabaseConfiguration.CreateSource(postgres.MigratorConnection);
        Assert.Equal(0, await CountAsync(source, "SELECT count(*) FROM identity.sessions WHERE id=$1", old.SessionId));
        Assert.Equal(0, await CountAsync(source, "SELECT count(*) FROM identity.refresh_tokens WHERE session_id=$1", old.SessionId));
        Assert.Equal(0, await CountAsync(source, "SELECT count(*) FROM identity.email_challenges WHERE id=$1", oldChallenge));
        Assert.Equal(0, await CountAsync(source, "SELECT count(*) FROM identity.throttles WHERE bucket=ANY($1)", new[] { oldAddress, oldIp }));
        Assert.Equal(1, await CountAsync(source, "SELECT count(*) FROM identity.sessions WHERE id=$1", live.SessionId));
        // The consumed hash stays with its live family, so presenting it again still revokes the family.
        Assert.Equal(1, await CountAsync(source, "SELECT count(*) FROM identity.refresh_tokens WHERE session_id=$1 AND consumed", live.SessionId));
        Assert.Equal(1, await CountAsync(source, "SELECT count(*) FROM identity.email_challenges WHERE id=$1", freshChallenge));
        Assert.Equal(2, await CountAsync(source, "SELECT count(*) FROM identity.throttles WHERE bucket=ANY($1)", new[] { freshAddress, freshIp }));
        Assert.Null(await store.RotateAsync(liveMaterial.RefreshHash, Bytes(), Ct));
        Assert.Null(await store.ReadSessionAsync(live.UserId, live.SessionId, Ct));
    }

    private static SessionMaterial Material() => new(Guid.NewGuid(), Guid.NewGuid(), Bytes());
    private static byte[] Bytes() => RandomNumberGenerator.GetBytes(32);
    private static async Task<long> CountAsync(NpgsqlDataSource source, string sql, object value)
    {
        await using var command = source.CreateCommand(sql);
        command.Parameters.AddWithValue(value);
        return (long)(await command.ExecuteScalarAsync(Ct))!;
    }
}
