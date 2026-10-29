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
        var database = "fb_upgrade_" + Guid.NewGuid().ToString("N");
        var connection = await postgres.CreateUpgradeDatabaseAsync(database);
        try
        {
            await postgres.Runner.RunAsync(connection, Ct);
            await CatalogModule.ImportAsync(connection, Path.Combine(Root, "build/catalog"), Ct);
            var appConnection = new NpgsqlConnectionStringBuilder(postgres.AppConnection) { Database = database }.ConnectionString;
            await using var source = DatabaseConfiguration.CreateSource(appConnection);
            using var cases = JsonDocument.Parse(await File.ReadAllTextAsync(Path.Combine(Root, "tools/buddy_eval/cases/m3.yaml"), Ct));
            var parsed = JsonSerializer.Deserialize<ParsedMessage>(cases.RootElement.GetProperty("cases").EnumerateArray()
                .Single(r => r.GetProperty("id").GetString() == "T06").GetProperty("parsed").GetRawText(), InterpretProtocol.Json)!;
            await using var h = new IdentityHarness(postgres); await h.InitializeAsync();
            using var wire = new BuddyApiTests.BuddyWire { Parse = _ => parsed };
            await using var api = new BuddyApiTests.BuddyApi(postgres, h, wire, configure: services =>
                services.AddSingleton<IFoodResolver>(new CatalogQueries(new PostgresCatalogStore(source))));
            using var client = api.CreateClient(); BuddyApiTests.Headers(client, h); await BuddyApiTests.SignIn(client, h);
            using (var response = await BuddyApiTests.Send(client, h, Guid.CreateVersion7(), "500ml milk 3%"))
            {
                Assert.Equal(HttpStatusCode.OK, response.StatusCode);
                var body = await response.Content.ReadFromJsonAsync<JsonElement>(Ct);
                Assert.Equal("unmatchedFood", body.GetProperty("intents")[0].GetProperty("reason").GetString());
            }
            parsed = parsed with { Intents = [parsed.Intents[0] with { Items = [parsed.Intents[0].Items[0] with { Variant = null }] }] };
            using (var response = await BuddyApiTests.Send(client, h, Guid.CreateVersion7(), "500ml milk"))
            {
                Assert.Equal(HttpStatusCode.OK, response.StatusCode);
                var body = await response.Content.ReadFromJsonAsync<JsonElement>(Ct);
                Assert.Equal("usda:milk_whole", body.GetProperty("intents")[0].GetProperty("items")[0].GetProperty("match").GetProperty("key").GetString());
            }
            Assert.Equal(2, wire.Calls); // Recorded SDK fixtures only; no provider/key.
        }
        finally { await postgres.DropUpgradeDatabaseAsync(database); }
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
        var (passed, calls) = await RunPublicEvalAsync("m3", "B08-offline.json");
        Assert.Equal(26, passed); Assert.Equal(26, calls);
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
        var (passed, calls) = await RunPublicEvalAsync("b09", "B09-offline.json");
        Assert.Equal(count, passed); Assert.Equal(count, calls); // valid recorded outputs: no repair sends
    }

    /// <summary>
    /// Runs <c>bin/public_eval.dart</c> against a real authenticated loopback API whose provider transport replays the case
    /// file's recorded parsed outputs through the official SDK (no key, no network). Copies the report to the CI artifacts.
    /// </summary>
    private async Task<(int Passed, int Calls)> RunPublicEvalAsync(string caseFile, string artifact)
    {
        await using var h = new IdentityHarness(postgres); await h.InitializeAsync();
        using var cases = JsonDocument.Parse(await File.ReadAllTextAsync(Path.Combine(Root, $"tools/buddy_eval/cases/{caseFile}.yaml"), Ct));
        var rows = cases.RootElement.GetProperty("cases").EnumerateArray().ToArray();
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
        await using var api = new BuddyApiTests.BuddyApi(postgres, h, wire, dailyLimit: 100, s => s.AddSingleton<IFoodResolver, FixtureCatalog>());
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
            return (result.RootElement.GetProperty("passed").GetInt32(), wire.Calls);
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
