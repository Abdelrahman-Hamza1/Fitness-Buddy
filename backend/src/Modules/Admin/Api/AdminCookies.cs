using FitnessBuddy.Modules.Admin.Application;
using Microsoft.AspNetCore.Http;

namespace FitnessBuddy.Modules.Admin.Api;

/// <summary>
/// The console's cookies (B23 P2). <c>__Host-</c>: Secure, Path=/, no Domain; HttpOnly and SameSite=Strict. Browsers accept
/// Secure cookies on <c>http://localhost</c>, so the laptop's loopback URL works as well as the Tailscale HTTPS one.
/// </summary>
internal static class AdminCookies
{
    public const string Session = "__Host-fb-admin";
    public const string Challenge = "__Host-fb-admin-pre";

    public static void SetSession(HttpContext context, string token, DateTimeOffset expiresAt) =>
        context.Response.Cookies.Append(Session, token, Options(expiresAt));

    public static void SetChallenge(HttpContext context, ChallengeTicket ticket, DateTimeOffset now) =>
        context.Response.Cookies.Append(Challenge, ticket.CookieValue, Options(now + ChallengeTicket.Lifetime));

    public static void Delete(HttpContext context, string name) => context.Response.Cookies.Delete(name, Options(null));

    private static CookieOptions Options(DateTimeOffset? expires) => new()
    {
        HttpOnly = true,
        Secure = true,
        SameSite = SameSiteMode.Strict,
        Path = "/",
        Expires = expires,
        IsEssential = true,
    };
}
