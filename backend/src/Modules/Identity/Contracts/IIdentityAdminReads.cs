namespace FitnessBuddy.Modules.Identity.Contracts;

/// <summary>
/// Content-free Identity counts for the admin console (B23, owner O1, TD-118). Implemented with <c>identity.admin_*</c> functions
/// that only the console login can run: counts, versions and platforms; never emails, subjects or device IDs.
/// </summary>
public interface IIdentityAdminReads
{
    /// <summary>Active accounts' devices seen since <paramref name="since"/>, by app version and platform.</summary>
    Task<IReadOnlyList<InstallCount>> InstallsAsync(DateTimeOffset since, CancellationToken cancellationToken);

    /// <summary>Accounts by type (<c>guest</c>, <c>google</c>, <c>email</c>, <c>registered</c>) and status.</summary>
    Task<IReadOnlyList<AccountTypeCount>> AccountsByTypeAsync(CancellationToken cancellationToken);

    /// <summary>One page, newest first: accounts older than <paramref name="before"/>, of <paramref name="type"/> when set.</summary>
    Task<IReadOnlyList<AdminAccount>> AccountPageAsync(string? type, Guid? before, int limit, CancellationToken cancellationToken);

    /// <summary>The given accounts (at most 200), newest first; unknown ids are absent.</summary>
    Task<IReadOnlyList<AdminAccount>> AccountsAsync(IReadOnlyCollection<Guid> ids, CancellationToken cancellationToken);

    /// <summary>
    /// Accounts whose email is exactly <paramref name="email"/> under Identity's normalization (trimmed, lower case): ids only,
    /// never a partial match. Google identities match their stored address; email sign-in accounts match by the keyed address
    /// hash, which needs Identity's lookup key (<c>Identity:PepperFile</c>); without it they aren't searched, and the result says so.
    /// </summary>
    Task<EmailLookup> FindByEmailAsync(string email, CancellationToken cancellationToken);

    /// <summary>An account's devices without their ids, most recently seen first.</summary>
    Task<IReadOnlyList<AdminDevice>> DevicesAsync(Guid user, DateTimeOffset now, CancellationToken cancellationToken);
}

public sealed record AccountTypeCount(string Type, string Status, long Accounts);

/// <summary>The matching account ids, and whether email sign-in accounts were searched (they need Identity's lookup key).</summary>
public sealed record EmailLookup(IReadOnlyList<Guid> Accounts, bool EmailSignInSearched);

/// <summary>Why an account shows the email it does (AD-002).</summary>
public static class AdminEmailState
{
    /// <summary>First letter + domain of a stored address.</summary>
    public const string Masked = "masked";

    /// <summary>Email sign-in only: the address is never stored, only its keyed hash, so there is nothing to mask.</summary>
    public const string NotStored = "not-stored";

    /// <summary>A stored address that doesn't have an address shape, so it isn't shown at all.</summary>
    public const string Hidden = "hidden";

    /// <summary>No email identity (guests).</summary>
    public const string None = "none";
}

/// <summary>An account as the console shows it. <paramref name="MaskedEmail"/> is first letter + domain (AD-002) when
/// <paramref name="EmailState"/> is <see cref="AdminEmailState.Masked"/>, otherwise null.</summary>
public sealed record AdminAccount(Guid Id, string Type, string? MaskedEmail, string EmailState, string Status, DateTimeOffset CreatedAt,
    DateTimeOffset? LastSeenAt, string? AppVersion, long Devices);

public sealed record AdminDevice(string? Platform, string? AppVersion, DateTimeOffset? LastSeenAt, long ActiveSessions);

/// <summary><paramref name="AppVersion"/> is the reported <c>MAJOR.MINOR.PATCH</c>; <paramref name="Platform"/> is <c>android</c> or <c>ios</c>.</summary>
public sealed record InstallCount(string AppVersion, string Platform, long Installs);
