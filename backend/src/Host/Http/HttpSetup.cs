using FitnessBuddy.Host.Platform;
using FitnessBuddy.BuildingBlocks.Web.Idempotency;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;

namespace FitnessBuddy.Host.Http;

/// <summary>The api role's HTTP conventions: services, then the pipeline in the order of S03 plan §3.2.</summary>
internal static class HttpSetup
{
    /// <summary>04 §4.2. Routes that take images (2 MB, later) raise it per endpoint with <c>IRequestSizeLimitMetadata</c>.</summary>
    public const long MaxRequestBodyBytes = 256 * 1024;

    public static WebApplicationBuilder AddFbHttp(this WebApplicationBuilder builder)
    {
        var services = builder.Services;
        var configuration = builder.Configuration;

        var proxy = services.AddOptions<ProxyOptions>().Bind(configuration.GetSection(ProxyOptions.SectionName)).ValidateDataAnnotations();
        var perIp = services.AddOptions<PerIpRateLimitOptions>().Bind(configuration.GetSection(PerIpRateLimitOptions.SectionName)).ValidateDataAnnotations();
        if (!PlatformSetup.IsBuildTimeDocument)
        {
            proxy.ValidateOnStart();
            perIp.ValidateOnStart();
        }

        builder.WebHost.ConfigureKestrel(kestrel =>
        {
            kestrel.AddServerHeader = false;
            kestrel.Limits.MaxRequestBodySize = MaxRequestBodyBytes;
        });

        services.AddFbForwardedHeaders();
        // TLS ends at kamal-proxy, so no HTTPS redirection (the app never follows redirects). No preload or
        // subdomains until the domain is fixed (S05).
        services.AddHsts(options => options.MaxAge = TimeSpan.FromDays(365));

        services.AddSingleton<IProblemDetailsWriter, ApiProblemDetailsWriter>();
        services.AddProblemDetails(options => options.CustomizeProblemDetails = ProblemDetailsCustomizer.Apply);
        services.AddExceptionHandler<UnhandledExceptionHandler>();
        // A client error (unreadable or too large body) is not a server error: no error log or metric for it.
        services.Configure<ExceptionHandlerOptions>(options =>
            options.SuppressDiagnosticsCallback = context => context.Exception is BadHttpRequestException);

        services.AddFbRateLimiting();
        services.AddSingleton<UserRequestLimiter>();
        services.AddHealthChecks();

        return builder;
    }

    public static WebApplication UseFbHttpPipeline(this WebApplication app)
    {
        app.UseForwardedHeaders();
        app.UseMiddleware<RequestIdMiddleware>();
        app.UseExceptionHandler();
        if (!app.Environment.IsDevelopment())
        {
            app.UseHsts();
        }

        app.UseStatusCodePages();
        app.UseRouting();
        app.UseMiddleware<HttpPrivacyMiddleware>();
        app.UseRateLimiter();
        app.UseMiddleware<ClientHeadersMiddleware>();
        app.UseAuthentication();
        app.UseMiddleware<UserRateLimiting>();
        app.UseAuthorization();
        app.UseMiddleware<IdempotencyMiddleware>();

        ForwardedHeadersSetup.LogTrustedNetworks(app);
        return app;
    }

    /// <summary>
    /// Liveness (no checks) and readiness (checks tagged <c>ready</c>; the database from S04), for kamal-proxy.
    /// Outside <c>/v1</c>: no client headers, no rate limit, not in the contract.
    /// </summary>
    public static WebApplication MapFbHealth(this WebApplication app)
    {
        app.MapHealthChecks("/health/live", new HealthCheckOptions { Predicate = _ => false }).ExcludeFromDescription();
        app.MapHealthChecks("/health/ready", new HealthCheckOptions { Predicate = check => check.Tags.Contains("ready") })
            .ExcludeFromDescription();
        return app;
    }
}
