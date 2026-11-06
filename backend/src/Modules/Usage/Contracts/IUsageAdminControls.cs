using FitnessBuddy.BuildingBlocks.Persistence;

namespace FitnessBuddy.Modules.Usage.Contracts;

/// <summary>
/// The operator's per-account Buddy daily call limit (B24, AD-011), on the console's session (fb_admin). The caller must have
/// revalidated the account with Identity's lock in the same session first (<c>IIdentityAdminControls.LockAsync</c>).
/// </summary>
public interface IUsageAdminControls
{
    public const int MaxDailyCalls = 1000;

    /// <summary>The override, or null for the default.</summary>
    Task<int?> DailyLimitAsync(DatabaseSession session, Guid user, CancellationToken cancellationToken);

    /// <summary>Sets (0–1000; 0 = Buddy off for this account) or clears (null) the override; returns the previous value.</summary>
    Task<int?> SetDailyLimitAsync(DatabaseSession session, Guid user, int? dailyCalls, DateTimeOffset now, CancellationToken cancellationToken);
}
