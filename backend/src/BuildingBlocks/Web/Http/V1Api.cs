using FitnessBuddy.BuildingBlocks.Web.Modules;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Routing;

namespace FitnessBuddy.BuildingBlocks.Web.Http;

/// <summary>
/// The <c>/v1</c> route group: the single definition of what every API endpoint shares (S02 A8, S03 plan D12).
/// The client-header middleware, the 426 gate, the rate limiter and the OpenAPI transformers all read the metadata
/// set here, so endpoints declare only their own success and domain-error responses.
/// </summary>
public static class V1Api
{
    public const string Prefix = "/v1";

    /// <summary>The per-IP rate limiting policy every <c>/v1</c> endpoint uses.</summary>
    public const string RateLimitPolicy = "per-ip";

    public static RouteGroupBuilder MapV1(IEndpointRouteBuilder app)
    {
        var v1 = app.MapGroup(Prefix)
            .WithMetadata(ClientHeadersMetadata.Instance)
            .RequireRateLimiting(RateLimitPolicy)
            .ProducesValidationProblem()
            .ProducesProblem(StatusCodes.Status429TooManyRequests)
            .ProducesProblem(StatusCodes.Status500InternalServerError);

        // Finally: runs after the endpoints' own conventions, so it sees AllowOutdatedClients().
        ((IEndpointConventionBuilder)v1).Finally(endpoint =>
        {
            if (!endpoint.Metadata.OfType<AllowOutdatedClientsMetadata>().Any())
            {
                endpoint.Metadata.Add(new ProducesResponseTypeMetadata(
                    StatusCodes.Status426UpgradeRequired, typeof(ProblemDetails), ["application/problem+json"]));
            }
        });

        return v1;
    }

    /// <summary>The module's group under <c>/v1</c>, tagged with the module's name (one tag per module by construction).</summary>
    public static RouteGroupBuilder MapModuleGroup(RouteGroupBuilder v1, IModule module)
    {
        ArgumentNullException.ThrowIfNull(module);
        var group = v1.MapGroup(string.Empty).WithTags(module.Name);
        module.MapEndpoints(group);
        return group;
    }
}
