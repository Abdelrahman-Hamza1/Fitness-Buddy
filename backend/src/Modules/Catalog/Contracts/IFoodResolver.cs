namespace FitnessBuddy.Modules.Catalog.Contracts;

/// <summary>Read-only catalog matching. State/kind are strict constraints; null means unspecified.</summary>
public interface IFoodResolver
{
    Task<IReadOnlyList<FoodCandidate>> ResolveAsync(FoodMention mention, CancellationToken cancellationToken);
    Task<FoodDetails?> DetailsAsync(string key, CancellationToken cancellationToken);
}

public sealed record FoodMention(string? CanonicalEn, string? CanonicalAr, string? State, string? Kind);
public sealed record FoodCandidate(string CatalogKey, string NameEn, string? NameAr, string State, string Kind, double Score);

/// <summary>Full release facts for offline recomputation by consumers; never model-generated.</summary>
public sealed record FoodDetails(string Key, string NameEn, string? NameAr, string State, string Source,
    FoodNutrients Nutrients, FoodNutrientRange? Ranges, FoodPortion[] Servings, double? DensityGPerMl, string? YieldGroup);
public sealed record FoodNutrients(double Kcal, double ProteinG, double CarbsG, double FatG, double FiberG);
public sealed record FoodNutrientRange(FoodNutrients Low, FoodNutrients High);
public sealed record FoodPortion(string UnitCode, double? G, double? Ml, double? RangeLo, double? RangeHi, string Source);

/// <summary>TD-030 normalization shared in process, without allowing access to Catalog internals.</summary>
public static class FoodName
{
    public static string Normalize(string value) => Domain.SearchKey.Normalize(value);
}
