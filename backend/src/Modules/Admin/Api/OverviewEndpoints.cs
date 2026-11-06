using System.Globalization;
using FitnessBuddy.Modules.Admin.Api.Pages;
using FitnessBuddy.Modules.Admin.Application;
using Microsoft.AspNetCore.Antiforgery;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Routing;

namespace FitnessBuddy.Modules.Admin.Api;

/// <summary>AD-010: the Overview is the console home.</summary>
internal static class OverviewEndpoints
{
    public static void Map(RouteGroupBuilder group) =>
        // One route: routing ignores a trailing slash, so "/admin/" matches it too (a second "/" route would be ambiguous).
        group.MapGet("", ShowAsync).WithCapability(AdminCapability.Session);

    private static async Task<IResult> ShowAsync(HttpContext context, ReadOverview read, IAntiforgery antiforgery, TimeProvider clock, CancellationToken cancellationToken)
    {
        var state = await read.HandleAsync(cancellationToken);
        var view = new OverviewView(Health(state, clock.GetUtcNow()), [.. state.Alerts.Select(alert => new AlertView(alert.Message, alert.Link))],
            [.. ReadOverview.InstallWindows.Select(days => new KeyValueView(days.ToString(CultureInfo.InvariantCulture) + (days == 1 ? " day" : " days"),
                Show.Count(state.InstallsByDays[days])))],
            state.Versions30Days, state.Accounts, state.ServerErrors24h, "$" + state.SpendThisMonth.EstimatedUsd.ToString("0.00", CultureInfo.InvariantCulture),
            state.SpendThisMonth.Calls,
            [.. new[] { ("Grafana", state.GrafanaUrl), ("Sentry", state.SentryUrl) }.Where(link => link.Item2 is not null).Select(link => new LinkView(link.Item1, link.Item2!))]);
        return AdminResponses.Page<OverviewPage>(AdminResponses.View(context, antiforgery, "Overview", "home"), new Dictionary<string, object?> { ["Overview"] = view });
    }

    private static List<HealthView> Health(OverviewState state, DateTimeOffset now)
    {
        var lastBeat = state.Workers.Count == 0 ? (DateTimeOffset?)null : state.Workers.Max(worker => worker.LastBeatAt);
        var workersOk = lastBeat is { } beat && now - beat <= Domain.OverviewAlerts.WorkerSilence;
        var backupOk = state.Backup is { Ok: true, CompletedAt: { } done } && now - done <= Domain.OverviewAlerts.BackupMaxAge;
        return
        [
            state.ApiReady switch
            {
                true => new("API", "ok", "ready", ""),
                false => new("API", "bad", "not ready", "The readiness probe failed."),
                null => new("API", "info", "not checked", "No probe URL is configured."),
            },
            new("Database", "ok", "reachable", "This page read it."),
            new("Workers", workersOk ? "ok" : "bad", workersOk ? "running" : "silent",
                lastBeat is null ? "No heartbeat yet." : "Last heartbeat " + Show.Age(lastBeat, now) + " ago."),
            state.Backup is null ? new("Backups", "info", "not checked", "No status file is configured.")
                : new("Backups", backupOk ? "ok" : "bad", backupOk ? "recent" : "check", "Last completed " + Show.Time(state.Backup.CompletedAt) + "."),
            state.CurrentRelease is { } release
                ? new("Catalog", "ok", "published", "Release " + release.Version.ToString(CultureInfo.InvariantCulture) + ", " + Show.Count(release.Foods) + " foods.")
                : new("Catalog", "bad", "none", "No release is published."),
            new("Buddy", state.BuddyOn ? "ok" : "warn", state.BuddyOn ? "on" : "off", Show.Count(state.BuddyCallsToday) + " AI calls today (UTC)."),
        ];
    }
}
