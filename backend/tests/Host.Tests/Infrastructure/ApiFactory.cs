using FitnessBuddy.BuildingBlocks.Web.Modules;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace FitnessBuddy.Host.Tests.Infrastructure;

/// <summary>
/// The real api role in environment <c>Testing</c> (production-like: HSTS on, no OpenAPI endpoint), plus the
/// <see cref="ProbeModule"/> and the <see cref="TestPeerStartupFilter"/>. Settings override appsettings.
/// </summary>
public sealed class ApiFactory : WebApplicationFactory<Program>
{
    private readonly Dictionary<string, string?> settings = new(StringComparer.OrdinalIgnoreCase)
    {
        ["Clients:MinimumAppVersion"] = "0.1.0",
        ["ConnectionStrings:Application"] = "Host=127.0.0.1;Port=1;Database=unused;Username=fb_app;Pooling=false",
        // High, so the shared factory never throttles; the rate-limit tests set their own.
        ["RateLimiting:PerIp:PermitLimit"] = "100000",
    };

    public ApiFactory()
    {
    }

    private ApiFactory(IReadOnlyDictionary<string, string?> overrides, string environment)
    {
        foreach (var (key, value) in overrides)
        {
            settings[key] = value;
        }

        Environment = environment;
    }

    public string Environment { get; } = "Testing";

    /// <summary>A factory with its own settings (dispose it in the test).</summary>
    public static ApiFactory With(IReadOnlyDictionary<string, string?> overrides, string environment = "Testing") =>
        new(overrides, environment);

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment(Environment);
        builder.ConfigureAppConfiguration((_, configuration) => configuration.AddInMemoryCollection(settings));
        builder.ConfigureTestServices(services =>
        {
            var probe = new ProbeModule();
            probe.AddServices(services, new ConfigurationBuilder().Build());
            services.AddSingleton<IModule>(probe);
            services.AddSingleton<IStartupFilter, TestPeerStartupFilter>();
        });
    }
}
