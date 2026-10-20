using FitnessBuddy.BuildingBlocks.Messaging;
using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.BuildingBlocks.Web.Modules;
using FitnessBuddy.Modules.Catalog.Api;
using FitnessBuddy.Modules.Catalog.Application;
using FitnessBuddy.Modules.Catalog.Contracts;
using FitnessBuddy.Modules.Catalog.Infrastructure;
using Microsoft.AspNetCore.Routing;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace FitnessBuddy.Modules.Catalog;

/// <summary>Global, release-published food catalog. OFF stays isolated until B10.</summary>
public sealed class CatalogModule : IModule
{
    public string Name => "Catalog";
    public UserDataOwnership UserData => new([], ["pack_releases", "current_release", "foods", "dishes", "names", "servings", "yields", "exercises", "cities", "off_cache"], null);
    public static Task ImportAsync(string migratorConnection, string directory, CancellationToken cancellationToken) => CatalogImporter.ImportAsync(migratorConnection, directory, cancellationToken);
    public void AddServices(IServiceCollection services, IConfiguration configuration)
    {
        services.AddValidation();
        services.AddScoped<ICatalogStore, PostgresCatalogStore>(); services.AddScoped<CatalogQueries>();
        services.AddScoped<IFoodResolver>(p => p.GetRequiredService<CatalogQueries>());
        services.AddSingleton(new ModuleMigration("catalog", connection => new CatalogContext(DatabaseConfiguration.ContextOptions<CatalogContext>(connection, "catalog"))));
    }
    public void MapEndpoints(RouteGroupBuilder group) => CatalogEndpoints.Map(group);
}
