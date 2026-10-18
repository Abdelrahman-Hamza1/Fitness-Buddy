using System.Collections.Concurrent;
using System.Diagnostics;
using System.Diagnostics.Metrics;
using System.Net.Http.Json;
using System.Text;
using FitnessBuddy.Host.Observability;
using FitnessBuddy.Modules.Identity.Application;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Sentry.AspNetCore;
using Sentry.Extensibility;
using Sentry.Protocol.Envelopes;

namespace FitnessBuddy.Persistence.Tests;

[Trait("Req", "AC-041")]
[Trait("Rule", "09.4-privacy")]
public sealed class IdentityPrivacyTests(PostgresFixture postgres)
{
    [Fact]
    public async Task Auth_success_and_provider_delivery_failures_never_emit_identity_content_to_any_sink()
    {
        await using var h = new IdentityHarness(postgres); await h.InitializeAsync();
        var canaries = new List<string> { "CANARY-IDENTITY-EMAIL@example.invalid", "CANARY-PROVIDER-TOKEN", "CANARY-DELIVERY-EMAIL@example.invalid" };
        var logs = new CaptureLogs(); var activities = new ConcurrentQueue<string>(); var metrics = new ConcurrentQueue<string>(); var transport = new CaptureSentry();
        using var listener = new ActivityListener
        {
            ShouldListenTo = _ => true,
            Sample = (ref ActivityCreationOptions<ActivityContext> _) => ActivitySamplingResult.AllDataAndRecorded,
            SampleUsingParentId = (ref ActivityCreationOptions<string> _) => ActivitySamplingResult.AllDataAndRecorded,
            ActivityStopped = activity => activities.Enqueue(string.Join('|', activity.TagObjects.Select(t => $"{t.Key}={t.Value}")) + activity.StatusDescription + string.Join('|', activity.Events.Select(e => e.Name + string.Join('|', e.Tags)))),
        };
        ActivitySource.AddActivityListener(listener);
        using var meter = new MeterListener { InstrumentPublished = (instrument, receiver) => receiver.EnableMeasurementEvents(instrument) };
        meter.SetMeasurementEventCallback<long>((_, _, tags, _) => { foreach (var tag in tags) { metrics.Enqueue($"{tag.Key}={tag.Value}"); } });
        meter.SetMeasurementEventCallback<double>((_, _, tags, _) => { foreach (var tag in tags) { metrics.Enqueue($"{tag.Key}={tag.Value}"); } });
        meter.SetMeasurementEventCallback<int>((_, _, tags, _) => { foreach (var tag in tags) { metrics.Enqueue($"{tag.Key}={tag.Value}"); } });
        meter.Start();
        await using var factory = new IdentityApiTests.IdentityApi(postgres, h).WithWebHostBuilder(builder =>
        {
            builder.ConfigureAppConfiguration((_, config) => config.AddInMemoryCollection(new Dictionary<string, string?> { ["Sentry:Dsn"] = "https://public@localhost/1" }));
            builder.ConfigureTestServices(services =>
            {
                services.AddSingleton<ILoggerProvider>(_ => new ScrubbingLoggerProvider(logs));
                services.Configure<SentryAspNetCoreOptions>(options => options.Transport = transport);
                services.AddSingleton<IGoogleIdentityVerifier, FailingGoogle>();
                services.AddSingleton<IEmailSender>(new SelectiveEmail(h.Email, canaries));
            });
        });
        using var client = factory.CreateClient();
        client.DefaultRequestHeaders.Add("X-App-Version", "0.1.0"); client.DefaultRequestHeaders.Add("X-Platform", "android"); client.DefaultRequestHeaders.Add("X-Device-Id", h.Device.ToString());
        using var start = await client.PostAsJsonAsync("/v1/auth/email/start", new { email = canaries[0], purpose = "signIn" }, TestContext.Current.CancellationToken);
        Assert.Equal(200, (int)start.StatusCode);
        var code = h.Email.Code; canaries.Add(code);
        using var verify = await client.PostAsJsonAsync("/v1/auth/email/verify", new { challengeId = h.Email.Challenge, code }, TestContext.Current.CancellationToken);
        Assert.Equal(200, (int)verify.StatusCode);
        var issued = (await verify.Content.ReadFromJsonAsync<IssuedTokens>(TestContext.Current.CancellationToken))!;
        canaries.Add(issued.AccessToken); canaries.Add(issued.RefreshToken);
        client.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", issued.AccessToken);
        using var me = await client.GetAsync("/v1/me", TestContext.Current.CancellationToken);
        Assert.Equal(200, (int)me.StatusCode);
        using var provider = await client.PostAsJsonAsync("/v1/auth/google", new { idToken = canaries[1] }, TestContext.Current.CancellationToken);
        Assert.Equal(500, (int)provider.StatusCode);
        using var delivery = await client.PostAsJsonAsync("/v1/auth/email/start", new { email = canaries[2], purpose = "signIn" }, TestContext.Current.CancellationToken);
        Assert.Equal(500, (int)delivery.StatusCode);
        await factory.Services.GetRequiredService<IHub>().FlushAsync(TimeSpan.FromSeconds(5));
        meter.RecordObservableInstruments();
        // API cannot read even its own audit table directly. Inspect using the schema owner below.
        await using var owner = FitnessBuddy.BuildingBlocks.Persistence.DatabaseConfiguration.CreateSource(postgres.MigratorConnection);
        await using var read = owner.CreateCommand("SELECT row_to_json(a)::text FROM identity.audit a");
        await using var reader = await read.ExecuteReaderAsync(TestContext.Current.CancellationToken);
        var auditLines = new List<string>(); while (await reader.ReadAsync(TestContext.Current.CancellationToken)) { auditLines.Add(reader.GetString(0)); }
        Assert.NotEmpty(logs.Lines); Assert.NotEmpty(activities); Assert.NotEmpty(metrics); Assert.NotEmpty(auditLines);
        Assert.Contains(transport.Envelopes, envelope => envelope.Contains("\"exception\"", StringComparison.Ordinal));
        foreach (var canary in canaries)
        {
            Assert.DoesNotContain(canary, string.Join('\n', logs.Lines), StringComparison.OrdinalIgnoreCase);
            Assert.DoesNotContain(canary, string.Join('\n', activities), StringComparison.OrdinalIgnoreCase);
            Assert.DoesNotContain(canary, string.Join('\n', metrics), StringComparison.OrdinalIgnoreCase);
            Assert.DoesNotContain(canary, string.Join('\n', transport.Envelopes), StringComparison.OrdinalIgnoreCase);
            Assert.DoesNotContain(canary, string.Join('\n', auditLines), StringComparison.OrdinalIgnoreCase);
            Assert.DoesNotContain(canary, await postgres.LogsAsync(), StringComparison.OrdinalIgnoreCase);
        }
    }
    private sealed class FailingGoogle : IGoogleIdentityVerifier
    {
        public Task<GoogleIdentity?> VerifyAsync(string idToken, CancellationToken ct) => throw new InvalidOperationException(idToken + " CANARY-IDENTITY-EMAIL@example.invalid");
    }
    private sealed class SelectiveEmail(IdentityHarness.CapturingEmail inner, List<string> canaries) : IEmailSender
    {
        public Task SendAsync(Guid challenge, string address, string code, DateTimeOffset expiresAt, CancellationToken ct)
        {
            if (address.StartsWith("canary-delivery", StringComparison.OrdinalIgnoreCase))
            {
                canaries.Add(code);
                throw new InvalidOperationException(address + " " + code);
            }
            return inner.SendAsync(challenge, address, code, expiresAt, ct);
        }
    }
    private sealed class CaptureSentry : ITransport
    {
        public ConcurrentQueue<string> Envelopes { get; } = new();
        public async Task SendEnvelopeAsync(Envelope envelope, CancellationToken cancellationToken = default)
        {
            using var stream = new MemoryStream(); await envelope.SerializeAsync(stream, null, cancellationToken);
            Envelopes.Enqueue(Encoding.UTF8.GetString(stream.ToArray()));
        }
    }
    private sealed class CaptureLogs : ILoggerProvider
    {
        public ConcurrentQueue<string> Lines { get; } = new();
        public ILogger CreateLogger(string categoryName) => new Logger(this);
        public void Dispose() { }
        private sealed class Logger(CaptureLogs owner) : ILogger
        {
            public IDisposable? BeginScope<TState>(TState state) where TState : notnull => null;
            public bool IsEnabled(LogLevel logLevel) => true;
            public void Log<TState>(LogLevel logLevel, EventId eventId, TState state, Exception? exception, Func<TState, Exception?, string> formatter) => owner.Lines.Enqueue(formatter(state, exception) + " " + exception + " " + state);
        }
    }
}
