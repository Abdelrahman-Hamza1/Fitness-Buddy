using Microsoft.AspNetCore.Routing;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace FitnessBuddy.BuildingBlocks.Web.Modules;

/// <summary>
/// A backend module's entry point (S03 plan D12). The Host lists every module in its <c>ModuleCatalog</c>, calls
/// <see cref="AddServices"/> at startup, and calls <see cref="MapEndpoints"/> with a group under <c>/v1</c> that
/// is already tagged <see cref="Name"/> and carries the API-wide conventions (client headers, 426 gate, rate limit,
/// shared error responses). The implementation is the module's only public type besides its <c>*.Contracts</c>.
/// </summary>
public interface IModule
{
    /// <summary>The module's name, which is also its OpenAPI tag (one Dart client class per module).</summary>
    string Name { get; }

    void AddServices(IServiceCollection services, IConfiguration configuration);

    /// <summary>Maps the module's endpoints. Routes are relative to <c>/v1</c>.</summary>
    void MapEndpoints(RouteGroupBuilder group);
}
