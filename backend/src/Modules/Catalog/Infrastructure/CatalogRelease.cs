using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using FitnessBuddy.Modules.Catalog.Domain;

namespace FitnessBuddy.Modules.Catalog.Infrastructure;

internal sealed record CatalogRelease(JsonElement Manifest, byte[] Pack, IReadOnlyDictionary<string, JsonElement[]> Rows)
{
    public int Version => Manifest.GetProperty("catalog_version").GetInt32();
    public static readonly string[] Files = ["foods", "dishes", "names", "servings", "yields", "exercises", "cities"];
    public static async Task<CatalogRelease> ReadAsync(string directory, CancellationToken ct)
    {
        using var manifestDocument = JsonDocument.Parse(await ReadBoundedAsync(Path.Combine(directory, "release", "manifest.json"), 65536, ct));
        var manifest = manifestDocument.RootElement.Clone(); ReleaseSchemas.Validate("manifest", manifest);
        if (manifest.GetProperty("includes_drafts").GetBoolean()) { throw new InvalidDataException("Draft catalog releases cannot be published."); }
        var pack = await ReadBoundedAsync(Path.Combine(directory, "catalog.db"), 9999999, ct);
        Verify(manifest.GetProperty("pack"), pack);
        if (pack.Length < 100 || !pack.AsSpan(0, 16).SequenceEqual("SQLite format 3\0"u8)) { throw new InvalidDataException("Invalid catalog pack."); }
        using var content = IncrementalHash.CreateHash(HashAlgorithmName.SHA256);
        var rows = new Dictionary<string, JsonElement[]>(StringComparer.Ordinal);
        long total = pack.Length;
        foreach (var file in Files)
        {
            var bytes = await ReadBoundedAsync(Path.Combine(directory, "release", file + ".jsonl"), 16000000, ct);
            total += bytes.Length; if (total > 64000000) { throw new InvalidDataException("Catalog release exceeds size budget."); }
            var metadata = manifest.GetProperty("files").GetProperty(file + ".jsonl"); Verify(metadata, bytes);
            content.AppendData(Encoding.UTF8.GetBytes(file + "\0")); content.AppendData(bytes);
            var lines = new UTF8Encoding(false, true).GetString(bytes).Split('\n', StringSplitOptions.RemoveEmptyEntries);
            if (lines.Length != metadata.GetProperty("count").GetInt32() || lines.Length > 100000) { throw new InvalidDataException("Invalid catalog row count."); }
            var records = new List<JsonElement>(lines.Length);
            foreach (var line in lines)
            {
                if (line.Length > 131072) { throw new InvalidDataException("Catalog record exceeds size budget."); }
                using var document = JsonDocument.Parse(line, new JsonDocumentOptions { MaxDepth = 24 });
                var value = document.RootElement.Clone(); ReleaseSchemas.Validate(file, value); records.Add(value);
            }
            rows.Add(file, records.ToArray());
        }
        if (Convert.ToHexStringLower(content.GetHashAndReset()) != manifest.GetProperty("content_sha256").GetString()) { throw new InvalidDataException("Invalid catalog content hash."); }
        var release = new CatalogRelease(manifest, pack, rows); release.CheckReferences(); return release;
    }
    private static async Task<byte[]> ReadBoundedAsync(string file, int maximum, CancellationToken ct)
    {
        await using var stream = new FileStream(file, FileMode.Open, FileAccess.Read, FileShare.Read, 4096, true);
        if (stream.Length > maximum) { throw new InvalidDataException("Catalog file exceeds size budget."); }
        var bytes = new byte[(int)stream.Length]; await stream.ReadExactlyAsync(bytes, ct);
        if (stream.ReadByte() != -1) { throw new InvalidDataException("Catalog file changed during import."); }
        return bytes;
    }
    private static void Verify(JsonElement metadata, byte[] bytes)
    {
        if (metadata.GetProperty("bytes").GetInt64() != bytes.Length || metadata.GetProperty("sha256").GetString() != Convert.ToHexStringLower(SHA256.HashData(bytes)))
        { throw new InvalidDataException("Catalog file integrity check failed."); }
    }
    private void CheckReferences()
    {
        Dictionary<string, JsonElement> Index(string file)
        {
            var index = new Dictionary<string, JsonElement>(StringComparer.Ordinal);
            foreach (var row in Rows[file])
            { if (!index.TryAdd(row.GetProperty("id").GetString()!, row)) { throw new InvalidDataException("Duplicate catalog identity."); } }
            return index;
        }
        var foods = Index("foods"); var dishes = Index("dishes"); var exercises = Index("exercises"); _ = Index("cities");
        var identityList = foods.Keys.Concat(dishes.Keys).Concat(exercises.Keys).ToArray();
        var identities = identityList.ToHashSet(StringComparer.Ordinal);
        if (identities.Count != identityList.Length) { throw new InvalidDataException("Duplicate catalog identity."); }
        foreach (var (id, food) in foods)
        {
            var basic = food.GetProperty("kind").GetString() == "basic";
            if (food.GetProperty("basis").GetString() != "per_100g" || food.GetProperty("review_status").GetString() != "reviewed" || food.GetProperty("catalog_version").GetInt32() > Version
                || (basic ? food.GetProperty("source").GetString() != "usda" || !id.StartsWith("usda:", StringComparison.Ordinal) || food.GetProperty("dish_id").ValueKind != JsonValueKind.Null
                    : food.GetProperty("source").GetString() != "reference" || !dishes.ContainsKey(food.GetProperty("dish_id").GetString() ?? ""))) { throw new InvalidDataException("Invalid food identity."); }
            foreach (var nutrient in new[] { "kcal", "protein", "carbs", "fat", "fiber" })
            {
                var hasRange = food.GetProperty("kcal_low").ValueKind != JsonValueKind.Null;
                if ((food.GetProperty(nutrient + "_low").ValueKind != JsonValueKind.Null) != hasRange) { throw new InvalidDataException("Incomplete nutrient range."); }
                var lo = food.GetProperty(nutrient + "_low"); var hi = food.GetProperty(nutrient + "_high");
                if ((lo.ValueKind == JsonValueKind.Null) != (hi.ValueKind == JsonValueKind.Null) || lo.ValueKind != JsonValueKind.Null && lo.GetDecimal() > hi.GetDecimal()) { throw new InvalidDataException("Invalid nutrient range."); }
            }
        }
        foreach (var (id, dish) in dishes)
        {
            var variants = dish.GetProperty("variants").EnumerateArray().Select(v => v.GetProperty("id").GetString()!).ToArray();
            if (dish.GetProperty("review_status").GetString() != "reviewed" || dish.GetProperty("review").GetProperty("status").GetString() != "reviewed"
                || dish.GetProperty("catalog_version").GetInt32() > Version || !variants.Contains(dish.GetProperty("default_variant_id").GetString(), StringComparer.Ordinal)
                || variants.Distinct(StringComparer.Ordinal).Count() != variants.Length
                || variants.Any(v => !foods.TryGetValue(v, out var f) || f.GetProperty("dish_id").GetString() != id)) { throw new InvalidDataException("Invalid dish variants."); }
            foreach (var variant in dish.GetProperty("variants").EnumerateArray())
            {
                var recipe = variant.GetProperty("recipe");
                if (recipe.ValueKind == JsonValueKind.Array && recipe.EnumerateArray().Any(i => !foods.ContainsKey(i.GetProperty("food").GetString()!))) { throw new InvalidDataException("Unknown recipe ingredient."); }
            }
        }
        foreach (var food in foods.Values.Where(f => f.GetProperty("kind").GetString() != "basic"))
        {
            if (!dishes[food.GetProperty("dish_id").GetString()!].GetProperty("variants").EnumerateArray().Any(v => v.GetProperty("id").GetString() == food.GetProperty("id").GetString())) { throw new InvalidDataException("Orphan variant."); }
        }
        if (exercises.Values.Any(e => e.GetProperty("catalog_version").GetInt32() > Version)) { throw new InvalidDataException("Invalid exercise first appearance."); }
        foreach (var name in Rows["names"])
        {
            if (!identities.Contains(name.GetProperty("target_id").GetString()!) || SearchKey.Normalize(name.GetProperty("name").GetString()!) != name.GetProperty("key").GetString()) { throw new InvalidDataException("Invalid alias."); }
        }
        foreach (var serving in Rows["servings"])
        {
            if (!foods.ContainsKey(serving.GetProperty("food_id").GetString()!)) { throw new InvalidDataException("Unknown serving food."); }
            var lo = serving.GetProperty("range_lo"); var hi = serving.GetProperty("range_hi");
            if ((lo.ValueKind == JsonValueKind.Null) != (hi.ValueKind == JsonValueKind.Null) || lo.ValueKind != JsonValueKind.Null && lo.GetDecimal() > hi.GetDecimal()) { throw new InvalidDataException("Invalid serving range."); }
        }
        var counts = Manifest.GetProperty("counts");
        var expected = new Dictionary<string, int>(StringComparer.Ordinal)
        {
            ["basics"] = foods.Values.Count(f => f.GetProperty("kind").GetString() == "basic"),
            ["variants"] = foods.Values.Count(f => f.GetProperty("kind").GetString() != "basic")
        };
        foreach (var name in new[] { "dishes", "names", "servings", "yields", "exercises", "cities" }) { expected[name] = Rows[name].Length; }
        if (expected.Any(p => counts.GetProperty(p.Key).GetInt32() != p.Value)) { throw new InvalidDataException("Invalid catalog counts."); }
    }
}
