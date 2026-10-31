using FitnessBuddy.Modules.Catalog.Domain;
using Microsoft.Extensions.Logging;

namespace FitnessBuddy.Modules.Catalog.Application;

internal enum BarcodeStatus { Found, NotFound, Invalid, UserLimited, Unavailable }

/// <summary><see cref="CheckLabel"/> (B22): the numbers passed the hard checks but something looks off; the app says to compare with the label.</summary>
internal sealed record BarcodeResult(BarcodeStatus Status, OffProduct? Product = null, TimeSpan? RetryAfter = null, bool CheckLabel = false);

/// <summary>Server half of the barcode chain (`07` §7, B10a D1–D6): <c>off_cache</c>, then one gated OFF read.
/// Products live 30 days, unknown codes 1 day; an expired product is served for 7 more days while OFF can't be asked.
/// Every OFF product, fresh or cached, goes through <see cref="OffSanity"/> (B22): impossible or unusable rows answer
/// not-found, doubtful ones carry a check-the-label flag. OFF data stays in the cache table; nothing here writes catalog release tables (`07` §3).</summary>
internal sealed partial class BarcodeLookup(IOffCache cache, IOffClient client, OffGate gate, TimeProvider clock, ILogger<BarcodeLookup>? logger = null)
{
    public static readonly TimeSpan FoundTtl = TimeSpan.FromDays(30);
    public static readonly TimeSpan NotFoundTtl = TimeSpan.FromDays(1);
    public static readonly TimeSpan StaleGrace = TimeSpan.FromDays(7);

    public async Task<BarcodeResult> LookupAsync(string raw, Guid user, CancellationToken cancellationToken)
    {
        var code = Gtin.Normalize(raw);
        if (code is null) { return new(BarcodeStatus.Invalid); }
        var cached = await cache.GetAsync(code, cancellationToken);
        if (cached is not null && cached.ExpiresAt > clock.GetUtcNow()) { return Serve(cached.Product); }
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
            OffFetchStatus.Found when fetched.Product is { } product => Serve(product with { Code = code }),
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
                // A rejected product is cached like an unknown code: the user scans the label or creates the food.
                var accepted = OffSanity.Check(product.Per100, product.Basis).Rejected ? null : product with { Code = code };
                await cache.PutAsync(code, accepted, now + (accepted is null ? NotFoundTtl : FoundTtl), CancellationToken.None);
                if (product.Corrections is { Length: > 0 } fixes) { LogCorrections(fixes.Length, string.Join(',', fixes)); }
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
        cached?.Product is { } product && cached.ExpiresAt + StaleGrace > clock.GetUtcNow() ? Serve(product) : null;

    /// <summary>The sanity gate on the way out, so rows cached before B22 are checked too.</summary>
    private BarcodeResult Serve(OffProduct? product)
    {
        if (product is null) { return new(BarcodeStatus.NotFound); }
        var verdict = OffSanity.Check(product.Per100, product.Basis);
        if (verdict.Rejected) { LogRejected(string.Join(',', verdict.Rejects)); return new(BarcodeStatus.NotFound); }
        var scaled = product.Corrections?.Contains(OffSanity.PerServingScaled) == true || product.Corrections?.Contains(OffSanity.PerServingInPer100) == true;
        return new(BarcodeStatus.Found, product, CheckLabel: verdict.Warnings.Length > 0 || scaled);
    }

    // Rule names only: never a barcode or a product name (rule 6).
    private void LogRejected(string rules) { if (logger is { } l) { LogRejectedMessage(l, rules); } }
    private void LogCorrections(int count, string rules) { if (logger is { } l) { LogCorrectionsMessage(l, count, rules); } }

    [LoggerMessage(Level = LogLevel.Information, Message = "Open Food Facts product rejected by sanity rule(s) {Rules}")]
    private static partial void LogRejectedMessage(ILogger logger, string rules);

    [LoggerMessage(Level = LogLevel.Information, Message = "Open Food Facts product repaired by {Count} sanity rule(s): {Rules}")]
    private static partial void LogCorrectionsMessage(ILogger logger, int count, string rules);
}
