using FitnessBuddy.BuildingBlocks.Messaging;
using FitnessBuddy.BuildingBlocks.Persistence;

namespace FitnessBuddy.BuildingBlocks.Jobs;

/// <summary>Expires replay records and completed infrastructure messages; never removes dead letters.</summary>
public sealed class OpsCleanupJob(TimeProvider clock) : IJobHandler
{
    public const string Type = "ops.cleanup";
    public string JobType => Type;

    public async Task HandleAsync(QueueMessage message, DatabaseSession session, CancellationToken cancellationToken)
    {
        var now = clock.GetUtcNow();
        var commands = new (string Sql, DateTimeOffset Cutoff)[]
        {
            ("DELETE FROM ops.idempotency WHERE expires_at <= $1", now),
            ("DELETE FROM ops.processed_messages WHERE message_id IN(SELECT id FROM ops.outbox WHERE state='done' AND completed_at < $1)", now - TimeSpan.FromDays(7)),
            ("DELETE FROM ops.outbox WHERE state='done' AND completed_at < $1", now - TimeSpan.FromDays(7)),
            ("DELETE FROM ops.jobs WHERE state='done' AND completed_at < $1", now - TimeSpan.FromDays(7)),
        };
        foreach (var (sql, cutoff) in commands)
        {
            await using var cleanup = session.Command(sql);
            cleanup.Parameters.AddWithValue(cutoff);
            await cleanup.ExecuteNonQueryAsync(cancellationToken);
        }
    }
}
