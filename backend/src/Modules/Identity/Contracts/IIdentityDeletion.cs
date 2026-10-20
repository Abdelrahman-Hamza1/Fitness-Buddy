using FitnessBuddy.BuildingBlocks.Persistence;

namespace FitnessBuddy.Modules.Identity.Contracts;

/// <summary>Authenticated coordinator only, after recovery and user locks; no network or commit.</summary>
public interface IIdentityDeletion
{
    Task<bool> BeginAsync(DatabaseSession session, Guid sessionId, CancellationToken cancellationToken);
}
