using FitnessBuddy.BuildingBlocks.Messaging;
using FitnessBuddy.BuildingBlocks.Auth;
using FitnessBuddy.BuildingBlocks.Recovery;
using FitnessBuddy.BuildingBlocks.Persistence;
using Microsoft.Extensions.Logging;
using Npgsql;

namespace FitnessBuddy.BuildingBlocks.Jobs;

/// <summary>Retry policy shared by outbox and jobs. Attempt counts include the first execution.</summary>
public sealed record QueuePolicy(int MaxAttempts = 5, int InitialBackoffSeconds = 5)
{
    public TimeSpan Backoff(int attempt) => TimeSpan.FromSeconds(Math.Min(3600, InitialBackoffSeconds * Math.Pow(2, Math.Min(attempt - 1, 16))));
}

/// <summary>Claims one item with a transaction lock. Handler effects, dedup markers and completion are atomic.
/// Savepoints roll back failed effects without releasing the claim; connection loss rolls everything back.</summary>
public sealed partial class QueueProcessor
{
    private readonly NpgsqlDataSource source;
    private readonly TimeProvider clock;
    private readonly IOutboxHandler[] outboxHandlers;
    private readonly IJobHandler[] jobHandlers;
    private readonly QueuePolicy policy;
    private readonly ILogger<QueueProcessor> logger;
    private readonly IUserLifecycle lifecycle;
    private readonly RecoveryBarrier recovery;

    public QueueProcessor(NpgsqlDataSource source, TimeProvider clock, IEnumerable<IOutboxHandler> outboxHandlers,
        IEnumerable<IJobHandler> jobHandlers, QueuePolicy policy, ILogger<QueueProcessor> logger, IUserLifecycle lifecycle, RecoveryBarrier recovery)
    {
        this.source = source;
        this.clock = clock;
        this.outboxHandlers = outboxHandlers.ToArray();
        this.jobHandlers = jobHandlers.ToArray();
        this.policy = policy;
        this.logger = logger;
        this.lifecycle = lifecycle;
        this.recovery = recovery;
        if (policy.MaxAttempts < 1 || policy.InitialBackoffSeconds < 1) { throw new ArgumentOutOfRangeException(nameof(policy)); }
        if (this.outboxHandlers.GroupBy(handler => (handler.EventType, handler.Name)).Any(group => group.Count() > 1) ||
            this.jobHandlers.GroupBy(handler => handler.JobType).Any(group => group.Count() > 1))
        {
            throw new InvalidOperationException("Duplicate queue handler registration.");
        }
    }

    public Task<bool> DispatchOutboxAsync(CancellationToken cancellationToken) => ProcessAsync(true, cancellationToken);
    public Task<bool> RunJobAsync(CancellationToken cancellationToken) => ProcessAsync(false, cancellationToken);

    /// <summary>The coordinator fails closed until every installed user-data module has its eraser.</summary>
    public bool HasHandlers(string eventType, IReadOnlyCollection<string> names) =>
        names.Distinct(StringComparer.Ordinal).Count() == names.Count &&
        names.All(name => outboxHandlers.Any(handler => handler.EventType == eventType && handler.Name == name));

    /// <summary>Dispatches an existing envelope within the caller's transaction, never commits it.
    /// Completed erasure removes this envelope/markers after all participants succeed.</summary>
    public async Task DispatchWithinTransactionAsync(Guid eventId, DatabaseSession session, CancellationToken cancellationToken)
    {
        QueueMessage message;
        await using (var command = session.Command("SELECT event_type,payload::text,user_id,attempts FROM ops.outbox WHERE id=$1 AND state='pending' FOR UPDATE"))
        {
            command.Parameters.AddWithValue(eventId);
            await using var reader = await command.ExecuteReaderAsync(cancellationToken);
            if (!await reader.ReadAsync(cancellationToken)) { throw new InvalidOperationException("Missing transactional event."); }
            message = new QueueMessage(eventId, reader.GetString(0), reader.GetString(1), reader.IsDBNull(2) ? null : reader.GetGuid(2), reader.GetInt32(3) + 1);
        }
        if (session.UserId is null || message.UserId != session.UserId) { throw new InvalidOperationException("Invalid transactional event owner."); }
        await DispatchAsync(message, session, cancellationToken);
        await using var complete = session.Command("UPDATE ops.outbox SET attempts=$2,state='done',completed_at=$3 WHERE id=$1");
        complete.Parameters.AddWithValue(eventId); complete.Parameters.AddWithValue(message.Attempt); complete.Parameters.AddWithValue(clock.GetUtcNow());
        await complete.ExecuteNonQueryAsync(cancellationToken);
    }

    private sealed record Candidate(Guid Id, string Type, Guid? UserId);

    private async Task<bool> ProcessAsync(bool outbox, CancellationToken cancellationToken)
    {
        var table = outbox ? "outbox" : "jobs";
        var typeColumn = outbox ? "event_type" : "job_type";
        var candidates = new List<Candidate>();
        // Discovery never holds a queue row while waiting for its owner's lifecycle lock.
        await using (var discover = source.CreateCommand($"SELECT id,{typeColumn},user_id FROM ops.{table} WHERE state='pending' AND available_at <= $1 ORDER BY available_at,id LIMIT 32"))
        {
            discover.Parameters.AddWithValue(clock.GetUtcNow());
            await using var reader = await discover.ExecuteReaderAsync(cancellationToken);
            while (await reader.ReadAsync(cancellationToken))
            { candidates.Add(new Candidate(reader.GetGuid(0), reader.GetString(1), reader.IsDBNull(2) ? null : reader.GetGuid(2))); }
        }
        foreach (var candidate in candidates)
        { if (await TryProcessAsync(outbox, candidate, cancellationToken)) { return true; } }
        return false;
    }

    private async Task<bool> TryProcessAsync(bool outbox, Candidate candidate, CancellationToken cancellationToken)
    {
        var table = outbox ? "outbox" : "jobs";
        var typeColumn = outbox ? "event_type" : "job_type";
        await using var session = new DatabaseSession();
        await session.BeginAsync(source, candidate.UserId, cancellationToken);
        await RecoveryBarrier.LockAsync(session, exclusive: false, cancellationToken);
        await recovery.VerifyAsync(session, cancellationToken);
        if (candidate.UserId is Guid owner && !await UserLifecycleLock.TryAcquireAsync(session, owner, cancellationToken)) { return false; }
        QueueMessage message;
        await using (var claim = session.Command($"SELECT id,{typeColumn},payload::text,user_id,attempts FROM ops.{table} WHERE id=$1 AND state='pending' AND available_at <= $2 AND user_id IS NOT DISTINCT FROM $3 AND {typeColumn}=$4 FOR UPDATE SKIP LOCKED"))
        {
            claim.Parameters.AddWithValue(candidate.Id); claim.Parameters.AddWithValue(clock.GetUtcNow());
            claim.Parameters.AddWithValue(NpgsqlTypes.NpgsqlDbType.Uuid, (object?)candidate.UserId ?? DBNull.Value);
            claim.Parameters.AddWithValue(candidate.Type);
            await using var reader = await claim.ExecuteReaderAsync(cancellationToken);
            if (!await reader.ReadAsync(cancellationToken)) { return false; }
            message = new QueueMessage(reader.GetGuid(0), reader.GetString(1), reader.GetString(2), reader.IsDBNull(3) ? null : reader.GetGuid(3), reader.GetInt32(4) + 1);
        }
        if (message.UserId.HasValue && !await lifecycle.IsActiveAsync(session, null, cancellationToken))
        {
            await OpsErasure.DeleteUserAsync(session, cancellationToken);
            await session.CommitAsync(cancellationToken);
            return true;
        }
        await session.Transaction.SaveAsync("handler_effects", cancellationToken);
        try
        {
            if (outbox) { await DispatchAsync(message, session, cancellationToken); }
            else
            {
                var handler = jobHandlers.SingleOrDefault(handler => handler.JobType == message.Type) ?? throw new UnknownQueueTypeException();
                await handler.HandleAsync(message, session, cancellationToken);
            }
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested) { throw; }
        catch (Exception exception)
        {
            await session.Transaction.RollbackAsync("handler_effects", cancellationToken);
            await using var fail = session.Command($"UPDATE ops.{table} SET attempts=$2,state=$3,available_at=$4,last_error=$5 WHERE id=$1");
            fail.Parameters.AddWithValue(message.Id);
            fail.Parameters.AddWithValue(message.Attempt);
            fail.Parameters.AddWithValue(message.Attempt >= policy.MaxAttempts ? "dead" : "pending");
            fail.Parameters.AddWithValue(clock.GetUtcNow() + policy.Backoff(message.Attempt));
            fail.Parameters.AddWithValue(exception.GetType().Name);
            await fail.ExecuteNonQueryAsync(cancellationToken);
            await session.CommitAsync(cancellationToken);
            LogFailure(logger, message.Id, message.Attempt, exception.GetType().Name);
            return true;
        }
        await using var complete = session.Command($"UPDATE ops.{table} SET attempts=$2,state='done',completed_at=$3,last_error=NULL WHERE id=$1");
        complete.Parameters.AddWithValue(message.Id);
        complete.Parameters.AddWithValue(message.Attempt);
        complete.Parameters.AddWithValue(clock.GetUtcNow());
        await complete.ExecuteNonQueryAsync(cancellationToken);
        await session.CommitAsync(cancellationToken);
        return true;
    }

    private async Task DispatchAsync(QueueMessage message, DatabaseSession session, CancellationToken cancellationToken)
    {
        var handlers = outboxHandlers.Where(handler => handler.EventType == message.Type).ToArray();
        if (handlers.Length == 0) { throw new UnknownQueueTypeException(); }
        foreach (var handler in handlers)
        {
            await using var processed = session.Command("INSERT INTO ops.processed_messages(message_id,handler,processed_at) VALUES($1,$2,$3) ON CONFLICT DO NOTHING");
            processed.Parameters.AddWithValue(message.Id);
            processed.Parameters.AddWithValue(handler.Name);
            processed.Parameters.AddWithValue(clock.GetUtcNow());
            if (await processed.ExecuteNonQueryAsync(cancellationToken) == 0) { continue; }
            await handler.HandleAsync(message, session, cancellationToken);
        }
    }

    [LoggerMessage(Level = LogLevel.Warning, Message = "Queue item {ItemId} attempt {Attempt} failed with {ErrorCode}")]
    private static partial void LogFailure(ILogger logger, Guid itemId, int attempt, string errorCode);

    private sealed class UnknownQueueTypeException : Exception;
}
