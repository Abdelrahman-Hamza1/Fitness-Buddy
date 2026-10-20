using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.Host.Platform;
using FitnessBuddy.Host.Observability;
using Microsoft.Extensions.Options;

namespace FitnessBuddy.Host.Roles;

/// <summary>Applies schema-owned migrations once under the shared advisory lock, then exits.</summary>
internal static partial class MigrateRole
{
    public static async Task<int> RunAsync(string[] args)
    {
        var builder = Microsoft.Extensions.Hosting.Host.CreateApplicationBuilder(args);
        builder.AddFbPlatform();
        builder.AddFbPersistence(migrate: true);
        builder.AddFbObservability("migrate");
        using var host = builder.Build();
        var logger = host.Services.GetRequiredService<ILoggerFactory>().CreateLogger(typeof(MigrateRole).FullName!);
        var connection = host.Services.GetRequiredService<IOptions<DatabaseOptions>>().Value.Migrator;
        if (string.IsNullOrWhiteSpace(connection))
        {
            LogFailed(logger, "missing-migrator-connection");
            return 1;
        }
        await host.StartAsync();
        try
        {
            var stopping = host.Services.GetRequiredService<IHostApplicationLifetime>().ApplicationStopping;
            await host.Services.GetRequiredService<MigrationRunner>().RunAsync(connection, stopping);
            await FitnessBuddy.BuildingBlocks.Recovery.RecoveryMaintenance.RunAsync(connection,
                host.Services.GetRequiredService<IOptions<FitnessBuddy.BuildingBlocks.Recovery.RecoveryOptions>>().Value,
                host.Services.GetRequiredService<FitnessBuddy.BuildingBlocks.Ids.IIdGenerator>(),
                builder.Configuration.GetValue<bool>("Recovery:Initialize"), async maintenanceToken =>
                {
                    await FitnessBuddy.Modules.UserData.UserDataModule.SeedLegacyCleanupAsync(connection, host.Services.GetRequiredService<TimeProvider>(),
                        host.Services.GetRequiredService<FitnessBuddy.BuildingBlocks.Ids.IIdGenerator>(), maintenanceToken);
                    var catalogDirectory = builder.Configuration["Catalog:ImportDirectory"];
                    if (!string.IsNullOrWhiteSpace(catalogDirectory))
                    { await FitnessBuddy.Modules.Catalog.CatalogModule.ImportAsync(connection, catalogDirectory, maintenanceToken); }
                    var keyOperation = builder.Configuration["Identity:KeyOperation"];
                    if (!string.IsNullOrEmpty(keyOperation))
                    {
                        await FitnessBuddy.Modules.Identity.IdentityModule.MaintainSigningKeysAsync(connection,
                            builder.Configuration["Identity:WrappingKeysDirectory"] ?? "",
                            builder.Configuration["Identity:WrappingVersion"] ?? "v1", keyOperation,
                            host.Services.GetRequiredService<TimeProvider>(), maintenanceToken);
                    }
                    if (builder.Configuration.GetValue<bool>("Sync:RotateDataset"))
                    { await FitnessBuddy.Modules.UserData.UserDataModule.RotateDatasetAsync(connection, maintenanceToken); }
                }, stopping);
            LogCompleted(logger);
            return 0;
        }
        catch (Exception exception)
        {
            LogFailed(logger, exception.GetType().Name);
            return 1;
        }
        finally { await host.StopAsync(); }
    }

    [LoggerMessage(Level = LogLevel.Information, Message = "Database migrations completed")]
    private static partial void LogCompleted(ILogger logger);
    [LoggerMessage(Level = LogLevel.Error, Message = "Database migration failed: {ErrorCode}")]
    private static partial void LogFailed(ILogger logger, string errorCode);
}
