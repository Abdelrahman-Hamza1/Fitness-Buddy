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
    public FitnessBuddy.BuildingBlocks.Messaging.UserDataOwnership UserData => new(["deletion_requests"], [], "account.erase");

    public void AddServices(IServiceCollection services, IConfiguration configuration)
    {
        services.AddOptions<ClientConfigOptions>().Bind(configuration.GetSection(ClientConfigOptions.SectionName));
        services.AddSingleton<GetClientConfig>();
        services.AddScoped<DeleteAccount>();
        services.AddScoped<IAccountDeletion, PostgresAccountDeletion>();
        services.AddScoped<IOutboxHandler, AccountErasureHandler>();
        services.AddSingleton(new ModuleMigration("account", connection => new AccountContext(DatabaseConfiguration.ContextOptions<AccountContext>(connection, "account"))));
        // Every module calls this itself: the validation source generator only sees this assembly's endpoints and DTOs.
        services.AddValidation();
    }

    public void MapEndpoints(RouteGroupBuilder group)
    {
        group.MapConfigEndpoints();
        Api.AccountEndpoints.Map(group);
    }
}
