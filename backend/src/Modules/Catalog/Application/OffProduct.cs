namespace FitnessBuddy.Modules.Catalog.Application;

/// <summary>Open Food Facts nutrients per 100 g or 100 ml, already bounded; null = not published or out of range.</summary>
internal sealed record OffNutrients(double? Kcal, double? ProteinG, double? CarbsG, double? FatG, double? FiberG)
{
    public bool Complete => Kcal.HasValue && ProteinG.HasValue && CarbsG.HasValue && FatG.HasValue && FiberG.HasValue;
}

/// <summary>The OFF fields the app uses (ODbL data, licence-isolated in <c>catalog.off_cache</c>; never catalog rows).</summary>
internal sealed record OffProduct(string Code, string? Name, string? NameAr, string? Brand, string Basis, OffNutrients Per100,
    double? ServingQuantity, string? ServingLabel, string? IngredientsText, string[] Labels);

internal enum OffFetchStatus { Found, NotFound, Unavailable }

/// <summary>One upstream read. <see cref="RetryAfter"/> is set when OFF itself asked us to back off (429/503).</summary>
internal sealed record OffFetch(OffFetchStatus Status, OffProduct? Product = null, TimeSpan? RetryAfter = null);

internal interface IOffClient
{
    /// <summary>Never throws for network, timeout, status or parse failures: those are <see cref="OffFetchStatus.Unavailable"/>.</summary>
    Task<OffFetch> FetchAsync(string code, CancellationToken cancellationToken);
}

/// <summary>A cached answer; <see cref="Product"/> null is a cached "unknown code".</summary>
internal sealed record OffCacheEntry(OffProduct? Product, DateTimeOffset ExpiresAt);

internal interface IOffCache
{
    Task<OffCacheEntry?> GetAsync(string code, CancellationToken cancellationToken);
    Task PutAsync(string code, OffProduct? product, DateTimeOffset expiresAt, CancellationToken cancellationToken);
}
