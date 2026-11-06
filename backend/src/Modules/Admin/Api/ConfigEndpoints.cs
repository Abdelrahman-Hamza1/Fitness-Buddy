using System.Globalization;
using FitnessBuddy.Modules.Account.Contracts;
using FitnessBuddy.Modules.Admin.Api.Pages;
using FitnessBuddy.Modules.Admin.Application;
using FitnessBuddy.Modules.Admin.Domain;
using Microsoft.AspNetCore.Antiforgery;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Routing;

namespace FitnessBuddy.Modules.Admin.Api;

/// <summary>AD-012 remote config and flags: draft → diff with reach → publish with a reason → history → roll back (AD-006).</summary>
internal static class ConfigEndpoints
{
    private const string Path = AdminModule.PathBase + "/config";

    public static void Map(RouteGroupBuilder group)
    {
        group.MapGet("/config", ShowAsync).WithCapability(AdminCapability.Session);
        group.MapPost("/config/draft", SaveAsync).WithCapability(AdminCapability.Operate);
        group.MapPost("/config/draft/discard", DiscardAsync).WithCapability(AdminCapability.Operate);
        group.MapPost("/config/publish", PublishAsync).WithCapability(AdminCapability.Operate);
        group.MapGet("/config/rollback/{version:int}", RollbackReviewAsync).WithCapability(AdminCapability.Session);
        group.MapPost("/config/rollback/{version:int}", RollbackAsync).WithCapability(AdminCapability.Operate);
    }

    private static async Task<IResult> ShowAsync(HttpContext context, ReadConfig read, IAntiforgery antiforgery, int? published, int? before,
        CancellationToken cancellationToken)
    {
        var state = await read.HandleAsync(before is > 0 ? before : null, cancellationToken);
        var notice = published is { } version ? "Published version " + version.ToString(CultureInfo.InvariantCulture) + ". Apps and servers pick it up within seconds." : null;
        return Page(context, antiforgery, state, null, [], notice, StatusCodes.Status200OK);
    }

    private static async Task<IResult> SaveAsync(HttpContext context, ReadConfig read, SaveConfigDraft save, IAntiforgery antiforgery, CancellationToken cancellationToken)
    {
        var state = await read.HandleAsync(cancellationToken);
        var form = await context.Request.ReadFormAsync(cancellationToken);
        var (document, errors, typed) = ConfigForm.Parse(form, state.Current);
        if (document is not null) { errors = await save.HandleAsync(Principal(context), document, cancellationToken); }
        if (errors.Count > 0) { return Page(context, antiforgery, state, typed, errors, null, StatusCodes.Status400BadRequest); }
        return TypedResults.Redirect(Path);
    }

    private static async Task<IResult> DiscardAsync(HttpContext context, DiscardConfigDraft discard, CancellationToken cancellationToken)
    {
        await discard.HandleAsync(Principal(context), cancellationToken);
        return TypedResults.Redirect(Path);
    }

    private static async Task<IResult> PublishAsync(HttpContext context, PublishConfig publish, ReadConfig read, IAntiforgery antiforgery, CancellationToken cancellationToken)
    {
        var form = await context.Request.ReadFormAsync(cancellationToken);
        if (!int.TryParse(form["baseVersion"], NumberStyles.None, CultureInfo.InvariantCulture, out var baseVersion)
            || !long.TryParse(form["revision"], NumberStyles.None, CultureInfo.InvariantCulture, out var revision))
        {
            return Page(context, antiforgery, await read.HandleAsync(cancellationToken), null, [], ConfigForm.Notice(PublishStatus.DraftChanged), StatusCodes.Status400BadRequest);
        }
        var outcome = await publish.HandleAsync(Principal(context), new PublishRequest(baseVersion, revision, form["hash"].ToString(),
            form["reason"].ToString(), form["typedVersion"].ToString()), cancellationToken);
        return await AfterPublishAsync(context, read, antiforgery, outcome, cancellationToken);
    }

    private static async Task<IResult> RollbackReviewAsync(HttpContext context, ReadConfig read, IAntiforgery antiforgery, int version, CancellationToken cancellationToken)
    {
        var state = await read.HandleAsync(cancellationToken);
        // Any stored version, not just the history page on screen (AD-006: every published version can be rolled back to).
        var target = version > 0 ? await read.VersionAsync(version, cancellationToken) : null;
        if (target is null || version >= state.CurrentVersion)
        {
            return Page(context, antiforgery, state, null, [], ConfigForm.Notice(PublishStatus.UnknownVersion), StatusCodes.Status404NotFound);
        }
        return AdminResponses.Page<RollbackPage>(AdminResponses.View(context, antiforgery, "Roll back to version " + version.ToString(CultureInfo.InvariantCulture), "config"),
            new Dictionary<string, object?> { ["Rollback"] = Rollback(state, target, null) });
    }

    private static async Task<IResult> RollbackAsync(HttpContext context, RollbackConfig rollback, ReadConfig read, IAntiforgery antiforgery, int version,
        CancellationToken cancellationToken)
    {
        var form = await context.Request.ReadFormAsync(cancellationToken);
        _ = int.TryParse(form["expectedVersion"], NumberStyles.None, CultureInfo.InvariantCulture, out var expected);
        var outcome = await rollback.HandleAsync(Principal(context), version, expected, form["reason"].ToString(), form["typedVersion"].ToString(), cancellationToken);
        return await AfterPublishAsync(context, read, antiforgery, outcome, cancellationToken);
    }

    private static async Task<IResult> AfterPublishAsync(HttpContext context, ReadConfig read, IAntiforgery antiforgery, PublishOutcome outcome, CancellationToken cancellationToken)
    {
        switch (outcome.Status)
        {
            case PublishStatus.Published:
                return TypedResults.Redirect(Path + "?published=" + outcome.Version!.Value.ToString(CultureInfo.InvariantCulture));
            case PublishStatus.NeedsRecentSignIn:
                // A full navigation, also from a boosted form: the re-auth page must load with its own CSP and Google's script.
                return AdminResponses.FullRedirect(context, AdminModule.PathBase + "/reauth?return=" + Uri.EscapeDataString(Path));
            default:
                var status = outcome.Status is PublishStatus.Invalid or PublishStatus.TypedVersionMismatch ? StatusCodes.Status400BadRequest : StatusCodes.Status409Conflict;
                return Page(context, antiforgery, await read.HandleAsync(cancellationToken), null, outcome.Errors ?? [], ConfigForm.Notice(outcome.Status), status);
        }
    }

    private static RollbackPageView Rollback(ConfigState state, PublishedConfig target, string? notice)
    {
        var changes = ConfigDiff.Compute(state.Current, target.Document);
        return new RollbackPageView(target.Version, state.CurrentVersion, ConfigForm.Changes(changes, state.Reach),
            InstallReach.Raises(state.Current.MinimumAppVersion, target.Document.MinimumAppVersion), target.Document.MinimumAppVersion, notice);
    }

    private static Microsoft.AspNetCore.Http.HttpResults.RazorComponentResult<ConfigPage> Page(HttpContext context, IAntiforgery antiforgery, ConfigState state, ConfigFormView? typed, IReadOnlyList<string> errors, string? notice, int status)
    {
        var draft = state.Draft is { } d
            ? new DraftView(d.BaseVersion, d.Revision, d.Hash, d.UpdatedBy, d.UpdatedAt, ConfigForm.Changes(state.DraftChanges, state.Reach),
                InstallReach.Raises(state.Current.MinimumAppVersion, d.Document.MinimumAppVersion), d.Document.MinimumAppVersion)
            : null;
        var view = new ConfigPageView(state.CurrentVersion, state.Published?.PublishedBy, state.Published?.PublishedAt, state.Published?.Reason,
            ConfigForm.Values(state.Current), draft,
            [.. state.History.Select(row => new HistoryRowView(row.Version, row.PublishedAt, row.PublishedBy, row.Reason, row.RolledBackFrom, row.Version == state.CurrentVersion))],
            state.Reach.Active, state.Reach.Newest?.ToString(), state.ActiveOverride,
            typed ?? ConfigForm.FormFor(state.Draft?.Document ?? state.Current, state.Current), errors, notice, state.OlderBefore);
        return AdminResponses.Page<ConfigPage>(AdminResponses.View(context, antiforgery, "Remote config & flags", "config"),
            new Dictionary<string, object?> { ["Config"] = view }, status);
    }

    private static AdminPrincipal Principal(HttpContext context) => context.Features.Get<AdminPrincipal>()!;
}
