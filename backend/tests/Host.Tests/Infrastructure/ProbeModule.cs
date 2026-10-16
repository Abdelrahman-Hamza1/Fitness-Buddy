using System.ComponentModel.DataAnnotations;
using FitnessBuddy.BuildingBlocks.Results;
using FitnessBuddy.BuildingBlocks.Web.Modules;
using FitnessBuddy.BuildingBlocks.Web.Problems;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Routing;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace FitnessBuddy.Host.Tests.Infrastructure;

// Request DTOs that carry validation are public: the .NET 10 validation generator skips internal types silently
// (backend/README.md "Validation"). The DTO is in another assembly than the Host, as a module's would be (S03 R1).
public sealed record ProbeItem([property: Range(1, 1000)] int Qty);

public sealed record ProbeChild([property: Required, StringLength(8)] string Code);

public sealed record ProbeRequest([property: Required] string Name, IReadOnlyList<ProbeItem> Items, ProbeChild Child);

internal sealed record ProbeReply(string Value);

/// <summary>Signals from the slow probe endpoint to the graceful-shutdown test.</summary>
internal sealed class ProbeSignals
{
    public TaskCompletionSource SlowRequestStarted { get; } = new(TaskCreationOptions.RunContinuationsAsynchronously);
}

/// <summary>
/// A test-only module under <c>/v1/_probe/…</c>, registered like a real one, so the tests run the real pipeline
/// (client headers, 426, rate limit, validation, problems) against endpoints and DTOs from another assembly.
/// </summary>
internal sealed class ProbeModule : IModule
{
    public const string ExceptionCanary = "CANARY-EXCEPTION secret message";

    public string Name => "Probe";

    public void AddServices(IServiceCollection services, IConfiguration configuration)
    {
        services.AddSingleton<ProbeSignals>();
        services.AddValidation();
    }

    public void MapEndpoints(RouteGroupBuilder group)
    {
        var probe = group.MapGroup("/_probe");
        probe.MapGet("/ok", () => TypedResults.Ok(new ProbeReply("ok")));
        probe.MapPost("/validate", (ProbeRequest request) => TypedResults.Ok(new ProbeReply(request.Name)));
        probe.MapGet("/count", (int n) => TypedResults.Ok(new ProbeReply($"{n}")));
        probe.MapGet("/throw", IResult () => throw new InvalidOperationException(ExceptionCanary));
        probe.MapGet("/conflict", () =>
            Result<ProbeReply>.Failure(Error.VersionConflict("probe.version_conflict")).ToHttpResult(TypedResults.Ok));
        probe.MapGet("/peer", (HttpContext context) =>
            TypedResults.Ok(new ProbeReply($"{context.Connection.RemoteIpAddress} {context.Request.Scheme}")));
        probe.MapGet("/slow", async (ProbeSignals signals) =>
        {
            signals.SlowRequestStarted.TrySetResult();
            // Deliberately ignores the abort token: the request must finish while the host drains.
            await Task.Delay(TimeSpan.FromMilliseconds(500), CancellationToken.None);
            return TypedResults.Ok(new ProbeReply("slow"));
        });
    }
}
