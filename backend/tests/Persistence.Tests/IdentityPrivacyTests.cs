using System.Collections.Concurrent;
using System.Diagnostics;
using System.Diagnostics.Metrics;
using System.Net.Http.Json;
using System.Text;
using System.Text.Encodings.Web;
using System.Text.Json;
using System.Text.Json.Nodes;
using System.Net;
using FitnessBuddy.Host.Observability;
using FitnessBuddy.Modules.Identity.Application;
using FitnessBuddy.TestData;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Sentry.AspNetCore;
using Sentry.Extensibility;
using Sentry.Protocol.Envelopes;

namespace FitnessBuddy.Persistence.Tests;

[Trait("Req", "AC-041")]
[Trait("Req", "AC-040")]
[Trait("Rule", "09.4-privacy")]
public sealed class IdentityPrivacyTests(PostgresFixture postgres)
{
    [Fact]
    public async Task Auth_success_and_provider_delivery_failures_never_emit_identity_content_to_any_sink()
    {
        await using var h = new IdentityHarness(postgres); await h.InitializeAsync();
        var canaries = new List<string> { "CANARY-IDENTITY-EMAIL@example.invalid", "CANARY-PROVIDER-TOKEN", "CANARY-DELIVERY-EMAIL@example.invalid" };
        using var capture = new SinkCapture();
        var (logs, activities, metrics, transport) = (capture.Logs, capture.Activities, capture.Metrics, capture.Transport);
        await using var factory = capture.Configure(new IdentityApiTests.IdentityApi(postgres, h), services =>
        {
            services.AddSingleton<IGoogleIdentityVerifier, FailingGoogle>();
            services.AddSingleton<IEmailSender>(new SelectiveEmail(h.Email, canaries));
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
        // B17: real success/rejection/read traffic, with a unique canary in every
        // private field class. Only owner pull/history may return this content.
        var foodCanaries = new[] { "CANARY-PERSONAL-NAME", "طعام-سري-خاص", "CANARY-PERSONAL-ALIAS", "CANARY-PERSONAL-BRAND", "96385074", "817.26491", "732.83419", "30.91827" };
        canaries.AddRange(foodCanaries);
        var foodPayload = JsonNode.Parse(PersonalFoodHttp.Fixture())!.AsObject();
        foodPayload["nameEn"] = foodCanaries[0]; foodPayload["nameAr"] = foodCanaries[1];
        foodPayload["aliasesJson"] = JsonSerializer.Serialize(new[] { foodCanaries[2] }); foodPayload["brand"] = foodCanaries[3];
        foodPayload["barcodesJson"] = "[\"96385074\"]"; foodPayload["per100Kcal"] = 817.26491m;
        foodPayload["per100ExtrasJson"] = "{\"sodium\":732.83419}"; foodPayload["entryServingAmount"] = 30.91827m;
        var privateRow = PersonalFoodHttp.NewRow(h, foodPayload.ToJsonString());
        var dataset = syncPage.GetProperty("datasetId").GetGuid();
        foreach (var invalid in new[] { false, true })
        {
            var raw = invalid ? privateRow.Raw.Replace("CANARY-PERSONAL-NAME", "", StringComparison.Ordinal) : privateRow.Raw;
            using var response = await PersonalFoodHttp.Push(client, h, dataset, [privateRow with { Id = invalid ? Guid.NewGuid() : privateRow.Id, Raw = raw }]);
            Assert.Equal(HttpStatusCode.OK, response.StatusCode);
            var ack = await PersonalFoodHttp.Json(response);
            Assert.Equal(invalid ? "invalidPayload" : null, ack.GetProperty("results")[0].GetProperty("reason").GetString());
            foreach (var canary in foodCanaries) { Assert.DoesNotContain(canary, ack.GetRawText(), StringComparison.Ordinal); }
        }
        using (var update = await PersonalFoodHttp.Push(client, h, dataset, [privateRow with { Hlc = PersonalFoodHttp.Hlc(h, 1) }]))
        { Assert.Equal(HttpStatusCode.OK, update.StatusCode); }
        var pulled = (await PersonalFoodHttp.Page(client, dataset)).GetProperty("changes").EnumerateArray().Single(c => c.GetProperty("id").GetGuid() == privateRow.Id);
        using (var expected = JsonDocument.Parse(privateRow.Raw)) { Assert.True(JsonElement.DeepEquals(expected.RootElement, pulled.GetProperty("payload"))); }
        Assert.Single((await PersonalFoodHttp.Page(client, dataset, privateRow.Id)).GetProperty("changes").EnumerateArray());
        // Unreadable outer JSON is a fixed 400, not a semantic per-row failure.
        using (var malformedBody = new StringContent(PersonalFoodHttp.Body(h, dataset, [privateRow]).Replace("817.26491", "NaN", StringComparison.Ordinal), Encoding.UTF8, "application/json"))
        using (var malformed = await client.PostAsync("/v1/sync/push", malformedBody, TestContext.Current.CancellationToken))
        {
            Assert.Equal(HttpStatusCode.BadRequest, malformed.StatusCode);
            var problem = await malformed.Content.ReadAsStringAsync(TestContext.Current.CancellationToken);
            foreach (var canary in foodCanaries) { Assert.DoesNotContain(canary, problem, StringComparison.Ordinal); }
        }
        using (var guestClient = await PersonalFoodHttp.Client(factory, h, await h.GuestAsync()))
        using (var denied = await PersonalFoodHttp.Push(guestClient, h, dataset, [privateRow]))
        {
            Assert.Equal(HttpStatusCode.Forbidden, denied.StatusCode);
            foreach (var canary in foodCanaries) { Assert.DoesNotContain(canary, await denied.Content.ReadAsStringAsync(TestContext.Current.CancellationToken), StringComparison.Ordinal); }
        }
        // TestServer has no body limit: this request must reach actual Kestrel.
        await using (var kestrelFactory = factory.WithWebHostBuilder(_ => { }))
        {
            kestrelFactory.UseKestrel(0);
            using var limited = kestrelFactory.CreateClient();
            limited.DefaultRequestHeaders.Add("X-App-Version", "0.1.0"); limited.DefaultRequestHeaders.Add("X-Platform", "android"); limited.DefaultRequestHeaders.Add("X-Device-Id", h.Device.ToString());
            limited.DefaultRequestHeaders.Authorization = client.DefaultRequestHeaders.Authorization;
            foodPayload["nameEn"] = foodCanaries[0] + new string('x', 300 * 1024);
            using var oversized = await PersonalFoodHttp.Push(limited, h, dataset, [privateRow with { Raw = foodPayload.ToJsonString() }]);
            Assert.Equal(HttpStatusCode.RequestEntityTooLarge, oversized.StatusCode);
            var problem = await oversized.Content.ReadAsStringAsync(TestContext.Current.CancellationToken);
            foreach (var canary in foodCanaries) { Assert.DoesNotContain(canary, problem, StringComparison.Ordinal); }
            await kestrelFactory.Services.GetRequiredService<IHub>().FlushAsync(TimeSpan.FromSeconds(5));
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
            using var failedPush = await PersonalFoodHttp.Push(historyClient, h, dataset, [privateRow]);
            Assert.Equal(HttpStatusCode.InternalServerError, failedPush.StatusCode);
            var failedBody = await failedPush.Content.ReadAsStringAsync(TestContext.Current.CancellationToken);
            foreach (var canary in foodCanaries) { Assert.DoesNotContain(canary, failedBody, StringComparison.Ordinal); }
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
        capture.Meter.RecordObservableInstruments();
        var auditLines = await SinkCapture.AuditAsync(postgres);
        Assert.Contains("operation=push", metrics);
        Assert.NotEmpty(logs.Lines); Assert.NotEmpty(activities); Assert.NotEmpty(metrics); Assert.NotEmpty(auditLines);
        Assert.Contains(transport.Envelopes, envelope => envelope.Contains("\"exception\"", StringComparison.Ordinal));
        await capture.AssertAbsentAsync(canaries, auditLines, postgres);
    }

    // B18 (D13, PA9): chat text (EN/Arabic/Arabizi) and opaque budget/interpretation/draft JSON reach
    // owner pull/history exactly, and no error response, log, scope, span, metric, Sentry event,
    // audit row or Postgres log, across accepted, invalid, oversize, ill-formed, 400, 403, 413 and 500.
    [Fact, Trait("Rule", "09.4-no-user-content"), Trait("Req", "AC-010")]
    public async Task B18_authorized_pull_returns_content_while_errors_logs_and_telemetry_omit_it()
    {
        var ct = TestContext.Current.CancellationToken;
        await using var h = new IdentityHarness(postgres); await h.InitializeAsync();
        using var capture = new SinkCapture();
        await using var factory = capture.Configure(new IdentityApiTests.IdentityApi(postgres, h), _ => { });
        using var client = await PersonalFoodHttp.Client(factory, h, await PersonalFoodHttp.Register(h));
        var dataset = await PersonalFoodHttp.Dataset(client);
        string[] canaries = ["CANARY-B18-CHAT-EN-private-reply", "رسالة-خاصة-سرية-كناري", "CANARY-ana-3ayez-akol-ta3miya-b18", "CANARY-B18-BUDGET-KEY",
            "CANARY-B18-INTERPRETATION", "تفسير-سري-كناري", "CANARY-B18-DRAFT-NOTE", "CANARY-B18-KIND", "CANARY-B18-LANG"];
        var text = $"{canaries[0]} {canaries[1]} {canaries[2]}";
        var message = B18Encode(ChatProposalCases.Baseline("chatMessage"), new()
        {
            ["text"] = text,
            ["language"] = canaries[8],
            ["budgetJson"] = $"{{\"{canaries[3]}\":[1,2],\"cards\":[]}}",
        });
        var card = B18Encode(ChatProposalCases.Baseline("proposal"), new()
        {
            ["kind"] = canaries[7],
            ["interpretationJson"] = $"[{{\"text\":\"{canaries[4]}\",\"raw\":\"{canaries[5]}\"}}]",
            ["draftJson"] = $"{{\"note\":\"{canaries[6]}\"}}",
        });
        var messageRow = PersonalFoodHttp.NewRow(h, message, entity: "chatMessage");
        var cardRow = PersonalFoodHttp.NewRow(h, card, entity: "proposal");
        using (var accepted = await PersonalFoodHttp.Push(client, h, dataset, [messageRow, cardRow]))
        {
            var ack = await accepted.Content.ReadAsStringAsync(ct);
            Assert.Equal(["accepted", "accepted"], JsonDocument.Parse(ack).RootElement.GetProperty("results").EnumerateArray().Select(r => r.GetProperty("status").GetString()));
            B18AssertNoCanary(canaries, ack);
        }
        // Invalid vocabulary, one unit over each bound, and unpaired surrogates, each carrying the canaries.
        var invalid = new[]
        {
            messageRow with { Id = Guid.NewGuid(), Raw = B18Encode(message, new() { ["role"] = "system" }) },
            cardRow with { Id = Guid.NewGuid(), Raw = B18Encode(card, new() { ["status"] = "active" }) },
            messageRow with { Id = Guid.NewGuid(), Raw = B18Encode(message, new() { ["text"] = text.PadRight(8193, 'x') }) },
            cardRow with { Id = Guid.NewGuid(), Raw = B18Encode(card, new() { ["draftJson"] = $"{{\"note\":\"{canaries[6]}\"}}".PadRight(32769) }) },
            messageRow with { Id = Guid.NewGuid(), Raw = B18Encode(message, new() { ["text"] = "\u0001marker\u0001" }).Replace("\\u0001marker\\u0001", text + "\\ud800", StringComparison.Ordinal) },
            cardRow with { Id = Guid.NewGuid(), Raw = B18Encode(card, new() { ["draftJson"] = "\u0001marker\u0001" }).Replace("\\u0001marker\\u0001", $"{{\\\"{canaries[6]}\\\":\\\"\\\\udc00\\\"}}", StringComparison.Ordinal) },
        };
        using (var rejected = await PersonalFoodHttp.Push(client, h, dataset, invalid))
        {
            Assert.Equal(HttpStatusCode.OK, rejected.StatusCode);
            var ack = await rejected.Content.ReadAsStringAsync(ct);
            Assert.All(JsonDocument.Parse(ack).RootElement.GetProperty("results").EnumerateArray(), r => Assert.Equal("invalidPayload", r.GetProperty("reason").GetString()));
            B18AssertNoCanary(canaries, ack);
        }
        // Owner pull and item history intentionally return the stored content exactly.
        using (var update = await PersonalFoodHttp.Push(client, h, dataset, [messageRow with { Hlc = PersonalFoodHttp.Hlc(h, 1) }, cardRow with { Hlc = PersonalFoodHttp.Hlc(h, 1) }]))
        { Assert.Equal(HttpStatusCode.OK, update.StatusCode); }
        var pulled = (await PersonalFoodHttp.Page(client, dataset)).GetProperty("changes").EnumerateArray().ToArray();
        Assert.Equal(2, pulled.Length);
        foreach (var row in new[] { messageRow, cardRow })
        {
            using var expected = JsonDocument.Parse(row.Raw);
            Assert.True(JsonElement.DeepEquals(expected.RootElement, pulled.Single(c => c.GetProperty("id").GetGuid() == row.Id).GetProperty("payload")));
            Assert.True(JsonElement.DeepEquals(expected.RootElement, Assert.Single((await PersonalFoodHttp.Page(client, dataset, row.Id, row.Entity)).GetProperty("changes").EnumerateArray()).GetProperty("payload")));
        }
        Assert.Equal(text, pulled.Single(c => c.GetProperty("id").GetGuid() == messageRow.Id).GetProperty("payload").GetProperty("text").GetString());
        // Unreadable outer JSON is a fixed 400; guests get 403.
        using (var body = new StringContent(PersonalFoodHttp.Body(h, dataset, [messageRow, cardRow]).Replace("\"createdAtMs\":0", "\"createdAtMs\":NaN", StringComparison.Ordinal), Encoding.UTF8, "application/json"))
        using (var malformed = await client.PostAsync("/v1/sync/push", body, ct))
        {
            Assert.Equal(HttpStatusCode.BadRequest, malformed.StatusCode);
            B18AssertNoCanary(canaries, await malformed.Content.ReadAsStringAsync(ct));
        }
        using (var guest = await PersonalFoodHttp.Client(factory, h, await h.GuestAsync()))
        using (var denied = await PersonalFoodHttp.Push(guest, h, dataset, [messageRow, cardRow]))
        {
            Assert.Equal(HttpStatusCode.Forbidden, denied.StatusCode);
            B18AssertNoCanary(canaries, await denied.Content.ReadAsStringAsync(ct));
        }
        // TestServer has no body limit: the 413 must come from real Kestrel.
        await using (var kestrelFactory = factory.WithWebHostBuilder(_ => { }))
        {
            kestrelFactory.UseKestrel(0);
            using var limited = kestrelFactory.CreateClient();
            limited.DefaultRequestHeaders.Add("X-App-Version", "0.1.0"); limited.DefaultRequestHeaders.Add("X-Platform", "android"); limited.DefaultRequestHeaders.Add("X-Device-Id", h.Device.ToString());
            limited.DefaultRequestHeaders.Authorization = client.DefaultRequestHeaders.Authorization;
            using var oversized = await PersonalFoodHttp.Push(limited, h, dataset, [messageRow with { Raw = B18Encode(message, new() { ["text"] = text + new string('x', 300 * 1024) }) }]);
            Assert.Equal(HttpStatusCode.RequestEntityTooLarge, oversized.StatusCode);
            B18AssertNoCanary(canaries, await oversized.Content.ReadAsStringAsync(ct));
            await kestrelFactory.Services.GetRequiredService<IHub>().FlushAsync(TimeSpan.FromSeconds(5));
        }
        // An injected storage failure whose exception message carries the pushed payloads (chat text,
        // budget, interpretation, draft) on push and the chat text on reads: 500 with no content, and
        // the exception reaches logs and Sentry with its message scrubbed.
        await using (var failingFactory = factory.WithWebHostBuilder(builder => builder.ConfigureTestServices(services =>
            services.AddScoped<FitnessBuddy.Modules.UserData.Application.ISyncStore>(_ => new FailingWithContent(text)))))
        {
            using var failing = failingFactory.CreateClient();
            failing.DefaultRequestHeaders.Add("X-App-Version", "0.1.0"); failing.DefaultRequestHeaders.Add("X-Platform", "android"); failing.DefaultRequestHeaders.Add("X-Device-Id", h.Device.ToString());
            failing.DefaultRequestHeaders.Authorization = client.DefaultRequestHeaders.Authorization;
            using var failedPush = await PersonalFoodHttp.Push(failing, h, dataset, [messageRow, cardRow]);
            Assert.Equal(HttpStatusCode.InternalServerError, failedPush.StatusCode);
            B18AssertNoCanary(canaries, await failedPush.Content.ReadAsStringAsync(ct));
            using var failedHistory = await failing.GetAsync($"/v1/sync/history/proposal/{cardRow.Id}?cursor=0&limit=10&datasetId={dataset}", ct);
            Assert.Equal(HttpStatusCode.InternalServerError, failedHistory.StatusCode);
            B18AssertNoCanary(canaries, await failedHistory.Content.ReadAsStringAsync(ct));
            await failingFactory.Services.GetRequiredService<IHub>().FlushAsync(TimeSpan.FromSeconds(5));
        }
        using (var erased = await client.DeleteAsync("/v1/me", ct)) { Assert.Equal(HttpStatusCode.NoContent, erased.StatusCode); }
        await factory.Services.GetRequiredService<IHub>().FlushAsync(TimeSpan.FromSeconds(5));
        capture.Meter.RecordObservableInstruments();
        var auditLines = await SinkCapture.AuditAsync(postgres);
        Assert.Contains("operation=push", capture.Metrics);
        Assert.NotEmpty(capture.Logs.Lines); Assert.NotEmpty(capture.Activities);
        Assert.Contains(capture.Transport.Envelopes, envelope => envelope.Contains("\"exception\"", StringComparison.Ordinal));
        await capture.AssertAbsentAsync(canaries, auditLines, postgres);
    }

    // Unescaped UTF-8 like the app's jsonEncode, so Arabic canaries travel as real text.
    private static readonly JsonSerializerOptions B18Relaxed = new() { Encoder = JavaScriptEncoder.UnsafeRelaxedJsonEscaping };

    private static string B18Encode(string raw, Dictionary<string, JsonNode?> fields)
    {
        var payload = JsonNode.Parse(raw)!.AsObject();
        foreach (var field in fields) { payload[field.Key] = field.Value; }
        return payload.ToJsonString(B18Relaxed);
    }

    private static void B18AssertNoCanary(IEnumerable<string> canaries, string body)
    {
        foreach (var canary in canaries.SelectMany(c => new[] { c, JsonSerializer.Serialize(c)[1..^1] }))
        { Assert.DoesNotContain(canary, body, StringComparison.OrdinalIgnoreCase); }
    }
    [Fact]
    public void Privacy_capture_detects_numeric_measurements_scopes_and_unformatted_structured_fields()
    {
        var metrics = new ConcurrentQueue<string>();
        using var listener = CaptureMetrics(metrics);
        using var source = new Meter("B17.PrivacyCapture.PositiveControl");
        source.CreateCounter<byte>("byte").Add(197);
        source.CreateCounter<short>("short").Add(29173);
        source.CreateCounter<int>("int").Add(917264931);
        source.CreateCounter<long>("long").Add(8172649312345L);
        source.CreateHistogram<float>("float").Record(713.25f);
        source.CreateHistogram<double>("double").Record(613.125);
        source.CreateHistogram<decimal>("decimal").Record(513.0625m);
        foreach (var marker in new[] { "197", "29173", "917264931", "8172649312345", "713.25", "613.125", "513.0625" })
        { Assert.Contains(marker, metrics); }

        using var logs = new CaptureLogs();
        var logger = logs.CreateLogger("B17.PositiveControl");
        using (logger.BeginScope(new Dictionary<string, object?> { ["ScopeKeyMarker"] = "ScopeValueMarker" }))
        {
            // Neither the formatter nor Dictionary.ToString reveals these fields.
            if (logger.IsEnabled(LogLevel.Information))
            {
                logger.Log(LogLevel.Information, new EventId(1),
                    new Dictionary<string, object?> { ["FieldKeyMarker"] = "FieldValueMarker" }, null, (_, _) => "fixed message");
            }
        }
        var captured = string.Join('\n', logs.Lines);
        foreach (var marker in new[] { "ScopeKeyMarker", "ScopeValueMarker", "FieldKeyMarker", "FieldValueMarker" })
        { Assert.Contains(marker, captured, StringComparison.Ordinal); }
    }

    // Every diagnostic sink the API writes to (B05/B17/B18 D13): logs and scopes through the production
    // scrubbing decorator, activities, every metric type, serialized Sentry envelopes; audit rows and
    // Postgres logs are read at the end.
    private sealed class SinkCapture : IDisposable
    {
        private readonly ActivityListener listener;
        public SinkCapture()
        {
            listener = new ActivityListener
            {
                ShouldListenTo = _ => true,
                Sample = (ref ActivityCreationOptions<ActivityContext> _) => ActivitySamplingResult.AllDataAndRecorded,
                SampleUsingParentId = (ref ActivityCreationOptions<string> _) => ActivitySamplingResult.AllDataAndRecorded,
                ActivityStopped = activity => Activities.Enqueue(activity.DisplayName + string.Join('|', activity.TagObjects.Select(t => $"{t.Key}={t.Value}")) + activity.StatusDescription + string.Join('|', activity.Events.Select(e => e.Name + string.Join('|', e.Tags)))),
            };
            ActivitySource.AddActivityListener(listener);
            Meter = CaptureMetrics(Metrics);
        }
        public CaptureLogs Logs { get; } = new();
        public ConcurrentQueue<string> Activities { get; } = new();
        public ConcurrentQueue<string> Metrics { get; } = new();
        public CaptureSentry Transport { get; } = new();
        public MeterListener Meter { get; }

        public WebApplicationFactory<Program> Configure(WebApplicationFactory<Program> factory, Action<IServiceCollection> services) => factory.WithWebHostBuilder(builder =>
        {
            builder.ConfigureAppConfiguration((_, config) => config.AddInMemoryCollection(new Dictionary<string, string?> { ["Sentry:Dsn"] = "https://public@localhost/1" }));
            builder.ConfigureTestServices(collection =>
            {
                collection.AddSingleton<ILoggerProvider>(_ => new ScrubbingLoggerProvider(Logs));
                collection.Configure<SentryAspNetCoreOptions>(options => options.Transport = Transport);
                services(collection);
            });
        });

        // API cannot read even its own audit table directly. Inspect using the schema owner.
        public static async Task<List<string>> AuditAsync(PostgresFixture postgres)
        {
            await using var owner = FitnessBuddy.BuildingBlocks.Persistence.DatabaseConfiguration.CreateSource(postgres.MigratorConnection);
            await using var read = owner.CreateCommand("SELECT row_to_json(a)::text FROM identity.audit a");
            await using var reader = await read.ExecuteReaderAsync(TestContext.Current.CancellationToken);
            var auditLines = new List<string>(); while (await reader.ReadAsync(TestContext.Current.CancellationToken)) { auditLines.Add(reader.GetString(0)); }
            return auditLines;
        }

        public async Task AssertAbsentAsync(IEnumerable<string> canaries, IReadOnlyList<string> auditLines, PostgresFixture postgres)
        {
            foreach (var canary in canaries.SelectMany(c => new[] { c, JsonSerializer.Serialize(c)[1..^1] }).Distinct(StringComparer.Ordinal))
            {
                Assert.DoesNotContain(canary, string.Join('\n', Logs.Lines), StringComparison.OrdinalIgnoreCase);
                Assert.DoesNotContain(canary, string.Join('\n', Activities), StringComparison.OrdinalIgnoreCase);
                Assert.DoesNotContain(canary, string.Join('\n', Metrics), StringComparison.OrdinalIgnoreCase);
                Assert.DoesNotContain(canary, string.Join('\n', Transport.Envelopes), StringComparison.OrdinalIgnoreCase);
                Assert.DoesNotContain(canary, string.Join('\n', auditLines), StringComparison.OrdinalIgnoreCase);
                Assert.DoesNotContain(canary, await postgres.LogsAsync(), StringComparison.OrdinalIgnoreCase);
            }
        }

        public void Dispose() { Meter.Dispose(); listener.Dispose(); Logs.Dispose(); }
    }

    private static MeterListener CaptureMetrics(ConcurrentQueue<string> metrics)
    {
        var listener = new MeterListener { InstrumentPublished = (instrument, receiver) => receiver.EnableMeasurementEvents(instrument) };
        Capture<byte>(); Capture<short>(); Capture<int>(); Capture<long>(); Capture<float>(); Capture<double>(); Capture<decimal>();
        listener.Start();
        return listener;

        void Capture<T>() where T : struct, IFormattable => listener.SetMeasurementEventCallback<T>((_, value, tags, _) =>
        {
            metrics.Enqueue(value.ToString(value is double or float ? "R" : null, System.Globalization.CultureInfo.InvariantCulture));
            foreach (var tag in tags) { metrics.Enqueue($"{tag.Key}={tag.Value}"); }
        });
    }

    private sealed class FailingWithContent(string text) : FitnessBuddy.Modules.UserData.Application.ISyncStore
    {
        public Task<FitnessBuddy.Modules.UserData.Domain.PushOutcome?> PushForSessionAsync(FitnessBuddy.Modules.Identity.Contracts.IdentitySession principal, Guid? dataset, IReadOnlyList<FitnessBuddy.Modules.UserData.Domain.SyncVersion> versions, DateTimeOffset now, CancellationToken cancellationToken) =>
            throw new InvalidOperationException(string.Join('\n', versions.Select(v => v.Payload.GetRawText())));
        public Task<FitnessBuddy.Modules.UserData.Domain.VersionPage?> PullForSessionAsync(FitnessBuddy.Modules.Identity.Contracts.IdentitySession principal, Guid? dataset, long cursor, int limit, bool history, string? entity, Guid? id, CancellationToken cancellationToken) =>
            throw new InvalidOperationException(text);
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
    private sealed class CaptureLogs : ILoggerProvider, ISupportExternalScope
    {
        public ConcurrentQueue<string> Lines { get; } = new();
        private IExternalScopeProvider scopes = new LoggerExternalScopeProvider();
        public void SetScopeProvider(IExternalScopeProvider scopeProvider) => scopes = scopeProvider;
        public ILogger CreateLogger(string categoryName) => new Logger(this);
        private void CaptureState(object? state)
        {
            Lines.Enqueue(state?.ToString() ?? "");
            if (state is IEnumerable<KeyValuePair<string, object?>> fields)
            {
                foreach (var field in fields) { Lines.Enqueue($"{field.Key}={field.Value}"); }
            }
        }
        public void Dispose() { }
        private sealed class Logger(CaptureLogs owner) : ILogger
        {
            public IDisposable? BeginScope<TState>(TState state) where TState : notnull => owner.scopes.Push(state);
            public bool IsEnabled(LogLevel logLevel) => true;
            public void Log<TState>(LogLevel logLevel, EventId eventId, TState state, Exception? exception, Func<TState, Exception?, string> formatter)
            {
                owner.Lines.Enqueue(formatter(state, exception) + " " + exception);
                owner.CaptureState(state);
                owner.scopes.ForEachScope((scope, capture) => capture.CaptureState(scope), owner);
            }
        }
    }
}
