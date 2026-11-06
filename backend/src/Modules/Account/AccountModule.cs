using FitnessBuddy.BuildingBlocks.Web.Modules;
using FitnessBuddy.Modules.Account.Api;
using FitnessBuddy.Modules.Account.Application;
using FitnessBuddy.Modules.Account.Infrastructure;
using FitnessBuddy.BuildingBlocks.Messaging;
using FitnessBuddy.BuildingBlocks.Persistence;
using Microsoft.AspNetCore.Routing;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace FitnessBuddy.Modules.Account;

/// <summary>Client configuration, current account and atomic server erasure.</summary>
public sealed class AccountModule : IModule
{
    public string Name => "Account";
    public FitnessBuddy.BuildingBlocks.Messaging.UserDataOwnership UserData => new(["deletion_requests"], ["config_versions"], "account.erase");

    public void AddServices(IServiceCollection services, IConfiguration configuration)
    {
        services.AddOptions<ClientConfigOptions>().Bind(configuration.GetSection(ClientConfigOptions.SectionName));
        services.AddSingleton<GetClientConfig>();
        // B23: the published remote config replaces the configuration-only minimum version and server flags.
        services.AddOptions<RemoteConfigPollOptions>().Bind(configuration.GetSection(RemoteConfigPollOptions.SectionName));
        services.AddSingleton<RemoteConfigDefaults>();
        services.AddSingleton<RuntimeConfigCache>();
        services.AddSingleton<IRuntimeConfig>(provider => provider.GetRequiredService<RuntimeConfigCache>());
        services.AddSingleton<FitnessBuddy.BuildingBlocks.Clients.IClientCompatibility>(provider => provider.GetRequiredService<RuntimeConfigCache>());
        services.AddSingleton<FitnessBuddy.BuildingBlocks.Features.IFeatureFlags>(provider => provider.GetRequiredService<RuntimeConfigCache>());
        services.AddSingleton<Contracts.IRemoteConfigAdmin, PostgresRemoteConfig>();
        services.AddScoped<DeleteAccount>();
        services.AddScoped<IAccountDeletion, PostgresAccountDeletion>();
        services.AddScoped<IOutboxHandler, AccountErasureHandler>();
        services.AddSingleton(new ModuleMigration("account", connection => new AccountContext(DatabaseConfiguration.ContextOptions<AccountContext>(connection, "account"))));
        // Every module calls this itself: the validation source generator only sees this assembly's endpoints and DTOs.
        services.AddValidation();
    }

    /// <summary>B23: keep the remote config current in a long-running role (api, worker, admin). Not for migrate or build time.</summary>
    public static void AddRuntimeConfigPolling(IServiceCollection services) => services.AddHostedService<RuntimeConfigPoller>();

    /// <summary>B24: run the console's operator deletions. The api role only (it holds what the B06 coordinator needs).</summary>
    public static void AddOperatorDeletionRunner(IServiceCollection services, IConfiguration configuration)
    {
        services.AddOptions<OperatorDeletionOptions>().Bind(configuration.GetSection(OperatorDeletionOptions.SectionName));
        services.AddHostedService<OperatorDeletionRunner>();
    }

    /// <summary>B23: the migrate role seeds version 1 from the canonical defaults when nothing is published yet.</summary>
    public static Task SeedRemoteConfigAsync(string migratorConnection, IServiceProvider services, CancellationToken cancellationToken) =>
        PostgresRemoteConfig.SeedAsync(migratorConnection, services.GetRequiredService<RemoteConfigDefaults>().Current,
            services.GetRequiredService<TimeProvider>().GetUtcNow(), cancellationToken);

    public void MapEndpoints(RouteGroupBuilder group)
    {
        group.MapConfigEndpoints();
        Api.AccountEndpoints.Map(group);
    }
}
