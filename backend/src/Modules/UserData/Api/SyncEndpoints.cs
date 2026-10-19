using System.Globalization;
using System.ComponentModel.DataAnnotations;
using FitnessBuddy.Modules.Identity.Contracts;
using FitnessBuddy.Modules.UserData.Domain;
using FitnessBuddy.Modules.UserData.Application;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Routing;

namespace FitnessBuddy.Modules.UserData.Api;

internal static class SyncEndpoints
{
    public static void MapSyncEndpoints(this RouteGroupBuilder group)
    {
        var sync = group.MapGroup("/sync").RequireAuthorization("registered-user").ProducesProblem(401).ProducesProblem(403);
        sync.MapPost("/push", Push).WithName("pushSync");
        sync.MapGet("/pull", Pull).WithName("pullSync");
        sync.MapGet("/history", History).WithName("getSyncHistory");
        sync.MapGet("/history/{entity}/{id:guid}", ItemHistory).WithName("getItemSyncHistory");
    }

    private static async Task<Results<Ok<SyncPushResponse>, ProblemHttpResult, ValidationProblem>> Push(SyncPushRequest body,
        HttpContext context, SyncService service, CancellationToken cancellationToken)
    {
        if (body.Changes.Any(change => change is null))
        {
            return TypedResults.ValidationProblem(new Dictionary<string, string[]> { ["changes"] = ["Changes must contain only non-null objects."] });
        }
        context.Response.Headers.CacheControl = "no-store";
        var result = await service.PushAsync(context.Features.Get<IdentitySession>()!, body.DatasetId,
            body.Changes.Select(change => change.ToVersion()).ToArray(), cancellationToken);
        if (result is null) { return TypedResults.Problem(statusCode: 401); }
        return TypedResults.Ok(new SyncPushResponse(result.Results.Select(row => new SyncPushResult(row.Entity, row.Id, row.Hlc, row.Status, row.Reason)).ToArray(), result.ServerTime, result.DatasetId));
    }

    private static Task<Results<Ok<SyncPage>, ProblemHttpResult, ValidationProblem>> Pull([RegularExpression(SyncRules.CursorPattern)] string cursor, int limit,
        HttpContext context, SyncService service, TimeProvider clock, CancellationToken cancellationToken, [FromQuery] Guid? datasetId = null) =>
        Page(cursor, limit, context, service, clock, false, null, null, datasetId, cancellationToken);

    private static Task<Results<Ok<SyncPage>, ProblemHttpResult, ValidationProblem>> History([RegularExpression(SyncRules.CursorPattern)] string cursor, int limit,
        HttpContext context, SyncService service, TimeProvider clock, CancellationToken cancellationToken, [FromQuery] Guid? datasetId = null) =>
        Page(cursor, limit, context, service, clock, true, null, null, datasetId, cancellationToken);

    private static Task<Results<Ok<SyncPage>, ProblemHttpResult, ValidationProblem>> ItemHistory([RegularExpression(SyncRules.CursorPattern)] string cursor, int limit,
        [MinLength(1), MaxLength(64)] string entity, Guid id, HttpContext context, SyncService service, TimeProvider clock,
        CancellationToken cancellationToken, [FromQuery] Guid? datasetId = null) =>
        Page(cursor, limit, context, service, clock, true, entity, id, datasetId, cancellationToken);

    private static async Task<Results<Ok<SyncPage>, ProblemHttpResult, ValidationProblem>> Page(string cursor, int limit,
        HttpContext context, SyncService service, TimeProvider clock, bool history, string? entity, Guid? id, Guid? dataset,
        CancellationToken cancellationToken)
    {
        if (!long.TryParse(cursor, NumberStyles.None, CultureInfo.InvariantCulture, out var sequence) ||
            sequence < 0 || sequence.ToString(CultureInfo.InvariantCulture) != cursor || limit is < 1 or > 500)
        {
            return TypedResults.ValidationProblem(new Dictionary<string, string[]> { ["cursor"] = ["Use a nonnegative decimal bigint cursor and limit 1–500."] });
        }
        context.Response.Headers.CacheControl = "no-store";
        var page = await service.PullAsync(context.Features.Get<IdentitySession>()!, dataset, sequence, limit, history, entity, id, cancellationToken);
        if (page is null) { return TypedResults.Problem(statusCode: 401); }
        return TypedResults.Ok(new SyncPage(page.Changes.Select(SyncDocument.From).ToArray(), page.NextCursor, page.DatasetId, clock.GetUtcNow(), page.Reason));
    }
}
