using FitnessBuddy.BuildingBlocks.Messaging;
using FitnessBuddy.BuildingBlocks.Persistence;

namespace FitnessBuddy.BuildingBlocks.Jobs;

/// <summary>Expires replay records and completed infrastructure messages; never removes dead letters. Also the console's
/// operational counters (B23 P3): server errors after 30 days, heartbeats after 1 day, cancelled jobs after 7 days.</summary>
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
            ("DELETE FROM ops.jobs WHERE state='cancelled' AND completed_at < $1", now - TimeSpan.FromDays(7)),
            ("DELETE FROM ops.http_errors_hourly WHERE hour < $1", now - TimeSpan.FromDays(30)),
            ("DELETE FROM ops.worker_heartbeats WHERE last_beat_at < $1", now - TimeSpan.FromDays(1)),
        };
        foreach (var (sql, cutoff) in commands)
        {
            await using var cleanup = session.Command(sql);
            cleanup.Parameters.AddWithValue(cutoff);
            await cleanup.ExecuteNonQueryAsync(cancellationToken);
        }
    }
}
