using FitnessBuddy.BuildingBlocks.Persistence;

namespace FitnessBuddy.Modules.Identity.Contracts;

/// <summary>Authenticated coordinator only, after recovery and user locks; no network or commit.</summary>
public interface IIdentityDeletion
{
    Task<bool> BeginAsync(DatabaseSession session, Guid sessionId, CancellationToken cancellationToken);

    /// <summary>
    /// B24: begins the deletion of the session's user for an operator. The database capability requires the operator's committed,
    /// due deletion intent under the lifecycle lock; without it nothing changes and this returns false.
    /// </summary>
    Task<bool> BeginOperatorAsync(DatabaseSession session, CancellationToken cancellationToken);
}
