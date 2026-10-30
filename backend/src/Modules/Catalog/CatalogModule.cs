using FitnessBuddy.BuildingBlocks.Jobs;
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

/// <summary>Global, release-published food catalog, plus the licence-isolated Open Food Facts barcode cache (B10a).</summary>
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
        services.AddOptions<OffOptions>().Bind(configuration.GetSection("Catalog:OpenFoodFacts"))
            .Validate(o => o.IsValid(), "Invalid bounded Open Food Facts configuration.").ValidateOnStart();
        services.AddHttpClient(OpenFoodFactsClient.HttpClientName, client => client.Timeout = Timeout.InfiniteTimeSpan)
            .ConfigurePrimaryHttpMessageHandler(() => new HttpClientHandler { AllowAutoRedirect = false, UseCookies = false })
            // The framework's request logs would print the product path, which carries the barcode (B10a D7).
            .RemoveAllLoggers();
        services.AddSingleton<OffGate>();
        services.AddScoped<IOffClient, OpenFoodFactsClient>(); services.AddScoped<IOffCache, PostgresOffCache>(); services.AddScoped<BarcodeLookup>();
        services.AddScoped<IJobHandler, OffCacheExpiryJob>(); services.AddSingleton(OffCacheExpiryJob.Schedule);
        services.AddSingleton(new ModuleMigration("catalog", connection => new CatalogContext(DatabaseConfiguration.ContextOptions<CatalogContext>(connection, "catalog"))));
    }
    public void MapEndpoints(RouteGroupBuilder group) => CatalogEndpoints.Map(group);
}
