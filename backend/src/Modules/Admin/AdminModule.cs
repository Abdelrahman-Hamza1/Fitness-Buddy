using System.Threading.RateLimiting;
using FitnessBuddy.BuildingBlocks.Messaging;
using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.Modules.Admin.Api;
using FitnessBuddy.Modules.Admin.Application;
using FitnessBuddy.Modules.Admin.Infrastructure;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Routing;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;

namespace FitnessBuddy.Modules.Admin;

/// <summary>
/// The owner-only admin console (B23, D-099). Called only by the Host's <c>admin</c> role: the public <c>api</c> role never
/// maps these endpoints, so the public listener can't serve <c>/admin</c>. Its tables are global console data, not user data.
/// </summary>
public static class AdminModule
{
    public const string Schema = "admin";

    /// <summary>The path every console route lives under.</summary>
    public const string PathBase = "/admin";

    /// <summary>The admin schema's migrations; the migrate role registers them with the other modules'.</summary>
    public static ModuleMigration Migration { get; } = new(Schema, connection => new AdminContext(DatabaseConfiguration.ContextOptions<AdminContext>(connection, Schema)));

    /// <summary>Every table is console data (sessions, challenges, audit, draft): global, never a user's data.</summary>
    public static UserDataOwnership Ownership { get; } = new([], ["sessions", "challenges", "audit_log", "config_draft"], null);

    /// <summary>The console's options and services (the admin role only). Call after the platform's services.</summary>
    public static void AddAdmin(IServiceCollection services, IConfiguration configuration)
    {
        services.AddOptions<AdminOptions>().Bind(configuration.GetSection(AdminOptions.SectionName)).ValidateDataAnnotations().ValidateOnStart();

        services.AddSingleton<FileAllowList>();
        services.AddSingleton<IAllowList>(provider => provider.GetRequiredService<FileAllowList>());
        services.AddSingleton<ISecretTokens, SecretTokens>();
        services.AddSingleton<IAdminDatabase, AdminDatabase>();
        services.AddSingleton<PostgresAdminStore>();
        services.AddSingleton<IAdminAuthStore>(provider => provider.GetRequiredService<PostgresAdminStore>());
        services.AddSingleton<IAuditLog>(provider => provider.GetRequiredService<PostgresAdminStore>());
        services.AddSingleton<IAuditReader>(provider => provider.GetRequiredService<PostgresAdminStore>());
        services.AddScoped<ListAudit>();
        services.AddSingleton<IConfigDraftStore, PostgresConfigDraftStore>();
        services.AddScoped<ReadConfig>();
        services.AddScoped<SaveConfigDraft>();
        services.AddScoped<DiscardConfigDraft>();
        services.AddScoped<PublishConfig>();
        services.AddScoped<RollbackConfig>();
        services.AddScoped<ExportAudit>();
        services.AddScoped<CredentialCheck>();
        services.AddScoped<StartChallenge>();
        services.AddScoped<SignIn>();
        services.AddScoped<ReAuthenticate>();
        services.AddScoped<SignOut>();
        services.AddScoped<ResolveSession>();
        // B23b monitor windows: Overview, Accounts, Jobs & sync, Catalog.
        services.AddHttpClient(HttpApiHealth.ClientName, client => client.Timeout = TimeSpan.FromSeconds(3))
            .ConfigurePrimaryHttpMessageHandler(() => new HttpClientHandler { AllowAutoRedirect = false, UseCookies = false }).RemoveAllLoggers();
        services.AddSingleton<IApiHealth, HttpApiHealth>();
        services.AddSingleton<IBackupStatus, FileBackupStatus>();
        services.AddScoped<ReadOverview>();
        services.AddScoped<ListAccounts>();
        services.AddScoped<ReadAccount>();
        services.AddScoped<FindAccountByEmail>();
        services.AddScoped<ReadJobsAndSync>();
        services.AddScoped<QueueActions>();
        services.AddScoped<ReadCatalog>();
        services.AddHealthChecks().AddCheck<FileAllowList>("allow-list", tags: ["ready"]);

        // The console's own scheme is the default here (the platform also registers the API's bearer scheme).
        services.AddAuthentication(options =>
            {
                options.DefaultScheme = AdminSessionHandler.SchemeName;
                options.DefaultAuthenticateScheme = AdminSessionHandler.SchemeName;
                options.DefaultChallengeScheme = AdminSessionHandler.SchemeName;
                options.DefaultForbidScheme = AdminSessionHandler.SchemeName;
            })
            .AddScheme<AuthenticationSchemeOptions, AdminSessionHandler>(AdminSessionHandler.SchemeName, null);
        services.AddAuthorizationBuilder()
            .AddPolicy(AdminPolicies.Session, policy => policy.AddAuthenticationSchemes(AdminSessionHandler.SchemeName).RequireAuthenticatedUser()
                .RequireClaim(AdminSessionHandler.RoleClaim, "viewer", "operator"))
            .AddPolicy(AdminPolicies.Operate, policy => policy.AddAuthenticationSchemes(AdminSessionHandler.SchemeName).RequireAuthenticatedUser()
                .RequireClaim(AdminSessionHandler.RoleClaim, "operator"))
            .SetFallbackPolicy(new Microsoft.AspNetCore.Authorization.AuthorizationPolicyBuilder(AdminSessionHandler.SchemeName).RequireAuthenticatedUser()
                .RequireClaim(AdminSessionHandler.RoleClaim, "viewer", "operator").Build());

        // One console instance: an in-memory key ring is enough (a restart only means reloading an open form).
        services.AddDataProtection().UseEphemeralDataProtectionProvider();
        services.AddAntiforgery(options =>
        {
            options.FormFieldName = "__csrf";
            options.HeaderName = "X-CSRF-Token";
            options.Cookie.Name = "fb-admin-csrf";
            options.Cookie.HttpOnly = true;
            options.Cookie.SameSite = SameSiteMode.Strict;
            options.Cookie.SecurePolicy = Microsoft.AspNetCore.Http.CookieSecurePolicy.SameAsRequest;
            options.SuppressXFrameOptionsHeader = true;
        });
        services.AddRazorComponents();
        services.AddRateLimiter(options =>
        {
            options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
            options.AddPolicy(AuthEndpoints.SignInRateLimit, context =>
            {
                var permit = context.RequestServices.GetRequiredService<IOptions<AdminOptions>>().Value.SignInPermitPerMinute;
                return RateLimitPartition.GetFixedWindowLimiter(context.Connection.RemoteIpAddress?.ToString() ?? "unknown",
                    _ => new FixedWindowRateLimiterOptions { PermitLimit = permit, Window = TimeSpan.FromMinutes(1), QueueLimit = 0 });
            });
            options.AddPolicy(AccountEndpoints.LookupRateLimit, context =>
            {
                var permit = context.RequestServices.GetRequiredService<IOptions<AdminOptions>>().Value.LookupPermitPerMinute;
                return RateLimitPartition.GetFixedWindowLimiter(context.Connection.RemoteIpAddress?.ToString() ?? "unknown",
                    _ => new FixedWindowRateLimiterOptions { PermitLimit = permit, Window = TimeSpan.FromMinutes(1), QueueLimit = 0 });
            });
            // Plus one process-wide bucket for the same endpoints, which no forwarded address can multiply.
            options.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(context =>
            {
                var policy = context.GetEndpoint()?.Metadata.GetMetadata<Microsoft.AspNetCore.RateLimiting.EnableRateLimitingAttribute>()?.PolicyName;
                if (policy != AuthEndpoints.SignInRateLimit) { return RateLimitPartition.GetNoLimiter("unlimited"); }
                var total = context.RequestServices.GetRequiredService<IOptions<AdminOptions>>().Value.SignInPermitPerMinuteTotal;
                return RateLimitPartition.GetFixedWindowLimiter("sign-in-total",
                    _ => new FixedWindowRateLimiterOptions { PermitLimit = total, Window = TimeSpan.FromMinutes(1), QueueLimit = 0 });
            });
        });
    }

    /// <summary>The console's middleware, after routing: headers, rate limits, session, CSRF guard, authorization.</summary>
    public static void UseAdmin(IApplicationBuilder app)
    {
        app.UseMiddleware<AdminSecurityHeaders>();
        app.UseRateLimiter();
        app.UseAuthentication();
        app.UseMiddleware<AdminRequestGuard>();
        app.UseAuthorization();
    }

    /// <summary>The console's routes, all under <see cref="PathBase"/>.</summary>
    public static RouteGroupBuilder MapAdmin(IEndpointRouteBuilder app)
    {
        var group = app.MapGroup(PathBase).ExcludeFromDescription();
        AuthEndpoints.Map(group);
        AssetEndpoints.Map(group);
        AuditEndpoints.Map(group);
        OverviewEndpoints.Map(group);
        AccountEndpoints.Map(group);
        JobsEndpoints.Map(group);
        ConfigEndpoints.Map(group);
        return group;
    }

    /// <summary>The configured listener URL, for the role to bind.</summary>
    public static string ListenerUrl(IConfiguration configuration) =>
        configuration.GetSection(AdminOptions.SectionName).Get<AdminOptions>()?.Url ?? new AdminOptions().Url;

    /// <summary>Marks health endpoints as reachable without a session (the fallback policy covers everything else).</summary>
    public static TBuilder AllowWithoutSession<TBuilder>(this TBuilder builder) where TBuilder : IEndpointConventionBuilder =>
        builder.WithCapability(AdminCapability.Anonymous);
}
