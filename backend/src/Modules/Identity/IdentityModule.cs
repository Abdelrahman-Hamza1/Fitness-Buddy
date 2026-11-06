using FitnessBuddy.BuildingBlocks.Web.Modules;
using FitnessBuddy.Modules.Identity.Api;
using FitnessBuddy.Modules.Identity.Application;
using FitnessBuddy.Modules.Identity.Contracts;
using FitnessBuddy.Modules.Identity.Infrastructure;
using FitnessBuddy.BuildingBlocks.Persistence;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Routing;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace FitnessBuddy.Modules.Identity;

/// <summary>B04 identity and session boundary.</summary>
public sealed class IdentityModule : IModule
{
    public string Name => "Identity";
    public FitnessBuddy.BuildingBlocks.Messaging.UserDataOwnership UserData => new(["users", "identities", "devices", "sessions", "refresh_tokens", "email_challenges", "audit", "throttles", "operator_deletions"], ["signing_keys"], "identity.erase");

    /// <summary>Operator-only entry point; call with migration credentials, never from the API.</summary>
    public static Task MaintainSigningKeysAsync(string migratorConnection, string keysDirectory, string version, string operation, TimeProvider clock, CancellationToken cancellationToken) =>
        SigningKeyMaintenance.RunAsync(migratorConnection, keysDirectory, version, operation, clock, cancellationToken);
    public void AddServices(IServiceCollection services, IConfiguration configuration)
    {
        services.AddValidation();
        services.AddScoped<IdentityBearerEvents>();
        services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme).AddJwtBearer(options =>
        {
            options.MapInboundClaims = false;
            options.IncludeErrorDetails = false;
            options.EventsType = typeof(IdentityBearerEvents);
        });
        services.AddAuthorizationBuilder()
            .AddPolicy("any-user", policy => policy.RequireAuthenticatedUser())
            .AddPolicy("registered-user", policy => policy.RequireAuthenticatedUser().RequireAssertion(context =>
                context.Resource is HttpContext http && http.Features.Get<IdentitySession>() is { IsAnonymous: false }));
        services.Configure<IdentityOptions>(configuration.GetSection("Identity"));
        services.AddScoped<IIdentityStore, PostgresIdentityStore>();
        services.AddScoped<IIdentityAccess>(provider => provider.GetRequiredService<IIdentityStore>());
        services.AddScoped<FitnessBuddy.BuildingBlocks.Auth.IUserLifecycle>(provider => (PostgresIdentityStore)provider.GetRequiredService<IIdentityStore>());
        services.AddScoped<IDeviceActivity>(provider => (PostgresIdentityStore)provider.GetRequiredService<IIdentityStore>());
        services.AddSingleton<IIdentityAdminReads, PostgresIdentityAdminReads>();
        // B24: console controls (on the console's session) and the api role's operator-deletion runner side.
        services.AddSingleton<IIdentityAdminControls, PostgresIdentityAdminControls>();
        services.AddSingleton<IIdentityOperatorDeletions, PostgresOperatorDeletions>();
        services.AddScoped<IdentityErasure>();
        services.AddScoped<IIdentityDeletion>(provider => provider.GetRequiredService<IdentityErasure>());
        services.AddScoped<FitnessBuddy.BuildingBlocks.Messaging.IOutboxHandler>(provider => provider.GetRequiredService<IdentityErasure>());
        services.AddScoped<IIdentityTokens, IdentityTokens>();
        services.AddScoped<IdentityService>();
        services.AddSingleton<IEmailSender, LocalFileEmailSender>();
        services.AddHostedService<EmailFileReaper>();
        services.AddHttpClient("google-identity", client => client.Timeout = TimeSpan.FromSeconds(5));
        // One verifier instance (one JWKS cache) behind the app port and the public contract the console uses (B23).
        services.AddSingleton(provider => new GoogleIdentityVerifier(
            provider.GetRequiredService<IHttpClientFactory>().CreateClient("google-identity"),
            provider.GetRequiredService<Microsoft.Extensions.Options.IOptions<IdentityOptions>>(), provider.GetRequiredService<TimeProvider>()));
        services.AddSingleton<IGoogleIdentityVerifier>(provider => provider.GetRequiredService<GoogleIdentityVerifier>());
        services.AddSingleton<IGoogleIdTokenVerifier>(provider => provider.GetRequiredService<GoogleIdentityVerifier>());
        services.AddSingleton(new ModuleMigration("identity", connection => new IdentityContext(DatabaseConfiguration.ContextOptions<IdentityContext>(connection, "identity"))));
    }
    public static void MapPublicEndpoints(IEndpointRouteBuilder app) => IdentityEndpoints.MapPublicEndpoints(app);

    public void MapEndpoints(RouteGroupBuilder group) => group.MapIdentityEndpoints();
}
