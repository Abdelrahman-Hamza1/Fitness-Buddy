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

/// <summary>The Buddy agent (turns, label reads): proposals only, content-free ledger and Usage reservations.</summary>
public sealed class BuddyModule : IModule
{
    public string Name => "Buddy";
    public UserDataOwnership UserData => new(["attempts", "turns", "turn_rounds"], [], "buddy.erase");
    public void AddServices(IServiceCollection services, IConfiguration configuration)
    {
        services.AddValidation();
        services.AddOptions<BuddyOptions>().Bind(configuration.GetSection("Buddy"))
            .Validate(o => !o.Enabled || Path.IsPathFullyQualified(o.ApiKeyFile), "Invalid Buddy configuration.").ValidateOnStart();
        services.AddHttpClient("buddy-openai", client => client.Timeout = Timeout.InfiniteTimeSpan)
            .ConfigurePrimaryHttpMessageHandler(() => new HttpClientHandler { AllowAutoRedirect = false });
        services.AddSingleton(BuddyClientRegistration.Create);
        services.AddScoped<IOutboxHandler, BuddyErasure>(); services.AddScoped<IJobHandler, BuddyCleanup>();
        // B25: the agent turn routes (06 §2–§3). The seal key is read lazily; without it the routes answer 503.
        services.AddOptions<BuddyAgentOptions>().Bind(configuration.GetSection("Buddy:Agent"))
            .Validate(o => o.Valid(), "Invalid bounded Buddy agent configuration.").ValidateOnStart();
        services.AddSingleton<IContinuationSealer, AesGcmContinuationSealer>(); services.AddSingleton<AgentConcurrency>(); services.AddSingleton<AttemptFences>();
        services.AddScoped<IAgentLedger, PostgresAgentLedger>(); services.AddScoped<BuddyAgent>();
        services.AddScoped<IAgentModel, ChatClientAgentModel>(); services.AddScoped<ToolRunner>(); services.AddScoped<ServerTools>(); services.AddScoped<ActionTools>(); services.AddScoped<ReplyWriter>();
        services.AddScoped<Exercises>();
        services.AddScoped<ILabelReader, ChatClientLabelReader>(); services.AddScoped<ExtractLabel>();
        services.AddScoped<RunTurn>();
        services.AddSingleton(new ModuleMigration("buddy", c => new Infrastructure.BuddyContext(DatabaseConfiguration.ContextOptions<Infrastructure.BuddyContext>(c, "buddy"))));
    }
    public void MapEndpoints(RouteGroupBuilder group) => BuddyEndpoints.Map(group);
}
