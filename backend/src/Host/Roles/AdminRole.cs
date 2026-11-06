using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.Host.Http;
using FitnessBuddy.Host.Observability;
using FitnessBuddy.Host.Platform;
using FitnessBuddy.Modules.Admin;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.Extensions.Options;

namespace FitnessBuddy.Host.Roles;

/// <summary>
/// The <c>admin</c> role (B23, D-099): the owner-only console on its own loopback listener with the fb_admin login.
/// It maps only <c>/admin</c> and health, never <c>/v1</c>; the <c>api</c> role never maps the console.
/// </summary>
internal static class AdminRole
{
    public static async Task<int> RunAsync(string[] args)
    {
        await using var app = Build(args);
        await app.RunAsync();
        return 0;
    }

    /// <summary>Builds the role's app. Tests pass <paramref name="configure"/> to use a test server and settings.</summary>
    internal static WebApplication Build(string[] args, Action<WebApplicationBuilder>? configure = null)
    {
        var builder = WebApplication.CreateBuilder(args);
        builder.AddFbPlatform();
        builder.Services.AddOptions<DatabaseOptions>().BindConfiguration("ConnectionStrings")
            .Validate(settings => !string.IsNullOrWhiteSpace(settings.Admin), "ConnectionStrings:Admin is required.").ValidateOnStart();
        builder.Services.AddFbDatabase(provider => provider.GetRequiredService<IOptions<DatabaseOptions>>().Value.Admin);
        builder.Services.AddHealthChecks().AddCheck<DatabaseReadiness>("database", tags: ["ready"]);
        // The codes the console shows as they are; tests add their own handler types (B23b).
        builder.Services.AddSingleton(FitnessBuddy.BuildingBlocks.Ops.QueueVocabulary.Default);
        builder.Services.AddSingleton<FitnessBuddy.BuildingBlocks.Ops.IOpsAdministration>(provider => new FitnessBuddy.BuildingBlocks.Ops.PostgresOpsAdministration(
            provider.GetRequiredService<Npgsql.NpgsqlDataSource>(), provider.GetRequiredService<FitnessBuddy.BuildingBlocks.Ops.QueueVocabulary>()));
        builder.AddFbObservability("admin");

        var proxy = builder.Services.AddOptions<ProxyOptions>().Bind(builder.Configuration.GetSection(ProxyOptions.SectionName)).ValidateDataAnnotations();
        proxy.ValidateOnStart();
        builder.Services.AddFbForwardedHeaders();
        builder.WebHost.ConfigureKestrel(kestrel =>
        {
            kestrel.AddServerHeader = false;
            kestrel.Limits.MaxRequestBodySize = 64 * 1024;
        });
        builder.WebHost.UseUrls(AdminModule.ListenerUrl(builder.Configuration));

        AdminModule.AddAdmin(builder.Services, builder.Configuration);
        FitnessBuddy.Modules.Account.AccountModule.AddRuntimeConfigPolling(builder.Services);
        configure?.Invoke(builder);

        var app = builder.Build();
        app.UseForwardedHeaders();
        app.UseMiddleware<RequestIdMiddleware>();
        // Console errors are HTML without internals; the API's problem details don't apply here (B23 P1).
        app.UseExceptionHandler(error => error.Run(async context =>
        {
            context.Response.StatusCode = StatusCodes.Status500InternalServerError;
            context.Response.ContentType = "text/plain; charset=utf-8";
            await context.Response.WriteAsync("Something went wrong. Trace " + context.TraceIdentifier + ".");
        }));
        app.UseRouting();
        app.UseMiddleware<HttpPrivacyMiddleware>();
        AdminModule.UseAdmin(app);
        app.MapHealthChecks("/health/live", new HealthCheckOptions { Predicate = _ => false }).AllowWithoutSession();
        app.MapHealthChecks("/health/ready", new HealthCheckOptions { Predicate = check => check.Tags.Contains("ready") }).AllowWithoutSession();
        AdminModule.MapAdmin(app);
        return app;
    }
}
