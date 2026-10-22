using FitnessBuddy.BuildingBlocks.Jobs;
using FitnessBuddy.BuildingBlocks.Messaging;
using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.BuildingBlocks.Web.Modules;
using FitnessBuddy.Modules.Buddy.Api;
using FitnessBuddy.Modules.Buddy.Application;
using FitnessBuddy.Modules.Buddy.Infrastructure;
using Microsoft.AspNetCore.Routing;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace FitnessBuddy.Modules.Buddy;

/// <summary>Authenticated read-only interpretation with durable paid-send reservations.</summary>
public sealed class BuddyModule : IModule
{
    public string Name => "Buddy";
    public UserDataOwnership UserData => new(["attempts"], [], "buddy.erase");
    public void AddServices(IServiceCollection services, IConfiguration configuration)
    {
        services.AddValidation();
        services.AddOptions<BuddyOptions>().Bind(configuration.GetSection("Buddy"))
            .Validate(o => o.MaxOutputTokens is >= 200 and <= 4000 && o.TimeoutSeconds is >= 1 and <= 30 && o.Concurrency is >= 1 and <= 8
                && o.GuestDailyCalls is >= 1 and <= 100 && o.RegisteredDailyCalls >= o.GuestDailyCalls && o.RegisteredDailyCalls <= 1000
                && (!o.Enabled || Path.IsPathFullyQualified(o.ApiKeyFile)), "Invalid bounded Buddy configuration.").ValidateOnStart();
        services.AddHttpClient("buddy-openai", client => client.Timeout = Timeout.InfiniteTimeSpan)
            .ConfigurePrimaryHttpMessageHandler(() => new HttpClientHandler { AllowAutoRedirect = false });
        services.AddSingleton(BuddyClientRegistration.Create);
        services.AddScoped<IProductionLlmClient, ProductionLlmClient>();
        services.AddScoped<IInterpretLedger, PostgresInterpretLedger>(); services.AddScoped<InterpretMessage>(); services.AddScoped<ResolveInterpretation>();
        services.AddSingleton<BuddyConcurrency>(); services.AddScoped<IOutboxHandler, BuddyErasure>(); services.AddScoped<IJobHandler, BuddyCleanup>();
        services.AddSingleton(new ModuleMigration("buddy", c => new Infrastructure.BuddyContext(DatabaseConfiguration.ContextOptions<Infrastructure.BuddyContext>(c, "buddy"))));
    }
    public void MapEndpoints(RouteGroupBuilder group) => BuddyEndpoints.Map(group);
}
