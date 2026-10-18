using System.Text.Json;
using Microsoft.Extensions.Options;

namespace FitnessBuddy.Host.Http;

/// <summary>The API contract fixes error representation, even when Accept requests an unsupported media type.</summary>
internal sealed class ApiProblemDetailsWriter(IOptions<ProblemDetailsOptions> options) : IProblemDetailsWriter
{
    public bool CanWrite(ProblemDetailsContext context) => true;
    public async ValueTask WriteAsync(ProblemDetailsContext context)
    {
        // The default writer normally applies framework RFC defaults before customization.
        var defaults = TypedResults.Problem(statusCode: context.ProblemDetails.Status ?? context.HttpContext.Response.StatusCode).ProblemDetails;
        context.ProblemDetails.Status ??= defaults.Status;
        context.ProblemDetails.Type ??= defaults.Type;
        context.ProblemDetails.Title ??= defaults.Title;
        options.Value.CustomizeProblemDetails?.Invoke(context);
        await context.HttpContext.Response.WriteAsJsonAsync(context.ProblemDetails, context.ProblemDetails.GetType(),
            (JsonSerializerOptions?)null, "application/problem+json", context.HttpContext.RequestAborted);
    }
}
