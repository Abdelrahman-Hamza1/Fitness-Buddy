using FitnessBuddy.Modules.UserData.Domain;

namespace FitnessBuddy.Modules.UserData.Application;

internal sealed class SyncService(ISyncStore store, TimeProvider clock)
{
    public async Task<PushOutcome> PushAsync(Guid userId, IReadOnlyList<SyncVersion> versions, CancellationToken cancellationToken)
    {
        var now = clock.GetUtcNow();
        var results = await store.PushAsync(userId, versions, now, cancellationToken);
        return new PushOutcome(results, now);
    }

    public Task<VersionPage> PullAsync(Guid userId, long cursor, int limit, bool history, CancellationToken cancellationToken) =>
        store.PullAsync(userId, cursor, limit, history, cancellationToken);
}
