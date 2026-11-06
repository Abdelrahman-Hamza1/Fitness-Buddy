using FitnessBuddy.BuildingBlocks.Persistence;

namespace FitnessBuddy.Modules.Identity.Contracts;

/// <summary>
/// Operator account controls for the admin console (B24, AD-011), on the console's own session (fb_admin), so the caller writes
/// its audit row in the same transaction. Every mutating method takes the user lifecycle lock first and revalidates the account
/// (active, not deleting); null means the account is gone or being deleted and nothing was written. The lock is held until the
/// caller's transaction ends. Content-free: codes, counts, timestamps and an account-scoped opaque device key, never device ids.
/// </summary>
public interface IIdentityAdminControls
{
    /// <summary>The account's control state, or null when no such account exists (deleted or never existed).</summary>
    Task<AccountControlState?> StateAsync(DatabaseSession session, Guid user, CancellationToken cancellationToken);

    /// <summary>The account's devices, most recently seen first, each with its opaque key.</summary>
    Task<IReadOnlyList<ControlDevice>> DevicesAsync(DatabaseSession session, Guid user, DateTimeOffset now, CancellationToken cancellationToken);

    /// <summary>Takes the lifecycle lock and revalidates the account; call before another module writes that account's rows.</summary>
    Task<AccountLock?> LockAsync(DatabaseSession session, Guid user, CancellationToken cancellationToken);

    /// <summary>Revokes the sessions of one device (<paramref name="deviceKey"/>) or of all devices (null).</summary>
    Task<RevokeOutcome?> RevokeAsync(DatabaseSession session, Guid user, string? deviceKey, DateTimeOffset now, CancellationToken cancellationToken);

    /// <summary>Disables (and revokes every session) or enables the account. Enabling is refused while a deletion is pending.</summary>
    Task<DisableOutcome?> SetDisabledAsync(DatabaseSession session, Guid user, bool disabled, DateTimeOffset now, CancellationToken cancellationToken);

    /// <summary>Disables the account, revokes every session and records the operator's deletion intent (the api role runs the deletion).</summary>
    Task<DeletionRequestOutcome?> RequestDeletionAsync(DatabaseSession session, Guid user, DateTimeOffset now, CancellationToken cancellationToken);
}

/// <summary><paramref name="Status"/> is <c>active</c>, <c>deleting</c> or <c>deleted</c>; the deletion fields are set while an operator deletion is pending.</summary>
public sealed record AccountControlState(string Status, bool IsAnonymous, DateTimeOffset? DisabledAt, DateTimeOffset? DeletionRequestedAt,
    int? DeletionAttempts, DateTimeOffset? DeletionNextAttemptAt, string? DeletionLastError)
{
    public bool DeletionPending => DeletionRequestedAt.HasValue;
}

/// <summary><paramref name="Key"/> is 32 lowercase hex characters derived from the account and device; it isn't the device id.</summary>
public sealed record ControlDevice(string Key, string? Platform, string? AppVersion, DateTimeOffset? LastSeenAt, long ActiveSessions);

public sealed record AccountLock(bool IsDisabled, bool DeletionPending);

public sealed record RevokeOutcome(bool DeviceFound, int RevokedSessions);

public sealed record DisableOutcome(bool WasDisabled, int RevokedSessions, bool DeletionPending);

public sealed record DeletionRequestOutcome(bool WasDisabled, int RevokedSessions, bool Created);

/// <summary>The operator deletion runner's side (B24, api role, fb_app). Ids only.</summary>
public interface IIdentityOperatorDeletions
{
    /// <summary>Accounts whose operator deletion intent is due, earliest first.</summary>
    Task<IReadOnlyList<Guid>> DueAsync(DateTimeOffset now, int limit, CancellationToken cancellationToken);

    /// <summary>
    /// Records a failed attempt (closed <paramref name="code"/>: <c>recovery-unavailable</c>, <c>unavailable</c>, <c>failed</c>) for the
    /// session's user, with backoff, only while the intent still exists. False when it doesn't (e.g. the deletion committed).
    /// </summary>
    Task<bool> RecordFailureAsync(DatabaseSession session, string code, CancellationToken cancellationToken);
}
