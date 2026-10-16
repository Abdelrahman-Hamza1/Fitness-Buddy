using System.Reflection;
using FitnessBuddy.Host.Platform;
using OpenTelemetry.Exporter;
using OpenTelemetry;
using OpenTelemetry.Logs;
using OpenTelemetry.Metrics;
using OpenTelemetry.Resources;
using OpenTelemetry.Trace;

namespace FitnessBuddy.Host.Observability;

internal static class ObservabilitySetup
{
    public static void AddFbObservability(this IHostApplicationBuilder builder, string role)
    {
        builder.Services.AddOptions<ObservabilityOptions>().BindConfiguration(ObservabilityOptions.SectionName);
        builder.Logging.ClearProviders();
        builder.Logging.AddJsonConsole(options =>
        {
            options.UseUtcTimestamp = true;
            options.TimestampFormat = "yyyy-MM-dd'T'HH:mm:ss.fff'Z'";
            options.IncludeScopes = true;
        });
        builder.Services.Configure<LoggerFactoryOptions>(options =>
            options.ActivityTrackingOptions = ActivityTrackingOptions.TraceId | ActivityTrackingOptions.SpanId);
        builder.Logging.AddOpenTelemetry(options =>
        {
            options.IncludeScopes = true;
            options.IncludeFormattedMessage = true;
        });

        if (builder is WebApplicationBuilder web)
        {
            web.WebHost.UseSentry(options => SentrySetup.Configure(options, builder.Configuration));
        }
        else
        {
            builder.Logging.AddSentry(options => SentrySetup.Configure(options, builder.Configuration));
        }

        var telemetry = builder.Services.AddOpenTelemetry()
            .ConfigureResource(resource => resource.AddService(
                    builder.Configuration["OTEL_SERVICE_NAME"] ?? $"fitness-buddy-{role}",
                    serviceVersion: Assembly.GetExecutingAssembly().GetName().Version?.ToString())
                .AddAttributes([new KeyValuePair<string, object>("deployment.environment.name", builder.Environment.EnvironmentName)]))
            .WithTracing(traces => traces
                .AddSource("FitnessBuddy.Buddy")
                .AddAspNetCoreInstrumentation(options =>
                {
                    options.Filter = context => !context.Request.Path.StartsWithSegments("/health");
                    options.RecordException = false;
                })
                .AddHttpClientInstrumentation(options => options.RecordException = false))
            .WithMetrics(metrics => metrics.AddMeter("FitnessBuddy.Buddy").AddAspNetCoreInstrumentation().AddHttpClientInstrumentation().AddRuntimeInstrumentation());

        if (!PlatformSetup.IsBuildTimeDocument)
        {
            var options = builder.Configuration.GetSection(ObservabilityOptions.SectionName).Get<ObservabilityOptions>();
            if (builder.Environment.IsDevelopment() && options?.ConsoleExporter == true)
            {
                telemetry.WithTracing(traces => traces.AddConsoleExporter())
                    .WithMetrics(metrics => metrics.AddConsoleExporter());
            }

            if (!string.IsNullOrWhiteSpace(builder.Configuration["OTEL_EXPORTER_OTLP_ENDPOINT"]))
            {
                var protocol = builder.Configuration["OTEL_EXPORTER_OTLP_PROTOCOL"] switch
                {
                    null or "http/protobuf" => OtlpExportProtocol.HttpProtobuf,
                    "grpc" => OtlpExportProtocol.Grpc,
                    _ => throw new InvalidOperationException("Unsupported OTLP protocol."),
                };
                telemetry.UseOtlpExporter(protocol, new Uri(builder.Configuration["OTEL_EXPORTER_OTLP_ENDPOINT"]!, UriKind.Absolute));
            }
        }

        builder.Services.ScrubLoggerProviders();
    }
}
