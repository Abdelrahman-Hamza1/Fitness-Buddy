using FitnessBuddy.BuildingBlocks.Messaging;
using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.BuildingBlocks.Web.Modules;
using FitnessBuddy.Modules.Usage.Contracts;
using FitnessBuddy.Modules.Usage.Infrastructure;
using Microsoft.AspNetCore.Routing;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace FitnessBuddy.Modules.Usage;

public sealed class UsageModule : IModule
{
    public string Name => "Usage";
    public UserDataOwnership UserData => new(["daily"], [], "usage.erase");
    public void AddServices(IServiceCollection services, IConfiguration configuration)
    {
        services.AddScoped<IUsageRecorder, PostgresUsageRecorder>(); services.AddScoped<IOutboxHandler, UsageErasure>();
        services.AddSingleton(new ModuleMigration("usage", c => new UsageContext(DatabaseConfiguration.ContextOptions<UsageContext>(c, "usage"))));
    }
    public void MapEndpoints(RouteGroupBuilder group) { }
}
