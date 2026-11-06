using FitnessBuddy.BuildingBlocks.Ops;
using FitnessBuddy.Modules.Admin.Api.Pages;
using FitnessBuddy.Modules.Admin.Application;
using Microsoft.AspNetCore.Antiforgery;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Routing;

namespace FitnessBuddy.Modules.Admin.Api;

/// <summary>AD-014 Jobs &amp; sync (retry, cancel, pause/resume are operator changes, each atomic with its audit row) and AD-015 Catalog (read).</summary>
internal static class JobsEndpoints
{
    private const string Path = AdminModule.PathBase + "/jobs";

    private static readonly Dictionary<string, (string Message, bool Error)> Results = new(StringComparer.Ordinal)
    {
        ["retried"] = ("Queued again with its attempts reset.", false),
        ["cancelled"] = ("Cancelled: it won't run.", false),
        ["paused"] = ("Paused: the workers skip this job type.", false),
        ["resumed"] = ("Resumed.", false),
        ["unchanged"] = ("Nothing to do: it already was in that state.", false),
        ["busy"] = ("Nothing changed: a worker is running it right now. Try again when it finishes.", true),
        ["refused"] = ("Nothing changed: the item isn't in that state any more, doesn't exist, or can't be paused.", true),
    };

    public static void Map(RouteGroupBuilder group)
    {
        group.MapGet("/jobs", ShowAsync).WithCapability(AdminCapability.Session);
        group.MapPost("/jobs/retry", RetryAsync).WithCapability(AdminCapability.Operate);
        group.MapPost("/jobs/cancel", CancelAsync).WithCapability(AdminCapability.Operate);
        group.MapPost("/jobs/pause", PauseAsync).WithCapability(AdminCapability.Operate);
        group.MapGet("/catalog", CatalogAsync).WithCapability(AdminCapability.Session);
    }

    private static async Task<IResult> ShowAsync(HttpContext context, ReadJobsAndSync read, IAntiforgery antiforgery, TimeProvider clock, string? result,
        CancellationToken cancellationToken)
    {
        var state = await read.HandleAsync(cancellationToken);
        var notice = result is not null && Results.TryGetValue(result, out var known) ? known : ((string Message, bool Error)?)null;
        var view = new JobsView(state.Queues, state.InProgress, state.Failed, state.Workers, state.Sync, state.Documents, notice?.Message, notice?.Error == true);
        return AdminResponses.Page<JobsPage>(AdminResponses.View(context, antiforgery, "Jobs & sync", "jobs"),
            new Dictionary<string, object?> { ["Jobs"] = view, ["Now"] = clock.GetUtcNow() });
    }

    private static async Task<IResult> RetryAsync(HttpContext context, QueueActions actions, CancellationToken cancellationToken)
    {
        var form = await context.Request.ReadFormAsync(cancellationToken);
        var kind = OpsQueues.Parse(form["kind"]);
        var outcome = kind is { } k && Guid.TryParse(form["id"], out var id)
            ? await actions.RetryAsync(Principal(context), k, id, cancellationToken) : QueueChangeOutcome.Refused;
        return Done(outcome, "retried");
    }

    private static async Task<IResult> CancelAsync(HttpContext context, QueueActions actions, CancellationToken cancellationToken)
    {
        var form = await context.Request.ReadFormAsync(cancellationToken);
        var outcome = Guid.TryParse(form["id"], out var id) ? await actions.CancelAsync(Principal(context), id, cancellationToken) : QueueChangeOutcome.Refused;
        return Done(outcome, "cancelled");
    }

    private static async Task<IResult> PauseAsync(HttpContext context, QueueActions actions, CancellationToken cancellationToken)
    {
        var form = await context.Request.ReadFormAsync(cancellationToken);
        var paused = form["paused"] == "1";
        var outcome = await actions.SetPausedAsync(Principal(context), form["type"].ToString(), paused, cancellationToken);
        return Done(outcome, paused ? "paused" : "resumed");
    }

    private static async Task<IResult> CatalogAsync(HttpContext context, ReadCatalog read, IAntiforgery antiforgery, CancellationToken cancellationToken)
    {
        var state = await read.HandleAsync(cancellationToken);
        var view = new CatalogView([.. state.Releases.Select(row => new ReleaseView(row.Release, row.FoodChange))], state.Cache,
            [.. state.Lookups.Where(row => !row.Outcome.StartsWith("sanity-", StringComparison.Ordinal))],
            [.. state.Lookups.Where(row => row.Outcome.StartsWith("sanity-", StringComparison.Ordinal))]);
        return AdminResponses.Page<CatalogPage>(AdminResponses.View(context, antiforgery, "Catalog", "catalog"), new Dictionary<string, object?> { ["Catalog"] = view });
    }

    private static Microsoft.AspNetCore.Http.HttpResults.RedirectHttpResult Done(QueueChangeOutcome outcome, string changed) => TypedResults.Redirect(Path + "?result=" + outcome switch
    {
        QueueChangeOutcome.Changed => changed,
        QueueChangeOutcome.Unchanged => "unchanged",
        QueueChangeOutcome.Busy => "busy",
        _ => "refused",
    });

    private static AdminPrincipal Principal(HttpContext context) => context.Features.Get<AdminPrincipal>()!;
}
