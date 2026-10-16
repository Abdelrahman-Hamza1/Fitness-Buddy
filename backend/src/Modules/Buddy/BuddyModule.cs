using FitnessBuddy.BuildingBlocks.Web.Modules;
using Microsoft.AspNetCore.Routing;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace FitnessBuddy.Modules.Buddy;

/// <summary>Buddy's parsing foundation. B08 adds authenticated contract endpoints and task configuration.</summary>
public sealed class BuddyModule : IModule
{
    public string Name => "Buddy";

    // Dark until B08: ordinary API/worker startup never loads an AI credential or creates a paid client.
    public void AddServices(IServiceCollection services, IConfiguration configuration) { }

    public void MapEndpoints(RouteGroupBuilder group) { }
}
