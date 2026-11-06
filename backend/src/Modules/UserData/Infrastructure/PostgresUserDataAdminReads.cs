using FitnessBuddy.Modules.UserData.Contracts;
using Npgsql;
using NpgsqlTypes;

namespace FitnessBuddy.Modules.UserData.Infrastructure;

/// <summary>Runs on the admin role's data source (fb_admin); the application login can't execute these functions.</summary>
internal sealed class PostgresUserDataAdminReads(NpgsqlDataSource source) : IUserDataAdminReads
{
    public async Task<IReadOnlyList<UserSyncStats>> StatsAsync(IReadOnlyCollection<Guid> users, DateOnly since, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(users);
        if (users.Count == 0) { return []; }
        await using var command = source.CreateCommand("SELECT user_id,documents,storage_bytes,rejects,last_push_at,last_pull_at FROM userdata.admin_user_stats($1,$2)");
        command.Parameters.AddWithValue(NpgsqlDbType.Array | NpgsqlDbType.Uuid, users.ToArray());
        command.Parameters.AddWithValue(since);
        var rows = new List<UserSyncStats>();
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            rows.Add(new UserSyncStats(reader.GetGuid(0), reader.GetInt64(1), reader.GetInt64(2), reader.GetInt64(3),
                reader.IsDBNull(4) ? null : reader.GetFieldValue<DateTimeOffset>(4), reader.IsDBNull(5) ? null : reader.GetFieldValue<DateTimeOffset>(5)));
        }
        return rows;
    }

    public async Task<IReadOnlyList<UserRejects>> UsersWithIssuesAsync(DateOnly since, int limit, UserRejects? after, CancellationToken cancellationToken)
    {
        await using var command = source.CreateCommand("SELECT user_id,rejects FROM userdata.admin_users_with_issues($1,$2,$3,$4)");
        command.Parameters.AddWithValue(since);
        command.Parameters.AddWithValue(limit);
        command.Parameters.AddWithValue(NpgsqlDbType.Bigint, (object?)after?.Rejects ?? DBNull.Value);
        command.Parameters.AddWithValue(NpgsqlDbType.Uuid, (object?)after?.UserId ?? DBNull.Value);
        var rows = new List<UserRejects>();
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken)) { rows.Add(new UserRejects(reader.GetGuid(0), reader.GetInt64(1))); }
        return rows;
    }

    public async Task<SyncSummary> SummaryAsync(DateOnly since, CancellationToken cancellationToken)
    {
        await using var command = source.CreateCommand("""
            SELECT pushes,pulls,changes_in,stale,clock_drift,version_conflict,unsupported,invalid_payload,dataset_mismatch,cursor_invalid
            FROM userdata.admin_sync_summary($1)
            """);
        command.Parameters.AddWithValue(since);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        await reader.ReadAsync(cancellationToken);
        return new SyncSummary(reader.GetInt64(0), reader.GetInt64(1), reader.GetInt64(2), reader.GetInt64(3), reader.GetInt64(4), reader.GetInt64(5),
            reader.GetInt64(6), reader.GetInt64(7), reader.GetInt64(8), reader.GetInt64(9));
    }

    public async Task<IReadOnlyList<EntityCount>> DocumentsAsync(Guid? user, CancellationToken cancellationToken)
    {
        await using var command = source.CreateCommand("SELECT entity,schema_version,documents,deleted FROM userdata.admin_documents($1,$2)");
        command.Parameters.AddWithValue(NpgsqlDbType.Uuid, (object?)user ?? DBNull.Value);
        command.Parameters.AddWithValue(SyncPayloads.EntityCodes);
        var rows = new List<EntityCount>();
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken)) { rows.Add(new EntityCount(reader.GetString(0), reader.GetInt32(1), reader.GetInt64(2), reader.GetInt64(3))); }
        return rows;
    }
}
