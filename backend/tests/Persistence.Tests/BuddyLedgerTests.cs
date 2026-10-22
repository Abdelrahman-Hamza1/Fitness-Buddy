using FitnessBuddy.BuildingBlocks.Auth;
using FitnessBuddy.BuildingBlocks.Ids;
using FitnessBuddy.Modules.Buddy.Application;
using FitnessBuddy.Modules.Buddy.Domain;
using FitnessBuddy.Modules.Buddy.Infrastructure;
using FitnessBuddy.Modules.Identity.Contracts;
using FitnessBuddy.Modules.Usage.Infrastructure;
using Microsoft.Extensions.Options;
using Npgsql;

namespace FitnessBuddy.Persistence.Tests;

public sealed class BuddyLedgerTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;
    [Fact]
    [Trait("Req", "MN-005")]
    [Trait("Req", "AC-041")]
    [Trait("Rule", "04.6-rls")]
    public async Task Crash_reservation_survives_new_instance_RLS_isolates_and_expired_content_is_purged()
    {
        await using var h = new IdentityHarness(postgres); await h.InitializeAsync(); var owner = await h.GuestAsync(); var other = await h.GuestAsync();
        var input = Input(h);
        Assert.Null(await Ledger(h, owner).ClaimAsync(input, Ct));
        Assert.Equal(InterpretStatus.Pending, (await Ledger(h, owner).ClaimAsync(input, Ct))!.Status);
        Assert.Equal(InterpretStatus.Limited, (await Ledger(h, owner).ClaimAsync(input with { RequestId = Guid.CreateVersion7() }, Ct))!.Status);
        await using (var alien = await postgres.SessionAsync(other.UserId))
        {
            await using var read = alien.Command("SELECT count(*) FROM buddy.attempts"); Assert.Equal(0L, await read.ExecuteScalarAsync(Ct));
            await using var insert = alien.Command("INSERT INTO buddy.attempts(user_id,message_id,fingerprint,created_at,dispatched_at,expires_at) VALUES($1,$2,'hash',$3,$3,$3)");
            insert.Parameters.AddWithValue(owner.UserId); insert.Parameters.AddWithValue(Guid.CreateVersion7()); insert.Parameters.AddWithValue(h.Clock.GetUtcNow());
            var error = await Assert.ThrowsAsync<PostgresException>(() => insert.ExecuteNonQueryAsync(Ct)); Assert.Equal("42501", error.SqlState);
        }
        h.Clock.Advance(TimeSpan.FromHours(25));
        await using (var session = await postgres.SessionAsync(owner.UserId))
        {
            await new BuddyCleanup(h.Clock, new PostgresUsageRecorder(h.Clock)).HandleAsync(new(Guid.CreateVersion7(), "buddy.cleanup", "{}", owner.UserId, 1), session, Ct);
            await session.CommitAsync(Ct);
        }
        await using (var session = await postgres.SessionAsync(owner.UserId))
        { await using var read = session.Command("SELECT count(*) FROM buddy.attempts"); Assert.Equal(0L, await read.ExecuteScalarAsync(Ct)); }
        Assert.Null(await Ledger(h, owner).ClaimAsync(input, Ct));
    }
    [Fact]
    [Trait("Req", "AC-031")]
    [Trait("Req", "MN-005")]
    public async Task Revoked_session_cannot_reserve_repair_or_record_and_midnight_usage_stays_on_dispatch_day()
    {
        await using var h = new IdentityHarness(postgres); await h.InitializeAsync(); var owner = await h.GuestAsync(); var ledger = Ledger(h, owner, 3); var input = Input(h);
        Assert.Null(await ledger.ClaimAsync(input, Ct)); h.Clock.Advance(TimeSpan.FromHours(15));
        Assert.True(await ledger.RecordAsync(input.RequestId, 1, new(LlmStatus.InvalidOutput, null, new(100, 0, 50), .000035m), Ct));
        await using (var session = await postgres.SessionAsync(owner.UserId))
        {
            await using var read = session.Command("SELECT day,input_tokens FROM usage.daily WHERE user_id=$1"); read.Parameters.AddWithValue(owner.UserId);
            await using var reader = await read.ExecuteReaderAsync(Ct); Assert.True(await reader.ReadAsync(Ct));
            Assert.Equal(new DateOnly(2026, 10, 16), reader.GetFieldValue<DateOnly>(0)); Assert.Equal(100L, reader.GetInt64(1));
        }
        await h.Store.RevokeAsync(owner.UserId, owner.SessionId, Ct);
        Assert.Equal(InterpretStatus.Unauthorized, await ledger.ReserveRepairAsync(input.RequestId, Ct));
        Assert.False(await ledger.RecordAsync(input.RequestId, 2, new(LlmStatus.Success, null, null, null), Ct));
    }
    private PostgresInterpretLedger Ledger(IdentityHarness h, IdentitySession owner, int limit = 1) => new(postgres.App, new Current(owner), h.Store,
        postgres.Recovery, h.Clock, new UuidV7IdGenerator(h.Clock), new PostgresUsageRecorder(h.Clock), Options.Create(new BuddyOptions { GuestDailyCalls = limit, RegisteredDailyCalls = limit }));
    private static InterpretInput Input(IdentityHarness h) => new(Guid.CreateVersion7(), "private-ledger-canary", h.Clock.GetUtcNow(), 180, new(false, null, null), [], null, new([], [], [], [], [], []));
    private sealed class Current(IdentitySession session) : ICurrentUser
    {
        public Guid? UserId => session.UserId;
        public Guid? SessionId => session.SessionId;
        public bool IsAuthenticated => true;
    }
}
