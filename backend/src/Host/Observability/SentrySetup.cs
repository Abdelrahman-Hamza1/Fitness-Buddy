using FitnessBuddy.Host.Platform;
using Sentry.Extensibility;
using Sentry.AspNetCore;
using Sentry.Extensions.Logging;

namespace FitnessBuddy.Host.Observability;

internal static class SentrySetup
{
    public static void Configure(SentryLoggingOptions options, IConfiguration configuration)
    {
        options.Dsn = PlatformSetup.IsBuildTimeDocument ? string.Empty : configuration["Sentry:Dsn"] ?? string.Empty;
        options.SendDefaultPii = false;
        options.TracesSampleRate = 0;
        options.CaptureFailedRequests = false;
        options.AutoSessionTracking = false;
        options.EnableLogs = false;
        options.SetBeforeSendMetric(_ => null);
        options.MinimumEventLevel = LogLevel.Error;
        options.SetBeforeBreadcrumb(_ => null);
        options.SetBeforeSendTransaction(_ => null);
        options.SetBeforeSend(SentryScrubber.Scrub);
        if (options is SentryAspNetCoreOptions web)
        {
            web.IncludeActivityData = false;
            web.MaxRequestBodySize = RequestSize.None;
            web.AutoRegisterTracing = false;
        }
    }
}
