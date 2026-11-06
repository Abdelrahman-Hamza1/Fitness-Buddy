using FitnessBuddy.Modules.Admin.Api.Pages;
using FitnessBuddy.Modules.Admin.Application;
using Microsoft.AspNetCore.Antiforgery;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Routing;

namespace FitnessBuddy.Modules.Admin.Api;

/// <summary>AD-011 (read) and AD-002: the accounts list, one account's detail, and the exact-email lookup (a POST-based read).</summary>
internal static class AccountEndpoints
{
    public const string LookupRateLimit = "admin-lookup";

    private const string NoMatch = "No account has exactly that email.";

    public static void Map(RouteGroupBuilder group)
    {
        group.MapGet("/accounts", ListAsync).WithCapability(AdminCapability.Session);
        group.MapGet("/accounts/{id:guid}", DetailAsync).WithCapability(AdminCapability.Session);
        // A read, so any role; POST keeps the address out of URLs, logs and history.
        group.MapPost("/accounts/find", FindAsync).WithCapability(AdminCapability.Session).RequireRateLimiting(LookupRateLimit);
    }

    private static async Task<IResult> ListAsync(HttpContext context, ListAccounts list, IAntiforgery antiforgery, string? type, string? issues, Guid? before,
        string? after, CancellationToken cancellationToken)
    {
        var filter = AccountFilter.Parse(type, issues);
        var page = await list.HandleAsync(filter, before, IssueCursor.Parse(after), cancellationToken);
        return Page(context, antiforgery, filter, page, null, StatusCodes.Status200OK);
    }

    private static async Task<IResult> DetailAsync(HttpContext context, ReadAccount read, ReadAccountControls readControls, IAntiforgery antiforgery, Guid id,
        string? done, string? refused, CancellationToken cancellationToken)
    {
        var detail = await read.HandleAsync(id, cancellationToken);
        if (detail is null)
        {
            await AdminResponses.WriteMessageAsync(context, StatusCodes.Status404NotFound, "No account with that id.");
            return TypedResults.Empty;
        }
        var view = new AccountDetailView(Row(detail.Row), detail.Documents, detail.Devices);
        // B24: the controls, with the notice of the control that redirected here. Null if the account went away in between.
        var controls = await readControls.HandleAsync(id, cancellationToken);
        return AdminResponses.Page<AccountPage>(AdminResponses.View(context, antiforgery, "Account " + Show.Short(id), "accounts"),
            new Dictionary<string, object?>
            {
                ["Detail"] = view,
                ["Controls"] = controls is null ? null : AccountControlsView.From(controls, AccountControlEndpoints.Notice(done, refused)),
            });
    }

    private static async Task<IResult> FindAsync(HttpContext context, FindAccountByEmail find, ListAccounts list, IAntiforgery antiforgery,
        CancellationToken cancellationToken)
    {
        var email = await AdminResponses.FormValueAsync(context, "email", cancellationToken);
        var found = await find.HandleAsync(context.Features.Get<AdminPrincipal>()!, email, cancellationToken);
        if (found.Match is { } id) { return TypedResults.Redirect(AdminModule.PathBase + "/accounts/" + id); }
        var filter = AccountFilter.Parse(null, null);
        var notice = found.EmailSignInSearched ? NoMatch
            : NoMatch + " Email sign-in accounts weren't searched: this console has no Identity lookup key (Identity:PepperFile).";
        return Page(context, antiforgery, filter, await list.HandleAsync(filter, null, null, cancellationToken), notice, StatusCodes.Status404NotFound);
    }

    private static Microsoft.AspNetCore.Http.HttpResults.RazorComponentResult<AccountsPage> Page(HttpContext context, IAntiforgery antiforgery, AccountFilter filter, AccountList page, string? notice, int status)
    {
        var view = new AccountsView(filter.Type, filter.SyncIssues, [.. page.Rows.Select(Row)], page.Next, notice,
            page.NextIssue is { } issue ? IssueCursor.Format(issue) : null, page.ScanLimited);
        return AdminResponses.Page<AccountsPage>(AdminResponses.View(context, antiforgery, "Accounts", "accounts"), new Dictionary<string, object?> { ["Accounts"] = view }, status);
    }

    /// <summary>The sync-issues cursor in a URL: <c>rejects_userId</c>, both public facts of the listed row.</summary>
    internal static class IssueCursor
    {
        public static string Format(FitnessBuddy.Modules.UserData.Contracts.UserRejects issue) =>
            issue.Rejects.ToString(System.Globalization.CultureInfo.InvariantCulture) + "_" + issue.UserId;

        public static FitnessBuddy.Modules.UserData.Contracts.UserRejects? Parse(string? value)
        {
            var parts = value?.Split('_');
            return parts is [var rejects, var user] && long.TryParse(rejects, System.Globalization.NumberStyles.None, System.Globalization.CultureInfo.InvariantCulture, out var count)
                && count > 0 && Guid.TryParse(user, out var id) ? new(id, count) : null;
        }
    }

    private static AccountRowView Row(AccountRow row) =>
        new(row.Account, row.Sync?.Documents ?? 0, row.Sync?.StorageBytes ?? 0, row.Sync?.Rejects ?? 0, row.Sync?.LastPushAt, row.Sync?.LastPullAt, row.AiUses30Days);
}
