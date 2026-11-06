using FitnessBuddy.BuildingBlocks.Ops;

namespace FitnessBuddy.Host.Http;

/// <summary>
/// Counts responses with a 5xx status for the console's Overview (B23 P4), including the exception handler's 500s. Only the
/// status and hour are kept. Health probes aren't counted. Counting never touches the response.
/// </summary>
internal sealed class ServerErrorCounting(RequestDelegate next, ServerErrorCounter counter)
{
    public async Task InvokeAsync(HttpContext context)
    {
        try { await next(context); }
        finally
        {
            if (context.Response.StatusCode >= 500 && !context.Request.Path.StartsWithSegments("/health", StringComparison.Ordinal))
            {
                counter.Record(context.Response.StatusCode);
            }
        }
    }
}
