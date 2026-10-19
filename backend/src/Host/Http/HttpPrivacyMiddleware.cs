using System.Diagnostics;
using FitnessBuddy.Host.Observability;

namespace FitnessBuddy.Host.Http;

/// <summary>Scrubs request Activities before observers see them stop; exporters also have a final processor.</summary>
internal sealed class HttpPrivacyMiddleware(RequestDelegate next)
{
    public async Task InvokeAsync(HttpContext context)
    {
        try { await next(context); }
        finally
        {
            if (Activity.Current is { } activity)
            {
                HttpActivityPrivacy.Sanitize(activity, (context.GetEndpoint() as RouteEndpoint)?.RoutePattern.RawText);
            }
        }
    }
}
