using System.Text.Json;
using FitnessBuddy.Modules.Catalog.Application;

namespace FitnessBuddy.Modules.Catalog.Api;

internal sealed record CatalogNutrients(double Kcal, double ProteinG, double CarbsG, double FatG, double FiberG);
internal sealed record CatalogNutrientRange(CatalogNutrients Low, CatalogNutrients High);
internal sealed record CatalogServing(string UnitCode, double? G, double? Ml, double? RangeLo, double? RangeHi, string Source);
internal sealed record CatalogFood(string CatalogKey, string Kind, string Source, string? SourceRef, string NameEn, string? NameAr,
    string State, bool Verified, int CatalogVersion, CatalogNutrients Nutrients, CatalogNutrientRange? Ranges,
    Dictionary<string, double>? Extras, double? DensityGPerMl, string? YieldGroup, CatalogServing[] Servings)
{
    internal static CatalogFood From(FoodRecord row)
    {
        var f = row.Data;
        string Text(string name) => f.GetProperty(name).GetString()!;
        CatalogNutrients Nutrients(string suffix) => new(f.GetProperty("kcal" + suffix).GetDouble(), f.GetProperty(suffix.Length == 0 ? "protein_g" : "protein" + suffix).GetDouble(),
            f.GetProperty(suffix.Length == 0 ? "carbs_g" : "carbs" + suffix).GetDouble(), f.GetProperty(suffix.Length == 0 ? "fat_g" : "fat" + suffix).GetDouble(), f.GetProperty(suffix.Length == 0 ? "fiber_g" : "fiber" + suffix).GetDouble());
        return new(Text("id"), Text("kind"), Text("source"), Text("source_ref"), Text("name_en"), f.GetProperty("name_ar").GetString(), Text("state"), f.GetProperty("verified").GetInt32() == 1,
            f.GetProperty("catalog_version").GetInt32(), Nutrients(""), f.GetProperty("kcal_low").ValueKind == JsonValueKind.Null ? null : new(Nutrients("_low"), Nutrients("_high")),
            f.GetProperty("extras").ValueKind == JsonValueKind.Null ? null : f.GetProperty("extras").EnumerateObject().ToDictionary(p => p.Name, p => p.Value.GetDouble(), StringComparer.Ordinal),
            Number(f, "density_g_per_ml"), f.GetProperty("yield_group").GetString(), row.Servings.Select(s => new CatalogServing(s.GetProperty("unit_code").GetString()!, Number(s, "g"), Number(s, "ml"), Number(s, "range_lo"), Number(s, "range_hi"), s.GetProperty("source").GetString()!)).ToArray());
    }
    private static double? Number(JsonElement v, string name) => v.GetProperty(name).ValueKind == JsonValueKind.Null ? null : v.GetProperty(name).GetDouble();
}
internal sealed record CatalogSearchPage(CatalogFood[] Items, string? NextCursor);
internal sealed record CatalogPack(int Version, string Url, string Sha256, int SizeBytes, int SchemaVersion);
