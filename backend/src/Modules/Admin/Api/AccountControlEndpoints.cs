using FitnessBuddy.Modules.Admin.Api.Pages;
using FitnessBuddy.Modules.Admin.Application;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Routing;

namespace FitnessBuddy.Modules.Admin.Api;

/// <summary>
/// AD-011 account controls (B24): revoke one device or all, disable/enable, the Buddy daily limit, delete. Operators only;
/// revoke all, disable and delete also need the account id typed and a sign-in under 15 minutes (AD-007). The handler checks the
/// sign-in age (no endpoint filter), so a stale attempt is audited as <c>needs-recent-sign-in</c> before re-auth. Kept in their own
/// routes and component (<see cref="AccountControls"/>), which the B23b account page includes.
/// </summary>
internal static class AccountControlEndpoints
{
    /// <summary>The account's detail page (B23b), which includes the controls.</summary>
    public static string PanelPath(Guid account) => AdminModule.PathBase + "/accounts/" + account.ToString("D");

    public static void Map(RouteGroupBuilder group)
    {
        group.MapPost("/accounts/{id:guid}/devices/{key}/revoke", RevokeDeviceAsync).WithCapability(AdminCapability.Operate);
        group.MapPost("/accounts/{id:guid}/revoke-all", RevokeAllAsync).WithCapability(AdminCapability.Operate);
        group.MapPost("/accounts/{id:guid}/disable", DisableAsync).WithCapability(AdminCapability.Operate);
        group.MapPost("/accounts/{id:guid}/enable", EnableAsync).WithCapability(AdminCapability.Operate);
        group.MapPost("/accounts/{id:guid}/buddy-limit", BuddyLimitAsync).WithCapability(AdminCapability.Operate);
        group.MapPost("/accounts/{id:guid}/delete", DeleteAsync).WithCapability(AdminCapability.Operate);
    }

    private static async Task<IResult> RevokeDeviceAsync(HttpContext context, RevokeDevice handler, Guid id, string key, CancellationToken cancellationToken)
    {
        var form = await context.Request.ReadFormAsync(cancellationToken);
        return After(context, id, "revoke-device", await handler.HandleAsync(Principal(context), id, key, form["reason"], cancellationToken));
    }

    private static async Task<IResult> RevokeAllAsync(HttpContext context, RevokeAllDevices handler, Guid id, CancellationToken cancellationToken)
    {
        var form = await context.Request.ReadFormAsync(cancellationToken);
        return After(context, id, "revoke-all", await handler.HandleAsync(Principal(context), id, form["reason"], form["confirmAccountId"], cancellationToken));
    }

    private static async Task<IResult> DisableAsync(HttpContext context, SetAccountDisabled handler, Guid id, CancellationToken cancellationToken)
    {
        var form = await context.Request.ReadFormAsync(cancellationToken);
        return After(context, id, "disable", await handler.HandleAsync(Principal(context), id, true, form["reason"], form["confirmAccountId"], cancellationToken));
    }

    private static async Task<IResult> EnableAsync(HttpContext context, SetAccountDisabled handler, Guid id, CancellationToken cancellationToken)
    {
        var form = await context.Request.ReadFormAsync(cancellationToken);
        return After(context, id, "enable", await handler.HandleAsync(Principal(context), id, false, form["reason"], null, cancellationToken));
    }

    private static async Task<IResult> BuddyLimitAsync(HttpContext context, SetBuddyLimit handler, Guid id, CancellationToken cancellationToken)
    {
        var form = await context.Request.ReadFormAsync(cancellationToken);
        return After(context, id, "buddy-limit", await handler.HandleAsync(Principal(context), id, form["dailyCalls"], form["reason"], cancellationToken));
    }

    private static async Task<IResult> DeleteAsync(HttpContext context, RequestAccountDeletion handler, Guid id, CancellationToken cancellationToken)
    {
        var form = await context.Request.ReadFormAsync(cancellationToken);
        return After(context, id, "delete", await handler.HandleAsync(Principal(context), id, form["reason"], form["confirmAccountId"], cancellationToken));
    }

    /// <summary>Back to the panel with a notice (post/redirect/get); a stale sign-in goes to re-auth first (full page load).</summary>
    private static IResult After(HttpContext context, Guid account, string action, ControlOutcome outcome)
    {
        var panel = PanelPath(account);
        if (outcome == ControlOutcome.NeedsRecentSignIn)
        {
            return AdminResponses.FullRedirect(context, AdminModule.PathBase + "/reauth?return=" + Uri.EscapeDataString(panel));
        }
        var query = outcome == ControlOutcome.Done ? "?done=" + action : "?refused=" + AccountControlRunner.Code(outcome);
        return AdminResponses.FullRedirect(context, panel + query);
    }

    /// <summary>The notice the account page shows after a control (post/redirect/get).</summary>
    public static string? Notice(string? done, string? refused) => (done, refused) switch
    {
        ("revoke-device", _) => "The device's sessions are revoked. Its next request is refused and the app signs out.",
        ("revoke-all", _) => "Every device's sessions are revoked.",
        ("disable", _) => "The account is disabled and every session is revoked.",
        ("enable", _) => "The account is enabled. The person signs in again on their device.",
        ("buddy-limit", _) => "The Buddy daily limit is saved.",
        ("delete", _) => "Deletion requested. The account is disabled now; the server deletes its data within seconds.",
        (_, "typed-id-mismatch") => "Nothing changed: the typed account ID doesn't match this account.",
        (_, "invalid-reason") => "Nothing changed: pick a reason.",
        (_, "invalid-limit") => "Nothing changed: the limit must be a whole number from 0 to 1000, or empty for the default.",
        (_, "unknown-device") => "Nothing changed: that device isn't on this account any more.",
        (_, "deletion-pending") => "Nothing changed: a deletion is pending, so the account stays disabled.",
        (_, "not-found") => "Nothing changed: the account no longer exists or is being deleted.",
        _ => null,
    };

    private static AdminPrincipal Principal(HttpContext context) => context.Features.Get<AdminPrincipal>()!;
}
