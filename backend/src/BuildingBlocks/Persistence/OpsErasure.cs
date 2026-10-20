using Npgsql;
using FitnessBuddy.BuildingBlocks.Messaging;

namespace FitnessBuddy.BuildingBlocks.Persistence;

/// <summary>Ops owns infrastructure bytes and markers. Caller holds the lifecycle lock and transaction.</summary>
public static class OpsErasure
{
    public static UserDataOwnership Ownership { get; } = new(["outbox", "jobs", "processed_messages", "schedules", "idempotency"], ["recovery"], null);

    public static async Task DeleteUserAsync(DatabaseSession session, CancellationToken cancellationToken)
    {
        var user = session.UserId ?? throw new InvalidOperationException("Missing erasure owner.");
        // Schedules first; claimers also serialize before locking their rows (B06 D4).
        await using var batch = new NpgsqlBatch(session.Connection, session.Transaction);
        foreach (var statement in new[]
        {
            "DELETE FROM ops.schedules WHERE user_id=$1",
            "DELETE FROM ops.processed_messages WHERE message_id IN (SELECT id FROM ops.outbox WHERE user_id=$1 UNION SELECT id FROM ops.jobs WHERE user_id=$1)",
            "DELETE FROM ops.outbox WHERE user_id=$1",
            "DELETE FROM ops.jobs WHERE user_id=$1",
            "DELETE FROM ops.idempotency WHERE user_id=$1",
        })
        {
            var command = new NpgsqlBatchCommand(statement);
            command.Parameters.AddWithValue(user);
            batch.BatchCommands.Add(command);
        }
        await batch.ExecuteNonQueryAsync(cancellationToken);
    }
}
