using FitnessBuddy.BuildingBlocks.Web.Http;
using FitnessBuddy.BuildingBlocks.Web.Modules;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Http.Metadata;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.AspNetCore.Routing;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace FitnessBuddy.BuildingBlocks.Tests;

/// <summary>The <c>/v1</c> group is the one definition of the API-wide conventions (S03 plan D12).</summary>
public sealed class V1ApiTests
{
    [Fact]
    public async Task V1_group_sets_client_headers_rate_limit_shared_errors_and_426_unless_exempt()
    {
        await using var app = WebApplication.CreateSlimBuilder().Build();
        var v1 = V1Api.MapV1(app);
        V1Api.MapModuleGroup(v1, new SampleModule());

        var endpoints = ((IEndpointRouteBuilder)app).DataSources.SelectMany(s => s.Endpoints).OfType<RouteEndpoint>()
            .ToDictionary(e => e.RoutePattern.RawText!, StringComparer.Ordinal);
        var gated = endpoints["/v1/sample/gated"];
        var exempt = endpoints["/v1/sample/exempt"];

        foreach (var endpoint in new[] { gated, exempt })
        {
            Assert.NotNull(endpoint.Metadata.GetMetadata<ClientHeadersMetadata>());
            Assert.Equal(V1Api.RateLimitPolicy, endpoint.Metadata.GetMetadata<EnableRateLimitingAttribute>()?.PolicyName);
            Assert.Equal(["Sample"], endpoint.Metadata.GetOrderedMetadata<ITagsMetadata>().SelectMany(t => t.Tags));
            Assert.Superset(new HashSet<int> { 400, 429, 500 }, Statuses(endpoint));
        }

        Assert.Contains(426, Statuses(gated));
        Assert.DoesNotContain(426, Statuses(exempt));
    }

    private static HashSet<int> Statuses(Endpoint endpoint) =>
        [.. endpoint.Metadata.GetOrderedMetadata<IProducesResponseTypeMetadata>().Select(m => m.StatusCode)];

    private sealed class SampleModule : IModule
    {
        public string Name => "Sample";

        public void AddServices(IServiceCollection services, IConfiguration configuration)
        {
        }

        public void MapEndpoints(RouteGroupBuilder group)
        {
            group.MapGet("/sample/gated", () => TypedResults.Ok());
            group.MapGet("/sample/exempt", () => TypedResults.Ok()).AllowOutdatedClients();
        }
    }
}
