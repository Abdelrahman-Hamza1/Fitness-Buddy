using FitnessBuddy.Modules.Buddy.Application;
using FitnessBuddy.Modules.Buddy.Domain;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Routing;

namespace FitnessBuddy.Modules.Buddy.Api;

internal static class BuddyEndpoints
{
    // The turn bodies carry a sealed continuation (≤ 256 KiB) plus tool results, or a photo: above the 256 KB default.
    private const long TurnBodyLimit = 1024 * 1024;

    public static void Map(RouteGroupBuilder group)
    {
        group.MapPost("/buddy/turns", StartTurn).RequireAuthorization("any-user").WithName("startBuddyTurn")
            .Produces<BuddyTurnEvent>(200, "text/event-stream").ProducesProblem(401).ProducesProblem(409).ProducesProblem(503)
            .WithMetadata(new Microsoft.AspNetCore.Mvc.RequestSizeLimitAttribute(TurnBodyLimit));
        group.MapPost("/buddy/turns/continue", ContinueTurn).RequireAuthorization("any-user").WithName("continueBuddyTurn")
            .Produces<BuddyTurnEvent>(200, "text/event-stream").ProducesProblem(401).ProducesProblem(409).ProducesProblem(503)
            .WithMetadata(new Microsoft.AspNetCore.Mvc.RequestSizeLimitAttribute(TurnBodyLimit));
        group.MapPost("/buddy/label", ExtractLabel).RequireAuthorization("any-user").WithName("extractBuddyLabel")
            .ProducesProblem(401).ProducesProblem(503).WithMetadata(new Microsoft.AspNetCore.Mvc.RequestSizeLimitAttribute(LabelBodyLimit));
    }

    // A label photo (≤ 400,000 base64 characters) plus the JSON around it.
    private const long LabelBodyLimit = 512 * 1024;

    /// <summary>A label read (FD-040–042): 400 for a body that isn't a JPEG, 429 before any provider call, 503 when Buddy can't answer.</summary>
    private static async Task<Results<Ok<BuddyLabelExtraction>, ValidationProblem, ProblemHttpResult>> ExtractLabel(BuddyLabelRequest request, HttpContext context,
        Application.ExtractLabel handler, TimeProvider clock, Microsoft.Extensions.Options.IOptions<BuddyAgentOptions> options, CancellationToken ct)
    {
        context.Response.Headers.CacheControl = "no-store";
        if (!JpegImage.Valid(request.Image))
        { return TypedResults.ValidationProblem(new Dictionary<string, string[]> { ["image"] = ["A base64 JPEG of at most 1024 px per side is required."] }); }
        var guest = context.Features.Get<FitnessBuddy.Modules.Identity.Contracts.IdentitySession>()?.IsAnonymous ?? true;
        LabelOutcome outcome;
        try { outcome = await handler.ExecuteAsync(request.Image, guest, ct); }
        catch (FitnessBuddy.BuildingBlocks.Recovery.RecoveryUnavailableException) { return TypedResults.Problem(statusCode: 503); }
        return outcome.Status switch
        {
            LabelStatus.Ok => TypedResults.Ok(outcome.Extraction!),
            LabelStatus.Unauthorized => TypedResults.Problem(statusCode: 401),
            LabelStatus.Limited => RateLimited(context, clock, outcome.Limit ?? (guest ? options.Value.GuestDailyMessages : options.Value.RegisteredDailyMessages)),
            _ => TypedResults.Problem(statusCode: 503),
        };
    }

    /// <summary>429 with the daily window's Retry-After and RateLimit headers (the allowance resets at UTC midnight).</summary>
    private static ProblemHttpResult RateLimited(HttpContext context, TimeProvider clock, int limit)
    {
        var now = clock.GetUtcNow();
        var seconds = (int)Math.Ceiling((new DateTimeOffset(now.UtcDateTime.Date.AddDays(1), TimeSpan.Zero) - now).TotalSeconds);
        context.Response.Headers.RetryAfter = seconds.ToString(System.Globalization.CultureInfo.InvariantCulture);
        context.Response.Headers["RateLimit"] = $"\"buddy\";r=0;t={seconds}";
        context.Response.Headers["RateLimit-Policy"] = $"\"buddy\";q={limit};w=86400";
        return TypedResults.Problem(statusCode: 429, type: "/errors/rate-limited", title: "Rate limited");
    }

    private static Task<Results<EmptyHttpResult, ValidationProblem, ProblemHttpResult>> StartTurn(BuddyTurnStart request,
        [Microsoft.AspNetCore.Mvc.FromHeader(Name = "Idempotency-Key")] Guid idempotencyKey, HttpContext context, RunTurn handler, TimeProvider clock,
        Microsoft.Extensions.Options.IOptions<BuddyAgentOptions> options, Microsoft.Extensions.Options.IOptions<Microsoft.AspNetCore.Http.Json.JsonOptions> json,
        CancellationToken ct)
        => TurnAsync(context, request.TurnId, 0, TurnRequestMapping.Invalid(request), guest => handler.PrepareStartAsync(request.ToInput(), guest, ct),
            handler, clock, options.Value, json.Value.SerializerOptions);

    private static Task<Results<EmptyHttpResult, ValidationProblem, ProblemHttpResult>> ContinueTurn(BuddyTurnContinue request,
        [Microsoft.AspNetCore.Mvc.FromHeader(Name = "Idempotency-Key")] Guid idempotencyKey, HttpContext context, RunTurn handler, TimeProvider clock,
        Microsoft.Extensions.Options.IOptions<BuddyAgentOptions> options, Microsoft.Extensions.Options.IOptions<Microsoft.AspNetCore.Http.Json.JsonOptions> json,
        CancellationToken ct)
        => TurnAsync(context, request.TurnId, request.Round, TurnRequestMapping.Invalid(request),
            guest => handler.PrepareContinueAsync(request.ToInput(json.Value.SerializerOptions), guest, ct), handler, clock, options.Value, json.Value.SerializerOptions);

    /// <summary>Problems before the stream (400/401/409/429/503); afterwards only events (06 §3.3).</summary>
    private static async Task<Results<EmptyHttpResult, ValidationProblem, ProblemHttpResult>> TurnAsync(HttpContext context, Guid turnId, int round, string? invalid,
        Func<bool, Task<TurnPrepared>> prepare, RunTurn handler, TimeProvider clock, BuddyAgentOptions options, System.Text.Json.JsonSerializerOptions json)
    {
        context.Response.Headers.CacheControl = "no-store";
        var keys = context.Request.Headers["Idempotency-Key"];
        if (keys.Count != 1 || keys[0] != turnId.ToString())
        { return TypedResults.ValidationProblem(new Dictionary<string, string[]> { ["idempotency-key"] = ["Idempotency-Key must equal the UUIDv7 turnId."] }); }
        if (invalid is not null) { return TypedResults.ValidationProblem(new Dictionary<string, string[]> { [invalid] = ["Invalid turn request."] }); }
        var guest = context.Features.Get<FitnessBuddy.Modules.Identity.Contracts.IdentitySession>()?.IsAnonymous ?? true;
        TurnPrepared prepared;
        try { prepared = await prepare(guest); }
        catch (FitnessBuddy.BuildingBlocks.Recovery.RecoveryUnavailableException) { return TypedResults.Problem(statusCode: 503); }
        switch (prepared.Problem)
        {
            case TurnProblem.Unauthorized: return TypedResults.Problem(statusCode: 401);
            case TurnProblem.AlreadyRan: return TypedResults.Problem(statusCode: 409, detail: "The round already ran.");
            case TurnProblem.Unavailable: return TypedResults.Problem(statusCode: 503);
            case TurnProblem.Limited:
                return RateLimited(context, clock, prepared.Limit ?? (guest ? options.GuestDailyMessages : options.RegisteredDailyMessages));
            default: break;
        }
        context.Response.Headers.CacheControl = "no-cache";
        await using var writer = await SseTurnWriter.StartAsync(context, json, turnId, round, TimeSpan.FromSeconds(options.HeartbeatSeconds), clock);
        if (prepared.Run is { } run) { await handler.RunAsync(run, writer, context.RequestAborted); }
        else { await writer.EmitAsync(new BuddyErrorEvent(prepared.StreamError ?? BuddyTurnErrorCode.Invalid), context.RequestAborted); }
        return TypedResults.Empty;
    }
}
