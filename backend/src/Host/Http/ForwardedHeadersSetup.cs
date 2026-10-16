using System.Net;
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.Extensions.Options;

namespace FitnessBuddy.Host.Http;

/// <summary>
/// <c>X-Forwarded-For</c>/<c>-Proto</c> from one proxy hop (kamal-proxy overwrites them), trusted only from loopback
/// and <c>Proxy:TrustedNetworks</c> (S03 plan D11). Never <c>ASPNETCORE_FORWARDEDHEADERS_ENABLED</c>: it trusts everyone.
/// </summary>
internal static partial class ForwardedHeadersSetup
{
    public static IServiceCollection AddFbForwardedHeaders(this IServiceCollection services)
    {
        services.AddOptions<ForwardedHeadersOptions>()
            .Configure<IOptions<ProxyOptions>>((options, proxy) =>
            {
                options.ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto;
                options.ForwardLimit = 1;
                foreach (var network in proxy.Value.GetTrustedNetworks())
                {
                    options.KnownIPNetworks.Add(network);
                }
            });
        return services;
    }

    /// <summary>Logs the trusted networks (configuration only, no client addresses), so a wrong trust list is visible.</summary>
    public static void LogTrustedNetworks(WebApplication app)
    {
        var options = app.Services.GetRequiredService<IOptions<ForwardedHeadersOptions>>().Value;
        var logger = app.Services.GetRequiredService<ILoggerFactory>().CreateLogger(typeof(ForwardedHeadersSetup).FullName!);
        LogTrusted(logger, options.KnownIPNetworks, options.KnownProxies);
    }

    [LoggerMessage(Level = LogLevel.Information, Message = "Forwarded headers trusted from networks {Networks} and proxies {Proxies}")]
    private static partial void LogTrusted(ILogger logger, IEnumerable<System.Net.IPNetwork> networks, IEnumerable<IPAddress> proxies);
}
