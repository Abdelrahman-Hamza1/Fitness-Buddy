namespace FitnessBuddy.Modules.Admin.Domain;

/// <summary>What the Overview's alerts are computed from (AD-010, B23 P4). Null means "not known" (not configured or not reported).</summary>
internal sealed record OverviewFacts(
    bool? ApiReady,
    bool BackupConfigured,
    DateTimeOffset? BackupCompletedAt,
    bool BackupOk,
    DateTimeOffset? LastWorkerBeat,
    long DeadItems,
    DateTimeOffset? OldestDueAt,
    long ServerErrors24h,
    bool OverrideActive,
    bool CatalogReleased);

/// <summary>One open alert: a closed code, a plain sentence (no internals) and the window behind it.</summary>
internal sealed record OverviewAlert(string Code, string Message, string Link);

/// <summary>The Overview's alert rules (B23 P4). Pure: the thresholds are here and nowhere else.</summary>
internal static class OverviewAlerts
{
    public static readonly TimeSpan BackupMaxAge = TimeSpan.FromHours(26);
    public static readonly TimeSpan WorkerSilence = TimeSpan.FromMinutes(2);
    public static readonly TimeSpan PendingMaxAge = TimeSpan.FromMinutes(10);

    public static IReadOnlyList<OverviewAlert> Evaluate(OverviewFacts facts, DateTimeOffset now)
    {
        ArgumentNullException.ThrowIfNull(facts);
        var alerts = new List<OverviewAlert>();
        if (facts.ApiReady == false) { alerts.Add(new("api-not-ready", "The API isn't ready.", "/admin")); }
        if (facts.BackupConfigured)
        {
            if (facts.BackupCompletedAt is not { } completed || !facts.BackupOk) { alerts.Add(new("backup-failed", "The last backup failed or isn't recorded.", "/admin")); }
            else if (now - completed > BackupMaxAge) { alerts.Add(new("backup-old", "The last backup is more than 26 hours old.", "/admin")); }
        }
        if (facts.LastWorkerBeat is not { } beat || now - beat > WorkerSilence)
        {
            alerts.Add(new("worker-silent", "No worker heartbeat in the last 2 minutes.", "/admin/jobs"));
        }
        if (facts.DeadItems > 0) { alerts.Add(new("dead-items", facts.DeadItems.ToString(System.Globalization.CultureInfo.InvariantCulture) + " failed queue item(s) need a look.", "/admin/jobs")); }
        if (facts.OldestDueAt is { } due && now - due > PendingMaxAge) { alerts.Add(new("queue-behind", "A queue item has waited more than 10 minutes.", "/admin/jobs")); }
        if (facts.ServerErrors24h > 0) { alerts.Add(new("server-errors", facts.ServerErrors24h.ToString(System.Globalization.CultureInfo.InvariantCulture) + " server error(s) in the last 24 hours.", "/admin")); }
        if (facts.OverrideActive) { alerts.Add(new("override-active", "The minimum-version override is set on the server.", "/admin/config")); }
        if (!facts.CatalogReleased) { alerts.Add(new("no-catalog", "No catalog release is published.", "/admin/catalog")); }
        return alerts;
    }
}
