using FitnessBuddy.Modules.Admin.Application;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;

namespace FitnessBuddy.Modules.Admin.Api;

/// <summary>AD-007: the endpoint needs a sign-in less than 15 minutes old; otherwise the admin is sent to re-auth first.</summary>
internal sealed class RecentSignInFilter(TimeProvider clock) : IEndpointFilter
{
    public async ValueTask<object?> InvokeAsync(EndpointFilterInvocationContext context, EndpointFilterDelegate next)
    {
        ArgumentNullException.ThrowIfNull(context);
        ArgumentNullException.ThrowIfNull(next);
        var principal = context.HttpContext.Features.Get<AdminPrincipal>();
        if (principal is null) { return TypedResults.Unauthorized(); }
        if (principal.SignedInRecently(clock.GetUtcNow())) { return await next(context); }
        var request = context.HttpContext.Request;
        // Back to this page (GET), or to the page the form was on (POST; same-origin, checked by the guard).
        var back = HttpMethods.IsGet(request.Method) ? request.Path.Value
            : Uri.TryCreate(request.Headers.Referer.ToString(), UriKind.Absolute, out var referer) ? referer.AbsolutePath : null;
        var target = AdminModule.PathBase + "/reauth?return=" + Uri.EscapeDataString(AdminResponses.SafeReturn(back));
        // htmx (boosted link or form): HX-Redirect, so the re-auth page loads as a full page with Google's script and CSP.
        if (AdminResponses.IsHtmx(request) || HttpMethods.IsGet(request.Method)) { return AdminResponses.FullRedirect(context.HttpContext, target); }
        return TypedResults.Content(
            "<!DOCTYPE html><html lang=\"en\"><meta charset=\"utf-8\"><title>Sign in again</title><link rel=\"stylesheet\" href=\"/admin/assets/admin.css\"><main><p>This action needs a recent sign-in. Nothing was changed.</p><p><a href=\""
            + System.Net.WebUtility.HtmlEncode(target) + "\">Sign in again to continue</a></p></main></html>",
            "text/html; charset=utf-8", statusCode: StatusCodes.Status403Forbidden);
    }
}

internal sealed class RecentSignInMetadata;

internal static class RecentSignInExtensions
{
    public static TBuilder RequireRecentSignIn<TBuilder>(this TBuilder builder) where TBuilder : IEndpointConventionBuilder
    {
        builder.WithMetadata(new RecentSignInMetadata());
        builder.AddEndpointFilter<TBuilder, RecentSignInFilter>();
        return builder;
    }
}
