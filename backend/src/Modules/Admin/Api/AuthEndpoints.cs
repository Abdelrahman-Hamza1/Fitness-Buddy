using FitnessBuddy.Modules.Admin.Api.Pages;
using FitnessBuddy.Modules.Admin.Application;
using Microsoft.AspNetCore.Antiforgery;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Routing;
using Microsoft.Extensions.Options;

namespace FitnessBuddy.Modules.Admin.Api;

/// <summary>Sign-in, enrolment, re-auth and sign-out (B23 P2). The console home is the Overview (<see cref="OverviewEndpoints"/>).</summary>
internal static class AuthEndpoints
{
    public const string SignInRateLimit = "admin-signin";

    public static void Map(RouteGroupBuilder group)
    {
        group.MapGet("/signin", SignInPageAsync).WithCapability(AdminCapability.Anonymous).RequireRateLimiting(SignInRateLimit).WithMetadata(new GoogleSignInPage());
        group.MapPost("/signin", SignInAsync).WithCapability(AdminCapability.Anonymous).RequireRateLimiting(SignInRateLimit).WithMetadata(new GoogleSignInPage());
        group.MapGet("/reauth", ReAuthPageAsync).WithCapability(AdminCapability.Session).RequireRateLimiting(SignInRateLimit).WithMetadata(new GoogleSignInPage());
        group.MapPost("/reauth", ReAuthAsync).WithCapability(AdminCapability.Session).RequireRateLimiting(SignInRateLimit).WithMetadata(new GoogleSignInPage());
        group.MapPost("/signout", SignOutAsync).WithCapability(AdminCapability.Session);
    }

    private static async Task<IResult> SignInPageAsync(HttpContext context, StartChallenge start, IAntiforgery antiforgery, IOptions<AdminOptions> options,
        TimeProvider clock, CancellationToken cancellationToken)
    {
        if (context.Features.Get<AdminPrincipal>() is not null) { return TypedResults.Redirect(AdminModule.PathBase); }
        // Reached inside htmx (a boosted link, or a redirect it followed): load it as a full page, or Google's button never starts.
        if (AdminResponses.IsHtmx(context.Request)) { return AdminResponses.FullRedirect(context, AdminModule.PathBase + "/signin"); }
        return await SignInStepAsync(context, start, antiforgery, options, clock, null, StatusCodes.Status200OK, cancellationToken);
    }

    private static async Task<IResult> SignInAsync(HttpContext context, SignIn signIn, StartChallenge start, IAntiforgery antiforgery, IOptions<AdminOptions> options,
        ISecretTokens tokens, TimeProvider clock, CancellationToken cancellationToken)
    {
        var credential = await AdminResponses.FormValueAsync(context, "credential", cancellationToken);
        var ticket = ChallengeTicket.Parse(context.Request.Cookies[AdminCookies.Challenge], tokens);
        AdminCookies.Delete(context, AdminCookies.Challenge);
        var outcome = await signIn.HandleAsync(credential, ticket, cancellationToken);
        switch (outcome.Status)
        {
            case SignInStatus.SignedIn:
                AdminCookies.SetSession(context, outcome.SessionToken!, outcome.ExpiresAt!.Value);
                return TypedResults.Redirect(AdminModule.PathBase);
            case SignInStatus.EnrolmentNeeded:
                return AdminResponses.Page<EnrolmentPage>(AdminResponses.View(context, antiforgery, "Finish setup"),
                    new Dictionary<string, object?> { ["Subject"] = outcome.EnrolmentSubject });
            default:
                return await SignInStepAsync(context, start, antiforgery, options, clock, "Sign-in was refused. Use an allow-listed Google account and try again.",
                    StatusCodes.Status403Forbidden, cancellationToken);
        }
    }

    private static async Task<IResult> ReAuthPageAsync(HttpContext context, StartChallenge start, IAntiforgery antiforgery, IOptions<AdminOptions> options,
        TimeProvider clock, string? @return, CancellationToken cancellationToken)
    {
        var back = AdminResponses.SafeReturn(@return);
        // As for sign-in: never swapped into another page by htmx, always a full page with the Google CSP and script.
        if (AdminResponses.IsHtmx(context.Request))
        {
            return AdminResponses.FullRedirect(context, AdminModule.PathBase + "/reauth?return=" + Uri.EscapeDataString(back));
        }
        return await ReAuthStepAsync(context, start, antiforgery, options, clock, back, null, StatusCodes.Status200OK, cancellationToken);
    }

    private static async Task<IResult> ReAuthAsync(HttpContext context, ReAuthenticate reAuthenticate, StartChallenge start, IAntiforgery antiforgery,
        IOptions<AdminOptions> options, ISecretTokens tokens, TimeProvider clock, CancellationToken cancellationToken)
    {
        var principal = context.Features.Get<AdminPrincipal>()!;
        var credential = await AdminResponses.FormValueAsync(context, "credential", cancellationToken);
        var back = AdminResponses.SafeReturn(await AdminResponses.FormValueAsync(context, "return", cancellationToken));
        var ticket = ChallengeTicket.Parse(context.Request.Cookies[AdminCookies.Challenge], tokens);
        AdminCookies.Delete(context, AdminCookies.Challenge);
        var refusal = await reAuthenticate.HandleAsync(principal, credential, ticket, cancellationToken);
        if (refusal is null) { return TypedResults.Redirect(back); }
        return await ReAuthStepAsync(context, start, antiforgery, options, clock, back,
            "That didn't work. Sign in again with the same Google account.", StatusCodes.Status403Forbidden, cancellationToken);
    }

    private static async Task<IResult> SignOutAsync(HttpContext context, SignOut signOut, CancellationToken cancellationToken)
    {
        await signOut.HandleAsync(context.Features.Get<AdminPrincipal>()!, cancellationToken);
        AdminCookies.Delete(context, AdminCookies.Session);
        return TypedResults.Redirect(AdminModule.PathBase + "/signin");
    }

    private static async Task<IResult> SignInStepAsync(HttpContext context, StartChallenge start, IAntiforgery antiforgery, IOptions<AdminOptions> options,
        TimeProvider clock, string? notice, int status, CancellationToken cancellationToken)
    {
        var ticket = await start.HandleAsync(ChallengePurpose.SignIn, null, cancellationToken);
        AdminCookies.SetChallenge(context, ticket, clock.GetUtcNow());
        var step = new GoogleStepView(options.Value.GoogleClientId, ticket.Nonce, AdminModule.PathBase + "/signin", null, notice);
        return AdminResponses.Page<SignInPage>(AdminResponses.View(context, antiforgery, "Sign in"), new Dictionary<string, object?> { ["Step"] = step }, status);
    }

    private static async Task<IResult> ReAuthStepAsync(HttpContext context, StartChallenge start, IAntiforgery antiforgery, IOptions<AdminOptions> options,
        TimeProvider clock, string back, string? notice, int status, CancellationToken cancellationToken)
    {
        var principal = context.Features.Get<AdminPrincipal>()!;
        var ticket = await start.HandleAsync(ChallengePurpose.ReAuth, principal.SessionId, cancellationToken);
        AdminCookies.SetChallenge(context, ticket, clock.GetUtcNow());
        var step = new GoogleStepView(options.Value.GoogleClientId, ticket.Nonce, AdminModule.PathBase + "/reauth", back, notice);
        return AdminResponses.Page<SignInPage>(AdminResponses.View(context, antiforgery, "Sign in again"), new Dictionary<string, object?> { ["Step"] = step }, status);
    }
}
