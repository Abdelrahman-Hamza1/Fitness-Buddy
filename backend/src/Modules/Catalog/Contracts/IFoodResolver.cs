namespace FitnessBuddy.Modules.Catalog.Contracts;

/// <summary>Read-only catalog matching. State/kind are strict constraints; null means unspecified.</summary>
public interface IFoodResolver
{
    Task<IReadOnlyList<FoodCandidate>> ResolveAsync(FoodMention mention, CancellationToken cancellationToken);
}

public sealed record FoodMention(string? CanonicalEn, string? CanonicalAr, string? State, string? Kind);
public sealed record FoodCandidate(string CatalogKey, string NameEn, string? NameAr, string State, string Kind, double Score);
