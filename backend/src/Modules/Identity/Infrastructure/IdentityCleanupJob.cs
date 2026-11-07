using FitnessBuddy.BuildingBlocks.Jobs;
using FitnessBuddy.BuildingBlocks.Messaging;
using FitnessBuddy.BuildingBlocks.Persistence;

namespace FitnessBuddy.Modules.Identity.Infrastructure;

/// <summary>Hourly, worker only: expired email challenges, idle throttle buckets and expired session families (bounded batch).</summary>
internal sealed class IdentityCleanupJob(TimeProvider clock) : IJobHandler
{
    public const string Type = "identity.cleanup";
    public const int BatchLimit = 5000;
    public static readonly JobSchedule Schedule = new(Type, "23 * * * *", Type);
    public string JobType => Type;

    public async Task HandleAsync(QueueMessage message, DatabaseSession session, CancellationToken cancellationToken)
    {
        await using var command = session.Command("SELECT identity.cleanup($1,$2)");
        command.Parameters.AddWithValue(clock.GetUtcNow()); command.Parameters.AddWithValue(BatchLimit);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }
}
