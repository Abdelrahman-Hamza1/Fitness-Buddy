using FitnessBuddy.Modules.Catalog.Contracts;

namespace FitnessBuddy.Modules.Catalog.Application;

internal sealed class BarcodeFactsAdapter(BarcodeLookup lookup) : IBarcodeFacts
{
    public async Task<BarcodeFacts?> LookupAsync(string code, Guid user, CancellationToken cancellationToken)
    {
        var result = await lookup.LookupAsync(code, user, cancellationToken);
        if (result is not { Status: BarcodeStatus.Found, Product: { } p }) { return null; }
        var n = p.Per100;
        var per100 = n.Complete ? new FoodNutrients(n.Kcal!.Value, n.ProteinG!.Value, n.CarbsG!.Value, n.FatG!.Value, n.FiberG!.Value) : null;
        return new(p.Code, p.Name, p.Brand, p.Basis, per100, p.ServingQuantity, p.ServingLabel, result.CheckLabel);
    }
}
