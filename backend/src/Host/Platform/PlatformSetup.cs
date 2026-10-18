using System.Reflection;
using FitnessBuddy.BuildingBlocks.Auth;
using FitnessBuddy.BuildingBlocks.Clients;
using FitnessBuddy.BuildingBlocks.Features;
using FitnessBuddy.BuildingBlocks.Ids;
using FitnessBuddy.BuildingBlocks.Web.Modules;

namespace FitnessBuddy.Host.Platform;

/// <summary>What the api and worker roles share: options, time, ids, flags, the current user and the modules' services.</summary>
internal static class PlatformSetup
{
    /// <summary>Under Kamal's default 30 s stop wait, so in-flight requests drain before the container is killed.</summary>
    private static readonly TimeSpan ShutdownTimeout = TimeSpan.FromSeconds(25);

    /// <summary>
    /// True while the build generates the OpenAPI document (it runs Program inside GetDocument.Insider). Startup
    /// work with side effects or that needs real configuration is skipped then (backend/README.md).
    /// </summary>
    public static bool IsBuildTimeDocument { get; } = Assembly.GetEntryAssembly()?.GetName().Name == "GetDocument.Insider";

    public static IHostApplicationBuilder AddFbPlatform(this IHostApplicationBuilder builder)
    {
        var identityConfig = Environment.GetEnvironmentVariable("FB_IDENTITY_CONFIG_FILE");
        if (!IsBuildTimeDocument && !string.IsNullOrEmpty(identityConfig))
        {
            if (!Path.IsPathFullyQualified(identityConfig)) { throw new InvalidOperationException("Identity config path must be absolute."); }
            builder.Configuration.AddJsonFile(identityConfig, optional: false, reloadOnChange: false);
        }
        var services = builder.Services;
        var configuration = builder.Configuration;

        services.Configure<HostOptions>(options => options.ShutdownTimeout = ShutdownTimeout);

        var compatibility = services.AddOptions<ClientCompatibilityOptions>()
            .Bind(configuration.GetSection(ClientCompatibilityOptions.SectionName))
            .ValidateDataAnnotations();
        if (!IsBuildTimeDocument)
        {
            compatibility.ValidateOnStart();
        }

        services.AddOptions<FeatureFlagsOptions>()
            .Configure(options => configuration.GetSection(FeatureFlagsOptions.SectionName).Bind(options.Flags));

        services.AddSingleton(TimeProvider.System);
        services.AddSingleton<IIdGenerator, UuidV7IdGenerator>();
        services.AddSingleton<IFeatureFlags, OptionsFeatureFlags>();
        services.AddHttpContextAccessor();
        services.AddScoped<ICurrentUser, HttpCurrentUser>();

        foreach (var module in ModuleCatalog.All)
        {
            module.AddServices(services, configuration);
            services.AddSingleton<IModule>(module);
        }

        return builder;
    }
}
