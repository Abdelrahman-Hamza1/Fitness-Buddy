using FitnessBuddy.Modules.UserData.Domain;

namespace FitnessBuddy.Modules.UserData.Application;

internal interface ISyncStore
{
    Task<IReadOnlyList<VersionResult>> PushAsync(Guid userId, IReadOnlyList<SyncVersion> versions, DateTimeOffset now, CancellationToken cancellationToken);
    Task<VersionPage> PullAsync(Guid userId, long cursor, int limit, bool history, CancellationToken cancellationToken);
}
