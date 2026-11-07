using FitnessBuddy.BuildingBlocks.Auth;
using FitnessBuddy.BuildingBlocks.Ids;
using FitnessBuddy.BuildingBlocks.Messaging;
using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.BuildingBlocks.Recovery;
using FitnessBuddy.Modules.Buddy.Application;
using FitnessBuddy.Modules.Buddy.Domain;
using FitnessBuddy.Modules.Identity.Contracts;
using FitnessBuddy.Modules.Usage.Contracts;
using Microsoft.Extensions.Options;
using Npgsql;

namespace FitnessBuddy.Modules.Buddy.Infrastructure;

/// <summary>
/// The content-free turn ledger (06 §3.4, TD-125): one turn row (start, sends, tokens, rounds, message charged) and one row per
/// round (started | completed | cancelled, attempts, acknowledged). No text, no tool data. Each transaction rechecks the live
/// session and recovery generation like interpret's ledger; no lock spans provider I/O.
/// </summary>
internal sealed class PostgresAgentLedger(NpgsqlDataSource source, ICurrentUser user, IIdentityAccess identity, RecoveryBarrier recovery,
    TimeProvider clock, IIdGenerator ids, IUsageRecorder usage, IOptions<BuddyAgentOptions> options) : IAgentLedger
{
    private static readonly TimeSpan Acknowledged = TimeSpan.FromMinutes(10);
    private Guid? generation;

    public async Task<RoundGate> BeginStartAsync(Guid turnId, Guid? ackTurn, bool guest, CancellationToken cancellationToken)
    {
        await using var session = new DatabaseSession();
        if (!await OpenAsync(session, cancellationToken)) { return new(RoundGateStatus.Unauthorized); }
        var owner = user.UserId!.Value; var now = clock.GetUtcNow();
        if (ackTurn is { } previous && previous != turnId)
        {
            await using var ack = session.Command("UPDATE buddy.turn_rounds SET acknowledged=true WHERE user_id=$1 AND turn_id=$2");
            ack.Parameters.AddWithValue(owner); ack.Parameters.AddWithValue(previous); await ack.ExecuteNonQueryAsync(cancellationToken);
        }
        var budget = await TurnAsync(session, turnId, cancellationToken);
        if (budget is null)
        {
            var limits = options.Value;
            var reservation = await usage.ReserveMessageAsync(session, OpenAIClientFactory.Model,
                guest ? limits.GuestDailyMessages : limits.RegisteredDailyMessages, DateOnly.FromDateTime(now.UtcDateTime), cancellationToken);
            if (!reservation.Reserved) { return new(RoundGateStatus.Limited, Limit: reservation.Ceiling); }
            await using (var insert = session.Command("INSERT INTO buddy.turns(user_id,turn_id,started_at,expires_at,message_charged) VALUES($1,$2,$3,$4,true)"))
            {
                insert.Parameters.AddWithValue(owner); insert.Parameters.AddWithValue(turnId); insert.Parameters.AddWithValue(now); insert.Parameters.AddWithValue(now.AddHours(24));
                await insert.ExecuteNonQueryAsync(cancellationToken);
            }
            await using (var first = session.Command("INSERT INTO buddy.turn_rounds(user_id,turn_id,round,state) VALUES($1,$2,0,'started')"))
            {
                first.Parameters.AddWithValue(owner); first.Parameters.AddWithValue(turnId); await first.ExecuteNonQueryAsync(cancellationToken);
            }
            await new QueueWriter(session, clock, ids).ScheduleUserAsync("buddy.cleanup:" + owner, "*/5 * * * *", "buddy.cleanup", now.AddMinutes(5), cancellationToken);
            await session.CommitAsync(cancellationToken);
            return new(RoundGateStatus.Run, 1, new(now, 0, 0, 0));
        }
        var gate = await RetryAsync(session, turnId, 0, now, cancellationToken);
        if (gate.Status == RoundGateStatus.Run) { await session.CommitAsync(cancellationToken); }
        return gate with { Budget = budget };
    }

    public async Task<RoundGate> BeginContinueAsync(Guid turnId, int round, int producerAttempt, PhoneDisclosure disclosure, CancellationToken cancellationToken)
    {
        await using var session = new DatabaseSession();
        if (!await OpenAsync(session, cancellationToken)) { return new(RoundGateStatus.Unauthorized); }
        var owner = user.UserId!.Value; var now = clock.GetUtcNow();
        var budget = await TurnAsync(session, turnId, cancellationToken);
        if (budget is null || round is < 1 or > 3) { return new(RoundGateStatus.Invalid); }
        // The previous round's current attempt sealed this continuation (a superseded attempt's continuation is void);
        // posting this round acknowledges it.
        await using (var previous = session.Command("UPDATE buddy.turn_rounds SET acknowledged=true WHERE user_id=$1 AND turn_id=$2 AND round=$3 AND attempts=$4"))
        {
            previous.Parameters.AddWithValue(owner); previous.Parameters.AddWithValue(turnId); previous.Parameters.AddWithValue(round - 1); previous.Parameters.AddWithValue(producerAttempt);
            if (await previous.ExecuteNonQueryAsync(cancellationToken) != 1) { return new(RoundGateStatus.Invalid); }
        }
        await using (var insert = session.Command("INSERT INTO buddy.turn_rounds(user_id,turn_id,round,state,results_digest) VALUES($1,$2,$3,'started',$4) ON CONFLICT DO NOTHING"))
        {
            insert.Parameters.AddWithValue(owner); insert.Parameters.AddWithValue(turnId); insert.Parameters.AddWithValue(round); insert.Parameters.AddWithValue(disclosure.Digest);
            if (await insert.ExecuteNonQueryAsync(cancellationToken) == 1)
            {
                // The turn's authoritative disclosure counters (TD-127): only a first post of a round adds to them.
                bool exceeded;
                await using (var count = session.Command("""
                    UPDATE buddy.turns SET rounds=GREATEST(rounds,$3),disclosed_rows=disclosed_rows+$4,disclosed_bytes=disclosed_bytes+$5
                    WHERE user_id=$1 AND turn_id=$2 RETURNING disclosed_rows>$6 OR disclosed_bytes>$7
                    """))
                {
                    count.Parameters.AddWithValue(owner); count.Parameters.AddWithValue(turnId); count.Parameters.AddWithValue(round);
                    count.Parameters.AddWithValue(disclosure.Rows); count.Parameters.AddWithValue(disclosure.Bytes);
                    count.Parameters.AddWithValue(PhoneTools.MaxRows); count.Parameters.AddWithValue(PhoneTools.MaxBytes);
                    exceeded = (bool)(await count.ExecuteScalarAsync(cancellationToken))!;
                }
                await session.CommitAsync(cancellationToken);
                return new(RoundGateStatus.Run, 1, budget, DisclosureExceeded: exceeded);
            }
        }
        // A retry must repeat the same results (same digest) and reuses the first post's disclosure reservation.
        bool sameResults, overBudget;
        await using (var read = session.Command("""
            SELECT r.results_digest=$4,t.disclosed_rows>$5 OR t.disclosed_bytes>$6 FROM buddy.turn_rounds r JOIN buddy.turns t ON t.user_id=r.user_id AND t.turn_id=r.turn_id
            WHERE r.user_id=$1 AND r.turn_id=$2 AND r.round=$3
            """))
        {
            read.Parameters.AddWithValue(owner); read.Parameters.AddWithValue(turnId); read.Parameters.AddWithValue(round); read.Parameters.AddWithValue(disclosure.Digest);
            read.Parameters.AddWithValue(PhoneTools.MaxRows); read.Parameters.AddWithValue(PhoneTools.MaxBytes);
            await using var row = await read.ExecuteReaderAsync(cancellationToken);
            if (!await row.ReadAsync(cancellationToken)) { return new(RoundGateStatus.Invalid); }
            sameResults = !row.IsDBNull(0) && row.GetBoolean(0); overBudget = row.GetBoolean(1);
        }
        var gate = await RetryAsync(session, turnId, round, now, cancellationToken);
        if (gate.Status == RoundGateStatus.Run && !sameResults) { return new(RoundGateStatus.Invalid); }
        await session.CommitAsync(cancellationToken); // keeps the acknowledgement of round − 1 either way
        return gate with { Budget = budget, DisclosureExceeded = overBudget };
    }

    public async Task<SendGate> ReserveSendAsync(Guid turnId, int round, int attempt, bool guest, BuddyAgentOptions limits, long projectedInput, CancellationToken cancellationToken)
    {
        await using var session = new DatabaseSession();
        if (!await OpenAsync(session, cancellationToken)) { return SendGate.Unauthorized; }
        var now = clock.GetUtcNow();
        if (await TurnAsync(session, turnId, cancellationToken) is not { } budget) { return SendGate.Unauthorized; }
        // Attempt fencing (TD-125): only the round's current, still running attempt may send.
        await using (var fence = session.Command("SELECT attempts=$4 AND state='started' FROM buddy.turn_rounds WHERE user_id=$1 AND turn_id=$2 AND round=$3 FOR UPDATE"))
        {
            fence.Parameters.AddWithValue(user.UserId!.Value); fence.Parameters.AddWithValue(turnId); fence.Parameters.AddWithValue(round); fence.Parameters.AddWithValue(attempt);
            if (await fence.ExecuteScalarAsync(cancellationToken) is not true) { return SendGate.Superseded; }
        }
        // The input budget is checked with this send's projected input, before spending it.
        if (now >= budget.StartedAt.AddSeconds(limits.DeadlineSeconds) || budget.Sends >= limits.MaxSends
            || budget.InputTokens + budget.ReservedInput + projectedInput > limits.MaxInputTokens || budget.OutputTokens >= limits.MaxOutputTokens) { return SendGate.Limit; }
        var reservation = await usage.ReserveAsync(session, OpenAIClientFactory.Model, guest ? limits.GuestDailySends : limits.RegisteredDailySends,
            DateOnly.FromDateTime(now.UtcDateTime), newMessage: false, cancellationToken);
        if (!reservation.Reserved) { return SendGate.Quota; }
        await using var count = session.Command("UPDATE buddy.turns SET sends=sends+1,reserved_input=reserved_input+$3 WHERE user_id=$1 AND turn_id=$2");
        count.Parameters.AddWithValue(user.UserId!.Value); count.Parameters.AddWithValue(turnId); count.Parameters.AddWithValue(projectedInput);
        await count.ExecuteNonQueryAsync(cancellationToken);
        await session.CommitAsync(cancellationToken);
        return SendGate.Reserved;
    }

    public async Task RecordSendAsync(Guid turnId, long reservedInput, TokenUsage? tokens, decimal? estimatedUsd, CancellationToken cancellationToken)
    {
        await using var session = new DatabaseSession();
        if (!await OpenAsync(session, cancellationToken)) { return; }
        // The reservation is released into recorded input: the reported count, or the whole reservation when none was reported.
        await using (var command = session.Command("""
            UPDATE buddy.turns SET reserved_input=GREATEST(reserved_input-$3,0),input_tokens=input_tokens+$4,output_tokens=output_tokens+$5
            WHERE user_id=$1 AND turn_id=$2
            """))
        {
            command.Parameters.AddWithValue(user.UserId!.Value); command.Parameters.AddWithValue(turnId); command.Parameters.AddWithValue(reservedInput);
            command.Parameters.AddWithValue(tokens?.Input ?? reservedInput); command.Parameters.AddWithValue(tokens?.Output ?? 0L);
            await command.ExecuteNonQueryAsync(cancellationToken);
        }
        if (tokens is not null && estimatedUsd is { } cost)
        {
            await usage.RecordAsync(session, new(OpenAIClientFactory.Model, tokens.Input, tokens.CachedInput, tokens.Output, cost,
                DateOnly.FromDateTime(clock.GetUtcNow().UtcDateTime)), cancellationToken);
        }
        await session.CommitAsync(cancellationToken);
    }

    public async Task<TurnBudget?> ReadBudgetAsync(Guid turnId, CancellationToken cancellationToken)
    {
        await using var session = new DatabaseSession();
        if (!await OpenAsync(session, cancellationToken)) { return null; }
        return await TurnAsync(session, turnId, cancellationToken);
    }

    public async Task CompleteRoundAsync(Guid turnId, int round, int attempt, bool cancelled, CancellationToken cancellationToken)
    {
        await using var session = new DatabaseSession();
        if (!await OpenAsync(session, cancellationToken)) { return; }
        // A superseded attempt (attempts moved on) changes nothing.
        await using var command = session.Command("UPDATE buddy.turn_rounds SET state=$4,completed_at=$5 WHERE user_id=$1 AND turn_id=$2 AND round=$3 AND attempts=$6");
        command.Parameters.AddWithValue(user.UserId!.Value); command.Parameters.AddWithValue(turnId); command.Parameters.AddWithValue(round);
        command.Parameters.AddWithValue(cancelled ? "cancelled" : "completed");
        command.Parameters.AddWithValue(cancelled ? DBNull.Value : clock.GetUtcNow()); command.Parameters.AddWithValue(attempt);
        await command.ExecuteNonQueryAsync(cancellationToken);
        await session.CommitAsync(cancellationToken);
    }

    /// <summary>
    /// The retry rule (TD-125): an acknowledged round (or one followed by a later round, or completed more than 10 minutes ago)
    /// already ran; a started, cancelled or unacknowledged round re-runs once as attempt 2; a third attempt is expired.
    /// </summary>
    private async Task<RoundGate> RetryAsync(DatabaseSession session, Guid turnId, int round, DateTimeOffset now, CancellationToken ct)
    {
        await using var read = session.Command("""
            SELECT attempts,acknowledged,completed_at,EXISTS(SELECT 1 FROM buddy.turn_rounds n WHERE n.user_id=r.user_id AND n.turn_id=r.turn_id AND n.round>r.round)
            FROM buddy.turn_rounds r WHERE r.user_id=$1 AND r.turn_id=$2 AND r.round=$3 FOR UPDATE
            """);
        read.Parameters.AddWithValue(user.UserId!.Value); read.Parameters.AddWithValue(turnId); read.Parameters.AddWithValue(round);
        int attempts; bool acknowledged;
        await using (var row = await read.ExecuteReaderAsync(ct))
        {
            if (!await row.ReadAsync(ct)) { return new(RoundGateStatus.Invalid); }
            attempts = row.GetInt32(0);
            acknowledged = row.GetBoolean(1) || row.GetBoolean(3)
                || !row.IsDBNull(2) && new DateTimeOffset(row.GetDateTime(2), TimeSpan.Zero) <= now - Acknowledged;
        }
        if (acknowledged) { return new(RoundGateStatus.AlreadyRan); }
        if (attempts >= 2) { return new(RoundGateStatus.Expired); }
        await using var advance = session.Command("UPDATE buddy.turn_rounds SET attempts=2,state='started',completed_at=NULL WHERE user_id=$1 AND turn_id=$2 AND round=$3");
        advance.Parameters.AddWithValue(user.UserId!.Value); advance.Parameters.AddWithValue(turnId); advance.Parameters.AddWithValue(round);
        await advance.ExecuteNonQueryAsync(ct);
        return new(RoundGateStatus.Run, 2);
    }

    private async Task<TurnBudget?> TurnAsync(DatabaseSession session, Guid turnId, CancellationToken ct)
    {
        await using var read = session.Command("SELECT started_at,sends,input_tokens,output_tokens,reserved_input FROM buddy.turns WHERE user_id=$1 AND turn_id=$2 FOR UPDATE");
        read.Parameters.AddWithValue(user.UserId!.Value); read.Parameters.AddWithValue(turnId);
        await using var row = await read.ExecuteReaderAsync(ct);
        return await row.ReadAsync(ct) ? new(new DateTimeOffset(row.GetDateTime(0), TimeSpan.Zero), row.GetInt32(1), row.GetInt64(2), row.GetInt64(3), row.GetInt64(4)) : null;
    }

    private async Task<bool> OpenAsync(DatabaseSession session, CancellationToken ct)
    {
        if (!user.IsAuthenticated || user.UserId is not { } owner || user.SessionId is not { } sid) { return false; }
        await session.BeginAsync(source, owner, ct);
        await RecoveryBarrier.LockAsync(session, exclusive: false, ct);
        var currentGeneration = await recovery.VerifyAsync(session, ct);
        await UserLifecycleLock.AcquireAsync(session, owner, ct);
        if (!await identity.CheckActiveAsync(session, owner, sid, false, ct)) { return false; }
        if (generation is { } expected && expected != currentGeneration) { throw new RecoveryUnavailableException(); }
        generation = currentGeneration;
        return true;
    }
}
