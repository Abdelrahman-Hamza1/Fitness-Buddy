using FitnessBuddy.BuildingBlocks.Web.Modules;
using FitnessBuddy.Modules.Account.Api;
using FitnessBuddy.Modules.Account.Application;
using Microsoft.AspNetCore.Routing;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace FitnessBuddy.Modules.Account;

/// <summary>The Account module: <c>GET /v1/config</c> now, <c>/v1/me</c> later.</summary>
public sealed class AccountModule : IModule
{
    public string Name => "Account";

    public void AddServices(IServiceCollection services, IConfiguration configuration)
    {
        services.AddOptions<ClientConfigOptions>().Bind(configuration.GetSection(ClientConfigOptions.SectionName));
        services.AddSingleton<GetClientConfig>();
        // Every module calls this itself: the validation source generator only sees this assembly's endpoints and DTOs.
        services.AddValidation();
    }

    public void MapEndpoints(RouteGroupBuilder group)
    {
        group.MapConfigEndpoints();
        Api.AccountEndpoints.Map(group);
    }
}
