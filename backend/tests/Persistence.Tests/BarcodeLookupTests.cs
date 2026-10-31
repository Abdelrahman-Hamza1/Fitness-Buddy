using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text;
using System.Text.Json;
using FitnessBuddy.Modules.Catalog.Application;
using FitnessBuddy.Modules.Catalog.Infrastructure;
using FitnessBuddy.Modules.Identity.Application;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace FitnessBuddy.Persistence.Tests;

/// <summary>B10a: the barcode chain against a fake Open Food Facts (no network). Each test uses its own codes, so the
/// shared database's <c>catalog.off_cache</c> never couples tests.</summary>
[Trait("Req", "FD-030")]
[Trait("Req", "FD-031")]
[Trait("Rule", "07.3-off-isolation")]
[Trait("Rule", "07.7-barcode-chain")]
public sealed class BarcodeLookupTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;
    private static int nextCode = Random.Shared.Next(1_000_000, 9_000_000);

    [Fact]
    public async Task Found_products_are_mapped_cached_shared_and_never_reach_catalog_tables()
    {
        await using var h = new IdentityHarness(postgres); await h.InitializeAsync();
        using var wire = new OffWire();
        await using var api = new BarcodeApi(postgres, h, wire); using var client = Client(api, h.Device);
        var upcA = NewCode(12); var canonical = "0" + upcA;
        wire.Products[canonical] = Product(name: "Synthetic halawa " + upcA, kj: 2092, fiber: null);
        using (var anonymous = await client.GetAsync("/v1/foods/barcode/" + upcA, Ct)) { Assert.Equal(HttpStatusCode.Unauthorized, anonymous.StatusCode); }
        Assert.Equal(0, wire.Calls);
        await SignIn(client, h, h.Device);
        using (var invalid = await client.GetAsync("/v1/foods/barcode/" + upcA[..^1] + (char)('0' + (upcA[^1] - '0' + 1) % 10), Ct)) { Assert.Equal(HttpStatusCode.BadRequest, invalid.StatusCode); }
        using (var letters = await client.GetAsync("/v1/foods/barcode/12345abc", Ct)) { Assert.Equal(HttpStatusCode.BadRequest, letters.StatusCode); }
        Assert.Equal(0, wire.Calls);

        wire.Pause = true;
        var first = client.GetAsync("/v1/foods/barcode/" + upcA, Ct); var joined = client.GetAsync("/v1/foods/barcode/" + canonical, Ct);
        await wire.Started.Task.WaitAsync(TimeSpan.FromSeconds(10), Ct); await Task.Delay(200, Ct);
        wire.Continue.TrySetResult();
        using (var a = await first) using (var b = await joined) { Assert.Equal(HttpStatusCode.OK, a.StatusCode); Assert.Equal(HttpStatusCode.OK, b.StatusCode); }
        Assert.Equal(1, wire.Calls);
        using (var response = await client.GetAsync("/v1/foods/barcode/" + upcA, Ct))
        {
            Assert.Equal(HttpStatusCode.OK, response.StatusCode); Assert.True(response.Headers.CacheControl!.NoStore);
            var body = await response.Content.ReadFromJsonAsync<JsonElement>(Ct);
            Assert.Equal(canonical, body.GetProperty("code").GetString()); Assert.Equal("off", body.GetProperty("source").GetString());
            Assert.False(body.GetProperty("complete").GetBoolean());
            Assert.Equal(500, body.GetProperty("per100").GetProperty("kcal").GetDouble(), 3);
            Assert.Equal(JsonValueKind.Null, body.GetProperty("per100").GetProperty("fiberG").ValueKind);
            Assert.Equal("Synthetic Brand", body.GetProperty("brand").GetString()); Assert.Equal("g", body.GetProperty("basis").GetString());
            Assert.Equal(30, body.GetProperty("servingQuantity").GetDouble());
            Assert.Equal(["en:halal", "en:vegetarian"], body.GetProperty("labels").EnumerateArray().Select(l => l.GetString()));
        }
        Assert.Equal(1, wire.Calls);
        var request = Assert.Single(wire.Requests);
        Assert.StartsWith("FitnessBuddy/", request.UserAgent, StringComparison.Ordinal);
        Assert.False(request.HadAuthorization); Assert.False(request.HadCookie);
        Assert.Equal("/api/v2/product/" + canonical, request.Path); Assert.Contains("fields=", request.Query, StringComparison.Ordinal);
        Assert.DoesNotContain(upcA, string.Join("|", api.Logs.Messages), StringComparison.Ordinal);

        await using var check = postgres.App.CreateCommand("""
            SELECT (SELECT count(*) FROM catalog.off_cache WHERE code=$1),
                   (SELECT count(*) FROM catalog.foods WHERE source='off' OR source_ref LIKE '%' || $2 || '%'),
                   (SELECT count(*) FROM catalog.names WHERE name LIKE '%' || $2 || '%'),
                   has_table_privilege('fb_app','catalog.foods','INSERT') OR has_table_privilege('fb_app','catalog.names','INSERT')
                     OR has_table_privilege('fb_app','catalog.servings','INSERT') OR has_table_privilege('fb_app','catalog.foods','UPDATE')
            """);
        check.Parameters.AddWithValue(canonical); check.Parameters.AddWithValue(upcA);
        await using var reader = await check.ExecuteReaderAsync(Ct); Assert.True(await reader.ReadAsync(Ct));
        Assert.Equal(1, reader.GetInt64(0)); Assert.Equal(0, reader.GetInt64(1)); Assert.Equal(0, reader.GetInt64(2)); Assert.False(reader.GetBoolean(3));
    }

    [Fact]
    public async Task Unknown_codes_expiry_stale_if_error_and_cool_down()
    {
        await using var h = new IdentityHarness(postgres); await h.InitializeAsync();
        using var wire = new OffWire();
        await using var api = new BarcodeApi(postgres, h, wire); using var client = Client(api, h.Device); await SignIn(client, h, h.Device);
        var unknown = NewCode(13);
        using (var missing = await client.GetAsync("/v1/foods/barcode/" + unknown, Ct)) { Assert.Equal(HttpStatusCode.NotFound, missing.StatusCode); }
        using (var cached = await client.GetAsync("/v1/foods/barcode/" + unknown, Ct)) { Assert.Equal(HttpStatusCode.NotFound, cached.StatusCode); }
        Assert.Equal(1, wire.Calls);
        h.Clock.Advance(TimeSpan.FromDays(1) + TimeSpan.FromMinutes(1)); await SignIn(client, h, h.Device);
        wire.Products[unknown] = Product(name: "Now known", kj: null, fiber: 2);
        using (var refreshed = await client.GetAsync("/v1/foods/barcode/" + unknown, Ct)) { Assert.Equal(HttpStatusCode.OK, refreshed.StatusCode); }
        Assert.Equal(2, wire.Calls);

        h.Clock.Advance(TimeSpan.FromDays(31)); await SignIn(client, h, h.Device);
        wire.Status = HttpStatusCode.ServiceUnavailable; wire.RetryAfterSeconds = 120;
        using (var stale = await client.GetAsync("/v1/foods/barcode/" + unknown, Ct))
        { Assert.Equal(HttpStatusCode.OK, stale.StatusCode); Assert.True((await stale.Content.ReadFromJsonAsync<JsonElement>(Ct)).GetProperty("complete").GetBoolean()); }
        Assert.Equal(3, wire.Calls);
        using (var coolingDown = await client.GetAsync("/v1/foods/barcode/" + NewCode(13), Ct))
        {
            Assert.Equal(HttpStatusCode.ServiceUnavailable, coolingDown.StatusCode);
            Assert.InRange(int.Parse(coolingDown.Headers.GetValues("Retry-After").Single(), System.Globalization.CultureInfo.InvariantCulture), 1, 120);
        }
        Assert.Equal(3, wire.Calls);
        h.Clock.Advance(TimeSpan.FromDays(7)); await SignIn(client, h, h.Device);
        wire.Status = HttpStatusCode.InternalServerError; wire.RetryAfterSeconds = null;
        using (var gone = await client.GetAsync("/v1/foods/barcode/" + unknown, Ct)) { Assert.Equal(HttpStatusCode.ServiceUnavailable, gone.StatusCode); Assert.True(gone.Headers.Contains("Retry-After")); }
        Assert.Equal(4, wire.Calls);
    }

    [Fact]
    public async Task Upstream_budgets_are_per_account_and_process_wide_and_cache_hits_are_free()
    {
        await using var h = new IdentityHarness(postgres); await h.InitializeAsync();
        using var wire = new OffWire { NotFoundByDefault = false };
        await using (var api = new BarcodeApi(postgres, h, wire, new() { ["Catalog:OpenFoodFacts:UserFetchesPerHour"] = "2" }))
        {
            using var client = Client(api, h.Device); await SignIn(client, h, h.Device);
            var first = NewCode(13);
            foreach (var code in new[] { first, NewCode(13) }) { using var ok = await client.GetAsync("/v1/foods/barcode/" + code, Ct); Assert.Equal(HttpStatusCode.OK, ok.StatusCode); }
            using (var limited = await client.GetAsync("/v1/foods/barcode/" + NewCode(13), Ct))
            { Assert.Equal(HttpStatusCode.TooManyRequests, limited.StatusCode); Assert.True(limited.Headers.Contains("Retry-After")); }
            using (var hit = await client.GetAsync("/v1/foods/barcode/" + first, Ct)) { Assert.Equal(HttpStatusCode.OK, hit.StatusCode); }
            Assert.Equal(2, wire.Calls);
        }
        await using (var api = new BarcodeApi(postgres, h, wire, new() { ["Catalog:OpenFoodFacts:ReadsPerMinute"] = "1" }))
        {
            var otherDevice = Guid.NewGuid();
            using var one = Client(api, h.Device); await SignIn(one, h, h.Device);
            using var two = Client(api, otherDevice); await SignIn(two, h, otherDevice);
            using (var ok = await one.GetAsync("/v1/foods/barcode/" + NewCode(13), Ct)) { Assert.Equal(HttpStatusCode.OK, ok.StatusCode); }
            using (var spent = await two.GetAsync("/v1/foods/barcode/" + NewCode(13), Ct)) { Assert.Equal(HttpStatusCode.ServiceUnavailable, spent.StatusCode); }
            Assert.Equal(3, wire.Calls);
            h.Clock.Advance(TimeSpan.FromMinutes(1) + TimeSpan.FromSeconds(1));
            using (var again = await two.GetAsync("/v1/foods/barcode/" + NewCode(13), Ct)) { Assert.Equal(HttpStatusCode.OK, again.StatusCode); }
        }
    }

    [Fact]
    public async Task Expiry_job_removes_only_rows_past_the_stale_window()
    {
        var old = NewCode(13); var fresh = NewCode(13); var clock = new TestClock();
        await using (var insert = postgres.App.CreateCommand("INSERT INTO catalog.off_cache(code,data,expires_at) VALUES($1,'{\"v\":1,\"product\":null}',$2),($3,'{\"v\":1,\"product\":null}',$4)"))
        {
            insert.Parameters.AddWithValue(old); insert.Parameters.AddWithValue(clock.GetUtcNow() - TimeSpan.FromDays(8));
            insert.Parameters.AddWithValue(fresh); insert.Parameters.AddWithValue(clock.GetUtcNow() - TimeSpan.FromDays(6));
            await insert.ExecuteNonQueryAsync(Ct);
        }
        await using (var session = await postgres.SessionAsync())
        {
            await new OffCacheExpiryJob(clock).HandleAsync(new FitnessBuddy.BuildingBlocks.Messaging.QueueMessage(Guid.NewGuid(), OffCacheExpiryJob.Type, "{}", null, 1), session, Ct);
            await session.CommitAsync(Ct);
        }
        await using var count = postgres.App.CreateCommand("SELECT code FROM catalog.off_cache WHERE code=ANY($1)");
        count.Parameters.AddWithValue(new[] { old, fresh });
        Assert.Equal(fresh, await count.ExecuteScalarAsync(Ct) as string);
    }

    [Fact]
    public void Mapper_computes_kcal_from_kj_bounds_values_and_detects_ml()
    {
        using var doc = JsonDocument.Parse("""
            {"product_name":"  Juice\u0000 ","product_name_ar":"عصير","brands":" Brand A , Brand B","product_quantity_unit":"ml",
             "serving_quantity":"250","serving_quantity_unit":"ml","serving_size":"250 ml",
             "nutriments":{"energy_100g":"188.28","proteins_100g":0.5,"carbohydrates_100g":"11","fat_100g":0.1,"fiber_100g":0.2},
             "ingredients_text":"water, sugar","labels_tags":["en:halal",""],"ingredients_analysis_tags":["en:vegan","en:halal"]}
            """);
        var p = OffMapper.Map(doc.RootElement, "5000000000001");
        Assert.Equal("Juice", p.Name); Assert.Equal("عصير", p.NameAr); Assert.Equal("Brand A", p.Brand); Assert.Equal("ml", p.Basis);
        Assert.Equal(45, p.Per100.Kcal!.Value, 3); Assert.Equal(0.5, p.Per100.ProteinG); Assert.Equal(11, p.Per100.CarbsG); Assert.Equal(0.1, p.Per100.FatG);
        Assert.True(p.Per100.Complete); Assert.Equal(250, p.ServingQuantity); Assert.Equal(["en:halal", "en:vegan"], p.Labels);
        using var grams = JsonDocument.Parse("""{"serving_quantity":30,"serving_quantity_unit":"oz","nutriments":{"energy-kcal_100g":2000}}""");
        var g = OffMapper.Map(grams.RootElement, "5000000000001");
        Assert.Equal("g", g.Basis); Assert.Null(g.ServingQuantity); Assert.Null(g.Name);
        Assert.True(OffSanity.Check(g.Per100, g.Basis).Rejected);
    }

    [Fact]
    [Trait("Rule", "07.3-off-sanity")]
    public async Task Lookup_rejects_impossible_products_flags_doubtful_ones_and_rechecks_cached_rows()
    {
        var clock = new TestClock(); var cache = new MemoryCache();
        var bad = NewCode(13); var doubtful = NewCode(13); var good = NewCode(13); var legacy = NewCode(13);
        var client = new FakeClient(code => new(OffFetchStatus.Found, code == bad ? SyntheticProduct(code) with { Per100 = new(1500, 30, 30, 50, 1) }
            : code == doubtful ? SyntheticProduct(code) with { Per100 = new(400, 6, 45, 6, 1) }
            : SyntheticProduct(code) with { Per100 = new(258, 6, 45, 6, 1) }));
        var lookup = Lookup(cache, client, clock);
        Assert.Equal(BarcodeStatus.NotFound, (await lookup.LookupAsync(bad, Guid.NewGuid(), Ct)).Status);
        Assert.Null((await cache.GetAsync(bad, Ct))!.Product);
        var warn = await lookup.LookupAsync(doubtful, Guid.NewGuid(), Ct);
        Assert.Equal(BarcodeStatus.Found, warn.Status); Assert.True(warn.CheckLabel);
        var ok = await lookup.LookupAsync(good, Guid.NewGuid(), Ct);
        Assert.Equal(BarcodeStatus.Found, ok.Status); Assert.False(ok.CheckLabel);
        // A row cached before B22 is checked when it is served.
        await cache.PutAsync(legacy, SyntheticProduct(legacy) with { Per100 = new(2000, 5, 5, 5, 1) }, clock.GetUtcNow() + TimeSpan.FromDays(1), Ct);
        Assert.Equal(BarcodeStatus.NotFound, (await lookup.LookupAsync(legacy, Guid.NewGuid(), Ct)).Status);
        Assert.Equal(3, client.Calls);
    }

    [Fact]
    public async Task Single_flight_includes_the_cache_write_and_a_cancelled_waiter_only_stops_waiting()
    {
        var clock = new TestClock(); var code = NewCode(13);
        var cache = new MemoryCache { HoldPuts = true };
        var client = new FakeClient(_ => new(FitnessBuddy.Modules.Catalog.Application.OffFetchStatus.Found, SyntheticProduct(code)));
        var lookup = Lookup(cache, client, clock);
        using var cancel = new CancellationTokenSource();
        var first = lookup.LookupAsync(code, Guid.NewGuid(), cancel.Token);
        await client.Called.Task.WaitAsync(TimeSpan.FromSeconds(10), Ct);
        await cache.PutStarted.Task.WaitAsync(TimeSpan.FromSeconds(10), Ct);
        // The read is done but the cache write isn't: a new request joins instead of reading OFF again.
        var joined = lookup.LookupAsync(code, Guid.NewGuid(), Ct);
        await cancel.CancelAsync();
        await Assert.ThrowsAnyAsync<OperationCanceledException>(() => first);
        cache.Release.TrySetResult();
        Assert.Equal(FitnessBuddy.Modules.Catalog.Application.BarcodeStatus.Found, (await joined).Status);
        Assert.Equal(1, client.Calls);
        Assert.NotNull((await cache.GetAsync(code, Ct))?.Product);
    }

    [Fact]
    public async Task An_authoritative_not_found_replaces_a_stale_product_and_is_never_served_stale()
    {
        var clock = new TestClock(); var code = NewCode(13);
        var cache = new MemoryCache();
        await cache.PutAsync(code, SyntheticProduct(code), clock.GetUtcNow() - TimeSpan.FromDays(1), Ct);
        var status = FitnessBuddy.Modules.Catalog.Application.OffFetchStatus.NotFound;
        var client = new FakeClient(_ => new(status, RetryAfter: status == FitnessBuddy.Modules.Catalog.Application.OffFetchStatus.Unavailable ? TimeSpan.FromMinutes(5) : null));
        var lookup = Lookup(cache, client, clock);
        Assert.Equal(FitnessBuddy.Modules.Catalog.Application.BarcodeStatus.NotFound, (await lookup.LookupAsync(code, Guid.NewGuid(), Ct)).Status);
        var entry = await cache.GetAsync(code, Ct);
        Assert.Null(entry!.Product); Assert.True(entry.ExpiresAt > clock.GetUtcNow());
        // Even once that answer expires and OFF is down, the removed product is not served again.
        clock.Advance(TimeSpan.FromDays(1) + TimeSpan.FromMinutes(1));
        status = FitnessBuddy.Modules.Catalog.Application.OffFetchStatus.Unavailable;
        Assert.Equal(FitnessBuddy.Modules.Catalog.Application.BarcodeStatus.Unavailable, (await lookup.LookupAsync(code, Guid.NewGuid(), Ct)).Status);
    }

    [Theory]
    [InlineData(HttpStatusCode.TooManyRequests, false)]
    [InlineData(HttpStatusCode.TooManyRequests, true)]
    [InlineData(HttpStatusCode.ServiceUnavailable, false)]
    [InlineData(HttpStatusCode.ServiceUnavailable, true)]
    public async Task Retry_after_reads_seconds_and_http_dates_against_the_clock(HttpStatusCode status, bool date)
    {
        var clock = new TestClock();
        using var wire = new OffWire { Status = status };
        if (date) { wire.RetryAfterDate = clock.GetUtcNow() + TimeSpan.FromMinutes(10); } else { wire.RetryAfterSeconds = 600; }
        var client = new OpenFoodFactsClient(new WireFactory(wire), Microsoft.Extensions.Options.Options.Create(new FitnessBuddy.Modules.Catalog.Application.OffOptions()),
            clock, Microsoft.Extensions.Logging.Abstractions.NullLogger<OpenFoodFactsClient>.Instance);
        var fetched = await client.FetchAsync(NewCode(13), Ct);
        Assert.Equal(FitnessBuddy.Modules.Catalog.Application.OffFetchStatus.Unavailable, fetched.Status);
        Assert.Equal(TimeSpan.FromMinutes(10), fetched.RetryAfter);
        var now = clock.GetUtcNow();
        Assert.Equal(TimeSpan.FromHours(1), OpenFoodFactsClient.RetryAfter(new RetryConditionHeaderValue(now + TimeSpan.FromDays(1)), now));
        Assert.Equal(TimeSpan.FromSeconds(1), OpenFoodFactsClient.RetryAfter(new RetryConditionHeaderValue(now - TimeSpan.FromMinutes(1)), now));
        Assert.Equal(TimeSpan.FromSeconds(60), OpenFoodFactsClient.RetryAfter(null, now));
    }

    private sealed class WireFactory(HttpMessageHandler wire) : IHttpClientFactory
    {
        public HttpClient CreateClient(string name) => new(wire, disposeHandler: false);
    }

    private static FitnessBuddy.Modules.Catalog.Application.BarcodeLookup Lookup(MemoryCache cache, FakeClient client, TestClock clock) =>
        new(cache, client, new FitnessBuddy.Modules.Catalog.Application.OffGate(clock, Microsoft.Extensions.Options.Options.Create(new FitnessBuddy.Modules.Catalog.Application.OffOptions())), clock);

    private static FitnessBuddy.Modules.Catalog.Application.OffProduct SyntheticProduct(string code) =>
        new(code, "Synthetic", null, null, "g", new(100, 1, 1, 1, 1), null, null, null, []);

    private sealed class MemoryCache : FitnessBuddy.Modules.Catalog.Application.IOffCache
    {
        private readonly System.Collections.Concurrent.ConcurrentDictionary<string, FitnessBuddy.Modules.Catalog.Application.OffCacheEntry> rows = new(StringComparer.Ordinal);
        public bool HoldPuts { get; init; }
        public TaskCompletionSource PutStarted { get; } = new(TaskCreationOptions.RunContinuationsAsynchronously);
        public TaskCompletionSource Release { get; } = new(TaskCreationOptions.RunContinuationsAsynchronously);
        public Task<FitnessBuddy.Modules.Catalog.Application.OffCacheEntry?> GetAsync(string code, CancellationToken cancellationToken) =>
            Task.FromResult(rows.TryGetValue(code, out var entry) ? entry : null);
        public async Task PutAsync(string code, FitnessBuddy.Modules.Catalog.Application.OffProduct? product, DateTimeOffset expiresAt, CancellationToken cancellationToken)
        {
            PutStarted.TrySetResult();
            if (HoldPuts) { await Release.Task.WaitAsync(cancellationToken); }
            rows[code] = new(product, expiresAt);
        }
    }

    private sealed class FakeClient(Func<string, FitnessBuddy.Modules.Catalog.Application.OffFetch> answer) : FitnessBuddy.Modules.Catalog.Application.IOffClient
    {
        private int calls;
        public int Calls => Volatile.Read(ref calls);
        public TaskCompletionSource Called { get; } = new(TaskCreationOptions.RunContinuationsAsynchronously);
        public Task<FitnessBuddy.Modules.Catalog.Application.OffFetch> FetchAsync(string code, CancellationToken cancellationToken)
        {
            Interlocked.Increment(ref calls); Called.TrySetResult();
            return Task.FromResult(answer(code));
        }
    }

    private static string NewCode(int length)
    {
        var body = Interlocked.Increment(ref nextCode).ToString(System.Globalization.CultureInfo.InvariantCulture).PadLeft(length - 1, '7')[..(length - 1)];
        var sum = 0;
        for (int i = body.Length - 1, weight = 3; i >= 0; i--, weight = 4 - weight) { sum += (body[i] - '0') * weight; }
        return body + (char)('0' + (10 - sum % 10) % 10);
    }

    private static readonly string[] HalalTags = ["en:halal"];
    private static readonly string[] VegetarianTags = ["en:vegetarian"];

    private static string Product(string name, double? kj, double? fiber)
    {
        var nutriments = new Dictionary<string, object?> { ["proteins_100g"] = 12, ["carbohydrates_100g"] = 50, ["fat_100g"] = 30 };
        if (kj is { } energy) { nutriments["energy-kj_100g"] = energy; } else { nutriments["energy-kcal_100g"] = 520; }
        if (fiber is { } f) { nutriments["fiber_100g"] = f; }
        return JsonSerializer.Serialize(new Dictionary<string, object?>
        {
            ["status"] = 1,
            ["product"] = new Dictionary<string, object?>
            {
                ["product_name"] = name,
                ["brands"] = "Synthetic Brand",
                ["serving_quantity"] = 30,
                ["serving_quantity_unit"] = "g",
                ["nutriments"] = nutriments,
                ["labels_tags"] = HalalTags,
                ["ingredients_analysis_tags"] = VegetarianTags,
            },
        });
    }

    private static HttpClient Client(BarcodeApi api, Guid device)
    {
        var client = api.CreateClient();
        client.DefaultRequestHeaders.Add("X-App-Version", "0.1.0"); client.DefaultRequestHeaders.Add("X-Platform", "android"); client.DefaultRequestHeaders.Add("X-Device-Id", device.ToString());
        return client;
    }

    private static async Task SignIn(HttpClient client, IdentityHarness h, Guid device)
    {
        var tokens = (await h.Service.GuestAsync(device, Ct))!;
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", tokens.AccessToken);
    }

    internal sealed record OffRequest(string Path, string Query, string UserAgent, bool HadAuthorization, bool HadCookie);

    internal sealed class OffWire : HttpMessageHandler
    {
        private int calls;
        public int Calls => Volatile.Read(ref calls);
        public Dictionary<string, string> Products { get; } = new(StringComparer.Ordinal);
        public System.Collections.Concurrent.ConcurrentQueue<OffRequest> Requests { get; } = new();
        public HttpStatusCode Status { get; set; } = HttpStatusCode.OK;
        public int? RetryAfterSeconds { get; set; }
        public DateTimeOffset? RetryAfterDate { get; set; }
        public bool NotFoundByDefault { get; set; } = true;
        public bool Pause { get; set; }
        public TaskCompletionSource Started { get; } = new(TaskCreationOptions.RunContinuationsAsynchronously);
        public TaskCompletionSource Continue { get; } = new(TaskCreationOptions.RunContinuationsAsynchronously);
        protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            Interlocked.Increment(ref calls);
            Requests.Enqueue(new(request.RequestUri!.AbsolutePath, request.RequestUri.Query, string.Join(" ", request.Headers.GetValues("User-Agent")),
                request.Headers.Authorization is not null, request.Headers.Contains("Cookie")));
            Started.TrySetResult();
            if (Pause) { await Continue.Task.WaitAsync(cancellationToken); }
            if (Status != HttpStatusCode.OK)
            {
                var failure = new HttpResponseMessage(Status) { Content = new StringContent("{}", Encoding.UTF8, "application/json") };
                if (RetryAfterSeconds is { } seconds) { failure.Headers.RetryAfter = new RetryConditionHeaderValue(TimeSpan.FromSeconds(seconds)); }
                if (RetryAfterDate is { } at) { failure.Headers.RetryAfter = new RetryConditionHeaderValue(at); }
                return failure;
            }
            var code = request.RequestUri.AbsolutePath.Split('/')[^1];
            if (Products.TryGetValue(code, out var body)) { return new(HttpStatusCode.OK) { Content = new StringContent(body, Encoding.UTF8, "application/json") }; }
            return NotFoundByDefault
                ? new(HttpStatusCode.NotFound) { Content = new StringContent("""{"status":0,"status_verbose":"product not found"}""", Encoding.UTF8, "application/json") }
                : new(HttpStatusCode.OK) { Content = new StringContent(Product("Default " + code, null, 1), Encoding.UTF8, "application/json") };
        }
    }

    internal sealed class BarcodeApi(PostgresFixture p, IdentityHarness h, OffWire wire, Dictionary<string, string?>? extra = null) : WebApplicationFactory<Program>
    {
        public BuddyApiTests.CapturedLogs Logs { get; } = new();
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
                ["RateLimiting:PerIp:PermitLimit"] = "100000",
            }.Concat(extra ?? [])));
            builder.ConfigureTestServices(s =>
            {
                s.AddSingleton<Microsoft.Extensions.Logging.ILoggerProvider>(Logs);
                s.AddSingleton<TimeProvider>(h.Clock); s.AddSingleton<IGoogleIdentityVerifier, IdentityHarness.FakeGoogle>(); s.AddSingleton<IEmailSender>(h.Email);
                s.AddHttpClient(OpenFoodFactsClient.HttpClientName).ConfigurePrimaryHttpMessageHandler(() => wire);
            });
        }
    }
}
