using FitnessBuddy.BuildingBlocks.Persistence;

namespace FitnessBuddy.Modules.Usage.Contracts;

/// <summary>Physical sends are reserved durably before network I/O. Known usage is not invoice-grade billing.</summary>
public interface IUsageRecorder
{
    /// <summary>
    /// Reserves one call against the account's daily ceiling: its operator override (B24) when set, else <paramref name="defaultCeiling"/>.
    /// A ceiling of 0 or less reserves nothing, so no physical send happens.
    /// </summary>
    Task<UsageReservation> ReserveAsync(DatabaseSession session, string model, int defaultCeiling, DateOnly day, bool newMessage, CancellationToken cancellationToken);
    /// <summary>
    /// B25 (TD-128): reserves one logical message (an agent turn) against <paramref name="messageCeiling"/>, without a physical call;
    /// the turn's sends are reserved one by one with <see cref="ReserveAsync"/> (<c>newMessage: false</c>). An operator override of 0 refuses.
    /// </summary>
    Task<UsageReservation> ReserveMessageAsync(DatabaseSession session, string model, int messageCeiling, DateOnly day, CancellationToken cancellationToken);
    Task RecordAsync(DatabaseSession session, UsageCharge charge, CancellationToken cancellationToken);
    Task CleanupAsync(DatabaseSession session, CancellationToken cancellationToken);
}
/// <summary><paramref name="Ceiling"/> is the effective daily limit, for the rate-limit headers.</summary>
public sealed record UsageReservation(bool Reserved, int Ceiling);
public sealed record UsageCharge(string Model, long InputTokens, long CachedInputTokens, long OutputTokens, decimal EstimatedUsd, DateOnly Day);
