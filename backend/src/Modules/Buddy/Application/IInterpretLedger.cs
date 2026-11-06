using FitnessBuddy.Modules.Buddy.Domain;

namespace FitnessBuddy.Modules.Buddy.Application;

internal enum InterpretStatus { Success, Pending, Conflict, Limited, Unauthorized, Unavailable }
/// <summary><paramref name="Limit"/> is the effective daily limit when <see cref="InterpretStatus.Limited"/> (B24: the operator's override).</summary>
internal sealed record InterpretResult(InterpretStatus Status, BuddyInterpretation? Value = null, int? Limit = null);
internal interface IInterpretLedger
{
    Task<InterpretResult?> ClaimAsync(InterpretInput input, CancellationToken cancellationToken);
    Task<InterpretStatus> ReserveRepairAsync(Guid messageId, CancellationToken cancellationToken);
    Task<bool> RecordAsync(Guid messageId, int attempt, ProductionOutcome outcome, CancellationToken cancellationToken);
    Task<bool> CompleteAsync(Guid messageId, BuddyInterpretation result, CancellationToken cancellationToken);
}
