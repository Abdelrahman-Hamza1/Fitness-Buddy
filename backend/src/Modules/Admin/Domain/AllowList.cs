namespace FitnessBuddy.Modules.Admin.Domain;

/// <summary>AD-004: a viewer reads everything; an operator can also change.</summary>
internal enum ConsoleRole
{
    Viewer,
    Operator,
}

/// <summary>An admin who may sign in: identified by the Google subject (stable), with the verified email as a second check (B23 P2).</summary>
internal sealed record AllowListEntry(string Handle, string GoogleSubject, string Email, ConsoleRole Role);

/// <summary>An admin whose Google subject isn't pinned yet: a sign-in shows the signer their own subject and creates no session.</summary>
internal sealed record PendingEntry(string Handle, string Email, ConsoleRole Role);

/// <summary>The allow-list as last read. An invalid or missing file is <see cref="Invalid"/>: nobody can sign in (fail closed).</summary>
internal sealed class AllowListSnapshot
{
    public static AllowListSnapshot Invalid { get; } = new(false, [], []);

    public AllowListSnapshot(bool valid, IReadOnlyList<AllowListEntry> admins, IReadOnlyList<PendingEntry> pending)
    {
        IsValid = valid;
        Admins = admins;
        Pending = pending;
    }

    public bool IsValid { get; }

    public IReadOnlyList<AllowListEntry> Admins { get; }

    public IReadOnlyList<PendingEntry> Pending { get; }

    /// <summary>The entry for a verified token: same subject and same email (case-insensitive).</summary>
    public AllowListEntry? Match(string subject, string email) =>
        IsValid ? Admins.SingleOrDefault(entry => entry.GoogleSubject == subject && SameEmail(entry.Email, email)) : null;

    public AllowListEntry? ByHandle(string handle) =>
        IsValid ? Admins.SingleOrDefault(entry => entry.Handle == handle) : null;

    public PendingEntry? PendingByEmail(string email) =>
        IsValid ? Pending.SingleOrDefault(entry => SameEmail(entry.Email, email)) : null;

    public static bool SameEmail(string a, string b) => string.Equals(a.Trim(), b.Trim(), StringComparison.OrdinalIgnoreCase);
}
