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
            ActivityStopped = activity => activities.Enqueue(activity.DisplayName + string.Join('|', activity.TagObjects.Select(t => $"{t.Key}={t.Value}")) + activity.StatusDescription + string.Join('|', activity.Events.Select(e => e.Name + string.Join('|', e.Tags)))),
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
        canaries.Add("CANARY-SYNC-PRIVATE-CONTENT");
        using var discovery = await client.GetAsync("/v1/sync/pull?cursor=0&limit=100", TestContext.Current.CancellationToken);
        var syncPage = await discovery.Content.ReadFromJsonAsync<System.Text.Json.JsonElement>(TestContext.Current.CancellationToken);
        var payload = System.Text.Json.JsonSerializer.Deserialize<Dictionary<string, object?>>(System.Text.Json.JsonDocument.Parse(
            await File.ReadAllTextAsync(Path.Combine(AppContext.BaseDirectory, "entity-payloads.json"), TestContext.Current.CancellationToken)).RootElement.GetProperty("weighIn"))!;
        payload["note"] = canaries[^1];
        foreach (var invalid in new[] { false, true })
        {
            if (invalid) { payload["note"] = canaries[^1] + "\0"; }
            using var push = await client.PostAsJsonAsync("/v1/sync/push", new
            {
                datasetId = syncPage.GetProperty("datasetId").GetGuid(),
                changes = new[] { new { entity = "weighIn", id = Guid.NewGuid(), schemaVersion = 1,
                    hlc = $"{h.Clock.GetUtcNow().ToUnixTimeMilliseconds():D13}-00000-{h.Device}", deviceId = h.Device,
                    deletedAt = (DateTimeOffset?)null, payload } },
            }, TestContext.Current.CancellationToken);
            Assert.Equal(200, (int)push.StatusCode);
            var result = await push.Content.ReadFromJsonAsync<System.Text.Json.JsonElement>(TestContext.Current.CancellationToken);
            Assert.Equal(invalid ? "invalid" : "accepted", result.GetProperty("results")[0].GetProperty("status").GetString());
        }
        using var provider = await client.PostAsJsonAsync("/v1/auth/google", new { idToken = canaries[1] }, TestContext.Current.CancellationToken);
        Assert.Equal(500, (int)provider.StatusCode);
        using var delivery = await client.PostAsJsonAsync("/v1/auth/email/start", new { email = canaries[2], purpose = "signIn" }, TestContext.Current.CancellationToken);
        Assert.Equal(500, (int)delivery.StatusCode);
        canaries.AddRange(["CANARY-PATH-PRIVATE", "cafebabe-0000-7000-8000-000000000777", "CANARY-UNMATCHED-PRIVATE", "CANARY-PATH-QUERY"]);
        await using (var failingFactory = factory.WithWebHostBuilder(builder => builder.ConfigureTestServices(services =>
            services.AddScoped<FitnessBuddy.Modules.UserData.Application.ISyncStore, FailingHistory>())))
        {
            using var historyClient = failingFactory.CreateClient();
            historyClient.DefaultRequestHeaders.Add("X-App-Version", "0.1.0"); historyClient.DefaultRequestHeaders.Add("X-Platform", "android"); historyClient.DefaultRequestHeaders.Add("X-Device-Id", h.Device.ToString());
            historyClient.DefaultRequestHeaders.Authorization = client.DefaultRequestHeaders.Authorization;
            using var failed = await historyClient.GetAsync("/v1/sync/history/CANARY-PATH-PRIVATE/cafebabe-0000-7000-8000-000000000777?cursor=0&limit=1&q=CANARY-PATH-QUERY", TestContext.Current.CancellationToken);
            Assert.Equal(500, (int)failed.StatusCode);
            using var unmatched = await historyClient.GetAsync("/CANARY-UNMATCHED-PRIVATE?q=CANARY-PATH-QUERY", TestContext.Current.CancellationToken); Assert.Equal(404, (int)unmatched.StatusCode);
            await failingFactory.Services.GetRequiredService<IHub>().FlushAsync(TimeSpan.FromSeconds(5));
        }
        canaries.Add("CANARY-CATALOG-PRIVATE");
        using (var search = await client.GetAsync("/v1/foods/search?query=CANARY-CATALOG-PRIVATE&limit=10", TestContext.Current.CancellationToken)) { Assert.Equal(200, (int)search.StatusCode); }
        using (var missingFood = await client.GetAsync("/v1/foods/CANARY-CATALOG-PRIVATE", TestContext.Current.CancellationToken)) { Assert.Equal(404, (int)missingFood.StatusCode); }
        using var erased = await client.DeleteAsync("/v1/me", TestContext.Current.CancellationToken);
        Assert.Equal(204, (int)erased.StatusCode);
        using var afterErasure = await client.GetAsync("/v1/me", TestContext.Current.CancellationToken);
        Assert.Equal(401, (int)afterErasure.StatusCode);
        await factory.Services.GetRequiredService<IHub>().FlushAsync(TimeSpan.FromSeconds(5));
        meter.RecordObservableInstruments();
        // API cannot read even its own audit table directly. Inspect using the schema owner below.
        await using var owner = FitnessBuddy.BuildingBlocks.Persistence.DatabaseConfiguration.CreateSource(postgres.MigratorConnection);
        await using var read = owner.CreateCommand("SELECT row_to_json(a)::text FROM identity.audit a");
        await using var reader = await read.ExecuteReaderAsync(TestContext.Current.CancellationToken);
        var auditLines = new List<string>(); while (await reader.ReadAsync(TestContext.Current.CancellationToken)) { auditLines.Add(reader.GetString(0)); }
        Assert.Contains("operation=push", metrics);
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
    private sealed class FailingHistory : FitnessBuddy.Modules.UserData.Application.ISyncStore
    {
        public Task<FitnessBuddy.Modules.UserData.Domain.PushOutcome?> PushForSessionAsync(FitnessBuddy.Modules.Identity.Contracts.IdentitySession principal, Guid? dataset, IReadOnlyList<FitnessBuddy.Modules.UserData.Domain.SyncVersion> versions, DateTimeOffset now, CancellationToken cancellationToken) => throw new InvalidOperationException("CANARY-PATH-PRIVATE");
        public Task<FitnessBuddy.Modules.UserData.Domain.VersionPage?> PullForSessionAsync(FitnessBuddy.Modules.Identity.Contracts.IdentitySession principal, Guid? dataset, long cursor, int limit, bool history, string? entity, Guid? id, CancellationToken cancellationToken) => throw new InvalidOperationException("CANARY-PATH-PRIVATE");
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
