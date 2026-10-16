using System.Globalization;
using System.Text.Json;
using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.Modules.UserData.Application;
using FitnessBuddy.Modules.UserData.Domain;
using Npgsql;
using NpgsqlTypes;

namespace FitnessBuddy.Modules.UserData.Infrastructure;

internal sealed class PostgresSyncStore(NpgsqlDataSource source) : ISyncStore
{
    public async Task<IReadOnlyList<VersionResult>> PushAsync(Guid userId, IReadOnlyList<SyncVersion> versions, DateTimeOffset now, CancellationToken cancellationToken)
    {
        await using var session = new DatabaseSession();
        await session.BeginAsync(source, userId, cancellationToken);
        // A nextval is not commit ordered. Acquire *before* any allocation so a same-user
        // later commit cannot fall behind a delivered cursor (B01 D2). Hash collisions only serialize extra users.
        await using var acquire = session.Command("SELECT pg_advisory_xact_lock(hashtextextended($1, 4603912))");
        acquire.Parameters.AddWithValue(userId.ToString());
        await acquire.ExecuteNonQueryAsync(cancellationToken);
        var results = new List<VersionResult>(versions.Count);
        foreach (var version in versions)
        {
            var invalid = SyncRules.InvalidReason(version, now);
            if (invalid is not null)
            {
                results.Add(new(version.Entity, version.Id, version.Hlc, "invalid", invalid));
                continue;
            }
            results.Add(await ApplyAsync(session, userId, version, now, cancellationToken));
        }
        await session.CommitAsync(cancellationToken);
        return results;
    }

    private static async Task<VersionResult> ApplyAsync(DatabaseSession session, Guid userId, SyncVersion version, DateTimeOffset now, CancellationToken cancellationToken)
    {
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
                INSERT INTO userdata.row_history(user_id,entity,id,hlc,schema_version,device_id,deleted_at,payload,replaced_at)
                SELECT user_id,entity,id,hlc,schema_version,device_id,deleted_at,payload,$4
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
            INSERT INTO userdata.documents(user_id,entity,id,hlc,schema_version,device_id,deleted_at,payload)
            VALUES($1,$2,$3,$4,$5,$6,$7,$8)
            ON CONFLICT(user_id,entity,id) DO UPDATE SET hlc=EXCLUDED.hlc,schema_version=EXCLUDED.schema_version,
                device_id=EXCLUDED.device_id,deleted_at=EXCLUDED.deleted_at,payload=EXCLUDED.payload,server_seq=EXCLUDED.server_seq
            """);
        AddVersion(upsert, userId, version);
        await upsert.ExecuteNonQueryAsync(cancellationToken);
        return new(version.Entity, version.Id, version.Hlc, "accepted", null);
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

    public async Task<VersionPage> PullAsync(Guid userId, long cursor, int limit, bool history, CancellationToken cancellationToken)
    {
        await using var session = new DatabaseSession();
        await session.BeginAsync(source, userId, cancellationToken);
        // Table is a code-owned choice, never user input. Both cursor spaces obey the same ordering rule.
        var table = history ? "userdata.row_history" : "userdata.documents";
        await using var command = session.Command($"SELECT entity,id,schema_version,hlc,device_id,deleted_at,payload,server_seq FROM {table} WHERE user_id=$1 AND server_seq>$2 ORDER BY server_seq LIMIT $3");
        command.Parameters.AddWithValue(userId);
        command.Parameters.AddWithValue(cursor);
        command.Parameters.AddWithValue(limit);
        var rows = new List<StoredVersion>();
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            var version = new SyncVersion(reader.GetString(0), reader.GetGuid(1), reader.GetInt32(2), reader.GetString(3), reader.GetGuid(4),
                reader.IsDBNull(5) ? null : reader.GetFieldValue<DateTimeOffset>(5), reader.GetFieldValue<JsonElement>(6));
            rows.Add(new StoredVersion(version, reader.GetInt64(7).ToString(CultureInfo.InvariantCulture)));
        }
        return new VersionPage(rows, rows.Count == 0 ? cursor.ToString(CultureInfo.InvariantCulture) : rows[^1].ServerSeq);
    }
}
