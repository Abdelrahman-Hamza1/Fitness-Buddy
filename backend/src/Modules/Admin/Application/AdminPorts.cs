using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.Modules.Admin.Domain;

namespace FitnessBuddy.Modules.Admin.Application;

internal interface IAllowList
{
    AllowListSnapshot Current();
}

/// <summary>Random secrets and their hashes (SHA-256). Only hashes are stored.</summary>
internal interface ISecretTokens
{
    byte[] NewSecret();

    byte[] Hash(ReadOnlySpan<byte> value);

    byte[] Hash(string value);
}

/// <summary>Opens a system database session (no <c>app.user_id</c>) on the console login.</summary>
internal interface IAdminDatabase
{
    Task<DatabaseSession> BeginAsync(CancellationToken cancellationToken);
}

internal sealed record StoredSession(Guid Id, string Handle, string GoogleSubject, DateTimeOffset AuthenticatedAt, DateTimeOffset ExpiresAt, bool Revoked);

internal sealed record NewSession(Guid Id, byte[] TokenHash, string Handle, string GoogleSubject, DateTimeOffset CreatedAt, DateTimeOffset ExpiresAt);

internal enum ChallengePurpose
{
    SignIn,
    ReAuth,
}

internal interface IAdminAuthStore
{
    Task CreateChallengeAsync(DatabaseSession session, Guid id, ChallengePurpose purpose, Guid? adminSession, byte[] nonceHash, DateTimeOffset expiresAt, CancellationToken cancellationToken);

    /// <summary>Marks the challenge used if it is unused, unexpired, of this purpose and bound to <paramref name="adminSession"/>; false otherwise.</summary>
    Task<bool> ConsumeChallengeAsync(DatabaseSession session, Guid id, ChallengePurpose purpose, Guid? adminSession, byte[] nonceHash, DateTimeOffset now, CancellationToken cancellationToken);

    Task CreateSessionAsync(DatabaseSession session, NewSession value, CancellationToken cancellationToken);

    Task<StoredSession?> FindSessionAsync(DatabaseSession session, byte[] tokenHash, CancellationToken cancellationToken);

    Task RevokeSessionAsync(DatabaseSession session, Guid id, DateTimeOffset now, CancellationToken cancellationToken);

    Task MarkAuthenticatedAsync(DatabaseSession session, Guid id, DateTimeOffset now, CancellationToken cancellationToken);

    /// <summary>Removes expired/used challenges and expired or revoked sessions, bounded per call.</summary>
    Task CleanupAsync(DatabaseSession session, DateTimeOffset now, CancellationToken cancellationToken);
}

/// <summary>One audit row (AD-005). Never put user content, emails (only masked), tokens or config values that aren't the change itself here.</summary>
internal sealed record AuditEntry(string Actor, string Area, string Action, string Outcome, string? Target = null,
    string? BeforeJson = null, string? AfterJson = null, string? Reason = null);

internal interface IAuditLog
{
    Task AppendAsync(DatabaseSession session, AuditEntry entry, DateTimeOffset occurredAt, CancellationToken cancellationToken);
}
