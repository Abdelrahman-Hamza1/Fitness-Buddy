using System.Security.Cryptography;
using System.Text.Json;
using System.Text.Json.Nodes;
using FitnessBuddy.BuildingBlocks.Auth;
using FitnessBuddy.BuildingBlocks.Persistence;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Http.Features;
using Microsoft.Extensions.DependencyInjection;
using Npgsql;

namespace FitnessBuddy.BuildingBlocks.Web.Idempotency;

/// <summary>Buffers an opted-in POST until database effects and its 24-hour replay record commit atomically.
/// No anonymous scope is guessed from client headers. Auth endpoints must define their policy in S24.</summary>
public sealed class IdempotencyMiddleware(RequestDelegate next)
{
    public const int MaxRequestBytes = 256 * 1024;
    public const int MaxResponseBytes = 1024 * 1024;
    private static readonly string[] ReplayHeaders = ["ETag", "Location"];

    public async Task InvokeAsync(HttpContext context)
    {
        if (context.GetEndpoint()?.Metadata.GetMetadata<IdempotencyMetadata>() is null)
        {
            await next(context);
            return;
        }
        if (!HttpMethods.IsPost(context.Request.Method)) { throw new InvalidOperationException("Idempotency is only supported on POST endpoints."); }
        var user = context.RequestServices.GetRequiredService<ICurrentUser>();
        if (!user.IsAuthenticated || user.UserId is null)
        {
            await ProblemAsync(context, StatusCodes.Status401Unauthorized);
            return;
        }
        var keys = context.Request.Headers["Idempotency-Key"];
        if (keys.Count != 1 || keys[0] is not { Length: > 0 and <= 128 } key || key.Any(character => character is < '!' or > '~'))
        {
            await TypedResults.ValidationProblem(new Dictionary<string, string[]> { ["idempotency-key"] = ["A single Idempotency-Key of 1 to 128 visible ASCII characters is required."] }).ExecuteAsync(context);
            return;
        }
        if (context.Request.ContentLength > MaxRequestBytes)
        {
            await ProblemAsync(context, StatusCodes.Status413PayloadTooLarge);
            return;
        }
        var ct = context.RequestAborted;
        await using var requestBody = new MemoryStream();
        var chunk = new byte[16384];
        int read;
        while ((read = await context.Request.Body.ReadAsync(chunk, ct)) > 0)
        {
            if (requestBody.Length + read > MaxRequestBytes)
            {
                await ProblemAsync(context, StatusCodes.Status413PayloadTooLarge);
                return;
            }
            await requestBody.WriteAsync(chunk.AsMemory(0, read), ct);
        }
        var scope = IdempotencyStore.Hash(JsonSerializer.Serialize(new[] { user.UserId.Value.ToString(), context.Request.Method, context.Request.Path.Value }));
        var keyHash = IdempotencyStore.Hash(key);
        var fingerprint = IdempotencyStore.Hash(JsonSerializer.Serialize(new[] { context.Request.QueryString.Value, context.Request.ContentType,
            Convert.ToHexStringLower(SHA256.HashData(requestBody.GetBuffer().AsSpan(0, (int)requestBody.Length))) }));
        var session = context.RequestServices.GetRequiredService<DatabaseSession>();
        await session.BeginAsync(context.RequestServices.GetRequiredService<NpgsqlDataSource>(), user.UserId, ct);
        var store = new IdempotencyStore(session, context.RequestServices.GetRequiredService<TimeProvider>());
        await store.LockAsync(scope, keyHash, ct);
        var stored = await store.ReadAsync(scope, keyHash, ct);
        if (stored is { } existing)
        {
            if (!string.Equals(existing.Fingerprint, fingerprint, StringComparison.Ordinal))
            {
                await ProblemAsync(context, StatusCodes.Status409Conflict);
                return;
            }
            await ReplayAsync(context, existing.Response, ct);
            return;
        }

        var originalRequestBody = context.Request.Body;
        var originalResponseBody = context.Features.GetRequiredFeature<IHttpResponseBodyFeature>();
        await using var buffer = new LimitedMemoryStream(MaxResponseBytes);
        var bufferedFeature = new StreamResponseBodyFeature(buffer);
        requestBody.Position = 0;
        context.Request.Body = requestBody;
        context.Features.Set<IHttpResponseBodyFeature>(bufferedFeature);
        try
        {
            await next(context);
            await bufferedFeature.CompleteAsync();
            if (context.Response.StatusCode < 500)
            {
                var headers = ReplayHeaders.Where(header => context.Response.Headers.ContainsKey(header))
                    .ToDictionary(header => header, header => context.Response.Headers[header].ToString(), StringComparer.OrdinalIgnoreCase);
                var response = new StoredResponse(context.Response.StatusCode, context.Response.ContentType, buffer.ToArray(), headers);
                await store.WriteAsync(scope, keyHash, fingerprint, response, ct);
                await session.CommitAsync(ct);
            }
            else
            {
                // A server failure may have made partial writes. They must roll back before releasing this key.
                await session.DisposeAsync();
            }
        }
        finally
        {
            context.Request.Body = originalRequestBody;
            context.Features.Set(originalResponseBody);
        }
        context.Response.ContentLength = buffer.Length;
        buffer.Position = 0;
        await buffer.CopyToAsync(originalResponseBody.Stream, ct);
    }

    private static async Task ReplayAsync(HttpContext context, StoredResponse response, CancellationToken ct)
    {
        context.Response.StatusCode = response.Status;
        context.Response.ContentType = response.ContentType;
        foreach (var (header, value) in response.Headers) { context.Response.Headers[header] = value; }
        var body = response.Body;
        // Problems preserve their meaning, but must correlate with THIS request (TD-057), never an old trace.
        if (response.ContentType?.StartsWith("application/problem+json", StringComparison.OrdinalIgnoreCase) == true && JsonNode.Parse(body) is JsonObject problem)
        {
            problem["traceId"] = context.TraceIdentifier;
            body = JsonSerializer.SerializeToUtf8Bytes(problem);
        }
        context.Response.ContentLength = body.Length;
        await context.Response.Body.WriteAsync(body, ct);
    }

    private static Task ProblemAsync(HttpContext context, int status) => TypedResults.Problem(statusCode: status).ExecuteAsync(context);
}
