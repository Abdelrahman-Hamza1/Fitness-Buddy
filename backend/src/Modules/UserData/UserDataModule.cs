using FitnessBuddy.BuildingBlocks.Jobs;
using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.BuildingBlocks.Web.Modules;
using FitnessBuddy.Modules.UserData.Api;
using FitnessBuddy.Modules.UserData.Application;
using FitnessBuddy.Modules.UserData.Infrastructure;
using Microsoft.AspNetCore.Routing;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace FitnessBuddy.Modules.UserData;

/// <summary>Registered-user document sync with contract validation and recoverable immutable versions.</summary>
public sealed class UserDataModule : IModule
{
    public string Name => "UserData";
    public FitnessBuddy.BuildingBlocks.Messaging.UserDataOwnership UserData => new(["documents", "row_history", "version_receipts"], ["dataset"], "userdata.erase");

    /// <summary>Operator-only: rotate after rollback restore, before opening traffic. Ordinary restarts retain the dataset.</summary>
    public static async Task RotateDatasetAsync(string migratorConnection, CancellationToken cancellationToken)
    {
        await using var source = DatabaseConfiguration.CreateSource(migratorConnection);
        await using var command = source.CreateCommand("UPDATE userdata.dataset SET id=gen_random_uuid() WHERE singleton");
        await command.ExecuteNonQueryAsync(cancellationToken);
    }


    /// <summary>Migration-role maintenance seeds recurring cleanup for pre-B05 owners.</summary>
    public static Task SeedLegacyCleanupAsync(string migratorConnection, TimeProvider clock, FitnessBuddy.BuildingBlocks.Ids.IIdGenerator ids, CancellationToken cancellationToken) =>
        SyncMaintenance.SeedAsync(migratorConnection, clock, ids, cancellationToken);

    public void AddServices(IServiceCollection services, IConfiguration configuration)
    {
        services.AddValidation();
        services.AddScoped<SyncService>();
        services.AddSingleton<ISyncTelemetry, SyncTelemetry>();
        services.AddScoped<IJobHandler, SyncRetentionJob>();
        services.AddScoped<ISyncStore, PostgresSyncStore>();
        services.AddScoped<FitnessBuddy.BuildingBlocks.Messaging.IOutboxHandler, UserDataErasure>();
        services.AddSingleton(new ModuleMigration("userdata", connection => new UserDataContext(DatabaseConfiguration.ContextOptions<UserDataContext>(connection, "userdata"))));
    }

    public void MapEndpoints(RouteGroupBuilder group) => group.MapSyncEndpoints();
}
