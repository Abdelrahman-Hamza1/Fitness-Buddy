using System.Text.Json;
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
using NpgsqlTypes;

namespace FitnessBuddy.Modules.Buddy.Infrastructure;

internal sealed class PostgresInterpretLedger(NpgsqlDataSource source, ICurrentUser user, IIdentityAccess identity,
    RecoveryBarrier recovery, TimeProvider clock, IIdGenerator ids, IUsageRecorder usage, IOptions<BuddyOptions> options) : IInterpretLedger
{
    private Guid? generation;
    public async Task<InterpretResult?> ClaimAsync(InterpretInput input, CancellationToken cancellationToken)
    {
        await using var session = new DatabaseSession();
        if (!await OpenAsync(session, cancellationToken)) { return new(InterpretStatus.Unauthorized); }
        var fingerprint = IdempotencyStore.Hash(JsonSerializer.Serialize(input, InterpretProtocol.Json));
        await using (var read = session.Command("SELECT fingerprint,response::text FROM buddy.attempts WHERE user_id=$1 AND message_id=$2 AND expires_at>$3"))
        {
            read.Parameters.AddWithValue(user.UserId!.Value); read.Parameters.AddWithValue(input.RequestId); read.Parameters.AddWithValue(clock.GetUtcNow());
            await using var row = await read.ExecuteReaderAsync(cancellationToken);
            if (await row.ReadAsync(cancellationToken))
            {
                if (!string.Equals(fingerprint, row.GetString(0), StringComparison.Ordinal)) { return new(InterpretStatus.Conflict); }
                return row.IsDBNull(1) ? new(InterpretStatus.Pending) : new(InterpretStatus.Success, JsonSerializer.Deserialize<BuddyInterpretation>(row.GetString(1), InterpretProtocol.Stored));
            }
        }
        var dispatchTime = clock.GetUtcNow();
        if (!await ReserveAsync(session, dispatchTime, true, cancellationToken)) { return new(InterpretStatus.Limited); }
        await using var insert = session.Command("""
            INSERT INTO buddy.attempts(user_id,message_id,fingerprint,created_at,expires_at,dispatched_at)
            VALUES($1,$2,$3,$4,$5,$4) ON CONFLICT(user_id,message_id) DO UPDATE SET
            fingerprint=excluded.fingerprint,created_at=excluded.created_at,dispatched_at=excluded.dispatched_at,expires_at=excluded.expires_at,attempts=1,recorded=0,response=NULL
            """);
        insert.Parameters.AddWithValue(user.UserId!.Value); insert.Parameters.AddWithValue(input.RequestId); insert.Parameters.AddWithValue(fingerprint);
        insert.Parameters.AddWithValue(dispatchTime); insert.Parameters.AddWithValue(dispatchTime.AddHours(24));
        await insert.ExecuteNonQueryAsync(cancellationToken);
        await new QueueWriter(session, clock, ids).ScheduleUserAsync("buddy.cleanup:" + user.UserId.Value, "*/5 * * * *", "buddy.cleanup", clock.GetUtcNow().AddMinutes(5), cancellationToken);
        await session.CommitAsync(cancellationToken);
        // Null is the sole permission to make the FIRST physical send; claim and quota are already durable.
        return null;
    }
    public async Task<InterpretStatus> ReserveRepairAsync(Guid messageId, CancellationToken cancellationToken)
    {
        await using var session = new DatabaseSession(); if (!await OpenAsync(session, cancellationToken)) { return InterpretStatus.Unauthorized; }
        var dispatchTime = clock.GetUtcNow();
        await using var advance = session.Command("UPDATE buddy.attempts SET attempts=2,dispatched_at=$3 WHERE user_id=$1 AND message_id=$2 AND attempts=1 AND recorded=1 AND response IS NULL AND expires_at>$3");
        advance.Parameters.AddWithValue(user.UserId!.Value); advance.Parameters.AddWithValue(messageId); advance.Parameters.AddWithValue(dispatchTime);
        if (await advance.ExecuteNonQueryAsync(cancellationToken) != 1) { return InterpretStatus.Pending; }
        if (!await ReserveAsync(session, dispatchTime, false, cancellationToken)) { return InterpretStatus.Limited; }
        await session.CommitAsync(cancellationToken); return InterpretStatus.Success;
    }
    public async Task<bool> RecordAsync(Guid messageId, int attempt, ProductionOutcome outcome, CancellationToken cancellationToken)
    {
        await using var session = new DatabaseSession(); if (!await OpenAsync(session, cancellationToken)) { return false; }
        DateTimeOffset dispatched;
        await using (var record = session.Command("UPDATE buddy.attempts SET recorded=$3 WHERE user_id=$1 AND message_id=$2 AND attempts=$3 AND recorded<$3 AND expires_at>$4 RETURNING dispatched_at"))
        {
            record.Parameters.AddWithValue(user.UserId!.Value); record.Parameters.AddWithValue(messageId); record.Parameters.AddWithValue(attempt); record.Parameters.AddWithValue(clock.GetUtcNow());
            if (await record.ExecuteScalarAsync(cancellationToken) is not DateTime timestamp) { return false; }
            dispatched = new DateTimeOffset(timestamp, TimeSpan.Zero);
        }
        if (outcome.Usage is { } u && outcome.EstimatedUsd is { } cost)
        { await usage.RecordAsync(session, new(OpenAIClientFactory.Model, u.Input, u.CachedInput, u.Output, cost, DateOnly.FromDateTime(dispatched.UtcDateTime)), cancellationToken); }
        await session.CommitAsync(cancellationToken); return true;
    }
    public async Task<bool> CompleteAsync(Guid messageId, BuddyInterpretation result, CancellationToken cancellationToken)
    {
        await using var session = new DatabaseSession(); if (!await OpenAsync(session, cancellationToken)) { return false; }
        await using var command = session.Command("UPDATE buddy.attempts SET response=$3 WHERE user_id=$1 AND message_id=$2 AND response IS NULL AND recorded=attempts AND expires_at>$4");
        command.Parameters.AddWithValue(user.UserId!.Value); command.Parameters.AddWithValue(messageId);
        command.Parameters.AddWithValue(NpgsqlDbType.Jsonb, JsonSerializer.Serialize(result, InterpretProtocol.Json)); command.Parameters.AddWithValue(clock.GetUtcNow());
        var written = await command.ExecuteNonQueryAsync(cancellationToken); await session.CommitAsync(cancellationToken); return written == 1;
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
    private async Task<bool> ReserveAsync(DatabaseSession session, DateTimeOffset dispatchTime, bool newMessage, CancellationToken ct)
    {
        var principal = await identity.ReadSessionAsync(user.UserId!.Value, user.SessionId!.Value, ct);
        return principal is not null && await usage.ReserveAsync(session, OpenAIClientFactory.Model,
            principal.IsAnonymous ? options.Value.GuestDailyCalls : options.Value.RegisteredDailyCalls, DateOnly.FromDateTime(dispatchTime.UtcDateTime), newMessage, ct);
    }
}
