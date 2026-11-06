using System.Buffers.Text;
using System.Security.Cryptography;
using System.Text;
using FitnessBuddy.BuildingBlocks.Ids;
using FitnessBuddy.Modules.Admin.Domain;
using FitnessBuddy.Modules.Identity.Contracts;
using Microsoft.Extensions.Options;

namespace FitnessBuddy.Modules.Admin.Application;

/// <summary>Why a sign-in or re-auth was refused. The code goes into the audit row; the page shows one generic message.</summary>
internal enum SignInRefusal
{
    BadToken,
    ChallengeInvalid,
    StaleToken,
    NotAllowListed,
    WrongAccount,
}

internal enum SignInStatus
{
    SignedIn,
    EnrolmentNeeded,
    Refused,
}

/// <summary>The outcome: a session token (<see cref="SignInStatus.SignedIn"/>), the signer's own subject to pin
/// (<see cref="SignInStatus.EnrolmentNeeded"/>), or a refusal.</summary>
internal sealed record SignInOutcome(SignInStatus Status, string? SessionToken = null, DateTimeOffset? ExpiresAt = null,
    string? EnrolmentSubject = null, SignInRefusal? Refusal = null)
{
    public static SignInOutcome Refused(SignInRefusal refusal) => new(SignInStatus.Refused, Refusal: refusal);
}

/// <summary>Shared checks of a Google credential for sign-in and re-auth (B23 P2).</summary>
internal sealed class CredentialCheck(IGoogleIdTokenVerifier verifier, IOptions<AdminOptions> options, TimeProvider clock)
{
    /// <summary>The token must be freshly issued: a captured older token can't be replayed later.</summary>
    public static readonly TimeSpan MaxTokenAge = TimeSpan.FromMinutes(2);

    public async Task<(VerifiedGoogleToken? Token, SignInRefusal? Refusal)> CheckAsync(string? credential, ChallengeTicket? ticket, CancellationToken cancellationToken)
    {
        if (ticket is null) { return (null, SignInRefusal.ChallengeInvalid); }
        if (string.IsNullOrEmpty(credential)) { return (null, SignInRefusal.BadToken); }
        var token = await verifier.VerifyAsync(credential, [options.Value.GoogleClientId], cancellationToken);
        if (token is null) { return (null, SignInRefusal.BadToken); }
        if (token.Nonce is null || !CryptographicOperations.FixedTimeEquals(Encoding.UTF8.GetBytes(token.Nonce), Encoding.UTF8.GetBytes(ticket.Nonce)))
        {
            return (null, SignInRefusal.ChallengeInvalid);
        }
        if (clock.GetUtcNow() - token.IssuedAt > MaxTokenAge) { return (null, SignInRefusal.StaleToken); }
        return (token, null);
    }
}

/// <summary>Use case: issue a single-use challenge for the sign-in or re-auth page.</summary>
internal sealed class StartChallenge(IAdminDatabase database, IAdminAuthStore store, ISecretTokens tokens, IIdGenerator ids, TimeProvider clock)
{
    public async Task<ChallengeTicket> HandleAsync(ChallengePurpose purpose, Guid? adminSession, CancellationToken cancellationToken)
    {
        var secret = tokens.NewSecret();
        var ticket = new ChallengeTicket(ids.NewId(), secret, ChallengeTicket.NonceFor(secret, tokens));
        var now = clock.GetUtcNow();
        await using var session = await database.BeginAsync(cancellationToken);
        if (purpose == ChallengePurpose.SignIn) { await store.CleanupAsync(session, now, cancellationToken); }
        await store.CreateChallengeAsync(session, ticket.Id, purpose, adminSession, tokens.Hash(ticket.Nonce), now + ChallengeTicket.Lifetime, cancellationToken);
        await session.CommitAsync(cancellationToken);
        return ticket;
    }
}

/// <summary>Use case: sign in with a Google credential against the allow-list (AD-003). Every outcome is audited (AD-005).</summary>
internal sealed class SignIn(CredentialCheck check, IAllowList allowList, IAdminDatabase database, IAdminAuthStore store, IAuditLog audit,
    ISecretTokens tokens, IIdGenerator ids, IOptions<AdminOptions> options, TimeProvider clock)
{
    public async Task<SignInOutcome> HandleAsync(string? credential, ChallengeTicket? ticket, CancellationToken cancellationToken)
    {
        var (token, refusal) = await check.CheckAsync(credential, ticket, cancellationToken);
        var now = clock.GetUtcNow();
        await using var session = await database.BeginAsync(cancellationToken);
        if (token is null || ticket is null)
        {
            await RefuseAsync(session, refusal ?? SignInRefusal.BadToken, null, now, cancellationToken);
            return SignInOutcome.Refused(refusal ?? SignInRefusal.BadToken);
        }
        if (!await store.ConsumeChallengeAsync(session, ticket.Id, ChallengePurpose.SignIn, null, tokens.Hash(ticket.Nonce), now, cancellationToken))
        {
            await RefuseAsync(session, SignInRefusal.ChallengeInvalid, token.Email, now, cancellationToken);
            return SignInOutcome.Refused(SignInRefusal.ChallengeInvalid);
        }
        var snapshot = allowList.Current();
        var entry = snapshot.Match(token.Subject, token.Email);
        if (entry is null)
        {
            if (snapshot.PendingByEmail(token.Email) is { } pending)
            {
                await audit.AppendAsync(session, new AuditEntry(pending.Handle, "auth", "sign-in", "enrolment-needed", EmailMask.Mask(token.Email)), now, cancellationToken);
                await session.CommitAsync(cancellationToken);
                return new SignInOutcome(SignInStatus.EnrolmentNeeded, EnrolmentSubject: token.Subject);
            }
            await RefuseAsync(session, SignInRefusal.NotAllowListed, token.Email, now, cancellationToken);
            return SignInOutcome.Refused(SignInRefusal.NotAllowListed);
        }
        var secret = tokens.NewSecret();
        var expires = now + TimeSpan.FromHours(options.Value.SessionHours);
        await store.CreateSessionAsync(session, new NewSession(ids.NewId(), tokens.Hash(secret), entry.Handle, entry.GoogleSubject, now, expires), cancellationToken);
        await audit.AppendAsync(session, new AuditEntry(entry.Handle, "auth", "sign-in", "ok"), now, cancellationToken);
        await session.CommitAsync(cancellationToken);
        return new SignInOutcome(SignInStatus.SignedIn, Base64Url.EncodeToString(secret), expires);
    }

    private async Task RefuseAsync(BuildingBlocks.Persistence.DatabaseSession session, SignInRefusal refusal, string? email, DateTimeOffset now, CancellationToken cancellationToken)
    {
        await audit.AppendAsync(session, new AuditEntry("unknown", "auth", "sign-in", RefusalCode(refusal), email is null ? null : EmailMask.Mask(email)), now, cancellationToken);
        await session.CommitAsync(cancellationToken);
    }

    public static string RefusalCode(SignInRefusal refusal) => refusal switch
    {
        SignInRefusal.BadToken => "bad-token",
        SignInRefusal.ChallengeInvalid => "challenge-invalid",
        SignInRefusal.StaleToken => "stale-token",
        SignInRefusal.NotAllowListed => "not-allow-listed",
        SignInRefusal.WrongAccount => "wrong-account",
        _ => "refused",
    };
}

/// <summary>
/// Use case: re-authenticate the current session (AD-007, B23 P2). The token must come from a fresh, single-use challenge bound
/// to this session, for the same Google subject; if Google sent <c>auth_time</c>, it must be within 15 minutes. Without
/// <c>auth_time</c> this proves a fresh explicit Google sign-in step by the same account in this browser, not a password re-entry.
/// </summary>
internal sealed class ReAuthenticate(CredentialCheck check, IAdminDatabase database, IAdminAuthStore store, IAuditLog audit, ISecretTokens tokens, TimeProvider clock)
{
    public async Task<SignInRefusal?> HandleAsync(AdminPrincipal principal, string? credential, ChallengeTicket? ticket, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(principal);
        var (token, refusal) = await check.CheckAsync(credential, ticket, cancellationToken);
        var now = clock.GetUtcNow();
        if (token is not null && token.Subject != principal.GoogleSubject) { refusal = SignInRefusal.WrongAccount; }
        else if (token?.AuthTime is { } authTime && now - authTime > AdminPrincipal.RecentSignIn) { refusal = SignInRefusal.StaleToken; }
        await using var session = await database.BeginAsync(cancellationToken);
        if (refusal is null && ticket is not null
            && !await store.ConsumeChallengeAsync(session, ticket.Id, ChallengePurpose.ReAuth, principal.SessionId, tokens.Hash(ticket.Nonce), now, cancellationToken))
        {
            refusal = SignInRefusal.ChallengeInvalid;
        }
        if (refusal is null) { await store.MarkAuthenticatedAsync(session, principal.SessionId, now, cancellationToken); }
        await audit.AppendAsync(session, new AuditEntry(principal.Handle, "auth", "re-auth", refusal is null ? "ok" : SignIn.RefusalCode(refusal.Value)), now, cancellationToken);
        await session.CommitAsync(cancellationToken);
        return refusal;
    }
}

/// <summary>Use case: sign out (revokes the session row).</summary>
internal sealed class SignOut(IAdminDatabase database, IAdminAuthStore store, IAuditLog audit, TimeProvider clock)
{
    public async Task HandleAsync(AdminPrincipal principal, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(principal);
        var now = clock.GetUtcNow();
        await using var session = await database.BeginAsync(cancellationToken);
        await store.RevokeSessionAsync(session, principal.SessionId, now, cancellationToken);
        await audit.AppendAsync(session, new AuditEntry(principal.Handle, "auth", "sign-out", "ok"), now, cancellationToken);
        await session.CommitAsync(cancellationToken);
    }
}

/// <summary>
/// Use case: turn a session cookie into the request's admin (B23 P2, R#4). The session must be live, and its handle must
/// still be on the allow-list with the <b>same Google subject</b>; otherwise it is revoked on the spot (and audited). The
/// role is read from the allow-list on every request. An invalid allow-list file fails closed without revoking anything.
/// </summary>
internal sealed class ResolveSession(IAllowList allowList, IAdminDatabase database, IAdminAuthStore store, IAuditLog audit, ISecretTokens tokens, TimeProvider clock)
{
    public async Task<AdminPrincipal?> HandleAsync(string? sessionToken, CancellationToken cancellationToken)
    {
        if (sessionToken is null || sessionToken.Length != 43) { return null; }
        byte[] secret;
        try { secret = Base64Url.DecodeFromChars(sessionToken); }
        catch (FormatException) { return null; }
        if (secret.Length != 32) { return null; }
        var now = clock.GetUtcNow();
        var snapshot = allowList.Current();
        await using var session = await database.BeginAsync(cancellationToken);
        var stored = await store.FindSessionAsync(session, tokens.Hash(secret), cancellationToken);
        if (stored is null || stored.Revoked || stored.ExpiresAt <= now || !snapshot.IsValid) { return null; }
        var entry = snapshot.ByHandle(stored.Handle);
        if (entry is null || entry.GoogleSubject != stored.GoogleSubject)
        {
            await store.RevokeSessionAsync(session, stored.Id, now, cancellationToken);
            await audit.AppendAsync(session, new AuditEntry(stored.Handle, "auth", "session-revoked", "allow-list-changed"), now, cancellationToken);
            await session.CommitAsync(cancellationToken);
            return null;
        }
        return new AdminPrincipal(stored.Id, entry.Handle, entry.GoogleSubject, entry.Role, stored.AuthenticatedAt);
    }
}
