using FitnessBuddy.BuildingBlocks.Ids;
using System.Text.Json;
using FitnessBuddy.BuildingBlocks.Jobs;
using FitnessBuddy.BuildingBlocks.Messaging;
using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.Modules.UserData.Domain;

namespace FitnessBuddy.Modules.UserData.Infrastructure;

internal sealed class SyncRetentionJob(TimeProvider clock, IIdGenerator ids) : IJobHandler
{
    public string JobType => "userdata.cleanup";
    public async Task HandleAsync(QueueMessage message, DatabaseSession session, CancellationToken cancellationToken)
    {
        if (message.UserId is not { } user || session.UserId != user) { throw new InvalidOperationException("Missing cleanup owner."); }
        await UserLifecycleLock.AcquireAsync(session, user, cancellationToken);
        // Backfill receipts before any pre-B05 payload disappears. Work stays bounded and is resumable.
        var versions = new List<SyncVersion>();
        await using (var legacy = session.Command("""
            SELECT v.entity,v.id,v.schema_version,v.hlc,v.device_id,v.deleted_at,v.payload FROM (
              SELECT entity,id,schema_version,hlc,device_id,deleted_at,payload FROM userdata.documents WHERE user_id=$1
              UNION ALL
              SELECT entity,id,schema_version,hlc,device_id,deleted_at,payload FROM userdata.row_history WHERE user_id=$1
            ) v WHERE NOT EXISTS(SELECT 1 FROM userdata.version_receipts r WHERE r.user_id=$1 AND r.entity=v.entity AND r.id=v.id AND r.hlc=v.hlc) LIMIT 1000
            """))
        {
            legacy.Parameters.AddWithValue(user);
            await using var reader = await legacy.ExecuteReaderAsync(cancellationToken);
            while (await reader.ReadAsync(cancellationToken))
            {
                versions.Add(new(reader.GetString(0), reader.GetGuid(1), reader.GetInt32(2), reader.GetString(3), reader.GetGuid(4),
                    reader.IsDBNull(5) ? null : reader.GetFieldValue<DateTimeOffset>(5), reader.GetFieldValue<JsonElement>(6)));
            }
        }
        foreach (var version in versions) { await PostgresSyncStore.SaveReceiptAsync(session, user, version, SyncPayloads.Fingerprint(version), cancellationToken); }
        var cutoff = clock.GetUtcNow() - TimeSpan.FromDays(30);
        await using var history = session.Command("""
            DELETE FROM userdata.row_history WHERE user_id=$1 AND (entity,id,hlc) IN (
              SELECT h.entity,h.id,h.hlc FROM userdata.row_history h WHERE h.user_id=$1 AND h.replaced_at<=$2
              AND EXISTS(SELECT 1 FROM userdata.version_receipts r WHERE r.user_id=h.user_id AND r.entity=h.entity AND r.id=h.id AND r.hlc=h.hlc)
              ORDER BY h.replaced_at LIMIT 1000)
            """);
        history.Parameters.AddWithValue(user); history.Parameters.AddWithValue(cutoff);
        var expired = await history.ExecuteNonQueryAsync(cancellationToken);
        await using var compact = session.Command("""
            UPDATE userdata.documents SET payload='{}',compacted=true WHERE user_id=$1 AND (entity,id) IN (
              SELECT d.entity,d.id FROM userdata.documents d WHERE d.user_id=$1 AND d.deleted_at IS NOT NULL AND NOT d.compacted AND d.accepted_at<=$2
              AND EXISTS(SELECT 1 FROM userdata.version_receipts r WHERE r.user_id=d.user_id AND r.entity=d.entity AND r.id=d.id AND r.hlc=d.hlc)
              ORDER BY d.accepted_at LIMIT 1000)
            """);
        compact.Parameters.AddWithValue(user); compact.Parameters.AddWithValue(cutoff);
        var compacted = await compact.ExecuteNonQueryAsync(cancellationToken);
        if (versions.Count == 1000 || expired == 1000 || compacted == 1000)
        { await new QueueWriter(session, clock, ids).EnqueueForUserAsync(JobType, user, new { }, cancellationToken); }
    }
}
