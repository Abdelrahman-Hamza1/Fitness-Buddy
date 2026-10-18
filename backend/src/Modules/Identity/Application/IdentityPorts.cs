using FitnessBuddy.Modules.Identity.Contracts;

namespace FitnessBuddy.Modules.Identity.Application;

internal interface IIdentityStore : IIdentityAccess
{
    Task<IdentitySession?> CreateGuestAsync(Guid user, SessionMaterial material, CancellationToken ct);
    Task<IdentitySession?> GoogleSignInAsync(GoogleIdentity identity, Guid newUser, SessionMaterial material, CancellationToken ct);
    Task<IdentitySession?> RotateAsync(byte[] oldHash, byte[] newHash, CancellationToken ct);
    Task RevokeAsync(Guid user, Guid session, CancellationToken ct);
    Task<bool> StartEmailAsync(Guid challenge, byte[] addressHash, byte[] codeHash, string purpose, IdentitySession? principal, byte[] ipHash, CancellationToken ct);
    Task<IdentitySession?> ConsumeEmailAsync(Guid challenge, byte[] codeHash, string purpose, IdentitySession? principal, Guid newUser, SessionMaterial material, CancellationToken ct);
    Task<IdentitySession?> LinkGoogleAsync(IdentitySession principal, GoogleIdentity identity, SessionMaterial material, CancellationToken ct);
}

// Constructed by validated adapter output only, never by HTTP request binding.
internal sealed record GoogleIdentity(string Subject, string Email);
internal interface IGoogleIdentityVerifier
{
    Task<GoogleIdentity?> VerifyAsync(string idToken, CancellationToken ct);
}
internal interface IEmailSender
{
    Task SendAsync(Guid challenge, string address, string code, DateTimeOffset expiresAt, CancellationToken ct);
}
internal sealed record SessionMaterial(Guid SessionId, Guid DeviceId, byte[] RefreshHash);
internal sealed class IdentityConflictException : Exception;

internal sealed record IssuedTokens(Guid UserId, bool IsAnonymous, string AccessToken, string RefreshToken, DateTimeOffset ExpiresAt, DateTimeOffset RefreshExpiresAt);
internal interface IIdentityTokens
{
    Task<string> SignAsync(IdentitySession session, CancellationToken ct);
    Task<System.Security.Claims.ClaimsPrincipal?> ValidateAsync(string token, CancellationToken ct);
    Task<IReadOnlyList<PublicIdentityKey>> PublicKeysAsync(CancellationToken ct);
    byte[] Hash(string value);
    byte[] ProtectLookup(string domain, string value);
}
internal sealed record PublicIdentityKey(string Kty, string Crv, string Kid, string X, string Y, string Alg, string Use);
