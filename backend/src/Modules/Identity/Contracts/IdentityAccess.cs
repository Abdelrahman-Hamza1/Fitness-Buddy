using FitnessBuddy.BuildingBlocks.Persistence;

namespace FitnessBuddy.Modules.Identity.Contracts;

/// <summary>Only a cryptographically validated token may supply the IDs to this live-session check.</summary>
public interface IIdentityAccess
{
    /// <summary>Revalidates a trusted principal while holding its user/session rows in the supplied transaction.</summary>
    Task<bool> CheckActiveAsync(DatabaseSession session, Guid userId, Guid sessionId, bool registeredOnly, CancellationToken cancellationToken);

    Task<IdentitySession?> ReadSessionAsync(Guid userId, Guid sessionId, CancellationToken cancellationToken);
}

public sealed record IdentitySession(Guid UserId, bool IsAnonymous, Guid SessionId, DateTimeOffset RefreshExpiresAt);
