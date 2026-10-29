using System.Diagnostics;
using System.Text.Json;
using FitnessBuddy.Modules.Buddy.Domain;
using FitnessBuddy.Modules.Buddy.Infrastructure;
using FitnessBuddy.Modules.Catalog.Contracts;
using FitnessBuddy.Modules.Catalog;
using FitnessBuddy.Modules.Catalog.Application;
using FitnessBuddy.Modules.Catalog.Infrastructure;
using FitnessBuddy.BuildingBlocks.Persistence;
using Npgsql;
using System.Net;
using System.Net.Http.Json;
using Microsoft.Extensions.DependencyInjection;

namespace FitnessBuddy.Persistence.Tests;

public sealed class BuddyPublicEvalTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;
    internal static string Root
    {
        get
        {
            var dir = new DirectoryInfo(AppContext.BaseDirectory);
            while (dir is not null && !File.Exists(Path.Combine(dir.FullName, "AGENTS.md"))) { dir = dir.Parent; }
            return dir!.FullName;
        }
    }
    [Fact]
    [Trait("Req", "AI-070")]
    public async Task Shipped_catalog_without_labelled_percentage_clarifies_instead_of_inventing_variant()
    {
        // Global synthetic catalog tests publish higher versions; keep this real-release proof isolated.
        await WithRealCatalogAsync(async source =>
        {
            using var cases = JsonDocument.Parse(await File.ReadAllTextAsync(Path.Combine(Root, "tools/buddy_eval/cases/m3.yaml"), Ct));
            var parsed = JsonSerializer.Deserialize<ParsedMessage>(cases.RootElement.GetProperty("cases").EnumerateArray()
                .Single(r => r.GetProperty("id").GetString() == "T06").GetProperty("parsed").GetRawText(), InterpretProtocol.Json)!;
            await using var h = new IdentityHarness(postgres); await h.InitializeAsync();
            using var wire = new BuddyApiTests.BuddyWire { Parse = _ => parsed };
            await using var api = new BuddyApiTests.BuddyApi(postgres, h, wire, configure: services =>
                services.AddSingleton<IFoodResolver>(new CatalogQueries(new PostgresCatalogStore(source))));
            using var client = api.CreateClient(); BuddyApiTests.Headers(client, h); await BuddyApiTests.SignIn(client, h);
            // Since release v7 whole milk is labelled "3.25% fat" (B09b WP5), so 3% matches it at the stated precision; a
            // percentage no release name carries (1.5%) must still clarify instead of borrowing another milk's facts.
            var stated = parsed;
            ParsedMessage WithVariant(string? variant) =>
                stated with { Intents = [stated.Intents[0] with { Items = [stated.Intents[0].Items[0] with { Variant = variant }] }] };
            parsed = WithVariant("1.5%");
            using (var response = await BuddyApiTests.Send(client, h, Guid.CreateVersion7(), "500ml milk 1.5%"))
            {
                Assert.Equal(HttpStatusCode.OK, response.StatusCode);
                var body = await response.Content.ReadFromJsonAsync<JsonElement>(Ct);
                Assert.Equal("unmatchedFood", body.GetProperty("intents")[0].GetProperty("reason").GetString());
            }
            foreach (var (variant, text) in new[] { ("3%", "500ml milk 3%"), ((string?)null, "500ml milk") })
            {
                parsed = WithVariant(variant);
                using var response = await BuddyApiTests.Send(client, h, Guid.CreateVersion7(), text);
                Assert.Equal(HttpStatusCode.OK, response.StatusCode);
                var body = await response.Content.ReadFromJsonAsync<JsonElement>(Ct);
                Assert.Equal("usda:milk_whole", body.GetProperty("intents")[0].GetProperty("items")[0].GetProperty("match").GetProperty("key").GetString());
            }
            Assert.Equal(3, wire.Calls); // Recorded SDK fixtures only; no provider/key.
        });
    }

    [Fact]
    [Trait("Req", "AI-010")]
    [Trait("Req", "AI-016")]
    [Trait("Req", "AI-020")]
    [Trait("Req", "AI-022")]
    [Trait("Req", "AI-023")]
    [Trait("Req", "AI-015")]
    public async Task M3_multilingual_fixtures_pass_real_HTTP_SDK_resolver_and_Dart_grader()
    {
        var (report, calls) = await RunPublicEvalAsync("m3", "B08-offline.json");
        Assert.Equal(26, report.GetProperty("passed").GetInt32()); Assert.Equal(26, calls);
    }

    [Fact]
    [Trait("Req", "AI-091")]
    [Trait("Req", "AI-090")]
    [Trait("Req", "AI-050")]
    [Trait("Req", "AI-051")]
    [Trait("Req", "AI-055")]
    [Trait("Req", "AI-100")]
    [Trait("Req", "AI-101")]
    [Trait("Req", "AI-102")]
    [Trait("Req", "AI-054")]
    [Trait("Req", "DY-031")]
    [Trait("Req", "DY-044")]
    [Trait("Req", "DY-045")]
    [Trait("Req", "AI-010")]
    public async Task B09_intent_fixtures_pass_real_HTTP_SDK_resolver_and_Dart_grader()
    {
        // T03, T20–T29 (+ AR/Arabizi), DY-045, the AI-091 edges and active-card follow-ups; the Dart grader also checks PA5
        // provenance (every response UUID is a request context ID) on every case.
        using var cases = JsonDocument.Parse(await File.ReadAllTextAsync(Path.Combine(Root, "tools/buddy_eval/cases/b09.yaml"), Ct));
        var count = cases.RootElement.GetProperty("cases").GetArrayLength();
        var (report, calls) = await RunPublicEvalAsync("b09", "B09-offline.json");
        Assert.Equal(count, report.GetProperty("passed").GetInt32()); Assert.Equal(count, calls); // valid recorded outputs: no repair sends
    }

    [Fact]
    [Trait("Req", "AQ-02")]
    [Trait("Req", "AQ-03")]
    [Trait("Req", "AQ-04")]
    [Trait("Req", "AQ-06")]
    [Trait("Req", "AQ-07")]
    [Trait("Req", "AQ-08")]
    [Trait("Req", "AQ-10")]
    public async Task Real_catalog_runs_write_engine_level_AQ_reports_for_M3_and_B09()
    {
        // B09b: the recorded interpretations go through the real HTTP API, SDK, resolver and the imported release, then the
        // Dart CLI runs fb_domain's ProposalEngine on each response. This test proves the harness (every row 200, rows = the
        // selected cases, the imported catalog version, no repair send); the CI eval job gates the AQ thresholds (D22).
        await WithRealCatalogAsync(async source =>
        {
            using var manifest = JsonDocument.Parse(await File.ReadAllTextAsync(Path.Combine(Root, "build/catalog/release/manifest.json"), Ct));
            var version = manifest.RootElement.GetProperty("catalog_version").GetInt32();
            var aq = new { catalogDir = Path.Combine(Root, "build/catalog") };
            void Catalog(IServiceCollection services) => services.AddSingleton<IFoodResolver>(new CatalogQueries(new PostgresCatalogStore(source)));
            foreach (var (caseFile, artifact) in new[] { ("m3", "B09b-aq-m3.json"), ("b09", "B09b-aq-b09.json") })
            {
                var ids = CaseIds(caseFile, aqOnly: true);
                if (caseFile == "m3") { Assert.Equal(CaseIds("m3", aqOnly: false), ids); } // every M3 case is graded
                var (report, calls) = await RunPublicEvalAsync(caseFile, artifact, Catalog, aq, ids);
                Assert.Equal("aq", report.GetProperty("kind").GetString());
                var rows = report.GetProperty("rows").EnumerateArray().ToArray();
                Assert.Equal(ids, rows.Select(r => r.GetProperty("id").GetString()!).ToArray());
                Assert.All(rows, r => Assert.Equal(200, r.GetProperty("status").GetInt32()));
                Assert.Equal(version, report.GetProperty("catalog").GetProperty("version").GetInt32());
                Assert.Equal(rows.Length, calls); // valid recorded outputs: no repair sends
            }
        });
    }

    private static string[] CaseIds(string caseFile, bool aqOnly)
    {
        using var cases = JsonDocument.Parse(File.ReadAllText(Path.Combine(Root, $"tools/buddy_eval/cases/{caseFile}.yaml")));
        return cases.RootElement.GetProperty("cases").EnumerateArray().Where(c => !aqOnly || c.TryGetProperty("aq", out _))
            .Select(c => c.GetProperty("id").GetString()!).ToArray();
    }

    /// <summary>A scratch database with migrations and the generated real release (<c>build/catalog</c>) imported.</summary>
    private async Task WithRealCatalogAsync(Func<NpgsqlDataSource, Task> run)
    {
        var database = "fb_upgrade_" + Guid.NewGuid().ToString("N");
        var connection = await postgres.CreateUpgradeDatabaseAsync(database);
        try
        {
            await postgres.Runner.RunAsync(connection, Ct);
            await CatalogModule.ImportAsync(connection, Path.Combine(Root, "build/catalog"), Ct);
            var appConnection = new NpgsqlConnectionStringBuilder(postgres.AppConnection) { Database = database }.ConnectionString;
            await using var source = DatabaseConfiguration.CreateSource(appConnection);
            await run(source);
        }
        finally { await postgres.DropUpgradeDatabaseAsync(database); }
    }

    /// <summary>
    /// Runs <c>bin/public_eval.dart</c> against a real authenticated loopback API whose provider transport replays the case
    /// file's recorded parsed outputs through the official SDK (no key, no network). Copies the report to the CI artifacts.
    /// <paramref name="resolver"/> replaces the synthetic fixture catalog; <paramref name="aq"/> switches the CLI to B09b's
    /// AQ mode; <paramref name="caseIds"/> selects cases in order.
    /// </summary>
    private async Task<(JsonElement Report, int Calls)> RunPublicEvalAsync(string caseFile, string artifact,
        Action<IServiceCollection>? resolver = null, object? aq = null, string[]? caseIds = null)
    {
        await using var h = new IdentityHarness(postgres); await h.InitializeAsync();
        using var cases = JsonDocument.Parse(await File.ReadAllTextAsync(Path.Combine(Root, $"tools/buddy_eval/cases/{caseFile}.yaml"), Ct));
        var rows = cases.RootElement.GetProperty("cases").EnumerateArray().ToArray();
        // The wire finds a case by its message text (requests carry no case ID): cases sharing a text (T02/T03) must carry
        // the same recorded output, or a replay would grade one case with another's fixture (B09b PA26).
        foreach (var group in rows.GroupBy(r => r.GetProperty("text").GetString()))
        {
            var first = System.Text.Json.Nodes.JsonNode.Parse(group.First().GetProperty("parsed").GetRawText());
            Assert.All(group, r => Assert.True(System.Text.Json.Nodes.JsonNode.DeepEquals(first, System.Text.Json.Nodes.JsonNode.Parse(r.GetProperty("parsed").GetRawText())),
                r.GetProperty("id").GetString() + " shares a text with a different parsed fixture"));
        }
        using var wire = new BuddyApiTests.BuddyWire
        {
            Parse = body =>
            {
                using var request = JsonDocument.Parse(body);
                var input = request.RootElement.GetProperty("input").EnumerateArray().Last().GetProperty("content")[0].GetProperty("text").GetString()!;
                using var message = JsonDocument.Parse(input);
                var text = message.RootElement.GetProperty("text").GetString();
                var row = rows.First(r => r.GetProperty("text").GetString() == text);
                return JsonSerializer.Deserialize<ParsedMessage>(row.GetProperty("parsed").GetRawText(), InterpretProtocol.Json)!;
            },
        };
        await using var api = new BuddyApiTests.BuddyApi(postgres, h, wire, dailyLimit: 100, resolver ?? (s => s.AddSingleton<IFoodResolver, FixtureCatalog>()));
        api.UseKestrel(0); using var client = api.CreateClient(); BuddyApiTests.Headers(client, h); await BuddyApiTests.SignIn(client, h);
        var report = Path.Combine(Path.GetTempPath(), $"{caseFile}-eval-" + Guid.NewGuid() + ".json");
        try
        {
            var dart = Environment.GetEnvironmentVariable("DART") ?? (File.Exists("/home/abood/development/flutter-3.47.7/bin/dart") ? "/home/abood/development/flutter-3.47.7/bin/dart" : "dart");
            var info = new ProcessStartInfo(dart) { WorkingDirectory = Root, RedirectStandardInput = true, RedirectStandardOutput = true, RedirectStandardError = true };
            info.ArgumentList.Add("run"); info.ArgumentList.Add("tools/buddy_eval/bin/public_eval.dart");
            using var process = Process.Start(info)!;
            await process.StandardInput.WriteAsync(JsonSerializer.Serialize(new
            {
                endpoint = client.BaseAddress!.ToString(),
                token = client.DefaultRequestHeaders.Authorization!.Parameter,
                deviceId = h.Device,
                now = h.Clock.GetUtcNow(),
                mode = "fixture",
                caseFile,
                report,
                caseIds,
                aq,
            }));
            process.StandardInput.Close();
            var stdout = process.StandardOutput.ReadToEndAsync(Ct); var stderr = process.StandardError.ReadToEndAsync(Ct);
            await process.WaitForExitAsync(Ct);
            var output = await stdout + await stderr;
            if (process.ExitCode != 0)
            {
                // Failing rows name only case IDs and check names (no content) so a CI log points at the regression;
                // a run that failed before writing its report still shows the CLI's content-free output.
                var failed = File.Exists(report) ? FailedRows(await File.ReadAllTextAsync(report, Ct)) : "no report";
                Assert.Fail($"public_eval exited {process.ExitCode}: {failed} {output}");
            }
            using var result = JsonDocument.Parse(await File.ReadAllTextAsync(report, Ct));
            Assert.Equal(caseFile, result.RootElement.GetProperty("caseFile").GetString());
            Assert.True(System.Text.Json.Nodes.JsonNode.DeepEquals(System.Text.Json.Nodes.JsonNode.Parse(ProductionProtocol.Schema.GetRawText()),
                System.Text.Json.Nodes.JsonNode.Parse(JsonDocument.Parse(wire.Requests[0]).RootElement.GetProperty("text").GetProperty("format").GetProperty("schema").GetRawText())));
            Assert.DoesNotContain(h.Device.ToString(), string.Join('|', wire.Requests), StringComparison.Ordinal);
            // Generated reports contain IDs/booleans/measurements only, and are reproducible CI artifacts.
            var destination = Path.Combine(Root, "backend", "artifacts", "buddy"); Directory.CreateDirectory(destination);
            File.Copy(report, Path.Combine(destination, artifact), overwrite: true);
            return (result.RootElement.Clone(), wire.Calls);
        }
        finally { File.Delete(report); }
    }

    private static string FailedRows(string report)
    {
        using var result = JsonDocument.Parse(report);
        return string.Join(' ', result.RootElement.GetProperty("rows").EnumerateArray().Where(r => !r.GetProperty("passed").GetBoolean())
            .Select(r => r.GetProperty("id").GetString() + ":" + string.Join(',', r.GetProperty("checks").EnumerateObject().Where(c => c.Value.ValueKind != JsonValueKind.True).Select(c => c.Name))));
    }

    private sealed class FixtureCatalog : IFoodResolver
    {
        public Task<IReadOnlyList<FoodCandidate>> ResolveAsync(FoodMention mention, CancellationToken cancellationToken)
        {
            var name = mention.CanonicalEn!;
            IReadOnlyList<FoodCandidate> values = mention.State is not null ? [Candidate(name, mention.State)]
                : [Candidate(name, "raw"), Candidate(name, "cooked")];
            return Task.FromResult(values);
        }
        private static FoodCandidate Candidate(string name, string state) => new(name + "/" + state, name, null, state, "basic", 1);
        public Task<FoodDetails?> DetailsAsync(string key, CancellationToken cancellationToken)
        {
            var split = key.LastIndexOf('/');
            return Task.FromResult<FoodDetails?>(new(key, key[..split], null, key[(split + 1)..], "synthetic-fixture",
                new(130, 2, 28, 1, 1), null, [new("serving", 100, null, null, null, "synthetic-fixture")], null, "synthetic-fixture"));
        }
    }
}
