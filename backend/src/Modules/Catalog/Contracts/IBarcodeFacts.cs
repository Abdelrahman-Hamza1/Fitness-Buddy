namespace FitnessBuddy.Modules.Catalog.Contracts;

/// <summary>
/// Read-only barcode facts for the Buddy agent's <c>lookup_barcode</c> tool (B25): the same cache-then-OFF chain and sanity
/// checks as <c>GET /v1/foods/barcode/{code}</c>, including its per-user gate. Null when not found, invalid, limited or unavailable.
/// </summary>
public interface IBarcodeFacts
{
    Task<BarcodeFacts?> LookupAsync(string code, Guid user, CancellationToken cancellationToken);
}

/// <summary><see cref="Per100"/> is null unless all five nutrients are known; <see cref="Basis"/> is <c>100g</c> or <c>100ml</c>.</summary>
public sealed record BarcodeFacts(string Code, string? Name, string? Brand, string Basis, FoodNutrients? Per100, double? ServingQuantity, string? ServingLabel, bool CheckLabel);
