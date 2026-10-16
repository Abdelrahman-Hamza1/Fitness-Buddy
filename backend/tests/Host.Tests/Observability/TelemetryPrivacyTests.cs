using System.Collections.Concurrent;
using System.Diagnostics;
using System.Diagnostics.Metrics;
using FitnessBuddy.Host.Observability;
using FitnessBuddy.Host.Tests.Infrastructure;
using Microsoft.AspNetCore.TestHost;
using Microsoft.AspNetCore.HttpLogging;
using Microsoft.Extensions.ObjectPool;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using OpenTelemetry.Instrumentation.AspNetCore;
using OpenTelemetry.Instrumentation.Http;

namespace FitnessBuddy.Host.Tests.Observability;

[CollectionDefinition("Observability", DisableParallelization = true)]
public sealed class ObservabilityTestGroup;

// Proves 09 §4 / TD-058: synthetic private content must not reach any telemetry surface.
[Collection("Observability")]
[Trait("Rule", "09.4-logging")]
public sealed partial class TelemetryPrivacyTests
{
    internal static readonly string[] Canaries = ["CANARY-BODY", "CANARY-QUERY", "CANARY-EXCEPTION", "CANARY-AUTH", "cafecafe-0000-7000-8000-00000000ca11"];

    [Fact]
    public async Task No_canary_reaches_logs_activity_tags_events_status_or_metric_tags_for_200_400_426_429_500()
    {
        var capture = new CapturingLoggerProvider();
        var activities = new ConcurrentQueue<string>();
        using var listener = new ActivityListener
        {
            ShouldListenTo = _ => true,
            Sample = (ref ActivityCreationOptions<ActivityContext> _) => ActivitySamplingResult.AllDataAndRecorded,
            SampleUsingParentId = (ref ActivityCreationOptions<string> _) => ActivitySamplingResult.AllDataAndRecorded,
            ActivityStopped = activity => activities.Enqueue(Describe(activity)),
        };
        ActivitySource.AddActivityListener(listener);
        var metrics = new ConcurrentQueue<string>();
        using var meter = new MeterListener
        {
            InstrumentPublished = (instrument, receiver) => receiver.EnableMeasurementEvents(instrument),
        };
        meter.SetMeasurementEventCallback<double>((_, _, tags, _) => CaptureTags(tags, metrics));
        meter.SetMeasurementEventCallback<long>((_, _, tags, _) => CaptureTags(tags, metrics));
        meter.SetMeasurementEventCallback<int>((_, _, tags, _) => CaptureTags(tags, metrics));
        meter.Start();
        await using var factory = ApiFactory.With(new Dictionary<string, string?>
        {
            ["RateLimiting:PerIp:PermitLimit"] = "1",
        }).WithWebHostBuilder(builder => builder.ConfigureTestServices(services =>
            services.AddSingleton<ILoggerProvider>(_ => new ScrubbingLoggerProvider(capture))));
        using var client = factory.CreateClient();
        var requests = new[]
        {
            ("/v1/_probe/validate", "0.1.0", 200, "{\"name\":\"CANARY-BODY\",\"items\":[],\"child\":{\"code\":\"ok\"}}"),
            ("/v1/_probe/validate", "0.1.0", 400, "{\"name\":\"CANARY-BODY\",\"items\":[],\"child\":{\"code\":\"much-too-long\"}}"),
            ("/v1/_probe/ok", "0.0.1", 426, "CANARY-BODY"),
            ("/v1/_probe/ok", "0.1.0", 429, "CANARY-BODY"),
            ("/v1/_probe/throw", "0.1.0", 500, "CANARY-BODY"),
        };
        var index = 0;
        foreach (var (path, version, status, body) in requests)
        {
            var peer = $"192.0.2.{++index}";
            if (status == 429)
            {
                using var warmup = await client.FetchAsync(Api.Get("/v1/_probe/ok", peer: peer));
                Assert.Equal(200, (int)warmup.StatusCode);
            }

            using var request = Api.Request(path.EndsWith("validate", StringComparison.Ordinal) ? HttpMethod.Post : HttpMethod.Get,
                path + "?q=CANARY-QUERY", body, version, peer);
            request.Headers.Remove("X-Device-Id");
            request.Headers.Add("X-Device-Id", Canaries[4]);
            request.Headers.Add("Authorization", "Bearer CANARY-AUTH");
            using var response = await client.SendAsync(request, Api.Ct);
            Assert.Equal(status, (int)response.StatusCode);
        }

        meter.RecordObservableInstruments();
        Assert.NotEmpty(capture.Lines);
        Assert.NotEmpty(activities);
        Assert.NotEmpty(metrics);
        AssertClean(string.Join('\n', capture.Lines));
        AssertClean(string.Join('\n', activities));
        AssertClean(string.Join('\n', metrics));
        Assert.Contains(capture.Lines, line => line.Contains(nameof(InvalidOperationException), StringComparison.Ordinal));
    }

    [Fact]
    public async Task Every_logger_provider_is_scrubbed_except_Sentry_and_no_http_logging_or_enrichment_is_registered()
    {
        await using var factory = new ApiFactory();
        _ = factory.CreateClient();
        var providers = factory.Services.GetServices<ILoggerProvider>().ToArray();
        Assert.NotEmpty(providers);
        Assert.Contains(providers, ScrubbingLoggerRegistration.IsSentryProvider);
        Assert.All(providers.OfType<ScrubbingLoggerProvider>(), provider => Assert.False(ScrubbingLoggerRegistration.IsSentryProvider(provider.Inner)));
        Assert.All(providers, provider => Assert.True(provider is ScrubbingLoggerProvider || ScrubbingLoggerRegistration.IsSentryProvider(provider), provider.GetType().FullName));
        var server = factory.Services.GetRequiredService<IOptions<AspNetCoreTraceInstrumentationOptions>>().Value;
        Assert.Null(server.EnrichWithException);
        Assert.Null(server.EnrichWithHttpRequest);
        Assert.Null(server.EnrichWithHttpResponse);
        Assert.False(server.RecordException);
        var http = factory.Services.GetRequiredService<IOptions<HttpClientTraceInstrumentationOptions>>().Value;
        Assert.Null(http.EnrichWithException);
        Assert.Null(http.EnrichWithHttpRequestMessage);
        Assert.Null(http.EnrichWithHttpResponseMessage);
        Assert.False(http.RecordException);
        Assert.Null(factory.Services.GetService<IHttpLoggingInterceptor>());
        Assert.Null(factory.Services.GetService<ObjectPool<HttpLoggingInterceptorContext>>());
    }

    [Fact]
    public void No_options_AddHttpLogging_registers_the_pool_sentinel_even_without_an_interceptor()
    {
        var services = new ServiceCollection();
        services.AddHttpLogging();
        using var provider = services.BuildServiceProvider();
        Assert.NotNull(provider.GetService<ObjectPool<HttpLoggingInterceptorContext>>());
        Assert.Null(provider.GetService<IHttpLoggingInterceptor>());
    }

    [Fact]
    public async Task Request_log_scopes_carry_the_response_trace_id_and_last_line_reaches_sink_before_shutdown()
    {
        var capture = new CapturingLoggerProvider();
        await using (var factory = new ApiFactory().WithWebHostBuilder(builder => builder.ConfigureTestServices(services =>
            services.AddSingleton<ILoggerProvider>(_ => new ScrubbingLoggerProvider(capture)))))
        {
            using var client = factory.CreateClient();
            using var response = await client.FetchAsync(Api.Get("/v1/_probe/throw"));
            Assert.Contains(capture.Lines, line => line.Contains(Api.RequestId(response), StringComparison.Ordinal));
            factory.Services.GetRequiredService<ILoggerFactory>().CreateLogger("ShutdownProbe").Log(LogLevel.Information, new EventId(1), "Last line before shutdown", null, static (state, _) => state);
        }

        // RunAsync and WebApplicationFactory can dispose the same host concurrently. One disposal call
        // may return while the other still drains the provider graph; await the sink's actual signal.
        await capture.Disposal.Task.WaitAsync(TimeSpan.FromSeconds(5), Api.Ct);
        Assert.Contains(capture.Lines, line => line.Contains("Last line before shutdown", StringComparison.Ordinal));
        Assert.True(capture.Disposed);
    }

    [Fact]
    public void ScrubbedException_keeps_type_and_stack_and_drops_messages_recursively_including_aggregates()
    {
        Exception thrown;
        try
        {
            throw new InvalidOperationException("CANARY-EXCEPTION", new AggregateException("CANARY-BODY",
                new ArgumentException("CANARY-QUERY"), new IOException("CANARY-AUTH")));
        }
        catch (InvalidOperationException exception)
        {
            thrown = exception;
        }

        var scrubbed = new ScrubbedException(thrown);
        Assert.Equal(typeof(InvalidOperationException).FullName, scrubbed.Message);
        Assert.Equal(thrown.StackTrace, scrubbed.StackTrace);
        Assert.Contains(typeof(ArgumentException).FullName!, scrubbed.ToString(), StringComparison.Ordinal);
        Assert.Contains(typeof(IOException).FullName!, scrubbed.ToString(), StringComparison.Ordinal);
        AssertClean(scrubbed.ToString());
    }

    [Theory]
    [InlineData("worker")]
    [InlineData("migrate")]
    public void Non_http_roles_use_the_same_scrubbing_boundary(string role)
    {
        var builder = Microsoft.Extensions.Hosting.Host.CreateApplicationBuilder();
        builder.Configuration["Sentry:Dsn"] = "";
        builder.AddFbObservability(role);
        using var host = builder.Build();
        var providers = host.Services.GetServices<ILoggerProvider>().ToArray();
        Assert.Contains(providers, ScrubbingLoggerRegistration.IsSentryProvider);
        Assert.All(providers, provider => Assert.True(provider is ScrubbingLoggerProvider || ScrubbingLoggerRegistration.IsSentryProvider(provider)));
    }

    [Fact]
    public async Task Wrapper_forwards_external_scopes_and_async_disposal()
    {
        var capture = new CapturingLoggerProvider();
        var wrapper = new ScrubbingLoggerProvider(capture);
        var scopes = new LoggerExternalScopeProvider();
        wrapper.SetScopeProvider(scopes);
        using (scopes.Push("safe-scope"))
        {
            wrapper.CreateLogger("test").Log(LogLevel.Information, new EventId(1), "Safe message", null, static (state, _) => state);
        }

        await wrapper.DisposeAsync();
        Assert.True(capture.Disposed);
        Assert.Contains("safe-scope", Assert.Single(capture.Lines), StringComparison.Ordinal);
    }

    internal static void AssertClean(string text)
    {
        foreach (var canary in Canaries)
        {
            Assert.DoesNotContain(canary, text, StringComparison.OrdinalIgnoreCase);
        }
    }

    private static string Describe(Activity activity) =>
        $"{activity.DisplayName} {activity.StatusDescription} {string.Join(';', activity.TagObjects)} "
        + string.Join(';', activity.Events.Select(item => $"{item.Name}:{string.Join(',', item.Tags)}"));

    private static void CaptureTags(ReadOnlySpan<KeyValuePair<string, object?>> tags, ConcurrentQueue<string> target) =>
        target.Enqueue(string.Join(';', tags.ToArray().Select(tag => $"{tag.Key}={tag.Value}")));
}
