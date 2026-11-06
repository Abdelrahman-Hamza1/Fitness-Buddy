using System.Globalization;
using System.Security.Claims;
using System.Text.Encodings.Web;
using FitnessBuddy.Modules.Admin.Application;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace FitnessBuddy.Modules.Admin.Api;

/// <summary>The console's only authentication scheme: the server-side session behind <see cref="AdminCookies.Session"/>.</summary>
internal sealed class AdminSessionHandler(IOptionsMonitor<AuthenticationSchemeOptions> options, ILoggerFactory logger, UrlEncoder encoder, ResolveSession resolve)
    : AuthenticationHandler<AuthenticationSchemeOptions>(options, logger, encoder)
{
    public const string SchemeName = "AdminSession";
    public const string HandleClaim = "fb_admin_handle";
    public const string RoleClaim = "fb_admin_role";
    public const string AuthTimeClaim = "fb_admin_auth_time";

    protected override async Task<AuthenticateResult> HandleAuthenticateAsync()
    {
        if (!Request.Cookies.TryGetValue(AdminCookies.Session, out var token)) { return AuthenticateResult.NoResult(); }
        var principal = await resolve.HandleAsync(token, Context.RequestAborted);
        if (principal is null)
        {
            AdminCookies.Delete(Context, AdminCookies.Session);
            return AuthenticateResult.Fail("session-invalid");
        }
        Context.Features.Set(principal);
        var identity = new ClaimsIdentity(
        [
            new Claim(ClaimTypes.NameIdentifier, principal.SessionId.ToString("N")),
            new Claim(HandleClaim, principal.Handle),
            new Claim(RoleClaim, principal.Role == Domain.ConsoleRole.Operator ? "operator" : "viewer"),
            new Claim(AuthTimeClaim, principal.AuthenticatedAt.ToUnixTimeSeconds().ToString(CultureInfo.InvariantCulture)),
        ], SchemeName);
        return AuthenticateResult.Success(new AuthenticationTicket(new ClaimsPrincipal(identity), SchemeName));
    }

    protected override Task HandleChallengeAsync(AuthenticationProperties properties)
    {
        if (Request.Headers["HX-Request"] == "true")
        {
            Response.StatusCode = StatusCodes.Status401Unauthorized;
            Response.Headers["HX-Redirect"] = AdminModule.PathBase + "/signin";
        }
        else if (HttpMethods.IsGet(Request.Method) || HttpMethods.IsHead(Request.Method))
        {
            Response.Redirect(AdminModule.PathBase + "/signin");
        }
        else
        {
            Response.StatusCode = StatusCodes.Status401Unauthorized;
        }
        return Task.CompletedTask;
    }

    protected override async Task HandleForbiddenAsync(AuthenticationProperties properties)
    {
        Response.StatusCode = StatusCodes.Status403Forbidden;
        Response.ContentType = "text/html; charset=utf-8";
        await Response.WriteAsync("<!DOCTYPE html><title>Not allowed</title><p>Your role can't do this. Viewers can read but not change anything.</p><p><a href=\"/admin\">Back</a></p>");
    }
}
