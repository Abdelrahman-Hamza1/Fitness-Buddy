using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;
using FitnessBuddy.Modules.Buddy.Domain;
using FitnessBuddy.Modules.Buddy.Infrastructure;
using FitnessBuddy.Modules.Identity.Application;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.AI;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace FitnessBuddy.Persistence.Tests;

public sealed class BuddyApiTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;
    [Fact]
    [Trait("Req", "MN-005")]
    [Trait("Req", "AI-150")]
    [Trait("Req", "AI-153")]
    public async Task Public_endpoint_repairs_once_replays_conflicts_and_preserves_ambiguous_attempts()
    {
        await using var h = new IdentityHarness(postgres); await h.InitializeAsync();
        using var wire = new BuddyWire { InvalidCalls = 1 };
        await using var api = new BuddyApi(postgres, h, wire); using var client = api.CreateClient(); Headers(client, h);
        var id = Guid.CreateVersion7();
        using (var denied = await Send(client, h, id)) { Assert.Equal(HttpStatusCode.Unauthorized, denied.StatusCode); Assert.Equal(0, wire.Calls); }
        await SignIn(client, h);
        using (var success = await Send(client, h, id))
        {
            Assert.Equal(HttpStatusCode.OK, success.StatusCode); Assert.True(success.Headers.CacheControl!.NoStore);
            var body = await success.Content.ReadFromJsonAsync<JsonElement>(Ct); Assert.Equal("clarify", body.GetProperty("intents")[0].GetProperty("kind").GetString());
        }
        Assert.Equal(2, wire.Calls);
        using (var replay = await Send(client, h, id)) { Assert.Equal(HttpStatusCode.OK, replay.StatusCode); Assert.Equal(2, wire.Calls); }
        using (var conflict = await Send(client, h, id, "different-private-canary")) { Assert.Equal(HttpStatusCode.Conflict, conflict.StatusCode); Assert.Equal(2, wire.Calls); }
        var twice = Guid.CreateVersion7(); wire.InvalidCalls = wire.Calls + 2;
        using (var fallback = await Send(client, h, twice))
        { Assert.Equal(HttpStatusCode.OK, fallback.StatusCode); var body = await fallback.Content.ReadFromJsonAsync<JsonElement>(Ct); Assert.Equal("invalidInterpretation", body.GetProperty("intents")[0].GetProperty("reason").GetString()); }
        Assert.Equal(4, wire.Calls);
        wire.Status = HttpStatusCode.ServiceUnavailable;
        var pending = Guid.CreateVersion7();
        using (var failure = await Send(client, h, pending)) { Assert.Equal(HttpStatusCode.ServiceUnavailable, failure.StatusCode); }
        using (var replay = await Send(client, h, pending)) { Assert.Equal(HttpStatusCode.ServiceUnavailable, replay.StatusCode); Assert.Equal(5, wire.Calls); }
        Assert.DoesNotContain("private-canary", string.Join("|", api.Logs.Messages), StringComparison.Ordinal);
        Assert.DoesNotContain("different-private-canary", string.Join("|", api.Logs.Messages), StringComparison.Ordinal);
        Assert.All(wire.Requests, body =>
        {
            Assert.DoesNotContain(h.Device.ToString(), body, StringComparison.Ordinal); Assert.DoesNotContain(id.ToString(), body, StringComparison.Ordinal);
            Assert.All(DefaultSlotIds, slot => Assert.DoesNotContain(slot, body, StringComparison.OrdinalIgnoreCase));
        });
        var user = (await h.Tokens.ValidateAsync(client.DefaultRequestHeaders.Authorization!.Parameter!, Ct))!.FindFirst("sub")!.Value;
        await using var inspect = await postgres.SessionAsync(Guid.Parse(user));
        await using var count = inspect.Command("SELECT sum(calls),sum(input_tokens),sum(messages) FROM usage.daily WHERE user_id=$1"); count.Parameters.AddWithValue(Guid.Parse(user));
        await using var reader = await count.ExecuteReaderAsync(Ct); Assert.True(await reader.ReadAsync(Ct)); Assert.Equal(5, reader.GetDecimal(0)); Assert.Equal(400, reader.GetDecimal(1)); Assert.Equal(3, reader.GetDecimal(2));
    }

    [Fact]
    [Trait("Req", "MN-005")]
    [Trait("Rule", "04.6-authz")]
    public async Task Concurrent_keys_reserve_quota_before_send_and_crashed_claim_never_resends()
    {
        await using var h = new IdentityHarness(postgres); await h.InitializeAsync(); using var wire = new BuddyWire { Pause = true };
        await using var api = new BuddyApi(postgres, h, wire, dailyLimit: 1); using var client = api.CreateClient(); Headers(client, h); await SignIn(client, h);
        var id = Guid.CreateVersion7(); var first = Send(client, h, id);
        await wire.Started.Task.WaitAsync(TimeSpan.FromSeconds(10), Ct);
        using (var same = await Send(client, h, id)) { Assert.Equal(HttpStatusCode.ServiceUnavailable, same.StatusCode); Assert.Equal(1, wire.Calls); }
        using (var other = await Send(client, h, Guid.CreateVersion7())) { Assert.Equal(HttpStatusCode.TooManyRequests, other.StatusCode); Assert.True(other.Headers.Contains("RateLimit")); Assert.Equal(1, wire.Calls); }
        wire.Continue.TrySetResult(); using var completed = await first; Assert.Equal(HttpStatusCode.OK, completed.StatusCode);
        using (var same = await Send(client, h, id)) { Assert.Equal(HttpStatusCode.OK, same.StatusCode); Assert.Equal(1, wire.Calls); }
    }

    [Fact]
    [Trait("Req", "AC-031")]
    [Trait("Req", "AC-041")]
    public async Task Deletion_during_invalid_call_suppresses_repair_and_late_recreation()
    {
        await using var h = new IdentityHarness(postgres); await h.InitializeAsync(); using var wire = new BuddyWire { Pause = true, InvalidCalls = 1 };
        await using var api = new BuddyApi(postgres, h, wire); using var client = api.CreateClient(); Headers(client, h); await SignIn(client, h);
        var id = Guid.CreateVersion7(); var first = Send(client, h, id);
        await wire.Started.Task.WaitAsync(TimeSpan.FromSeconds(10), Ct);
        using (var erased = await client.DeleteAsync("/v1/me", Ct)) { Assert.Equal(HttpStatusCode.NoContent, erased.StatusCode); }
        wire.Continue.TrySetResult(); using var result = await first; Assert.Equal(HttpStatusCode.Unauthorized, result.StatusCode); Assert.Equal(1, wire.Calls);
        await using var admin = FitnessBuddy.BuildingBlocks.Persistence.DatabaseConfiguration.CreateSource(postgres.MigratorConnection);
        await using var count = admin.CreateCommand("SELECT count(*) FROM buddy.attempts WHERE message_id=$1"); count.Parameters.AddWithValue(id);
        Assert.Equal(0L, await count.ExecuteScalarAsync(Ct));
    }

    [Fact]
    [Trait("Req", "AC-041")]
    public async Task Invalid_context_and_missing_key_never_dispatch()
    {
        await using var h = new IdentityHarness(postgres); await h.InitializeAsync(); using var wire = new BuddyWire();
        await using var api = new BuddyApi(postgres, h, wire); using var client = api.CreateClient(); Headers(client, h); await SignIn(client, h);
        using (var invalid = await Send(client, h, Guid.CreateVersion7(), new string('a', 1001))) { Assert.Equal(HttpStatusCode.BadRequest, invalid.StatusCode); }
        using var missing = await client.PostAsJsonAsync("/v1/buddy/interpret", Request(Guid.CreateVersion7(), h), Ct);
        Assert.Equal(HttpStatusCode.BadRequest, missing.StatusCode); Assert.Equal(0, wire.Calls);
    }
    [Fact]
    [Trait("Req", "AI-153")]
    [Trait("Req", "MN-005")]
    public async Task Provider_timeout_and_denied_repair_remain_pending_without_another_send()
    {
        await using var h = new IdentityHarness(postgres); await h.InitializeAsync(); using var wire = new BuddyWire { Hang = true };
        await using var api = new BuddyApi(postgres, h, wire, configure: s => s.PostConfigure<FitnessBuddy.Modules.Buddy.Application.BuddyOptions>(o => o.TimeoutSeconds = 1));
        using var client = api.CreateClient(); Headers(client, h); await SignIn(client, h); var id = Guid.CreateVersion7();
        using (var timeout = await Send(client, h, id)) { Assert.Equal(HttpStatusCode.ServiceUnavailable, timeout.StatusCode); }
        wire.Hang = false;
        using (var replay = await Send(client, h, id)) { Assert.Equal(HttpStatusCode.ServiceUnavailable, replay.StatusCode); Assert.Equal(1, wire.Calls); }
        await using var limitedH = new IdentityHarness(postgres); await limitedH.InitializeAsync(); using var limitedWire = new BuddyWire { InvalidCalls = 1 };
        await using var limitedApi = new BuddyApi(postgres, limitedH, limitedWire, dailyLimit: 1);
        using var limitedClient = limitedApi.CreateClient(); Headers(limitedClient, limitedH); await SignIn(limitedClient, limitedH); var key = Guid.CreateVersion7();
        using (var deniedRepair = await Send(limitedClient, limitedH, key)) { Assert.Equal(HttpStatusCode.ServiceUnavailable, deniedRepair.StatusCode); Assert.Equal(1, limitedWire.Calls); }
        using (var replay = await Send(limitedClient, limitedH, key)) { Assert.Equal(HttpStatusCode.ServiceUnavailable, replay.StatusCode); Assert.Equal(1, limitedWire.Calls); }
    }

    // The phone's default meal slots carry UUIDv5 natural IDs (TD-070, fb_domain DefaultSlots), not UUIDv7.
    internal static readonly string[] DefaultSlotIds =
        ["4c5aed24-f404-506e-a925-f0ff33099753", "ca0daf21-3d15-53c5-b4ec-ee09a5e0c674", "260cb3fe-def5-53e5-9f5c-d64f61a4ec3e", "9c906ed8-064d-52d3-b116-803e12ee5630"];
    internal static object[] DefaultSlots() =>
    [
        new { id = DefaultSlotIds[0], name = "Breakfast", window = "04:00-11:00" }, new { id = DefaultSlotIds[1], name = "Lunch", window = "11:00-16:00" },
        new { id = DefaultSlotIds[2], name = "Dinner", window = "16:00-22:00" }, new { id = DefaultSlotIds[3], name = "Snacks", window = (string?)null },
    ];
    [Fact]
    [Trait("Rule", "05.1-natural-ids")]
    public async Task Natural_slot_ids_are_accepted_while_nil_slot_ids_and_non_v7_request_ids_are_rejected()
    {
        await using var h = new IdentityHarness(postgres); await h.InitializeAsync(); using var wire = new BuddyWire();
        await using var api = new BuddyApi(postgres, h, wire); using var client = api.CreateClient(); Headers(client, h); await SignIn(client, h);
        using (var natural = await Send(client, h, Guid.CreateVersion7())) { Assert.Equal(HttpStatusCode.OK, natural.StatusCode); Assert.Equal(1, wire.Calls); }
        using (var nil = await Send(client, h, Guid.CreateVersion7(), slots: [new { id = Guid.Empty, name = "Breakfast", window = (string?)null }]))
        { Assert.Equal(HttpStatusCode.BadRequest, nil.StatusCode); }
        using (var compact = await Send(client, h, Guid.CreateVersion7(), slots: [new { id = DefaultSlotIds[0].Replace("-", "", StringComparison.Ordinal), name = "Breakfast", window = (string?)null }]))
        { Assert.Equal(HttpStatusCode.BadRequest, compact.StatusCode); }
        using (var v5Request = await Send(client, h, Guid.Parse(DefaultSlotIds[0]))) { Assert.Equal(HttpStatusCode.BadRequest, v5Request.StatusCode); }
        using (var v4Request = await Send(client, h, Guid.NewGuid())) { Assert.Equal(HttpStatusCode.BadRequest, v4Request.StatusCode); }
        Assert.Equal(1, wire.Calls);
    }

    [Fact]
    [Trait("Rule", "04.8-additive-contract")]
    [Trait("Req", "MN-005")]
    public async Task Active_card_is_optional_null_equals_absent_for_replay_and_a_card_changes_the_fingerprint()
    {
        await using var h = new IdentityHarness(postgres); await h.InitializeAsync(); using var wire = new BuddyWire();
        await using var api = new BuddyApi(postgres, h, wire); using var client = api.CreateClient(); Headers(client, h); await SignIn(client, h);
        var id = Guid.CreateVersion7();
        using (var absent = await Send(client, h, id)) { Assert.Equal(HttpStatusCode.OK, absent.StatusCode); Assert.Equal(1, wire.Calls); }
        using (var explicitNull = await SendBody(client, id, WithCard(Request(id, h), null))) { Assert.Equal(HttpStatusCode.OK, explicitNull.StatusCode); Assert.Equal(1, wire.Calls); }
        var card = JsonNode.Parse("""{"slot":"Breakfast","time":"08:00","lines":[{"name":"private-card-canary","amount":2,"unitCode":"piece","state":"cooked"}]}""");
        using (var changed = await SendBody(client, id, WithCard(Request(id, h), card))) { Assert.Equal(HttpStatusCode.Conflict, changed.StatusCode); Assert.Equal(1, wire.Calls); }
        var fresh = Guid.CreateVersion7();
        using (var withCard = await SendBody(client, fresh, WithCard(Request(fresh, h), card))) { Assert.Equal(HttpStatusCode.OK, withCard.StatusCode); Assert.Equal(2, wire.Calls); }
        var lines = new JsonArray([.. Enumerable.Range(0, 31).Select(_ => JsonNode.Parse("""{"name":"private-over-canary","amount":1,"unitCode":"piece","state":null}"""))]);
        var over = Guid.CreateVersion7();
        using (var tooMany = await SendBody(client, over, WithCard(Request(over, h), new JsonObject { ["slot"] = null, ["time"] = null, ["lines"] = lines })))
        { Assert.Equal(HttpStatusCode.BadRequest, tooMany.StatusCode); Assert.Equal(2, wire.Calls); }
        var orphan = Guid.CreateVersion7(); var noProposal = WithCard(Request(orphan, h), card); noProposal["activeProposal"] = null;
        using (var missingProposal = await SendBody(client, orphan, noProposal)) { Assert.Equal(HttpStatusCode.BadRequest, missingProposal.StatusCode); Assert.Equal(2, wire.Calls); }
        var logs = string.Join("|", api.Logs.Messages);
        Assert.DoesNotContain("private-card-canary", logs, StringComparison.Ordinal); Assert.DoesNotContain("private-over-canary", logs, StringComparison.Ordinal);
    }

    private static JsonNode WithCard(object request, JsonNode? card)
    {
        // A card is sent with its active proposal (AI-044).
        var node = JsonSerializer.SerializeToNode(request)!; node["context"]!["activeCard"] = card?.DeepClone();
        if (card is not null) { node["activeProposal"] = "019a0000-0000-7000-8000-0000000000a1"; }
        return node;
    }
    private static async Task<HttpResponseMessage> SendBody(HttpClient client, Guid id, JsonNode body)
    {
        using var request = new HttpRequestMessage(HttpMethod.Post, "/v1/buddy/interpret") { Content = new StringContent(body.ToJsonString(), Encoding.UTF8, "application/json") };
        request.Headers.Add("Idempotency-Key", id.ToString()); return await client.SendAsync(request, Ct);
    }

    internal static object Request(Guid id, IdentityHarness h, string text = "private-canary", object[]? slots = null) => new
    {
        requestId = id,
        text,
        now = h.Clock.GetUtcNow(),
        tzOffsetMin = 180,
        ramadan = new { active = false, fajr = (string?)null, maghrib = (string?)null },
        slots = slots ?? DefaultSlots(),
        activeProposal = (Guid?)null,
        context = new { personalFoods = Array.Empty<object>(), savedMeals = Array.Empty<object>(), openBatches = Array.Empty<object>(), memory = Array.Empty<object>(), recentEntries = Array.Empty<object>(), customExercises = Array.Empty<object>() },
    };
    internal static async Task<HttpResponseMessage> Send(HttpClient client, IdentityHarness h, Guid id, string text = "private-canary", object[]? slots = null)
    {
        using var request = new HttpRequestMessage(HttpMethod.Post, "/v1/buddy/interpret") { Content = JsonContent.Create(Request(id, h, text, slots)) };
        request.Headers.Add("Idempotency-Key", id.ToString()); return await client.SendAsync(request, Ct);
    }
    internal static void Headers(HttpClient client, IdentityHarness h)
    { client.DefaultRequestHeaders.Add("X-App-Version", "0.1.0"); client.DefaultRequestHeaders.Add("X-Platform", "android"); client.DefaultRequestHeaders.Add("X-Device-Id", h.Device.ToString()); }
    internal static async Task SignIn(HttpClient client, IdentityHarness h)
    {
        var tokens = (await h.Service.GuestAsync(h.Device, Ct))!;
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", tokens.AccessToken);
    }
    internal sealed class BuddyApi(PostgresFixture p, IdentityHarness h, HttpMessageHandler wire, int dailyLimit = 30, Action<IServiceCollection>? configure = null) : WebApplicationFactory<Program>
    {
        public CapturedLogs Logs { get; } = new();
        protected override void ConfigureWebHost(IWebHostBuilder builder)
        {
            builder.UseEnvironment("Testing");
            builder.ConfigureAppConfiguration((_, c) => c.AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["ConnectionStrings:Application"] = p.AppConnection,
                ["Recovery:Directory"] = p.RecoveryDirectory,
                ["Identity:Enabled"] = "true",
                ["Identity:WrappingKeysDirectory"] = h.DirectoryPath,
                ["Identity:PepperFile"] = h.Options.PepperFile,
                ["Buddy:Enabled"] = "true",
                ["Buddy:ApiKeyFile"] = "/unused-synthetic",
                ["Buddy:GuestDailyCalls"] = dailyLimit.ToString(System.Globalization.CultureInfo.InvariantCulture),
                ["Buddy:RegisteredDailyCalls"] = "100",
                ["RateLimiting:PerIp:PermitLimit"] = "100000",
            }));
            builder.ConfigureTestServices(s =>
            {
                s.AddSingleton<Microsoft.Extensions.Logging.ILoggerProvider>(Logs);
                s.AddSingleton<TimeProvider>(h.Clock); s.AddSingleton<IGoogleIdentityVerifier, IdentityHarness.FakeGoogle>(); s.AddSingleton<IEmailSender>(h.Email);
                s.AddSingleton<IChatClient>(_ => OpenAIClientFactory.Create("offline-placeholder", new HttpClient(wire, disposeHandler: false)));
                configure?.Invoke(s);
            });
        }
    }
    internal sealed class CapturedLogs : Microsoft.Extensions.Logging.ILoggerProvider
    {
        public System.Collections.Concurrent.ConcurrentQueue<string> Messages { get; } = new();
        public Microsoft.Extensions.Logging.ILogger CreateLogger(string categoryName) => new Logger(Messages);
        public void Dispose() { }
        private sealed class Logger(System.Collections.Concurrent.ConcurrentQueue<string> messages) : Microsoft.Extensions.Logging.ILogger
        {
            public IDisposable? BeginScope<TState>(TState state) where TState : notnull => null;
            public bool IsEnabled(Microsoft.Extensions.Logging.LogLevel logLevel) => true;
            public void Log<TState>(Microsoft.Extensions.Logging.LogLevel logLevel, Microsoft.Extensions.Logging.EventId eventId, TState state, Exception? exception, Func<TState, Exception?, string> formatter)
                => messages.Enqueue(formatter(state, exception));
        }
    }
    internal sealed class BuddyWire : HttpMessageHandler
    {
        public int Calls { get; private set; }
        public int InvalidCalls { get; set; }
        public bool Pause { get; set; }
        public bool Hang { get; set; }
        public HttpStatusCode Status { get; set; } = HttpStatusCode.OK;
        public List<string> Requests { get; } = [];
        public TaskCompletionSource Started { get; } = new(TaskCreationOptions.RunContinuationsAsynchronously);
        public TaskCompletionSource Continue { get; } = new(TaskCreationOptions.RunContinuationsAsynchronously);
        public Func<string, ParsedMessage>? Parse { get; set; }
        protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            Calls++; var text = await request.Content!.ReadAsStringAsync(cancellationToken); Requests.Add(text); Started.TrySetResult();
            if (Pause) { await Continue.Task.WaitAsync(cancellationToken); }
            if (Hang) { await Task.Delay(System.Threading.Timeout.InfiniteTimeSpan, cancellationToken); }
            var fixture = JsonNode.Parse(await File.ReadAllTextAsync(Path.Combine(AppContext.BaseDirectory, "buddy-envelope.json"), cancellationToken))!;
            var parsed = Parse?.Invoke(text) ?? new ParsedMessage(MessageLanguage.English, MessageScript.Latin, [new(ParsedKind.Clarify, null, null, null, [], null, DeclineReason.Unclear)]);
            fixture["output"]![1]!["content"]![0]!["text"] = Calls <= InvalidCalls ? "{" : JsonSerializer.Serialize(parsed, InterpretProtocol.Json);
            return new(Status) { Content = new StringContent(fixture.ToJsonString(), Encoding.UTF8, "application/json") };
        }
    }
}
