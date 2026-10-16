using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Mvc;

namespace FitnessBuddy.Host.Http;

/// <summary>
/// The last resort for exceptions (04 §4.2 "Errors"): a problem with the framework's 500 <c>type</c>/<c>title</c>
/// and <c>traceId</c>, never a <c>detail</c>, message, type name or stack. A <see cref="BadHttpRequestException"/>
/// (unreadable body, body too large) keeps its own status, e.g. 400 or 413.
/// </summary>
internal sealed class UnhandledExceptionHandler(IProblemDetailsService problemDetails) : IExceptionHandler
{
    public ValueTask<bool> TryHandleAsync(HttpContext httpContext, Exception exception, CancellationToken cancellationToken)
    {
        var status = exception is BadHttpRequestException badRequest ? badRequest.StatusCode : StatusCodes.Status500InternalServerError;
        httpContext.Response.StatusCode = status;
        return problemDetails.TryWriteAsync(new ProblemDetailsContext
        {
            HttpContext = httpContext,
            ProblemDetails = new ProblemDetails { Status = status },
        });
    }
}
