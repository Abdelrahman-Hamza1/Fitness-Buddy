using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Routing;

namespace FitnessBuddy.Modules.Admin.Api;

/// <summary>The console's embedded CSS and JS (no CDN, no static-web-assets pipeline). A fixed list; nothing else is served.</summary>
internal static class AssetEndpoints
{
    private static readonly Dictionary<string, string> Types = new(StringComparer.Ordinal)
    {
        ["admin.css"] = "text/css; charset=utf-8",
        ["admin-signin.js"] = "text/javascript; charset=utf-8",
        ["htmx-2.0.11.min.js"] = "text/javascript; charset=utf-8",
    };

    public static void Map(RouteGroupBuilder group) =>
        group.MapGet("/assets/{name}", Serve).WithCapability(AdminCapability.Anonymous).WithMetadata(new CacheableAsset());

    private static IResult Serve(string name, HttpContext context)
    {
        if (!Types.TryGetValue(name, out var contentType)) { return TypedResults.NotFound(); }
        var stream = typeof(AdminModule).Assembly.GetManifestResourceStream("admin-assets/" + name);
        if (stream is null) { return TypedResults.NotFound(); }
        context.Response.Headers.CacheControl = "private, max-age=300";
        return TypedResults.Stream(stream, contentType);
    }
}
