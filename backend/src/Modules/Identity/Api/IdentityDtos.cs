using System.ComponentModel.DataAnnotations;

namespace FitnessBuddy.Modules.Identity.Api;

public sealed record GoogleSignInRequest([property: MaxLength(16384), MinLength(1)] string IdToken);

public sealed record EmailStartRequest([property: MaxLength(254), EmailAddress] string Email, [property: RegularExpression("^(signIn|link)$")] string Purpose);

public sealed record EmailChallenge(Guid ChallengeId, DateTimeOffset ExpiresAt);

public sealed record EmailVerifyRequest(Guid ChallengeId, [property: RegularExpression("^[0-9]{6}$")] string Code);

public sealed record RefreshRequest([property: MaxLength(256), MinLength(1)] string RefreshToken);

public sealed record LinkIdentityRequest([property: MaxLength(16384)] string? IdToken, Guid? ChallengeId, [property: RegularExpression("^[0-9]{6}$")] string? Code);

public sealed record AuthTokens(Guid UserId, bool IsAnonymous, string AccessToken, string RefreshToken, DateTimeOffset ExpiresAt, DateTimeOffset RefreshExpiresAt);

public sealed record JsonWebKey(string Kty, string Crv, string Kid, string X, string Y, string Alg, string Use);

public sealed record JsonWebKeySet(IReadOnlyList<JsonWebKey> Keys);

