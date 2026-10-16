using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.BuildingBlocks.Web.Modules;
using FitnessBuddy.Modules.UserData.Api;
using FitnessBuddy.Modules.UserData.Application;
using FitnessBuddy.Modules.UserData.Infrastructure;
using Microsoft.AspNetCore.Routing;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace FitnessBuddy.Modules.UserData;

/// <summary>B01 experimental document sync; production authentication and policy arrive in B05.</summary>
public sealed class UserDataModule : IModule
{
    public string Name => "UserData";

    public void AddServices(IServiceCollection services, IConfiguration configuration)
    {
        services.AddValidation();
        services.Configure<SpikeOptions>(configuration.GetSection("SyncSpike"));
        services.AddSingleton<SpikeAccess>();
        services.AddScoped<SyncService>();
        services.AddScoped<ISyncStore, PostgresSyncStore>();
        services.AddSingleton(new ModuleMigration("userdata", connection => new UserDataContext(DatabaseConfiguration.ContextOptions<UserDataContext>(connection, "userdata"))));
    }

    public void MapEndpoints(RouteGroupBuilder group) => group.MapSyncEndpoints();
}
