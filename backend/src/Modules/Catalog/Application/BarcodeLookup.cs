using FitnessBuddy.Modules.Catalog.Domain;

namespace FitnessBuddy.Modules.Catalog.Application;

internal enum BarcodeStatus { Found, NotFound, Invalid, UserLimited, Unavailable }

internal sealed record BarcodeResult(BarcodeStatus Status, OffProduct? Product = null, TimeSpan? RetryAfter = null);

/// <summary>Server half of the barcode chain (`07` §7, B10a D1–D6): <c>off_cache</c>, then one gated OFF read.
/// Products live 30 days, unknown codes 1 day; an expired product is served for 7 more days while OFF can't be asked.
/// OFF data stays in the cache table; nothing here writes catalog release tables (`07` §3).</summary>
internal sealed class BarcodeLookup(IOffCache cache, IOffClient client, OffGate gate, TimeProvider clock)
{
    public static readonly TimeSpan FoundTtl = TimeSpan.FromDays(30);
    public static readonly TimeSpan NotFoundTtl = TimeSpan.FromDays(1);
    public static readonly TimeSpan StaleGrace = TimeSpan.FromDays(7);

    public async Task<BarcodeResult> LookupAsync(string raw, Guid user, CancellationToken cancellationToken)
    {
        var code = Gtin.Normalize(raw);
        if (code is null) { return new(BarcodeStatus.Invalid); }
        var cached = await cache.GetAsync(code, cancellationToken);
        if (cached is not null && cached.ExpiresAt > clock.GetUtcNow()) { return Answer(cached.Product); }
        // The shared operation includes publishing to the cache, so a request arriving before the write
        // commits joins it, and the answer is cached even when every waiting caller has gone.
        var running = gate.Begin(code, user, () => FetchAndPublishAsync(code), out var denial);
        if (running is null)
        {
            return Stale(cached) ?? (denial == GateDenial.UserLimited
                ? new(BarcodeStatus.UserLimited, RetryAfter: gate.UserRetryAfter(user))
                : new(BarcodeStatus.Unavailable, RetryAfter: gate.GlobalRetryAfter()));
        }
        // A cancelled request only stops waiting; the shared read and its cache write carry on.
        var fetched = await running.WaitAsync(cancellationToken);
        return fetched.Status switch
        {
            OffFetchStatus.Found when fetched.Product is { } product => new(BarcodeStatus.Found, product with { Code = code }),
            OffFetchStatus.NotFound => new(BarcodeStatus.NotFound),
            // Stale answers only for OFF errors or unavailability, never after an authoritative not-found.
            _ => Stale(cached) ?? new(BarcodeStatus.Unavailable, RetryAfter: fetched.RetryAfter ?? gate.CoolDown ?? TimeSpan.FromSeconds(60)),
        };
    }

    private async Task<OffFetch> FetchAndPublishAsync(string code)
    {
        var fetched = await client.FetchAsync(code, CancellationToken.None);
        var now = clock.GetUtcNow();
        switch (fetched.Status)
        {
            case OffFetchStatus.Found when fetched.Product is { } product:
                await cache.PutAsync(code, product with { Code = code }, now + FoundTtl, CancellationToken.None);
                break;
            case OffFetchStatus.NotFound:
                // Authoritative: replaces a stale positive entry too.
                await cache.PutAsync(code, null, now + NotFoundTtl, CancellationToken.None);
                break;
            default:
                break;
        }
        return fetched;
    }

    private BarcodeResult? Stale(OffCacheEntry? cached) =>
        cached?.Product is { } product && cached.ExpiresAt + StaleGrace > clock.GetUtcNow() ? new(BarcodeStatus.Found, product) : null;

    private static BarcodeResult Answer(OffProduct? product) => product is null ? new(BarcodeStatus.NotFound) : new(BarcodeStatus.Found, product);
}
