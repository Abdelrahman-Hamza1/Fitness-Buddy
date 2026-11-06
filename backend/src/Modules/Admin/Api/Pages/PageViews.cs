namespace FitnessBuddy.Modules.Admin.Api.Pages;

// Razor components are always generated public, so their parameter types are public records here. They carry only
// what a page shows: no emails (only masked), subjects (except the signer's own on enrolment), tokens or user content.

/// <summary>What every page needs: its title, the antiforgery token for its forms and the signed-in admin (null when signed out).</summary>
public sealed record PageView(string Title, string Csrf, ViewerView? Viewer, string? Section = null);

public sealed record ViewerView(string Handle, bool IsOperator);

/// <summary>The Google sign-in step: the Web client ID, this challenge's nonce, where the form posts, and an optional notice.</summary>
public sealed record GoogleStepView(string ClientId, string Nonce, string Action, string? ReturnPath, string? Notice);

/// <summary>One audit row as the audit page shows it (AD-016). Before/after are the change itself (config documents), never user content.</summary>
public sealed record AuditRowView(long Id, DateTimeOffset OccurredAt, string Actor, string Area, string Action, string? Target, string Outcome,
    string? Reason, string? Before, string? After);

/// <summary>The audit page's filters as typed, and the cursor for the next page.</summary>
public sealed record AuditListView(string? Area, string? Actor, string? From, string? To, IReadOnlyList<AuditRowView> Rows, long? NextCursor, string? Notice);

/// <summary>A key and its shown value (flags as on/off).</summary>
public sealed record KeyValueView(string Key, string Value);

/// <summary>A remote-config document as shown (AD-012).</summary>
public sealed record ConfigValuesView(string MinimumAppVersion, IReadOnlyList<KeyValueView> AppFlags, IReadOnlyList<KeyValueView> Thresholds,
    IReadOnlyList<KeyValueView> ServerSwitches);

/// <summary>One changed key with its reach line (AD-006). <paramref name="Blocked"/> marks a change the rules will refuse.</summary>
public sealed record ChangeView(string Section, string Key, string? Old, string? New, string Reach, bool Blocked);

/// <summary>The reviewed draft: the exact revision and hash the publish form carries (R#3).</summary>
public sealed record DraftView(int BaseVersion, long Revision, string Hash, string UpdatedBy, DateTimeOffset UpdatedAt, IReadOnlyList<ChangeView> Changes,
    bool RaisesMinimum, string NewMinimum);

public sealed record HistoryRowView(int Version, DateTimeOffset PublishedAt, string PublishedBy, string Reason, int? RolledBackFrom, bool Current);

public sealed record ThresholdFieldView(string Key, string Value, string Range);

public sealed record SwitchFieldView(string Key, bool On);

/// <summary>The edit form's values (from the draft, the current version, or what was just typed).</summary>
public sealed record ConfigFormView(string MinimumAppVersion, string AppFlagsText, IReadOnlyList<ThresholdFieldView> Thresholds, IReadOnlyList<SwitchFieldView> Switches);

/// <summary>The remote config window (AD-012).</summary>
public sealed record ConfigPageView(int CurrentVersion, string? PublishedBy, DateTimeOffset? PublishedAt, string? Reason, ConfigValuesView Current,
    DraftView? Draft, IReadOnlyList<HistoryRowView> History, long ActiveInstalls, string? NewestReported, string? ActiveOverride, ConfigFormView Form,
    IReadOnlyList<string> Errors, string? Notice, int? OlderBefore = null);

/// <summary>The rollback review: the diff from the current version to the target and what the form needs.</summary>
public sealed record RollbackPageView(int Target, int CurrentVersion, IReadOnlyList<ChangeView> Changes, bool RaisesMinimum, string NewMinimum, string? Notice);

/// <summary>One device on the controls panel: its opaque key (never the device id), platform, version, last seen, live sessions.</summary>
public sealed record DeviceRowView(string Key, string? Platform, string? AppVersion, DateTimeOffset? LastSeenAt, long ActiveSessions);

/// <summary>A pending operator deletion: when it was requested, attempts so far, the last error code and the next try.</summary>
public sealed record DeletionView(DateTimeOffset RequestedAt, int Attempts, string? LastError, DateTimeOffset? NextAttemptAt);

/// <summary>The account controls panel (AD-011, B24). Codes, counts and timestamps only; no email, device id or content.</summary>
public sealed record AccountControlsView(Guid Account, string Status, bool IsGuest, DateTimeOffset? DisabledAt, DeletionView? Deletion,
    IReadOnlyList<DeviceRowView> Devices, int? BuddyLimit, IReadOnlyList<string> Reasons, string? Notice)
{
    internal static AccountControlsView From(FitnessBuddy.Modules.Admin.Application.AccountControlsState state, string? notice) => new(
        state.Account, state.State.Status, state.State.IsAnonymous, state.State.DisabledAt,
        state.State.DeletionRequestedAt is { } requested
            ? new DeletionView(requested, state.State.DeletionAttempts ?? 0, state.State.DeletionLastError, state.State.DeletionNextAttemptAt) : null,
        [.. state.Devices.Select(device => new DeviceRowView(device.Key, device.Platform, device.AppVersion, device.LastSeenAt, device.ActiveSessions))],
        state.BuddyLimit, FitnessBuddy.Modules.Admin.Domain.AccountControlRules.ReasonCodes, notice);
}
