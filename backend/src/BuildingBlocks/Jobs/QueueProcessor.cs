using FitnessBuddy.BuildingBlocks.Messaging;
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

    public QueueProcessor(NpgsqlDataSource source, TimeProvider clock, IEnumerable<IOutboxHandler> outboxHandlers,
        IEnumerable<IJobHandler> jobHandlers, QueuePolicy policy, ILogger<QueueProcessor> logger)
    {
        this.source = source;
        this.clock = clock;
        this.outboxHandlers = outboxHandlers.ToArray();
        this.jobHandlers = jobHandlers.ToArray();
        this.policy = policy;
        this.logger = logger;
        if (policy.MaxAttempts < 1 || policy.InitialBackoffSeconds < 1) { throw new ArgumentOutOfRangeException(nameof(policy)); }
        if (this.outboxHandlers.GroupBy(handler => (handler.EventType, handler.Name)).Any(group => group.Count() > 1) ||
            this.jobHandlers.GroupBy(handler => handler.JobType).Any(group => group.Count() > 1))
        {
            throw new InvalidOperationException("Duplicate queue handler registration.");
        }
    }

    public Task<bool> DispatchOutboxAsync(CancellationToken cancellationToken) => ProcessAsync(true, cancellationToken);
    public Task<bool> RunJobAsync(CancellationToken cancellationToken) => ProcessAsync(false, cancellationToken);

    private async Task<bool> ProcessAsync(bool outbox, CancellationToken cancellationToken)
    {
        var table = outbox ? "outbox" : "jobs";
        var typeColumn = outbox ? "event_type" : "job_type";
        await using var session = new DatabaseSession();
        await session.BeginAsync(source, null, cancellationToken);
        QueueMessage message;
        await using (var claim = session.Command($"SELECT id,{typeColumn},payload::text,user_id,attempts FROM ops.{table} WHERE state='pending' AND available_at <= $1 ORDER BY available_at,id FOR UPDATE SKIP LOCKED LIMIT 1"))
        {
            claim.Parameters.AddWithValue(clock.GetUtcNow());
            await using var reader = await claim.ExecuteReaderAsync(cancellationToken);
            if (!await reader.ReadAsync(cancellationToken)) { return false; }
            message = new QueueMessage(reader.GetGuid(0), reader.GetString(1), reader.GetString(2), reader.IsDBNull(3) ? null : reader.GetGuid(3), reader.GetInt32(4) + 1);
        }
        await session.SetUserAsync(message.UserId, cancellationToken);
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
