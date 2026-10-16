using System.Collections.Concurrent;
using System.Diagnostics;
using System.Net;
using FitnessBuddy.Host.Observability;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Npgsql;

namespace FitnessBuddy.Persistence.Tests;

public sealed class RuntimeTests(PostgresFixture database)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    [Fact]
    [Trait("Rule", "08.4-deploys")]
    public async Task Readiness_tracks_database_availability_but_liveness_stays_healthy()
    {
        await using var api = new IdempotencyApi(database, new TestClock());
        using var client = api.CreateClient();
        using (var ready = await client.GetAsync(new Uri("/health/ready", UriKind.Relative), Ct)) { Assert.Equal(HttpStatusCode.OK, ready.StatusCode); }
        await database.PauseAsync();
        try
        {
            using var ready = await client.GetAsync(new Uri("/health/ready", UriKind.Relative), Ct);
            using var live = await client.GetAsync(new Uri("/health/live", UriKind.Relative), Ct);
            Assert.Equal(HttpStatusCode.ServiceUnavailable, ready.StatusCode);
            Assert.Equal("Unhealthy", await ready.Content.ReadAsStringAsync(Ct));
            Assert.Equal(HttpStatusCode.OK, live.StatusCode);
        }
        finally { await database.UnpauseAsync(); }
        using var recovered = await client.GetAsync(new Uri("/health/ready", UriKind.Relative), Ct);
        Assert.Equal(HttpStatusCode.OK, recovered.StatusCode);
    }

    [Fact]
    [Trait("Rule", "09.4-logging")]
    public async Task Database_error_and_SQL_literals_do_not_reach_logs_or_traces_with_broad_listeners()
    {
        const string canary = "CANARY-PRIVATE-FOOD-TEXT";
        var capture = new CaptureLogs();
        var spans = new ConcurrentQueue<string>();
        using var listener = new ActivityListener
        {
            ShouldListenTo = _ => true,
            Sample = (ref ActivityCreationOptions<ActivityContext> _) => ActivitySamplingResult.AllDataAndRecorded,
            SampleUsingParentId = (ref ActivityCreationOptions<string> _) => ActivitySamplingResult.AllDataAndRecorded,
            ActivityStopped = activity => spans.Enqueue(activity.DisplayName + string.Join(',', activity.TagObjects) + activity.StatusDescription + string.Join(',', activity.Events)),
        };
        ActivitySource.AddActivityListener(listener);
        await using var api = new IdempotencyApi(database, new TestClock()).WithWebHostBuilder(builder => builder.ConfigureTestServices(services =>
            services.AddSingleton<ILoggerProvider>(_ => new ScrubbingLoggerProvider(capture))));
        using var client = api.CreateClient();
        using var request = new HttpRequestMessage(HttpMethod.Post, "/v1/_persistence/" + Guid.CreateVersion7() + "?databaseError=true");
        request.Headers.Add("X-App-Version", "0.1.0");
        request.Headers.Add("X-Platform", "android");
        request.Headers.Add("X-Device-Id", "0192a5d4-7c3e-7b1a-9f2e-3c4d5e6f7a8b");
        request.Headers.Add("Test-User", Guid.CreateVersion7().ToString());
        request.Headers.Add("Idempotency-Key", "canary-key");
        using var response = await client.SendAsync(request, Ct);
        Assert.Equal(HttpStatusCode.InternalServerError, response.StatusCode);
        Assert.NotEmpty(capture.Lines);
        Assert.NotEmpty(spans);
        Assert.Contains(capture.Lines, line => line.Contains(nameof(PostgresException), StringComparison.Ordinal));
        Assert.DoesNotContain(canary, string.Join('\n', capture.Lines), StringComparison.Ordinal);
        Assert.DoesNotContain(canary, string.Join('\n', spans), StringComparison.Ordinal);
        Assert.DoesNotContain(canary, await response.Content.ReadAsStringAsync(Ct), StringComparison.Ordinal);
        Assert.DoesNotContain(canary, await database.LogsAsync(), StringComparison.Ordinal);
        // A direct SQL literal would be emitted by a default Npgsql data source under this listener.
        await using var literal = database.App.CreateCommand("SELECT '" + canary + "'");
        Assert.Equal(canary, await literal.ExecuteScalarAsync(Ct));
        Assert.DoesNotContain(canary, string.Join('\n', spans), StringComparison.Ordinal);
    }

    private sealed class CaptureLogs : ILoggerProvider
    {
        public ConcurrentQueue<string> Lines { get; } = new();
        public ILogger CreateLogger(string categoryName) => new Sink(Lines);
        public void Dispose() { }
        private sealed class Sink(ConcurrentQueue<string> lines) : ILogger
        {
            public IDisposable? BeginScope<TState>(TState state) where TState : notnull => null;
            public bool IsEnabled(LogLevel logLevel) => true;
            public void Log<TState>(LogLevel logLevel, EventId eventId, TState state, Exception? exception, Func<TState, Exception?, string> formatter) =>
                lines.Enqueue(formatter(state, exception) + exception + string.Join(',', state as IEnumerable<KeyValuePair<string, object?>> ?? []));
        }
    }
}
