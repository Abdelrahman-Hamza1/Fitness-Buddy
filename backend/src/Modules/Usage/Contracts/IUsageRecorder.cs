using FitnessBuddy.BuildingBlocks.Persistence;

namespace FitnessBuddy.Modules.Usage.Contracts;

/// <summary>Physical sends are reserved durably before network I/O. Known usage is not invoice-grade billing.</summary>
public interface IUsageRecorder
{
    Task<bool> ReserveAsync(DatabaseSession session, string model, int ceiling, DateOnly day, bool newMessage, CancellationToken cancellationToken);
    Task RecordAsync(DatabaseSession session, UsageCharge charge, CancellationToken cancellationToken);
    Task CleanupAsync(DatabaseSession session, CancellationToken cancellationToken);
}
public sealed record UsageCharge(string Model, long InputTokens, long CachedInputTokens, long OutputTokens, decimal EstimatedUsd, DateOnly Day);
