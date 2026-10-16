using FitnessBuddy.BuildingBlocks.Messaging;
using FitnessBuddy.BuildingBlocks.Persistence;

namespace FitnessBuddy.BuildingBlocks.Jobs;

/// <summary>A database-only job. Use the supplied transaction for all effects; no commits or network I/O.</summary>
public interface IJobHandler
{
    string JobType { get; }
    Task HandleAsync(QueueMessage message, DatabaseSession session, CancellationToken cancellationToken);
}
