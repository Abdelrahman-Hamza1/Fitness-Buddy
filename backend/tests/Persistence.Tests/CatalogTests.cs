using System.Net;
using System.Net.Http.Json;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;
using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.Modules.Catalog;
using FitnessBuddy.Modules.Catalog.Application;
using FitnessBuddy.Modules.Catalog.Contracts;
using FitnessBuddy.Modules.Catalog.Domain;
using FitnessBuddy.Modules.Catalog.Infrastructure;
using Npgsql;

namespace FitnessBuddy.Persistence.Tests;

[Trait("Req", "FD-011")]
[Trait("Req", "FD-020")]
[Trait("Req", "FD-021")]
[Trait("Req", "FD-023")]
[Trait("Rule", "07.5-catalog-parity")]
public sealed class CatalogTests(PostgresFixture postgres)
{
    private static readonly string[] ExerciseTypes = ["assisted", "bodyweight_reps", "distance_duration", "duration", "reps_only", "weight_reps"];
    private static CancellationToken Ct => TestContext.Current.CancellationToken;
    private static string Root => FindRoot();
    private static string FindRoot()
    {
        var directory = new DirectoryInfo(AppContext.BaseDirectory);
        while (directory is not null && !File.Exists(Path.Combine(directory.FullName, "AGENTS.md"))) { directory = directory.Parent; }
        return directory!.FullName;
    }

    [Fact]
    public async Task Every_shared_golden_case_matches_and_is_a_fixed_point()
    {
        var id = ""; var input = ""; var count = 0;
        foreach (var line in await File.ReadAllLinesAsync(Path.Combine(Root, "contracts/testdata/normalization_cases.yaml"), Ct))
        {
            var text = line.Trim();
            if (text.StartsWith("- id: ", StringComparison.Ordinal)) { id = text[6..]; }
            if (text.StartsWith("input: ", StringComparison.Ordinal)) { input = JsonSerializer.Deserialize<string>(text[7..])!; }
            if (text.StartsWith("key: ", StringComparison.Ordinal))
            {
                var key = JsonSerializer.Deserialize<string>(text[5..])!;
                Assert.True(SearchKey.Normalize(input) == key, id); Assert.True(SearchKey.Normalize(key) == key, id + " fixed point"); count++;
            }
        }
        Assert.True(count >= 100);
    }

    [Fact]
    public async Task Import_search_paging_resolver_publication_and_security_boundaries()
    {
        using var release = new SyntheticRelease();
        await CatalogModule.ImportAsync(postgres.MigratorConnection, release.DirectoryPath, Ct);
        await CatalogModule.ImportAsync(postgres.MigratorConnection, release.DirectoryPath, Ct);
        var store = new PostgresCatalogStore(postgres.App); var queries = new CatalogQueries(store);
        var all = await queries.SearchAsync("rice", 50, null, Ct);
        Assert.Equal(["usda:rice_raw", "usda:rice_cooked", "ref:rice_bowl/default"], Keys(all));
        var paged = new List<string>(); string? cursor = null;
        do
        {
            var page = await queries.SearchAsync("rice", 1, cursor, Ct); paged.AddRange(Keys(page)); cursor = page.NextCursor;
        } while (cursor is not null);
        Assert.Equal(Keys(all), paged);
        Assert.Equal("usda:rice_raw", (await queries.SearchAsync("ارز", 50, null, Ct)).Items[0].Food.Data.GetProperty("id").GetString());
        Assert.Equal("usda:rice_raw", Assert.Single((await queries.SearchAsync("roz", 50, null, Ct)).Items).Food.Data.GetProperty("id").GetString());
        Assert.NotEmpty((await queries.SearchAsync("rice bol", 50, null, Ct)).Items);
        Assert.Empty((await queries.SearchAsync("!!!", 50, null, Ct)).Items);
        Assert.Equal("ref:rice_bowl/default", Assert.Single(await queries.ResolveAsync(new FoodMention("rice bowl", "طبق ارز", "cooked", "variant"), Ct)).CatalogKey);
        Assert.Equal(Keys(await queries.SearchAsync("rice bowl", 10, null, Ct)),
            (await queries.ResolveAsync(new FoodMention("rice bowl", null, null, null), Ct)).Select(c => c.CatalogKey));
        Assert.Empty(await queries.ResolveAsync(new FoodMention("rice bowl", null, "raw", "variant"), Ct));
        Assert.All(await queries.ResolveAsync(new FoodMention("rice bowl", null, "cooked", "basic"), Ct), c => Assert.Equal("basic", c.Kind));
        var first = await queries.SearchAsync("rice", 1, null, Ct);
        await Assert.ThrowsAsync<ArgumentException>(() => queries.SearchAsync("chicken", 1, first.NextCursor, Ct));
        await Assert.ThrowsAsync<ArgumentException>(() => queries.SearchAsync("rice", 1, "broken", Ct));
        await Assert.ThrowsAsync<ArgumentException>(() => queries.SearchAsync("rice", 51, null, Ct));
        await using var h = new IdentityHarness(postgres); await h.InitializeAsync();
        await using var factory = new IdentityApiTests.IdentityApi(postgres, h);
        using var client = factory.CreateClient();
        client.DefaultRequestHeaders.Add("X-App-Version", "0.1.0"); client.DefaultRequestHeaders.Add("X-Platform", "android"); client.DefaultRequestHeaders.Add("X-Device-Id", h.Device.ToString());
        using (var anonymous = await client.GetAsync("/v1/foods/search?query=rice&limit=10", Ct)) { Assert.Equal(HttpStatusCode.Unauthorized, anonymous.StatusCode); }
        foreach (var path in new[] { "/v1/foods/usda:rice_raw", "/v1/catalog/packs/latest", "/v1/catalog/packs/110" })
        { using var denied = await client.GetAsync(path, Ct); Assert.Equal(HttpStatusCode.Unauthorized, denied.StatusCode); }
        var tokens = (await h.Service.GuestAsync(h.Device, Ct))!;
        client.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", tokens.AccessToken);
        using (var response = await client.GetAsync("/v1/foods/search?query=rice&limit=10", Ct))
        { Assert.Equal(HttpStatusCode.OK, response.StatusCode); var json = await response.Content.ReadFromJsonAsync<JsonElement>(Ct); Assert.Equal(3, json.GetProperty("items").GetArrayLength()); Assert.Null(json.GetProperty("nextCursor").GetString()); }
        using (var food = await client.GetAsync("/v1/foods/ref:rice_bowl%2Fdefault", Ct))
        { Assert.Equal(HttpStatusCode.OK, food.StatusCode); var json = await food.Content.ReadFromJsonAsync<JsonElement>(Ct); Assert.Equal(100, json.GetProperty("nutrients").GetProperty("kcal").GetDouble()); Assert.NotEmpty(json.GetProperty("servings").EnumerateArray()); }
        using (var latest = await client.GetAsync("/v1/catalog/packs/latest", Ct))
        {
            Assert.Equal(HttpStatusCode.OK, latest.StatusCode); var metadata = await latest.Content.ReadFromJsonAsync<JsonElement>(Ct);
            using var download = await client.GetAsync(metadata.GetProperty("url").GetString(), Ct); Assert.Equal(HttpStatusCode.OK, download.StatusCode);
            var bytes = await download.Content.ReadAsByteArrayAsync(Ct); Assert.Equal(metadata.GetProperty("sha256").GetString(), Convert.ToHexStringLower(SHA256.HashData(bytes))); Assert.Equal(metadata.GetProperty("sizeBytes").GetInt32(), bytes.Length);
        }
        using (var missing = await client.GetAsync("/v1/foods/../../etc/passwd", Ct)) { Assert.Equal(HttpStatusCode.NotFound, missing.StatusCode); }
        await using (var owner = DatabaseConfiguration.CreateSource(postgres.MigratorConnection))
        await using (var forbidden = postgres.App.CreateCommand("UPDATE catalog.foods SET active=false"))
        { var error = await Assert.ThrowsAsync<PostgresException>(() => forbidden.ExecuteNonQueryAsync(Ct)); Assert.Equal("42501", error.SqlState); }
        var registered = (await h.Service.GoogleAsync("valid-catalog", h.Device, Ct))!;
        client.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", registered.AccessToken);
        using (var allowed = await client.GetAsync("/v1/catalog/packs/latest", Ct)) { Assert.Equal(HttpStatusCode.OK, allowed.StatusCode); }
        client.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", tokens.AccessToken);
        var oldPack = (await store.PackAsync(null, Ct))!;
        var retired = release.Foods.Single(f => f["id"]!.GetValue<string>() == "usda:rice_cooked").DeepClone().AsObject();
        release.Bump(); release.RemoveFood("usda:rice_cooked"); release.Write();
        await CatalogModule.ImportAsync(postgres.MigratorConnection, release.DirectoryPath, Ct);
        Assert.Equal(oldPack.Version + 1, (await store.PackAsync(null, Ct))!.Version);
        Assert.NotNull(await store.PackAsync(oldPack.Version, Ct));
        Assert.NotNull(await store.GetAsync("usda:rice_cooked", Ct));
        Assert.DoesNotContain("usda:rice_cooked", Keys(await queries.SearchAsync("rice", 50, null, Ct)));
        await Assert.ThrowsAsync<ArgumentException>(() => queries.SearchAsync("rice", 1, first.NextCursor, Ct));
        var stable = (await store.PackAsync(null, Ct))!.Version;
        release.Bump(); release.Foods[0]["source_ref"] = "synthetic:reused"; release.Write();
        await Assert.ThrowsAsync<InvalidDataException>(() => CatalogModule.ImportAsync(postgres.MigratorConnection, release.DirectoryPath, Ct));
        release.Foods[0]["source_ref"] = "synthetic:rice_raw";
        release.Foods[0]["catalog_version"] = 2; release.Write();
        await Assert.ThrowsAsync<InvalidDataException>(() => CatalogModule.ImportAsync(postgres.MigratorConnection, release.DirectoryPath, Ct));
        release.Foods[0]["catalog_version"] = 1;
        retired["source_ref"] = "synthetic:reused-retired"; release.Foods.Add(retired); release.Write();
        await Assert.ThrowsAsync<InvalidDataException>(() => CatalogModule.ImportAsync(postgres.MigratorConnection, release.DirectoryPath, Ct));
        using (var deleted = await client.DeleteAsync("/v1/me", Ct)) { Assert.Equal(HttpStatusCode.NoContent, deleted.StatusCode); }
        Assert.Equal(stable, (await store.PackAsync(null, Ct))!.Version); Assert.Equal("synthetic:rice_raw", (await store.GetAsync("usda:rice_raw", Ct))!.Data.GetProperty("source_ref").GetString());
    }

    [Fact]
    public async Task Tampered_draft_unknown_schema_duplicate_and_pack_reuse_are_rejected()
    {
        using var release = new SyntheticRelease();
        await CatalogModule.ImportAsync(postgres.MigratorConnection, release.DirectoryPath, Ct);
        var previous = release.Pack; release.Pack = [.. previous, 1]; release.Write();
        await Assert.ThrowsAsync<InvalidDataException>(() => CatalogModule.ImportAsync(postgres.MigratorConnection, release.DirectoryPath, Ct));
        release.Pack = previous; release.Write();
        var manifestFile = Path.Combine(release.DirectoryPath, "release/manifest.json");
        var original = await File.ReadAllTextAsync(manifestFile, Ct);
        foreach (var mutation in new Action<JsonNode>[] { m => m["includes_drafts"] = true, m => m["schema_version"] = 2, m => m["pack"]!["file"] = "../../private", m => m["unknown"] = true })
        {
            var manifest = JsonNode.Parse(original)!; mutation(manifest); await File.WriteAllTextAsync(manifestFile, manifest.ToJsonString(), Ct);
            await Assert.ThrowsAsync<InvalidDataException>(() => CatalogRelease.ReadAsync(release.DirectoryPath, Ct));
        }
        await File.WriteAllTextAsync(manifestFile, original, Ct);
        await File.AppendAllTextAsync(Path.Combine(release.DirectoryPath, "release/foods.jsonl"), "{}\n", Ct);
        await Assert.ThrowsAsync<InvalidDataException>(() => CatalogRelease.ReadAsync(release.DirectoryPath, Ct));
        release.Foods[0]["catalog_version"] = 0; release.Write();
        await Assert.ThrowsAsync<InvalidDataException>(() => CatalogModule.ImportAsync(postgres.MigratorConnection, release.DirectoryPath, Ct));
    }

    [Fact]
    public async Task Invalid_records_duplicate_ids_basis_and_references_fail_before_publication()
    {
        foreach (var mutate in new Action<SyntheticRelease>[]
        {
            r => r.Foods.Add(r.Foods[0].DeepClone().AsObject()),
            r => r.Foods[0]["unknown"] = true,
            r => r.Foods[0]["protein_g"] = -1,
            r => r.Foods[0]["basis"] = "per_100ml",
            r => r.Foods[^1]["kcal_low"] = 1,
            r => r.Foods[^1]["dish_id"] = "ref:missing",
        })
        {
            using var release = new SyntheticRelease(); mutate(release); release.Write();
            await Assert.ThrowsAsync<InvalidDataException>(() => CatalogRelease.ReadAsync(release.DirectoryPath, Ct));
        }
    }

    [Fact]
    [Trait("Req", "WO-001")]
    [Trait("Req", "WO-004")]
    [Trait("Req", "LC-033")]
    public async Task Full_shipped_release_import_and_search()
    {
        // `make test-dotnet` builds the non-mutating release first. CI and local tests use identical bytes.
        var path = Path.Combine(Root, "build/catalog");
        var release = await CatalogRelease.ReadAsync(path, Ct);
        Assert.Equal(100, release.Rows["exercises"].Length);
        Assert.Equal(2276, release.Rows["cities"].Length);
        Assert.Equal(ExerciseTypes,
            release.Rows["exercises"].Select(e => e.GetProperty("type").GetString()!).Distinct().Order(StringComparer.Ordinal));
        // Each case uses an isolated upgrade DB so the global synthetic releases never contaminate this proof.
        var database = "fb_upgrade_" + Guid.NewGuid().ToString("N");
        var connection = await postgres.CreateUpgradeDatabaseAsync(database);
        try
        {
            await postgres.Runner.RunAsync(connection, Ct);
            await CatalogModule.ImportAsync(connection, path, Ct);
            var appConnection = new NpgsqlConnectionStringBuilder(postgres.AppConnection) { Database = database }.ConnectionString;
            await using var source = DatabaseConfiguration.CreateSource(appConnection);
            var queries = new CatalogQueries(new PostgresCatalogStore(source));
            foreach (var exerciseAlias in new[] { "BB bench", "OHP", "Assisted dip machine" })
            {
                var hits = await queries.SearchAsync(exerciseAlias, 50, null, Ct);
                Assert.DoesNotContain(hits.Items, h => h.Food.Data.GetProperty("id").GetString()!.StartsWith("ex:", StringComparison.Ordinal));
            }
            await using (var count = source.CreateCommand("SELECT count(*) FROM catalog.exercises WHERE active"))
            {
                Assert.Equal(100L, await count.ExecuteScalarAsync(Ct));
            }
            await using (var aliases = source.CreateCommand("SELECT count(*) FROM catalog.names WHERE target_id LIKE 'ex:%' AND food_id IS NOT NULL"))
            {
                Assert.Equal(0L, await aliases.ExecuteScalarAsync(Ct));
            }
            // No host timing assertion (TD-104): the searches only have to run.
            foreach (var query in new[] { "rice", "ارز", "roz", "chicken", "دجاج", "djaj", "chiken", "milk", "oil", "banana" })
            {
                _ = await queries.SearchAsync(query, 20, null, Ct);
            }
            Console.WriteLine($"B07 full catalog: foods={release.Rows["foods"].Length},names={release.Rows["names"].Length},packBytes={release.Pack.Length}");
            var fixtures = JsonNode.Parse(await File.ReadAllTextAsync(Path.Combine(Root, "contracts/testdata/catalog_search.json"), Ct))!.AsArray();
            foreach (var fixture in fixtures)
            {
                var result = await queries.SearchAsync(fixture!["query"]!.GetValue<string>(), 50, null, Ct);
                Assert.Equal(fixture["first"]!.GetValue<string>(), Keys(result)[0]);
            }
        }
        finally { await postgres.DropUpgradeDatabaseAsync(database); }
    }

    private static string[] Keys(SearchResult page) => page.Items.Select(r => r.Food.Data.GetProperty("id").GetString()!).ToArray();

    private sealed class SyntheticRelease : IDisposable
    {
        public string DirectoryPath { get; } = Path.Combine(Path.GetTempPath(), "fb-catalog-" + Guid.NewGuid());
        private static int nextVersion = 100;
        private int version = Interlocked.Add(ref nextVersion, 10);
        public List<JsonObject> Foods { get; } = [];
        private List<JsonObject> Names { get; } = [];
        public byte[] Pack { get; set; } = [.. "SQLite format 3\0"u8.ToArray(), .. new byte[100]];
        public SyntheticRelease()
        {
            Directory.CreateDirectory(Path.Combine(DirectoryPath, "release"));
            AddFood("usda:rice_raw", "Rice", "raw", "basic", "ارز", ["rice", "white rice", "rice duplicate", "ارز", "roz"]);
            AddFood("usda:rice_cooked", "Rice cooked", "cooked", "basic", "ارز مطبوخ", ["rice cooked"]);
            AddFood("ref:rice_bowl/default", "Rice bowl", "cooked", "variant", "طبق ارز", ["rice bowl", "طبق ارز"]);
            Write();
        }
        private void AddFood(string id, string name, string state, string kind, string ar, string[] aliases)
        {
            var source = JsonNode.Parse(File.ReadLines(Path.Combine(Root, "build/catalog/release/foods.jsonl")).First())!.AsObject();
            source["id"] = id; source["name_en"] = name; source["name_ar"] = ar; source["state"] = state; source["kind"] = kind;
            source["source"] = kind == "basic" ? "usda" : "reference"; source["source_ref"] = "synthetic:" + id.Split(':')[1]; source["dish_id"] = kind == "basic" ? null : "ref:rice_bowl";
            source["kcal"] = 100; source["catalog_version"] = 1; Foods.Add(source);
            foreach (var alias in aliases) { Names.Add(new JsonObject { ["target_id"] = id, ["lang"] = alias == ar ? "ar" : alias == "roz" ? "arabizi" : "en", ["name"] = alias, ["key"] = SearchKey.Normalize(alias), ["is_display"] = 0 }); }
        }
        public void RemoveFood(string id) { Foods.RemoveAll(f => f["id"]!.GetValue<string>() == id); Names.RemoveAll(n => n["target_id"]!.GetValue<string>() == id); }
        public void Bump() => version++;
        public void Write()
        {
            var dish = JsonNode.Parse("""
                {"id":"ref:rice_bowl","name_en":"Rice bowl","name_ar":"طبق ارز","default_variant_id":"ref:rice_bowl/default","review_status":"reviewed","time_min":null,"catalog_version":1,
                "variants":[{"id":"ref:rice_bowl/default","recipe":[{"food":"usda:rice_raw","grams":100,"range_lo":null,"range_hi":null}],"cooked_total_g":200,"cooked_total_range_lo":180,"cooked_total_range_hi":220,"nutrient_source":null}],
                "portions":{"plate":{"g":200,"range_lo":180,"range_hi":220}},"review":{"status":"reviewed","reviewed_by":"synthetic","sources":["synthetic fixture"],"notes":""}}
                """)!;
            var rows = new Dictionary<string, IEnumerable<JsonNode>>(StringComparer.Ordinal)
            {
                ["foods"] = Foods,
                ["dishes"] = [dish],
                ["names"] = Names,
                ["servings"] = [JsonNode.Parse("""{"food_id":"ref:rice_bowl/default","unit_code":"plate","g":200,"ml":null,"range_lo":180,"range_hi":220,"source":"synthetic"}""")!],
                ["yields"] = [],
                ["exercises"] = [],
                ["cities"] = []
            };
            var files = new JsonObject(); using var hash = IncrementalHash.CreateHash(HashAlgorithmName.SHA256);
            foreach (var name in CatalogRelease.Files)
            {
                var list = rows[name].ToArray(); var bytes = Encoding.UTF8.GetBytes(string.Concat(list.Select(r => r.ToJsonString() + "\n")));
                File.WriteAllBytes(Path.Combine(DirectoryPath, "release", name + ".jsonl"), bytes);
                hash.AppendData(Encoding.UTF8.GetBytes(name + "\0")); hash.AppendData(bytes);
                files[name + ".jsonl"] = new JsonObject { ["sha256"] = Convert.ToHexStringLower(SHA256.HashData(bytes)), ["bytes"] = bytes.Length, ["count"] = list.Length };
            }
            File.WriteAllBytes(Path.Combine(DirectoryPath, "catalog.db"), Pack);
            var manifest = new JsonObject
            {
                ["catalog_version"] = version,
                ["schema_version"] = 1,
                ["content_sha256"] = Convert.ToHexStringLower(hash.GetHashAndReset()),
                ["git_commit"] = null,
                ["includes_drafts"] = false,
                ["files"] = files,
                ["pack"] = new JsonObject { ["file"] = "catalog.db", ["sha256"] = Convert.ToHexStringLower(SHA256.HashData(Pack)), ["bytes"] = Pack.Length },
                ["counts"] = new JsonObject { ["basics"] = Foods.Count(f => f["kind"]!.GetValue<string>() == "basic"), ["variants"] = Foods.Count(f => f["kind"]!.GetValue<string>() == "variant"), ["dishes"] = 1, ["names"] = Names.Count, ["servings"] = 1, ["yields"] = 0, ["exercises"] = 0, ["cities"] = 0 }
            };
            File.WriteAllText(Path.Combine(DirectoryPath, "release/manifest.json"), manifest.ToJsonString());
        }
        public void Dispose() => Directory.Delete(DirectoryPath, true);
    }
}
