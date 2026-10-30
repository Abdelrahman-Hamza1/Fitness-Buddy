using System.Globalization;
using System.Security.Cryptography;
using FitnessBuddy.BuildingBlocks.Ids;
using FitnessBuddy.Modules.Identity.Contracts;
using Microsoft.Extensions.Options;

namespace FitnessBuddy.Modules.Identity.Application;

internal sealed class IdentityService(IIdentityStore store, IIdentityTokens tokens, IGoogleIdentityVerifier google, IEmailSender email, IIdGenerator ids, TimeProvider clock, IOptions<IdentityOptions> options)
{
    public bool Enabled => options.Value.Enabled;
    public async Task<IssuedTokens?> GuestAsync(Guid device, CancellationToken ct)
    {
        var (raw, m) = Material(device);
        return await IssueAsync(await store.CreateGuestAsync(ids.NewId(), m, ct), raw, ct);
    }
    public async Task<IssuedTokens?> GoogleAsync(string idToken, Guid device, CancellationToken ct)
    {
        var proof = await google.VerifyAsync(idToken, ct);
        if (proof is null) { return null; }
        var (raw, m) = Material(device);
        return await IssueAsync(await store.GoogleSignInAsync(proof, ids.NewId(), m, ct), raw, ct);
    }
    public async Task<IssuedTokens?> RefreshAsync(string refreshToken, CancellationToken ct)
    {
        if (refreshToken.Length != 43 || refreshToken.Any(c => !char.IsAsciiLetterOrDigit(c) && c is not '-' and not '_')) { return null; }
        var raw = NewRefresh();
        return await IssueAsync(await store.RotateAsync(tokens.Hash(refreshToken), tokens.Hash(raw), ct), raw, ct);
    }
    public async Task<(Guid Id, DateTimeOffset Expires)> StartEmailAsync(string address, string purpose, IdentitySession? principal, string ip, CancellationToken ct)
    {
        var id = ids.NewId();
        var expires = clock.GetUtcNow().AddMinutes(10);
        var normalized = address.Trim().ToLowerInvariant();
        if (purpose == "link" && (principal is null || !principal.IsAnonymous)) { return (id, expires); }
        var code = RandomNumberGenerator.GetInt32(1000000).ToString("D6", CultureInfo.InvariantCulture);
        var allowed = await store.StartEmailAsync(id, tokens.ProtectLookup("email-address", normalized), CodeHash(id, code, purpose), purpose,
            purpose == "link" ? principal : null, tokens.ProtectLookup("email-ip", ip), ct);
        if (allowed) { await email.SendAsync(id, normalized, code, expires, ct); }
        return (id, expires);
    }
    // A33: the guest-upgrade email code needs the live guest bearer, so a missing or
    // stale token is a 401 the app can refresh, never a silent no-code challenge.
    public async Task<(Guid Id, DateTimeOffset Expires)?> StartLinkEmailAsync(string address, IdentitySession principal, string ip, CancellationToken ct)
    {
        if (!principal.IsAnonymous) { return null; }
        return await StartEmailAsync(address, "link", principal, ip, ct);
    }
    public async Task<IssuedTokens?> VerifyEmailAsync(Guid id, string code, Guid device, CancellationToken ct)
    {
        var (raw, m) = Material(device);
        return await IssueAsync(await store.ConsumeEmailAsync(id, CodeHash(id, code, "signIn"), "signIn", null, ids.NewId(), m, ct), raw, ct);
    }
    public async Task<IssuedTokens?> LinkAsync(IdentitySession principal, string provider, string? idToken, Guid? challenge, string? code, Guid device, CancellationToken ct)
    {
        if (!principal.IsAnonymous) { return null; }
        var (raw, m) = Material(device);
        IdentitySession? session;
        if (provider == "google" && idToken is not null && challenge is null && code is null)
        {
            var proof = await google.VerifyAsync(idToken, ct);
            if (proof is null) { return null; }
            session = await store.LinkGoogleAsync(principal, proof, m, ct);
        }
        else if (provider == "email" && idToken is null && challenge.HasValue && code is not null)
        {
            session = await store.ConsumeEmailAsync(challenge.Value, CodeHash(challenge.Value, code, "link"), "link", principal, ids.NewId(), m, ct);
        }
        else { return null; }
        return await IssueAsync(session, raw, ct);
    }
    private byte[] CodeHash(Guid id, string code, string purpose) => tokens.ProtectLookup("email-code:" + purpose, id + ":" + code);
    private (string Raw, SessionMaterial Material) Material(Guid device)
    {
        var raw = NewRefresh();
        return (raw, new SessionMaterial(ids.NewId(), device, tokens.Hash(raw)));
    }
    private static string NewRefresh() => Microsoft.IdentityModel.Tokens.Base64UrlEncoder.Encode(RandomNumberGenerator.GetBytes(32));
    private async Task<IssuedTokens?> IssueAsync(IdentitySession? session, string raw, CancellationToken ct) => session is null ? null :
        new IssuedTokens(session.UserId, session.IsAnonymous, await tokens.SignAsync(session, ct), raw, clock.GetUtcNow().AddMinutes(15), session.RefreshExpiresAt);
}
