using System.Globalization;
using FitnessBuddy.BuildingBlocks.Ops;
using FitnessBuddy.Modules.Catalog.Contracts;
using FitnessBuddy.Modules.Identity.Contracts;
using FitnessBuddy.Modules.UserData.Contracts;

namespace FitnessBuddy.Modules.Admin.Api.Pages;

// B23b monitor windows (AD-010, AD-011 read, AD-014, AD-015). Public because Razor components are; they carry the module
// contracts' content-free records (counts, codes, times, pseudonymous ids, masked emails) and nothing else.

/// <summary>A status shown as icon + word (AD-008): <c>ok</c>, <c>warn</c>, <c>bad</c> or <c>info</c>.</summary>
public sealed record HealthView(string Name, string Kind, string Word, string Detail);

public sealed record AlertView(string Message, string Link);

public sealed record LinkView(string Label, string Url);

/// <summary>The Overview (AD-010).</summary>
public sealed record OverviewView(IReadOnlyList<HealthView> Health, IReadOnlyList<AlertView> Alerts, IReadOnlyList<KeyValueView> Installs,
    IReadOnlyList<InstallCount> Versions, IReadOnlyList<AccountTypeCount> Accounts, IReadOnlyList<ServerErrorCount> ServerErrors, string SpendUsd,
    long SpendCalls, IReadOnlyList<LinkView> Links);

/// <summary>One account as the list and the detail show it (AD-011). The email is masked (AD-002).</summary>
public sealed record AccountRowView(AdminAccount Account, long Documents, long StorageBytes, long Rejects7Days, DateTimeOffset? LastPushAt,
    DateTimeOffset? LastPullAt, long AiUses30Days);

/// <summary><paramref name="NextIssue"/> pages the sync-issues list; <paramref name="ScanLimited"/>: that page stopped at the scan bound.</summary>
public sealed record AccountsView(string? Type, bool SyncIssues, IReadOnlyList<AccountRowView> Rows, Guid? Next, string? Notice, string? NextIssue = null,
    bool ScanLimited = false);

public sealed record AccountDetailView(AccountRowView Row, IReadOnlyList<EntityCount> Documents, IReadOnlyList<AdminDevice> Devices);

/// <summary>Jobs &amp; sync (AD-014). <paramref name="InProgress"/> is per queue kind and type, from the last heartbeats.</summary>
public sealed record JobsView(IReadOnlyList<QueueSummary> Queues, IReadOnlyDictionary<(QueueKind Kind, string Type), int> InProgress, IReadOnlyList<FailedItem> Failed,
    IReadOnlyList<WorkerBeat> Workers, SyncSummary Sync, IReadOnlyList<EntityCount> Documents, string? Notice, bool NoticeIsError);

/// <summary>One release row with its food-count change against the previous release.</summary>
public sealed record ReleaseView(CatalogReleaseInfo Release, int? FoodChange);

/// <summary>Catalog (AD-015 read).</summary>
public sealed record CatalogView(IReadOnlyList<ReleaseView> Releases, OffCacheInfo Cache, IReadOnlyList<LookupCount> Outcomes, IReadOnlyList<LookupCount> Sanity);

/// <summary>Formatting for console pages: UTC, invariant culture, "—" for unknown.</summary>
internal static class Show
{
    public const string None = "—";

    public static string Time(DateTimeOffset? value) => value is { } time ? time.UtcDateTime.ToString("yyyy-MM-dd HH:mm", CultureInfo.InvariantCulture) : None;

    public static string Day(DateOnly value) => value.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture);

    public static string Count(long value) => value.ToString("N0", CultureInfo.InvariantCulture);

    public static string Bytes(long value) => value switch
    {
        < 1024 => value.ToString(CultureInfo.InvariantCulture) + " B",
        < 1024 * 1024 => (value / 1024d).ToString("0.0", CultureInfo.InvariantCulture) + " KB",
        _ => (value / (1024d * 1024)).ToString("0.0", CultureInfo.InvariantCulture) + " MB",
    };

    public static string Age(DateTimeOffset? since, DateTimeOffset now)
    {
        if (since is not { } start) { return None; }
        var age = now - start;
        return age.TotalMinutes < 1 ? "under a minute" : age.TotalHours < 1 ? ((int)age.TotalMinutes).ToString(CultureInfo.InvariantCulture) + " min"
            : age.TotalDays < 2 ? ((int)age.TotalHours).ToString(CultureInfo.InvariantCulture) + " h" : ((int)age.TotalDays).ToString(CultureInfo.InvariantCulture) + " days";
    }

    public static string Short(Guid id) => id.ToString()[..8];
}
