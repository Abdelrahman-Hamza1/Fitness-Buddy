namespace FitnessBuddy.Modules.Identity.Contracts;

/// <summary>
/// B04's Google ID-token verification for another caller with its own audiences (B23: the admin console's Web client).
/// Checks the Google JWKS signature (RS256), issuer, audience, expiry, <c>iat</c> and <c>email_verified</c>; returns null
/// when any check fails. Never log the token or the returned values.
/// </summary>
public interface IGoogleIdTokenVerifier
{
    Task<VerifiedGoogleToken?> VerifyAsync(string idToken, IReadOnlyCollection<string> audiences, CancellationToken cancellationToken);
}

/// <summary>A verified token's identity. <paramref name="AuthTime"/> and <paramref name="Nonce"/> are present only when Google sent them.</summary>
public sealed record VerifiedGoogleToken(string Subject, string Email, DateTimeOffset IssuedAt, DateTimeOffset? AuthTime, string? Nonce);
