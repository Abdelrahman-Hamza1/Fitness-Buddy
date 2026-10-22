using FitnessBuddy.Modules.Catalog.Contracts;
using FitnessBuddy.Modules.Catalog.Domain;

namespace FitnessBuddy.Modules.Catalog.Application;

internal sealed class CatalogQueries(ICatalogStore store) : IFoodResolver
{
    public Task<SearchResult> SearchAsync(string query, int limit, string? cursor, CancellationToken ct)
    {
        if (query.Length is < 1 or > 200 || limit is < 1 or > 50 || cursor?.Length > 2048) { throw new ArgumentException("Invalid catalog search parameters."); }
        return store.SearchAsync(SearchKey.Normalize(query), limit, cursor, null, null, ct);
    }
    public Task<FoodRecord?> GetAsync(string id, CancellationToken ct) => store.GetAsync(id, ct);
    public Task<PackRecord?> PackAsync(int? version, CancellationToken ct) => store.PackAsync(version, ct);
    public async Task<IReadOnlyList<FoodCandidate>> ResolveAsync(FoodMention mention, CancellationToken cancellationToken)
    {
        if (mention.CanonicalEn?.Length > 200 || mention.CanonicalAr?.Length > 200 || mention.State?.Length > 32 || mention.Kind?.Length > 32) { throw new ArgumentException("Invalid food mention."); }
        var candidates = new List<FoodCandidate>();
        foreach (var key in new[] { mention.CanonicalEn, mention.CanonicalAr }.Where(s => !string.IsNullOrWhiteSpace(s)).Select(s => SearchKey.Normalize(s!)).Distinct(StringComparer.Ordinal))
        {
            var result = await store.SearchAsync(key, 10, null, mention.State, mention.Kind, cancellationToken);
            candidates.AddRange(result.Items.Select(item =>
            {
                var food = item.Food.Data;
                return new FoodCandidate(food.GetProperty("id").GetString()!, food.GetProperty("name_en").GetString()!, food.GetProperty("name_ar").GetString(),
                    food.GetProperty("state").GetString()!, food.GetProperty("kind").GetString()!, ((2 - item.SourceRank) * 6 + 5 - item.MatchRank + item.Score) / 18);
            }));
        }
        return candidates.GroupBy(c => c.CatalogKey, StringComparer.Ordinal).Select(g => g.MaxBy(c => c.Score)!)
            .OrderByDescending(c => c.Score).ThenBy(c => c.CatalogKey, StringComparer.Ordinal).Take(10).ToArray();
    }
    public async Task<FoodDetails?> DetailsAsync(string key, CancellationToken cancellationToken)
    {
        var row = await store.GetAsync(key, cancellationToken); if (row is null) { return null; }
        var f = row.Data;
        string Text(string name) => f.GetProperty(name).GetString()!;
        double? Number(System.Text.Json.JsonElement element, string name) => element.GetProperty(name).ValueKind == System.Text.Json.JsonValueKind.Null ? null : element.GetProperty(name).GetDouble();
        FoodNutrients Nutrients(string suffix) => new(f.GetProperty("kcal" + suffix).GetDouble(),
            f.GetProperty(suffix.Length == 0 ? "protein_g" : "protein" + suffix).GetDouble(),
            f.GetProperty(suffix.Length == 0 ? "carbs_g" : "carbs" + suffix).GetDouble(),
            f.GetProperty(suffix.Length == 0 ? "fat_g" : "fat" + suffix).GetDouble(),
            f.GetProperty(suffix.Length == 0 ? "fiber_g" : "fiber" + suffix).GetDouble());
        return new(Text("id"), Text("name_en"), f.GetProperty("name_ar").GetString(), Text("state"), Text("source"), Nutrients(""),
            f.GetProperty("kcal_low").ValueKind == System.Text.Json.JsonValueKind.Null ? null : new(Nutrients("_low"), Nutrients("_high")),
            row.Servings.Select(s => new FoodPortion(s.GetProperty("unit_code").GetString()!, Number(s, "g"), Number(s, "ml"), Number(s, "range_lo"), Number(s, "range_hi"), s.GetProperty("source").GetString()!)).ToArray(),
            Number(f, "density_g_per_ml"), f.GetProperty("yield_group").GetString());
    }
}
