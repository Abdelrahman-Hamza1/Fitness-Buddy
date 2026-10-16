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

    private async Task<Guid> InsertAsync<T>(string table, string typeColumn, string type, T payload, DateTimeOffset availableAt, CancellationToken cancellationToken)
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
        command.Parameters.AddWithValue(NpgsqlDbType.Uuid, (object?)session.UserId ?? DBNull.Value);
        await command.ExecuteNonQueryAsync(cancellationToken);
        return id;
    }
}
