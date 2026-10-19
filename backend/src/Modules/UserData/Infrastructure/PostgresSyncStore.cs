using FitnessBuddy.BuildingBlocks.Messaging;
using FitnessBuddy.BuildingBlocks.Ids;
using FitnessBuddy.Modules.Identity.Contracts;
using System.Globalization;
using System.Text.Json;
using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.Modules.UserData.Application;
using FitnessBuddy.Modules.UserData.Domain;
using Npgsql;
using NpgsqlTypes;

namespace FitnessBuddy.Modules.UserData.Infrastructure;

internal sealed class PostgresSyncStore(NpgsqlDataSource source, IIdentityAccess identity, TimeProvider clock, IIdGenerator ids) : ISyncStore
{
    internal async Task<IReadOnlyList<VersionResult>> PushAsync(Guid userId, IReadOnlyList<SyncVersion> versions, DateTimeOffset now, CancellationToken cancellationToken)
    {
        await using var session = new DatabaseSession();
        await session.BeginAsync(source, userId, cancellationToken);
        await UserLifecycleLock.AcquireAsync(session, userId, cancellationToken);
        var results = await PushInTransactionAsync(session, userId, versions, now, false, cancellationToken);
        await session.CommitAsync(cancellationToken);
        return results;
    }

    private async Task<IReadOnlyList<VersionResult>> PushInTransactionAsync(DatabaseSession session, Guid userId,
        IReadOnlyList<SyncVersion> versions, DateTimeOffset now, bool validatePayload, CancellationToken cancellationToken)
    {
        var results = new List<VersionResult>(versions.Count);
        foreach (var version in versions)
        {
            var invalid = SyncRules.InvalidReason(version, now) ?? (validatePayload ? SyncPayloads.InvalidReason(version) : null);
            results.Add(invalid is null ? await ApplyAsync(session, userId, version, now, cancellationToken) :
                new(version.Entity, version.Id, version.Hlc, "invalid", invalid));
        }
        await new QueueWriter(session, clock, ids)
            .ScheduleUserAsync("userdata.cleanup:" + userId, "0 * * * *", "userdata.cleanup", now.AddHours(1), cancellationToken);
        return results;
    }

    public async Task<PushOutcome?> PushForSessionAsync(IdentitySession principal, Guid? dataset, IReadOnlyList<SyncVersion> versions,
        DateTimeOffset now, CancellationToken cancellationToken)
    {
        await using var session = await AuthenticatedAsync(principal, cancellationToken);
        if (session is null) { return null; }
        var current = await DatasetAsync(session, cancellationToken);
        var results = dataset != current ? versions.Select(v => new VersionResult(v.Entity, v.Id, v.Hlc, "invalid", "datasetMismatch")).ToArray() :
            await PushInTransactionAsync(session, principal.UserId, versions, now, true, cancellationToken);
        await session.CommitAsync(cancellationToken);
        return new PushOutcome(results, now, current);
    }

    private async Task<DatabaseSession?> AuthenticatedAsync(IdentitySession principal, CancellationToken cancellationToken)
    {
        var session = new DatabaseSession();
        try
        {
            await session.BeginAsync(source, principal.UserId, cancellationToken);
            await UserLifecycleLock.AcquireAsync(session, principal.UserId, cancellationToken);
            if (await identity.CheckActiveAsync(session, principal.UserId, principal.SessionId, true, cancellationToken)) { return session; }
            await session.DisposeAsync(); return null;
        }
        catch { await session.DisposeAsync(); throw; }
    }

    private static async Task<Guid> DatasetAsync(DatabaseSession session, CancellationToken cancellationToken)
    {
        await using var command = session.Command("SELECT id FROM userdata.dataset WHERE singleton");
        return (Guid)(await command.ExecuteScalarAsync(cancellationToken))!;
    }

    public async Task<VersionPage?> PullForSessionAsync(IdentitySession principal, Guid? dataset, long cursor, int limit, bool history,
        string? entity, Guid? id, CancellationToken cancellationToken)
    {
        await using var session = await AuthenticatedAsync(principal, cancellationToken);
        if (session is null) { return null; }
        var current = await DatasetAsync(session, cancellationToken);
        if (dataset != current && (dataset.HasValue || cursor != 0)) { return new VersionPage([], "0", current, "datasetMismatch"); }
        var sequence = history ? "userdata.history_seq" : "userdata.document_seq";
        await using var high = session.Command($"SELECT CASE WHEN is_called THEN last_value ELSE 0 END FROM {sequence}");
        if (cursor > (long)(await high.ExecuteScalarAsync(cancellationToken))!) { return new VersionPage([], "0", current, "cursorInvalid"); }
        var page = await PageAsync(session, principal.UserId, cursor, limit, history, entity, id, cancellationToken, clock.GetUtcNow() - TimeSpan.FromDays(30));
        await session.CommitAsync(cancellationToken);
        return page with { DatasetId = current };
    }

    private static async Task<VersionResult> ApplyAsync(DatabaseSession session, Guid userId, SyncVersion version, DateTimeOffset now, CancellationToken cancellationToken)
    {
        var fingerprint = SyncPayloads.Fingerprint(version);
        await using var receipt = session.Command("SELECT fingerprint FROM userdata.version_receipts WHERE user_id=$1 AND entity=$2 AND id=$3 AND hlc=$4");
        receipt.Parameters.AddWithValue(userId); receipt.Parameters.AddWithValue(version.Entity); receipt.Parameters.AddWithValue(version.Id); receipt.Parameters.AddWithValue(version.Hlc);
        if (await receipt.ExecuteScalarAsync(cancellationToken) is byte[] knownFingerprint)
        {
            if (!System.Security.Cryptography.CryptographicOperations.FixedTimeEquals(knownFingerprint, fingerprint))
            { return new(version.Entity, version.Id, version.Hlc, "invalid", "versionConflict"); }
            await using var winner = session.Command("SELECT hlc FROM userdata.documents WHERE user_id=$1 AND entity=$2 AND id=$3");
            winner.Parameters.AddWithValue(userId); winner.Parameters.AddWithValue(version.Entity); winner.Parameters.AddWithValue(version.Id);
            var latest = (string?)await winner.ExecuteScalarAsync(cancellationToken);
            return new(version.Entity, version.Id, version.Hlc, latest == version.Hlc ? "accepted" : "stale", null);
        }
        // Retaining same-device losers too makes version identity immutable after any replacement.
        // It also allows an independent no-loss assertion instead of only testing the final winner.
        await using var duplicate = session.Command("""
            SELECT (schema_version = $5 AND device_id = $6 AND deleted_at IS NOT DISTINCT FROM $7 AND payload = $8)
            FROM (
                SELECT schema_version, device_id, deleted_at, payload FROM userdata.documents
                    WHERE user_id=$1 AND entity=$2 AND id=$3 AND hlc=$4
                UNION ALL
                SELECT schema_version, device_id, deleted_at, payload FROM userdata.row_history
                    WHERE user_id=$1 AND entity=$2 AND id=$3 AND hlc=$4
            ) AS known
            """);
        AddVersion(duplicate, userId, version);
        var match = await duplicate.ExecuteScalarAsync(cancellationToken);
        if (match is bool same && !same) { return new(version.Entity, version.Id, version.Hlc, "invalid", "versionConflict"); }
        await SaveReceiptAsync(session, userId, version, fingerprint, cancellationToken);
        await using var currentCommand = session.Command("SELECT hlc FROM userdata.documents WHERE user_id=$1 AND entity=$2 AND id=$3");
        currentCommand.Parameters.AddWithValue(userId);
        currentCommand.Parameters.AddWithValue(version.Entity);
        currentCommand.Parameters.AddWithValue(version.Id);
        var current = (string?)await currentCommand.ExecuteScalarAsync(cancellationToken);
        var comparison = current is null ? 1 : string.CompareOrdinal(version.Hlc, current);
        if (comparison == 0) { return new(version.Entity, version.Id, version.Hlc, "accepted", null); }
        if (comparison < 0)
        {
            await using var archive = session.Command("""
                INSERT INTO userdata.row_history(user_id,entity,id,hlc,schema_version,device_id,deleted_at,payload,replaced_at)
                VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9) ON CONFLICT(user_id,entity,id,hlc) DO NOTHING
                """);
            AddVersion(archive, userId, version);
            archive.Parameters.AddWithValue(now);
            await archive.ExecuteNonQueryAsync(cancellationToken);
            return new(version.Entity, version.Id, version.Hlc, "stale", null);
        }
        if (current is not null)
        {
            await using var archive = session.Command("""
                INSERT INTO userdata.row_history(user_id,entity,id,hlc,schema_version,device_id,deleted_at,payload,replaced_at,compacted)
                SELECT user_id,entity,id,hlc,schema_version,device_id,deleted_at,payload,$4,compacted
                FROM userdata.documents WHERE user_id=$1 AND entity=$2 AND id=$3
                ON CONFLICT(user_id,entity,id,hlc) DO NOTHING
                """);
            archive.Parameters.AddWithValue(userId);
            archive.Parameters.AddWithValue(version.Entity);
            archive.Parameters.AddWithValue(version.Id);
            archive.Parameters.AddWithValue(now);
            await archive.ExecuteNonQueryAsync(cancellationToken);
        }
        await using var upsert = session.Command("""
            INSERT INTO userdata.documents(user_id,entity,id,hlc,schema_version,device_id,deleted_at,payload,accepted_at)
            VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9)
            ON CONFLICT(user_id,entity,id) DO UPDATE SET hlc=EXCLUDED.hlc,schema_version=EXCLUDED.schema_version,
                device_id=EXCLUDED.device_id,deleted_at=EXCLUDED.deleted_at,payload=EXCLUDED.payload,server_seq=EXCLUDED.server_seq,accepted_at=EXCLUDED.accepted_at,compacted=false
            """);
        AddVersion(upsert, userId, version); upsert.Parameters.AddWithValue(now);
        await upsert.ExecuteNonQueryAsync(cancellationToken);
        return new(version.Entity, version.Id, version.Hlc, "accepted", null);
    }

    internal static async Task SaveReceiptAsync(DatabaseSession session, Guid userId, SyncVersion version, byte[] fingerprint, CancellationToken cancellationToken)
    {
        await using var save = session.Command("INSERT INTO userdata.version_receipts(user_id,entity,id,hlc,fingerprint) VALUES($1,$2,$3,$4,$5) ON CONFLICT DO NOTHING");
        save.Parameters.AddWithValue(userId); save.Parameters.AddWithValue(version.Entity); save.Parameters.AddWithValue(version.Id);
        save.Parameters.AddWithValue(version.Hlc); save.Parameters.AddWithValue(fingerprint); await save.ExecuteNonQueryAsync(cancellationToken);
    }

    private static void AddVersion(NpgsqlCommand command, Guid userId, SyncVersion version)
    {
        command.Parameters.AddWithValue(userId);
        command.Parameters.AddWithValue(version.Entity);
        command.Parameters.AddWithValue(version.Id);
        command.Parameters.AddWithValue(version.Hlc);
        command.Parameters.AddWithValue(version.SchemaVersion);
        command.Parameters.AddWithValue(version.DeviceId);
        command.Parameters.Add(new NpgsqlParameter { NpgsqlDbType = NpgsqlDbType.TimestampTz, Value = version.DeletedAt is { } deleted ? deleted.ToUniversalTime() : DBNull.Value });
        command.Parameters.AddWithValue(NpgsqlDbType.Jsonb, version.Payload.GetRawText());
    }

    internal async Task<VersionPage> PullAsync(Guid userId, long cursor, int limit, bool history, CancellationToken cancellationToken)
    {
        await using var session = new DatabaseSession();
        await session.BeginAsync(source, userId, cancellationToken);
        return await PageAsync(session, userId, cursor, limit, history, null, null, cancellationToken);
    }

    private static async Task<VersionPage> PageAsync(DatabaseSession session, Guid userId, long cursor, int limit, bool history,
        string? entity, Guid? id, CancellationToken cancellationToken, DateTimeOffset? historyCutoff = null)
    {
        // Table is a code-owned choice, never user input. Both cursor spaces obey the same ordering rule.
        var table = history ? "userdata.row_history" : "userdata.documents";
        await using var command = session.Command($"SELECT entity,id,schema_version,hlc,device_id,deleted_at,payload,server_seq,compacted FROM {table} WHERE user_id=$1 AND server_seq>$2 AND ($4::text IS NULL OR entity=$4) AND ($5::uuid IS NULL OR id=$5) {(history ? "AND ($6::timestamptz IS NULL OR replaced_at>$6)" : "")} ORDER BY server_seq LIMIT $3");
        command.Parameters.AddWithValue(userId);
        command.Parameters.AddWithValue(cursor);
        command.Parameters.AddWithValue(limit);
        command.Parameters.AddWithValue(NpgsqlDbType.Text, (object?)entity ?? DBNull.Value);
        command.Parameters.AddWithValue(NpgsqlDbType.Uuid, (object?)id ?? DBNull.Value);
        if (history) { command.Parameters.AddWithValue(NpgsqlDbType.TimestampTz, (object?)historyCutoff ?? DBNull.Value); }
        var rows = new List<StoredVersion>();
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            var version = new SyncVersion(reader.GetString(0), reader.GetGuid(1), reader.GetInt32(2), reader.GetString(3), reader.GetGuid(4),
                reader.IsDBNull(5) ? null : reader.GetFieldValue<DateTimeOffset>(5), reader.GetFieldValue<JsonElement>(6));
            rows.Add(new StoredVersion(version, reader.GetInt64(7).ToString(CultureInfo.InvariantCulture), reader.GetBoolean(8)));
        }
        return new VersionPage(rows, rows.Count == 0 ? cursor.ToString(CultureInfo.InvariantCulture) : rows[^1].ServerSeq);
    }
}
