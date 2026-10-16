using System.Diagnostics;

namespace FitnessBuddy.Host.Http;

/// <summary>
/// Gives every request one id, the W3C trace id (32 lowercase hex), and returns it as <c>X-Request-Id</c> on every
/// response (S03 plan D8 + A2). Inbound correlation is <c>traceparent</c> only: an inbound <c>X-Request-Id</c> is
/// ignored. The id is also <see cref="HttpContext.TraceIdentifier"/>, which the problem customizer puts in <c>traceId</c>.
/// </summary>
internal sealed class RequestIdMiddleware(RequestDelegate next)
{
    public const string HeaderName = "X-Request-Id";

    public Task InvokeAsync(HttpContext context)
    {
        context.TraceIdentifier = CurrentTraceId();

        // Set when the response starts, so it survives the exception handler clearing the headers.
        context.Response.OnStarting(
            static state =>
            {
                var httpContext = (HttpContext)state;
                httpContext.Response.Headers[HeaderName] = httpContext.TraceIdentifier;
                return Task.CompletedTask;
            },
            context);

        return next(context);
    }

    private static string CurrentTraceId() =>
        Activity.Current is { IdFormat: ActivityIdFormat.W3C } activity
            ? activity.TraceId.ToHexString()
            : ActivityTraceId.CreateRandom().ToHexString();
}
