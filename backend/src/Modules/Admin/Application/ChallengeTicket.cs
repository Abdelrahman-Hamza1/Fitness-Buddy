using System.Buffers.Text;

namespace FitnessBuddy.Modules.Admin.Application;

/// <summary>
/// A single-use sign-in or re-auth challenge (B23 P2, R#5). The browser keeps <c>id.secret</c> in a short-lived cookie;
/// Google gets <see cref="Nonce"/> = base64url(SHA-256(secret)) and puts it in the ID token; the database stores only
/// SHA-256(nonce). A token is accepted once, from the browser that holds the secret, for this purpose and session.
/// </summary>
internal sealed record ChallengeTicket(Guid Id, byte[] Secret, string Nonce)
{
    public static readonly TimeSpan Lifetime = TimeSpan.FromMinutes(5);

    public string CookieValue => Id.ToString("N") + "." + Base64Url.EncodeToString(Secret);

    public static ChallengeTicket? Parse(string? cookie, ISecretTokens tokens)
    {
        ArgumentNullException.ThrowIfNull(tokens);
        if (cookie is null || cookie.Length > 128) { return null; }
        var dot = cookie.IndexOf('.', StringComparison.Ordinal);
        if (dot != 32 || !Guid.TryParseExact(cookie.AsSpan(0, dot), "N", out var id)) { return null; }
        byte[] secret;
        try { secret = Base64Url.DecodeFromChars(cookie.AsSpan(dot + 1)); }
        catch (FormatException) { return null; }
        return secret.Length == 32 ? new ChallengeTicket(id, secret, NonceFor(secret, tokens)) : null;
    }

    public static string NonceFor(byte[] secret, ISecretTokens tokens)
    {
        ArgumentNullException.ThrowIfNull(tokens);
        return Base64Url.EncodeToString(tokens.Hash(secret));
    }
}
