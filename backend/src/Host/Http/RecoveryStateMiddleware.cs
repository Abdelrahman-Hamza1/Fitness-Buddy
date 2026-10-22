using FitnessBuddy.Host.Platform;
using FitnessBuddy.BuildingBlocks.Web.Http;

namespace FitnessBuddy.Host.Http;

/// <summary>Readiness alone cannot guard direct Tailscale traffic after a stale/manual restore (B06 D7).</summary>
internal sealed class RecoveryStateMiddleware(RequestDelegate next)
{
    private static readonly HashSet<string> ModuleTags = ModuleCatalog.All.Select(module => module.Name).ToHashSet(StringComparer.Ordinal);
    public async Task InvokeAsync(HttpContext context, RecoveryRequestGate gate)
    {
        var endpoint = context.GetEndpoint();
        var name = endpoint?.Metadata.GetMetadata<IEndpointNameMetadata>()?.EndpointName;
        if (name == "getConfig" || endpoint?.Metadata.GetMetadata<ModuleEndpointMetadata>() is not { } module || !ModuleTags.Contains(module.Name))
        { await next(context); return; }
        FitnessBuddy.BuildingBlocks.Persistence.DatabaseSession lease;
        try { lease = await gate.EnterAsync(context.RequestAborted); }
        catch (Exception) when (!context.RequestAborted.IsCancellationRequested)
        {
            context.Response.Headers.CacheControl = "no-store";
            await TypedResults.Problem(statusCode: 503).ExecuteAsync(context);
            return;
        }
        // These handlers own short recovery/lifecycle transactions. A shared request lease would
        // block deletion throughout external AI I/O; each Buddy dispatch/completion rechecks recovery.
        if (name is "deleteAccount" or "interpretMessage")
        { await lease.DisposeAsync(); await next(context); return; }
        await using (lease) { await next(context); }
    }
}
