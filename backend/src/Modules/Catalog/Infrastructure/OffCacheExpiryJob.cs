using FitnessBuddy.BuildingBlocks.Jobs;
using FitnessBuddy.BuildingBlocks.Messaging;
using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.Modules.Catalog.Application;

namespace FitnessBuddy.Modules.Catalog.Infrastructure;

/// <summary>Daily: removes OFF cache rows past their stale-if-error window (B10a D5). Database only.</summary>
internal sealed class OffCacheExpiryJob(TimeProvider clock) : IJobHandler
{
    public const string Type = "catalog.off-cache-expiry";
    public static readonly JobSchedule Schedule = new(Type, "17 3 * * *", Type);
    public string JobType => Type;

    public async Task HandleAsync(QueueMessage message, DatabaseSession session, CancellationToken cancellationToken)
    {
        await using var command = session.Command("DELETE FROM catalog.off_cache WHERE expires_at <= $1");
        command.Parameters.AddWithValue(clock.GetUtcNow() - BarcodeLookup.StaleGrace);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }
}
