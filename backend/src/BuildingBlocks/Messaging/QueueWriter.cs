using System.Text.Json;
using FitnessBuddy.BuildingBlocks.Ids;
using FitnessBuddy.BuildingBlocks.Persistence;
using NpgsqlTypes;

namespace FitnessBuddy.BuildingBlocks.Messaging;

/// <summary>Writes events/jobs inside the caller's business transaction. The caller owns the commit.</summary>
public sealed class QueueWriter(DatabaseSession session, TimeProvider clock, IIdGenerator ids)
{
    public Task<Guid> PublishAsync<T>(string eventType, T payload, CancellationToken cancellationToken) =>
        InsertAsync("outbox", "event_type", eventType, payload, clock.GetUtcNow(), cancellationToken);

    public Task<Guid> EnqueueAsync<T>(string jobType, T payload, DateTimeOffset? availableAt, CancellationToken cancellationToken) =>
        InsertAsync("jobs", "job_type", jobType, payload, availableAt ?? clock.GetUtcNow(), cancellationToken);

    /// <summary>Enqueues module-discovered user work; never use a user ID supplied by an HTTP caller.</summary>
    public Task<Guid> EnqueueForUserAsync<T>(string jobType, Guid userId, T payload, CancellationToken cancellationToken) =>
        InsertAsync("jobs", "job_type", jobType, payload, clock.GetUtcNow(), cancellationToken, userId);

    /// <summary>Registers recurring work for this transaction's owner without elevated enumeration.</summary>
    public async Task ScheduleUserAsync(string name, string cron, string jobType, DateTimeOffset firstDue, CancellationToken cancellationToken)
    {
        var user = session.UserId ?? throw new InvalidOperationException("Missing schedule owner.");
        await using var command = session.Command("""
            INSERT INTO ops.schedules(name,cron,job_type,payload,next_due,user_id)
            VALUES($1,$4,$5,'{}',$2,$3) ON CONFLICT(name) DO NOTHING
            """);
        command.Parameters.AddWithValue(name);
        command.Parameters.AddWithValue(firstDue); command.Parameters.AddWithValue(user);
        command.Parameters.AddWithValue(cron); command.Parameters.AddWithValue(jobType);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    private async Task<Guid> InsertAsync<T>(string table, string typeColumn, string type, T payload, DateTimeOffset availableAt, CancellationToken cancellationToken, Guid? owner = null)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(type);
        if (type.Length > 200) { throw new ArgumentOutOfRangeException(nameof(type)); }
        var id = ids.NewId();
        // Table/column are closed internal constants; payload and identity always use parameters.
        await using var command = session.Command($"INSERT INTO ops.{table}(id,{typeColumn},payload,created_at,available_at,user_id) VALUES($1,$2,$3,$4,$5,$6)");
        command.Parameters.AddWithValue(id);
        command.Parameters.AddWithValue(type);
        command.Parameters.AddWithValue(NpgsqlDbType.Jsonb, JsonSerializer.Serialize(payload));
        command.Parameters.AddWithValue(clock.GetUtcNow());
        command.Parameters.AddWithValue(availableAt.ToUniversalTime());
        command.Parameters.AddWithValue(NpgsqlDbType.Uuid, (object?)(owner ?? session.UserId) ?? DBNull.Value);
        await command.ExecuteNonQueryAsync(cancellationToken);
        return id;
    }
}
