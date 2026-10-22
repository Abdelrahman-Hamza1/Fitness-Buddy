using System.Diagnostics;
using System.Net;
using System.Text.Json;
using FitnessBuddy.Modules.Buddy.Infrastructure;
using FitnessBuddy.Modules.Catalog;
using Microsoft.Extensions.AI;
using Microsoft.Extensions.DependencyInjection;

namespace FitnessBuddy.Persistence.Tests;

// Paid execution is opt-in and outside every make/CI target. The durable transport fence counts all repairs.
public sealed class BuddyLiveTests(PostgresFixture postgres)
{
    private static readonly JsonSerializerOptions ReportJson = new() { WriteIndented = true };
    private static CancellationToken Ct => TestContext.Current.CancellationToken;
    [Fact]
    [Trait("Req", "AQ-12")]
    public async Task Owner_authorized_max10_synthetic_live_measurement()
    {
        if (Environment.GetEnvironmentVariable("FB_B08_LIVE") != "owner-2026-10-21-max10") { return; }
        var root = BuddyPublicEvalTests.Root;
        var state = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), ".local", "state", "fitness-buddy");
        Directory.CreateDirectory(state); if (!OperatingSystem.IsWindows()) { File.SetUnixFileMode(state, UnixFileMode.UserRead | UnixFileMode.UserWrite | UnixFileMode.UserExecute); }
        var counter = Path.Combine(state, "B08-openai-20261021.count");
        using var transport = new PaidBudgetTransport(counter);
        await CatalogModule.ImportAsync(postgres.MigratorConnection, Path.Combine(root, "build/catalog"), Ct);
        await using var h = new IdentityHarness(postgres); await h.InitializeAsync();
        using var unused = new BuddyApiTests.BuddyWire();
        await using var api = new BuddyApiTests.BuddyApi(postgres, h, unused, configure: services =>
            services.AddSingleton<IChatClient>(_ => OpenAIClientFactory.Create(ReadKey(), new HttpClient(transport, disposeHandler: false))));
        api.UseKestrel(0); using var client = api.CreateClient(); BuddyApiTests.Headers(client, h); await BuddyApiTests.SignIn(client, h);
        using var cases = JsonDocument.Parse(await File.ReadAllTextAsync(Path.Combine(root, "tools/buddy_eval/cases/m3.yaml"), Ct));
        var allowed = new[] { "T04", "AR-T04", "AZ-T04", "T06", "T01", "T07", "T39", "T40" };
        var ids = Environment.GetEnvironmentVariable("FB_B08_LIVE_CASES")?.Split(',') ?? allowed;
        Assert.True(ids.Distinct(StringComparer.Ordinal).Count() == ids.Length && ids.All(id => allowed.Contains(id, StringComparer.Ordinal)));
        var measurements = new List<object>(); var times = new List<double>();
        var reportPath = Path.Combine(root, "tools/buddy_eval/reports/B08-live.json");
        if (File.Exists(reportPath))
        {
            using var old = JsonDocument.Parse(await File.ReadAllTextAsync(reportPath, Ct));
            foreach (var row in old.RootElement.GetProperty("rows").EnumerateArray())
            { measurements.Add(row.Clone()); times.Add(row.GetProperty("elapsedMs").GetDouble()); }
        }
        foreach (var id in ids)
        {
            if (transport.Count >= 10) { break; }
            var row = cases.RootElement.GetProperty("cases").EnumerateArray().Single(r => r.GetProperty("id").GetString() == id);
            var watch = Stopwatch.StartNew();
            using var response = await BuddyApiTests.Send(client, h, Guid.CreateVersion7(), row.GetProperty("text").GetString()!);
            watch.Stop();
            string[] kinds = []; var explicitCookedPass = false; var hasRealMatch = false; var hasEstimate = false;
            if (response.StatusCode == HttpStatusCode.OK)
            {
                using var body = JsonDocument.Parse(await response.Content.ReadAsStringAsync(Ct));
                var intents = body.RootElement.GetProperty("intents").EnumerateArray().ToArray();
                kinds = intents.Select(i => i.GetProperty("kind").GetString()!).ToArray();
                var item = intents.Where(i => i.GetProperty("kind").GetString() == "foodLog").SelectMany(i => i.GetProperty("items").EnumerateArray()).FirstOrDefault();
                if (item.ValueKind != JsonValueKind.Undefined)
                {
                    hasRealMatch = item.GetProperty("match").ValueKind != JsonValueKind.Null;
                    hasEstimate = item.GetProperty("estimate").ValueKind != JsonValueKind.Null;
                    explicitCookedPass = item.GetProperty("amount").GetProperty("value").ValueKind == JsonValueKind.Number
                        && item.GetProperty("amount").GetProperty("value").GetDouble() == 250
                        && item.GetProperty("amount").GetProperty("unit").GetString() == "g"
                        && (hasRealMatch && item.GetProperty("match").GetProperty("state").GetString() == "cooked"
                            || item.GetProperty("dimensions").EnumerateArray().Any(d => d.GetProperty("kind").GetString() == "state" && d.GetProperty("statedValue").GetString() == "cooked"));
                }
            }
            times.Add(watch.Elapsed.TotalMilliseconds);
            measurements.Add(new { id, status = (int)response.StatusCode, elapsedMs = watch.Elapsed.TotalMilliseconds, kinds, hasRealMatch, hasEstimate, explicitCookedPass, physicalSends = transport.Count });
            // Stop a failed provider/configuration run; do not spend the remaining budget blindly.
            if ((int)response.StatusCode >= 500) { break; }
        }
        times.Sort();
        var report = new
        {
            scope = "Owner-authorized synthetic laptop HTTP smoke, real catalog and provider; not broad AQ acceptance",
            physicalSends = transport.Count,
            p90Ms = times.Count == 0 ? (double?)null : times[(int)Math.Ceiling(times.Count * .9) - 1],
            rows = measurements
        };
        await File.WriteAllTextAsync(reportPath, JsonSerializer.Serialize(report, ReportJson) + "\n", Ct);
        Assert.InRange(transport.Count, 0, 10);
    }
    private static string ReadKey()
    {
        var path = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), ".config", "fitness-buddy", "openai-api-key");
        if (new FileInfo(path).LinkTarget is not null || !OperatingSystem.IsWindows() && (File.GetUnixFileMode(path) & (UnixFileMode)63) != 0) { throw new InvalidOperationException("Live credential must be private."); }
        return File.ReadAllText(path).Trim();
    }
    private sealed class PaidBudgetTransport(string path) : DelegatingHandler(new HttpClientHandler { AllowAutoRedirect = false })
    {
        public int Count => PaidSmokeBudget.Count(path);
        protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            if (request.RequestUri is not { Scheme: "https", Host: "api.openai.com", AbsolutePath: "/v1/responses" }) { throw new HttpRequestException("Unexpected live provider route."); }
            PaidSmokeBudget.Reserve(path);
            return await base.SendAsync(request, cancellationToken);
        }
    }
}
