using System.ComponentModel.DataAnnotations;
using FitnessBuddy.BuildingBlocks.Auth;
using FitnessBuddy.Modules.Catalog.Application;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Routing;

namespace FitnessBuddy.Modules.Catalog.Api;

internal static class CatalogEndpoints
{
    public static void Map(RouteGroupBuilder group)
    {
        var authenticated = group.MapGroup("").RequireAuthorization("any-user").ProducesProblem(401).ProducesProblem(503);
        authenticated.MapGet("/foods/search", Search).WithName("searchFoods");
        // A literal segment outranks the catch-all below, and no catalog key starts with "barcode/".
        authenticated.MapGet("/foods/barcode/{code}", Barcode).WithName("getFoodByBarcode").ProducesProblem(404);
        // Stable variant keys include a slash. Unescape the encoded route once, never use it as a filesystem path.
        authenticated.MapGet("/foods/{**id}", Get).WithName("getFood").ProducesProblem(404);
        authenticated.MapGet("/catalog/packs/latest", Latest).WithName("getLatestCatalogPack").ProducesProblem(404);
        authenticated.MapGet("/catalog/packs/{version:int}", Download).WithName("downloadCatalogPack").ProducesProblem(404);
    }
    private static async Task<Results<Ok<CatalogSearchPage>, ValidationProblem>> Search([MinLength(1), MaxLength(200)] string query, int limit,
        CatalogQueries handler, HttpContext context, CancellationToken cancellationToken, string? cursor = null)
    {
        context.Response.Headers.CacheControl = "no-store";
        try
        {
            var page = await handler.SearchAsync(query, limit, cursor, cancellationToken);
            return TypedResults.Ok(new CatalogSearchPage(page.Items.Select(r => CatalogFood.From(r.Food)).ToArray(), page.NextCursor));
        }
        catch (ArgumentException) { return TypedResults.ValidationProblem(new Dictionary<string, string[]> { ["query"] = ["Use query 1–200 characters, limit 1–50 and a current search cursor."] }); }
    }
    private static async Task<Results<Ok<BarcodeProduct>, ValidationProblem, ProblemHttpResult>> Barcode(string code, BarcodeLookup lookup,
        ICurrentUser user, HttpContext context, CancellationToken cancellationToken)
    {
        context.Response.Headers.CacheControl = "no-store";
        if (user.UserId is not { } owner) { return TypedResults.Problem(statusCode: 401); }
        var result = await lookup.LookupAsync(code, owner, cancellationToken);
        switch (result.Status)
        {
            case BarcodeStatus.Found: return TypedResults.Ok(BarcodeProduct.From(result.Product!));
            case BarcodeStatus.NotFound: return TypedResults.Problem(statusCode: 404);
            case BarcodeStatus.Invalid:
                return TypedResults.ValidationProblem(new Dictionary<string, string[]> { ["code"] = ["Use a GTIN-8, -12, -13 or -14 barcode with a valid check digit."] });
            case BarcodeStatus.UserLimited:
                var seconds = RetrySeconds(result.RetryAfter);
                context.Response.Headers.RetryAfter = seconds;
                context.Response.Headers["RateLimit"] = "\"barcode\";r=0;t=" + seconds;
                return TypedResults.Problem(statusCode: 429, type: "/errors/rate-limited", title: "Rate limited");
            default:
                context.Response.Headers.RetryAfter = RetrySeconds(result.RetryAfter);
                return TypedResults.Problem(statusCode: 503);
        }
    }
    private static string RetrySeconds(TimeSpan? wait) =>
        Math.Clamp((int)Math.Ceiling((wait ?? TimeSpan.FromSeconds(60)).TotalSeconds), 1, 3600).ToString(System.Globalization.CultureInfo.InvariantCulture);
    private static async Task<Results<Ok<CatalogFood>, ProblemHttpResult>> Get(string id, CatalogQueries handler, HttpContext context, CancellationToken cancellationToken)
    {
        context.Response.Headers.CacheControl = "no-store";
        if (id.Length > 256) { return TypedResults.Problem(statusCode: 404); }
        var food = await handler.GetAsync(Uri.UnescapeDataString(id), cancellationToken);
        return food is null ? TypedResults.Problem(statusCode: 404) : TypedResults.Ok(CatalogFood.From(food));
    }
    private static async Task<Results<Ok<CatalogPack>, ProblemHttpResult>> Latest(CatalogQueries handler, HttpContext context, CancellationToken cancellationToken)
    {
        context.Response.Headers.CacheControl = "no-store";
        var pack = await handler.PackAsync(null, cancellationToken);
        return pack is null ? TypedResults.Problem(statusCode: 404) : TypedResults.Ok(new CatalogPack(pack.Version,
            "/v1/catalog/packs/" + pack.Version.ToString(System.Globalization.CultureInfo.InvariantCulture), pack.Sha256, pack.SizeBytes, pack.SchemaVersion));
    }
    private static async Task<Results<FileContentHttpResult, ProblemHttpResult>> Download(int version, CatalogQueries handler, HttpContext context, CancellationToken cancellationToken)
    {
        context.Response.Headers.CacheControl = "no-store";
        var pack = await handler.PackAsync(version, cancellationToken);
        return pack is null ? TypedResults.Problem(statusCode: 404) : TypedResults.File(pack.Bytes!, "application/octet-stream", "catalog.db");
    }
}
