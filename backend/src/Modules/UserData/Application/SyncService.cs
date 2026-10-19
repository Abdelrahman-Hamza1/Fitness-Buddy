using FitnessBuddy.Modules.UserData.Domain;
using FitnessBuddy.Modules.Identity.Contracts;

namespace FitnessBuddy.Modules.UserData.Application;

internal sealed class SyncService(ISyncStore store, TimeProvider clock, ISyncTelemetry telemetry)
{
    public async Task<PushOutcome?> PushAsync(IdentitySession principal, Guid? dataset, IReadOnlyList<SyncVersion> versions, CancellationToken cancellationToken)
    {
        var start = clock.GetTimestamp();
        var result = await store.PushForSessionAsync(principal, dataset, versions, clock.GetUtcNow(), cancellationToken);
        telemetry.Record("push", versions.Count, result?.Results.Count(r => r.Status == "stale") ?? 0,
            result?.Results.Count(r => r.Status == "invalid") ?? 0, clock.GetElapsedTime(start).TotalMilliseconds);
        return result;
    }

    public async Task<VersionPage?> PullAsync(IdentitySession principal, Guid? dataset, long cursor, int limit, bool history,
        string? entity, Guid? id, CancellationToken cancellationToken)
    {
        var start = clock.GetTimestamp();
        var page = await store.PullForSessionAsync(principal, dataset, cursor, limit, history, entity, id, cancellationToken);
        telemetry.Record(history ? "history" : "pull", page?.Changes.Count ?? 0, 0, page?.Reason is null ? 0 : 1, clock.GetElapsedTime(start).TotalMilliseconds);
        return page;
    }
}
