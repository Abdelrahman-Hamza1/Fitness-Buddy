using FitnessBuddy.BuildingBlocks.Ops;
using FitnessBuddy.Modules.Catalog.Contracts;
using FitnessBuddy.Modules.UserData.Contracts;

namespace FitnessBuddy.Modules.Admin.Application;

/// <summary>Jobs &amp; sync (AD-014): queues, items in progress per queue kind and type (from heartbeats), failed items, workers, sync in 7 days.</summary>
internal sealed record JobsState(IReadOnlyList<QueueSummary> Queues, IReadOnlyDictionary<(QueueKind Kind, string Type), int> InProgress, IReadOnlyList<FailedItem> Failed,
    IReadOnlyList<WorkerBeat> Workers, SyncSummary Sync, IReadOnlyList<EntityCount> Documents);

/// <summary>Use case: read the Jobs &amp; sync window.</summary>
internal sealed class ReadJobsAndSync(IOpsAdministration ops, IUserDataAdminReads userData, TimeProvider clock)
{
    public const int FailedLimit = 50;
    public static readonly TimeSpan SyncWindow = TimeSpan.FromDays(7);

    public async Task<JobsState> HandleAsync(CancellationToken cancellationToken)
    {
        var now = clock.GetUtcNow();
        var workers = await ops.HeartbeatsAsync(cancellationToken);
        // "In progress (as of the last heartbeat)": only workers that beat recently count (B23 R#11).
        var inProgress = workers.Where(worker => worker.BusyKind is not null && worker.BusyType is not null && now - worker.LastBeatAt <= Domain.OverviewAlerts.WorkerSilence)
            .GroupBy(worker => (worker.BusyKind!.Value, worker.BusyType!)).ToDictionary(group => group.Key, group => group.Count());
        return new JobsState(await ops.QueuesAsync(now, cancellationToken), inProgress, await ops.FailedAsync(FailedLimit, cancellationToken), workers,
            await userData.SummaryAsync(DateOnly.FromDateTime((now - SyncWindow).UtcDateTime), cancellationToken), await userData.DocumentsAsync(null, cancellationToken));
    }
}

/// <summary>
/// The queue changes (AD-014, B23 R#7): each runs the <c>ops</c> function and writes its audit row in one console transaction, so
/// a failed audit insert rolls the change back. The function reports what it found under the row lock (B23b review), and the
/// audit says exactly that: <c>ok</c> with the real before → after, <c>no-op</c> when it already was so (a replayed form), or
/// <c>refused</c> (wrong state, running, missing, not pausable) with the state found. Only <c>ok</c> changed anything.
/// </summary>
internal sealed class QueueActions(IAdminDatabase database, IOpsAdministration ops, IAuditLog audit, QueueVocabulary vocabulary, TimeProvider clock)
{
    public Task<QueueChangeOutcome> RetryAsync(AdminPrincipal principal, QueueKind kind, Guid id, CancellationToken cancellationToken) =>
        RunAsync(principal, "retry", OpsQueues.Code(kind) + " " + id, StateJson, "pending",
            (session, now) => ops.RetryAsync(session, kind, id, now, cancellationToken), cancellationToken);

    public Task<QueueChangeOutcome> CancelAsync(AdminPrincipal principal, Guid id, CancellationToken cancellationToken) =>
        RunAsync(principal, "cancel", "job " + id, StateJson, "cancelled",
            (session, now) => ops.CancelAsync(session, id, now, cancellationToken), cancellationToken);

    public Task<QueueChangeOutcome> SetPausedAsync(AdminPrincipal principal, string jobType, bool paused, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(principal);
        var action = paused ? "pause" : "resume";
        if (!OpsQueues.IsPausable(jobType) || !vocabulary.JobTypes.Contains(jobType, StringComparer.Ordinal))
        {
            return RunAsync(principal, action, "job type", PausedJson, "", (_, _) => Task.FromResult(new QueueChange(QueueChangeOutcome.Refused, null)), cancellationToken);
        }
        return RunAsync(principal, action, jobType, PausedJson, paused ? "paused" : "running",
            (session, now) => ops.SetPausedAsync(session, jobType, paused, principal.Handle, now, cancellationToken), cancellationToken);
    }

    private static string StateJson(string state) => System.Text.Json.JsonSerializer.Serialize(new { state });

    private static string PausedJson(string state) => state == "paused" ? """{"paused":true}""" : """{"paused":false}""";

    private async Task<QueueChangeOutcome> RunAsync(AdminPrincipal principal, string action, string target, Func<string, string> json, string targetState,
        Func<BuildingBlocks.Persistence.DatabaseSession, DateTimeOffset, Task<QueueChange>> change, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(principal);
        var now = clock.GetUtcNow();
        await using var session = await database.BeginAsync(cancellationToken);
        var result = await change(session, now);
        var before = result.Previous is { } previous ? json(previous) : null;
        var entry = result.Outcome switch
        {
            QueueChangeOutcome.Changed => new AuditEntry(principal.Handle, "jobs", action, "ok", target, before, json(targetState)),
            QueueChangeOutcome.Unchanged => new AuditEntry(principal.Handle, "jobs", action, "no-op", target, before, before),
            _ => new AuditEntry(principal.Handle, "jobs", action, "refused", target, before),
        };
        await audit.AppendAsync(session, entry, now, cancellationToken);
        await session.CommitAsync(cancellationToken);
        return result.Outcome;
    }
}

/// <summary>Catalog (AD-015 read): releases with their food-count change, the OFF cache, lookup outcomes and sanity rules per day.</summary>
internal sealed record CatalogState(IReadOnlyList<(CatalogReleaseInfo Release, int? FoodChange)> Releases, OffCacheInfo Cache, IReadOnlyList<LookupCount> Lookups);

/// <summary>Use case: read the Catalog window (14 days of lookups).</summary>
internal sealed class ReadCatalog(ICatalogAdminReads catalog, TimeProvider clock)
{
    public const int LookupDays = 14;

    public async Task<CatalogState> HandleAsync(CancellationToken cancellationToken)
    {
        var now = clock.GetUtcNow();
        var releases = await catalog.ReleasesAsync(cancellationToken);
        // Newest first: each release's change is against the next older one.
        var rows = releases.Select((release, index) => (release, index + 1 < releases.Count ? release.Foods - releases[index + 1].Foods : (int?)null)).ToArray();
        return new CatalogState(rows, await catalog.OffCacheAsync(now, cancellationToken),
            await catalog.LookupsAsync(DateOnly.FromDateTime(now.UtcDateTime).AddDays(-(LookupDays - 1)), cancellationToken));
    }
}
