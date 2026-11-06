using FitnessBuddy.BuildingBlocks.Ids;
using FitnessBuddy.BuildingBlocks.Messaging;
using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.Modules.UserData.Domain;

namespace FitnessBuddy.Modules.UserData.Infrastructure;

/// <summary>One request's contribution to <c>userdata.sync_daily</c> (B23 P4): outcomes and reject reasons, never content.</summary>
internal sealed record SyncCounts(int Pushes = 0, int Pulls = 0, int ChangesIn = 0, int Stale = 0, int ClockDrift = 0, int VersionConflict = 0,
    int Unsupported = 0, int InvalidPayload = 0, int DatasetMismatch = 0, int CursorInvalid = 0)
{
    public static SyncCounts Push(IReadOnlyList<VersionResult> results)
    {
        int Reason(string reason) => results.Count(result => result.Status == "invalid" && result.Reason == reason);
        return new(Pushes: 1, ChangesIn: results.Count(result => result.Status == "accepted"), Stale: results.Count(result => result.Status == "stale"),
            ClockDrift: Reason("clockDrift"), VersionConflict: Reason("versionConflict"), Unsupported: Reason("unsupported"),
            InvalidPayload: Reason("invalidPayload"), DatasetMismatch: Reason("datasetMismatch"));
    }

    public static SyncCounts Pull(string? reason) =>
        new(Pulls: 1, DatasetMismatch: reason == "datasetMismatch" ? 1 : 0, CursorInvalid: reason == "cursorInvalid" ? 1 : 0);
}

/// <summary>
/// Writes sync counts inside the caller's transaction under a savepoint (B23 R2#1): a failed counter statement rolls back to
/// the savepoint and the request goes on. The first count for a user also registers the user's retention schedule, so the
/// rows of pull-only users and of rejected pushes expire too (B23 R2#2).
/// </summary>
internal static class SyncCounters
{
    public static Task<Npgsql.PostgresException?> RecordAsync(DatabaseSession session, Guid userId, SyncCounts counts, bool push, DateTimeOffset now,
        TimeProvider clock, IIdGenerator ids, CancellationToken cancellationToken) =>
        session.TryInSavepointAsync(async () =>
        {
            await using var command = session.Command("""
                INSERT INTO userdata.sync_daily(user_id,day,pushes,pulls,changes_in,stale,clock_drift,version_conflict,unsupported,invalid_payload,
                  dataset_mismatch,cursor_invalid,last_push_at,last_pull_at)
                VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14)
                ON CONFLICT(user_id,day) DO UPDATE SET pushes=sync_daily.pushes+excluded.pushes,pulls=sync_daily.pulls+excluded.pulls,
                  changes_in=sync_daily.changes_in+excluded.changes_in,stale=sync_daily.stale+excluded.stale,
                  clock_drift=sync_daily.clock_drift+excluded.clock_drift,version_conflict=sync_daily.version_conflict+excluded.version_conflict,
                  unsupported=sync_daily.unsupported+excluded.unsupported,invalid_payload=sync_daily.invalid_payload+excluded.invalid_payload,
                  dataset_mismatch=sync_daily.dataset_mismatch+excluded.dataset_mismatch,cursor_invalid=sync_daily.cursor_invalid+excluded.cursor_invalid,
                  last_push_at=greatest(sync_daily.last_push_at,excluded.last_push_at),last_pull_at=greatest(sync_daily.last_pull_at,excluded.last_pull_at)
                """);
            command.Parameters.AddWithValue(userId);
            command.Parameters.AddWithValue(DateOnly.FromDateTime(now.UtcDateTime));
            foreach (var value in new[] { counts.Pushes, counts.Pulls, counts.ChangesIn, counts.Stale, counts.ClockDrift, counts.VersionConflict,
                counts.Unsupported, counts.InvalidPayload, counts.DatasetMismatch, counts.CursorInvalid })
            {
                command.Parameters.AddWithValue(value);
            }
            command.Parameters.AddWithValue(NpgsqlTypes.NpgsqlDbType.TimestampTz, push ? (object)now : DBNull.Value);
            command.Parameters.AddWithValue(NpgsqlTypes.NpgsqlDbType.TimestampTz, push ? DBNull.Value : (object)now);
            await command.ExecuteNonQueryAsync(cancellationToken);
            await new QueueWriter(session, clock, ids).ScheduleUserAsync(SyncRetention.ScheduleName(userId), SyncRetention.Cron, SyncRetention.JobType,
                now.AddHours(1), cancellationToken);
        }, cancellationToken);
}
