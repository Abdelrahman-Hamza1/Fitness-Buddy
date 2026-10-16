using System.Globalization;
using System.ComponentModel.DataAnnotations;
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
        var sync = group.MapGroup("/sync").ProducesProblem(401).ProducesProblem(501);
        sync.MapPost("/push", Push).WithName("pushSync");
        sync.MapGet("/pull", Pull).WithName("pullSync");
        sync.MapGet("/history", History).WithName("getSyncHistory");
    }

    private static async Task<Results<Ok<SyncPushResponse>, ProblemHttpResult, ValidationProblem>> Push(SyncPushRequest body,
        [FromHeader(Name = "X-Sync-Spike-Key")] string key, SpikeAccess access, SyncService service, CancellationToken cancellationToken)
    {
        var status = access.Check(key);
        if (status != 200) { return TypedResults.Problem(statusCode: status); }
        // RespectNullableAnnotations does not cover collection elements. Validate the
        // whole envelope before mapping or opening a transaction (B01 review R1).
        if (body.Changes.Any(change => change is null))
        {
            return TypedResults.ValidationProblem(new Dictionary<string, string[]> { ["changes"] = ["Changes must contain only non-null objects."] });
        }
        var result = await service.PushAsync(access.UserId, body.Changes.Select(change => change.ToVersion()).ToArray(), cancellationToken);
        return TypedResults.Ok(new SyncPushResponse(result.Results.Select(row => new SyncPushResult(row.Entity, row.Id, row.Hlc, row.Status, row.Reason)).ToArray(), result.ServerTime));
    }

    private static Task<Results<Ok<SyncPage>, ProblemHttpResult, ValidationProblem>> Pull([RegularExpression(SyncRules.CursorPattern)] string cursor, int limit,
        [FromHeader(Name = "X-Sync-Spike-Key")] string key, SpikeAccess access, SyncService service, CancellationToken cancellationToken) =>
        Page(cursor, limit, key, access, service, false, cancellationToken);

    private static Task<Results<Ok<SyncPage>, ProblemHttpResult, ValidationProblem>> History([RegularExpression(SyncRules.CursorPattern)] string cursor, int limit,
        [FromHeader(Name = "X-Sync-Spike-Key")] string key, SpikeAccess access, SyncService service, CancellationToken cancellationToken) =>
        Page(cursor, limit, key, access, service, true, cancellationToken);

    private static async Task<Results<Ok<SyncPage>, ProblemHttpResult, ValidationProblem>> Page(string cursor, int limit, string key,
        SpikeAccess access, SyncService service, bool history, CancellationToken cancellationToken)
    {
        var status = access.Check(key);
        if (status != 200) { return TypedResults.Problem(statusCode: status); }
        if (!long.TryParse(cursor, NumberStyles.None, CultureInfo.InvariantCulture, out var sequence) ||
            sequence < 0 || sequence.ToString(CultureInfo.InvariantCulture) != cursor || limit is < 1 or > 500)
        {
            return TypedResults.ValidationProblem(new Dictionary<string, string[]> { ["cursor"] = ["Use a nonnegative decimal bigint cursor and limit 1–500."] });
        }
        var page = await service.PullAsync(access.UserId, sequence, limit, history, cancellationToken);
        return TypedResults.Ok(new SyncPage(page.Changes.Select(SyncDocument.From).ToArray(), page.NextCursor));
    }
}
