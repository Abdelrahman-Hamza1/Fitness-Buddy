using FitnessBuddy.Modules.Buddy.Application;
using FitnessBuddy.Modules.Buddy.Domain;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Routing;

namespace FitnessBuddy.Modules.Buddy.Api;

internal static class BuddyEndpoints
{
    public static void Map(RouteGroupBuilder group) => group.MapPost("/buddy/interpret", Interpret)
        .RequireAuthorization("any-user").WithName("interpretMessage").ProducesProblem(401).ProducesProblem(409).ProducesProblem(503);
    private static async Task<Results<Ok<BuddyInterpretation>, ValidationProblem, ProblemHttpResult>> Interpret(
        InterpretRequest request, [Microsoft.AspNetCore.Mvc.FromHeader(Name = "Idempotency-Key")] Guid idempotencyKey, HttpContext context, InterpretMessage handler, TimeProvider clock, Microsoft.Extensions.Options.IOptions<BuddyOptions> options, CancellationToken ct)
    {
        context.Response.Headers.CacheControl = "no-store";
        var keys = context.Request.Headers["Idempotency-Key"];
        if (keys.Count != 1 || idempotencyKey != request.RequestId || keys[0] != request.RequestId.ToString())
        { return TypedResults.ValidationProblem(new Dictionary<string, string[]> { ["idempotency-key"] = ["Idempotency-Key must equal the UUIDv7 requestId."] }); }
        var result = await handler.ExecuteAsync(request.ToInput(), ct);
        if (result.Status == InterpretStatus.Success) { return TypedResults.Ok(result.Value!); }
        if (result.Status == InterpretStatus.Limited)
        {
            var now = clock.GetUtcNow();
            var seconds = (int)Math.Ceiling((new DateTimeOffset(now.UtcDateTime.Date.AddDays(1), TimeSpan.Zero) - now).TotalSeconds);
            var limit = context.Features.Get<FitnessBuddy.Modules.Identity.Contracts.IdentitySession>()!.IsAnonymous ? options.Value.GuestDailyCalls : options.Value.RegisteredDailyCalls;
            context.Response.Headers.RetryAfter = seconds.ToString(System.Globalization.CultureInfo.InvariantCulture);
            context.Response.Headers["RateLimit"] = $"\"buddy\";r=0;t={seconds}";
            context.Response.Headers["RateLimit-Policy"] = $"\"buddy\";q={limit};w=86400";
            return TypedResults.Problem(statusCode: 429, type: "/errors/rate-limited", title: "Rate limited");
        }
        return TypedResults.Problem(statusCode: result.Status == InterpretStatus.Conflict ? 409 : result.Status == InterpretStatus.Unauthorized ? 401 : 503);
    }
}
