using FitnessBuddy.BuildingBlocks.Web.Problems;
using Microsoft.AspNetCore.WebUtilities;

namespace FitnessBuddy.Host.Http;

/// <summary>
/// Runs for every problem the API writes (results, middleware, status-code pages, exception handler), 04 §4.2
/// "Errors" and S03 plan D1, D2, D8:
/// <list type="bullet">
/// <item><c>traceId</c> = the request id (bare W3C trace id); the framework's <c>requestId</c> (a connection id) is removed.</item>
/// <item>Every 400 is <c>/errors/validation-failed</c> with an <c>errors</c> map, keys camelCased. A 400 without
/// field errors is an unreadable request: <c>errors</c> is empty and the framework's <c>detail</c>, which may echo
/// the input, is replaced by a fixed text.</item>
/// <item><c>type</c> and <c>title</c> are always set (<c>about:blank</c> and the reason phrase when the framework has no default, e.g. 413).</item>
/// </list>
/// </summary>
internal static class ProblemDetailsCustomizer
{
    public const string UnreadableRequestDetail = "The request could not be read.";

    public static void Apply(ProblemDetailsContext context)
    {
        var problem = context.ProblemDetails;
        var status = problem.Status ?? context.HttpContext.Response.StatusCode;
        problem.Status = status;

        problem.Extensions.Remove("requestId");
        problem.Extensions.Remove("traceId");

        if (status == StatusCodes.Status400BadRequest)
        {
            problem.Type = ProblemTypes.ValidationFailed;
            problem.Title = ProblemTitles.ValidationFailed;
            if (problem is HttpValidationProblemDetails validation)
            {
                var errors = ValidationKeyCasing.ToCamelCase(validation.Errors);
                validation.Errors.Clear();
                foreach (var (key, messages) in errors)
                {
                    validation.Errors[key] = messages;
                }
            }
            else
            {
                problem.Detail = UnreadableRequestDetail;
                problem.Extensions["errors"] = new Dictionary<string, string[]>();
            }
        }

        problem.Type ??= "about:blank";
        problem.Title ??= ReasonPhrases.GetReasonPhrase(status);

        // Last, so it follows `errors` in both kinds of 400 (the framework writes a validation problem's errors first).
        problem.Extensions["traceId"] = context.HttpContext.TraceIdentifier;
    }
}
