using FitnessBuddy.BuildingBlocks.Jobs;
using FitnessBuddy.BuildingBlocks.Messaging;
using FitnessBuddy.BuildingBlocks.Persistence;
using Microsoft.Extensions.Options;

namespace FitnessBuddy.Host.Platform;

internal sealed class DatabaseOptions
{
    public string Application { get; set; } = "";
    public string Migrator { get; set; } = "";
}

internal static class PersistenceSetup
{
    public static void AddFbPersistence(this IHostApplicationBuilder builder, bool migrate = false)
    {
        var options = builder.Services.AddOptions<DatabaseOptions>().BindConfiguration("ConnectionStrings");
        if (!migrate && !PlatformSetup.IsBuildTimeDocument)
        {
            options.Validate(settings => !string.IsNullOrWhiteSpace(settings.Application), "ConnectionStrings:Application is required.").ValidateOnStart();
        }
        builder.Services.AddFbDatabase(provider => provider.GetRequiredService<IOptions<DatabaseOptions>>().Value.Application);
        builder.Services.AddSingleton<MigrationRunner>();
        builder.Services.AddScoped<QueueWriter>();
        builder.Services.AddSingleton(new QueuePolicy());
        builder.Services.AddScoped<QueueProcessor>();
        builder.Services.AddSingleton<JobScheduler>();
        builder.Services.AddScoped<IJobHandler, OpsCleanupJob>();
        builder.Services.AddHealthChecks().AddCheck<DatabaseReadiness>("database", tags: ["ready"]);
    }
}
