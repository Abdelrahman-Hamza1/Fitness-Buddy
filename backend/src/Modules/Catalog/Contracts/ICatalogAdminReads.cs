namespace FitnessBuddy.Modules.Catalog.Contracts;

/// <summary>
/// Content-free catalog facts for the admin console (AD-015; B23, owner O1, TD-118): releases, OFF cache sizes and daily lookup
/// outcomes. Never a barcode, a product or a food name.
/// </summary>
public interface ICatalogAdminReads
{
    Task<IReadOnlyList<CatalogReleaseInfo>> ReleasesAsync(CancellationToken cancellationToken);

    Task<OffCacheInfo> OffCacheAsync(DateTimeOffset now, CancellationToken cancellationToken);

    /// <summary>Per UTC day since <paramref name="since"/>: outcome code, sanity rule code (empty for plain outcomes) and count.</summary>
    Task<IReadOnlyList<LookupCount>> LookupsAsync(DateOnly since, CancellationToken cancellationToken);
}

public sealed record CatalogReleaseInfo(int Version, int SchemaVersion, int Foods, int PackBytes, string ShaPrefix, bool Current);

public sealed record OffCacheInfo(long Products, long UnknownCodes, long Expiring7Days);

/// <summary>Outcomes: <c>found-complete</c>, <c>found-partial</c>, <c>not-found</c>, <c>invalid</c>, <c>limited</c>, <c>unavailable</c>;
/// sanity: <c>sanity-reject</c>, <c>sanity-repair</c>, <c>sanity-warn</c> with the B22 rule name.</summary>
public sealed record LookupCount(DateOnly Day, string Outcome, string Rule, long Lookups);
