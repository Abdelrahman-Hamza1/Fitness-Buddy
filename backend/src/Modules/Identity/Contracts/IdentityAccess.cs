namespace FitnessBuddy.Modules.Identity.Contracts;

/// <summary>Only a cryptographically validated token may supply the IDs to this live-session check.</summary>
public interface IIdentityAccess
{
    Task<IdentitySession?> ReadSessionAsync(Guid userId, Guid sessionId, CancellationToken cancellationToken);
}

public sealed record IdentitySession(Guid UserId, bool IsAnonymous, Guid SessionId, DateTimeOffset RefreshExpiresAt);
