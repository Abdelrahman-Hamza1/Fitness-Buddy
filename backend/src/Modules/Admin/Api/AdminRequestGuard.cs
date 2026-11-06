using Microsoft.AspNetCore.Antiforgery;
using Microsoft.AspNetCore.Http;

namespace FitnessBuddy.Modules.Admin.Api;

/// <summary>
/// CSRF for every state-changing console request (B23 P2): a same-origin check on <c>Sec-Fetch-Site</c> / <c>Origin</c>, then the
/// built-in antiforgery token (form field or htmx header). Runs before authorization, so it applies to anonymous sign-in too.
/// </summary>
internal sealed class AdminRequestGuard(RequestDelegate next, IAntiforgery antiforgery)
{
    public async Task InvokeAsync(HttpContext context)
    {
        var method = context.Request.Method;
        if (!(HttpMethods.IsGet(method) || HttpMethods.IsHead(method)))
        {
            if (!SameOrigin(context.Request))
            {
                await AdminResponses.WriteMessageAsync(context, StatusCodes.Status403Forbidden, "Cross-site request refused.");
                return;
            }
            try
            {
                await antiforgery.ValidateRequestAsync(context);
            }
            catch (AntiforgeryValidationException)
            {
                await AdminResponses.WriteMessageAsync(context, StatusCodes.Status400BadRequest, "This form has expired. Reload the page and try again.");
                return;
            }
        }
        await next(context);
    }

    /// <summary>Browsers send these on unsafe requests; when present they must say same-origin. Non-browser clients still need the token.</summary>
    internal static bool SameOrigin(HttpRequest request)
    {
        var site = request.Headers["Sec-Fetch-Site"].ToString();
        if (site.Length > 0 && site != "same-origin") { return false; }
        var origin = request.Headers.Origin.ToString();
        if (origin.Length == 0) { return true; }
        return string.Equals(origin, request.Scheme + "://" + request.Host.Value, StringComparison.OrdinalIgnoreCase);
    }
}

/// <summary>Security headers on every console response (B23 P2). Google's sign-in script is allowed only on the sign-in pages.</summary>
internal sealed class AdminSecurityHeaders(RequestDelegate next)
{
    public const string DefaultPolicy = "default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self' data:; connect-src 'self'; frame-ancestors 'none'; form-action 'self'; base-uri 'none'; object-src 'none'";
    public const string GooglePolicy = "default-src 'self'; script-src 'self' https://accounts.google.com/gsi/client; style-src 'self' https://accounts.google.com/gsi/style; frame-src https://accounts.google.com/gsi/; connect-src 'self' https://accounts.google.com/gsi/; img-src 'self' data:; frame-ancestors 'none'; form-action 'self'; base-uri 'none'; object-src 'none'";

    public Task InvokeAsync(HttpContext context)
    {
        context.Response.OnStarting(static state =>
        {
            var http = (HttpContext)state;
            var headers = http.Response.Headers;
            var google = http.GetEndpoint()?.Metadata.GetMetadata<GoogleSignInPage>() is not null;
            headers.ContentSecurityPolicy = google ? GooglePolicy : DefaultPolicy;
            headers.XContentTypeOptions = "nosniff";
            headers.XFrameOptions = "DENY";
            headers["Referrer-Policy"] = "same-origin";
            if (http.GetEndpoint()?.Metadata.GetMetadata<CacheableAsset>() is null) { headers.CacheControl = "no-store"; }
            if (http.Request.IsHttps) { headers.StrictTransportSecurity = "max-age=31536000"; }
            return Task.CompletedTask;
        }, context);
        return next(context);
    }
}

/// <summary>Marks the sign-in and re-auth pages, which load Google's sign-in script.</summary>
internal sealed class GoogleSignInPage;

/// <summary>Marks the embedded static assets, which may be cached.</summary>
internal sealed class CacheableAsset;
