namespace FitnessBuddy.Modules.UserData.Contracts;

/// <summary>
/// Content-free sync and storage counts for the admin console (B23, owner O1, TD-118). Implemented with <c>userdata.admin_*</c>
/// functions that only the console login can run: counts, sizes, entity codes, timestamps and pseudonymous ids; never a payload.
/// </summary>
public interface IUserDataAdminReads
{
    /// <summary>Per account (at most 200): live documents, stored bytes, rejects since <paramref name="since"/>, last push and pull.</summary>
    Task<IReadOnlyList<UserSyncStats>> StatsAsync(IReadOnlyCollection<Guid> users, DateOnly since, CancellationToken cancellationToken);

    /// <summary>Accounts with sync rejects since <paramref name="since"/>, most rejects first (then newest id), after <paramref name="after"/>.</summary>
    Task<IReadOnlyList<UserRejects>> UsersWithIssuesAsync(DateOnly since, int limit, UserRejects? after, CancellationToken cancellationToken);

    Task<SyncSummary> SummaryAsync(DateOnly since, CancellationToken cancellationToken);

    /// <summary>Documents by entity and schema version, for one account or (null) everyone.</summary>
    Task<IReadOnlyList<EntityCount>> DocumentsAsync(Guid? user, CancellationToken cancellationToken);
}

public sealed record UserSyncStats(Guid UserId, long Documents, long StorageBytes, long Rejects, DateTimeOffset? LastPushAt, DateTimeOffset? LastPullAt);

public sealed record UserRejects(Guid UserId, long Rejects);

/// <summary>Sync requests and outcomes; the reject reasons are the contract's closed codes.</summary>
public sealed record SyncSummary(long Pushes, long Pulls, long ChangesIn, long Stale, long ClockDrift, long VersionConflict, long Unsupported,
    long InvalidPayload, long DatasetMismatch, long CursorInvalid);

public sealed record EntityCount(string Entity, int SchemaVersion, long Documents, long Deleted);
