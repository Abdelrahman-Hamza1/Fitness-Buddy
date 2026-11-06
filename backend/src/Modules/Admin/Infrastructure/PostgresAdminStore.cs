using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.Modules.Admin.Application;
using NpgsqlTypes;

namespace FitnessBuddy.Modules.Admin.Infrastructure;

/// <summary>Sessions, challenges and the audit log in the <c>admin</c> schema, on the caller's transaction.</summary>
internal sealed class PostgresAdminStore(IAdminDatabase database) : IAdminAuthStore, IAuditLog, IAuditReader
{
    public async Task CreateChallengeAsync(DatabaseSession session, Guid id, ChallengePurpose purpose, Guid? adminSession, byte[] nonceHash, DateTimeOffset expiresAt, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(session);
        await using var command = session.Command("INSERT INTO admin.challenges(id,purpose,admin_session_id,nonce_hash,expires_at) VALUES($1,$2,$3,$4,$5)");
        command.Parameters.AddWithValue(id);
        command.Parameters.AddWithValue(Purpose(purpose));
        command.Parameters.Add(new() { Value = (object?)adminSession ?? DBNull.Value, NpgsqlDbType = NpgsqlDbType.Uuid });
        command.Parameters.AddWithValue(nonceHash);
        command.Parameters.AddWithValue(expiresAt);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    public async Task<bool> ConsumeChallengeAsync(DatabaseSession session, Guid id, ChallengePurpose purpose, Guid? adminSession, byte[] nonceHash, DateTimeOffset now, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(session);
        await using var command = session.Command("""
            UPDATE admin.challenges SET used_at=$5
            WHERE id=$1 AND purpose=$2 AND admin_session_id IS NOT DISTINCT FROM $3 AND nonce_hash=$4 AND used_at IS NULL AND expires_at>$5
            """);
        command.Parameters.AddWithValue(id);
        command.Parameters.AddWithValue(Purpose(purpose));
        command.Parameters.Add(new() { Value = (object?)adminSession ?? DBNull.Value, NpgsqlDbType = NpgsqlDbType.Uuid });
        command.Parameters.AddWithValue(nonceHash);
        command.Parameters.AddWithValue(now);
        return await command.ExecuteNonQueryAsync(cancellationToken) == 1;
    }

    public async Task CreateSessionAsync(DatabaseSession session, NewSession value, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(session);
        ArgumentNullException.ThrowIfNull(value);
        await using var command = session.Command("""
            INSERT INTO admin.sessions(id,token_hash,handle,google_subject,created_at,authenticated_at,expires_at) VALUES($1,$2,$3,$4,$5,$5,$6)
            """);
        command.Parameters.AddWithValue(value.Id);
        command.Parameters.AddWithValue(value.TokenHash);
        command.Parameters.AddWithValue(value.Handle);
        command.Parameters.AddWithValue(value.GoogleSubject);
        command.Parameters.AddWithValue(value.CreatedAt);
        command.Parameters.AddWithValue(value.ExpiresAt);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    public async Task<StoredSession?> FindSessionAsync(DatabaseSession session, byte[] tokenHash, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(session);
        await using var command = session.Command("SELECT id,handle,google_subject,authenticated_at,expires_at,revoked_at IS NOT NULL FROM admin.sessions WHERE token_hash=$1");
        command.Parameters.AddWithValue(tokenHash);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken)) { return null; }
        return new StoredSession(reader.GetGuid(0), reader.GetString(1), reader.GetString(2),
            reader.GetFieldValue<DateTimeOffset>(3), reader.GetFieldValue<DateTimeOffset>(4), reader.GetBoolean(5));
    }

    public async Task RevokeSessionAsync(DatabaseSession session, Guid id, DateTimeOffset now, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(session);
        await using var command = session.Command("UPDATE admin.sessions SET revoked_at=$2 WHERE id=$1 AND revoked_at IS NULL");
        command.Parameters.AddWithValue(id);
        command.Parameters.AddWithValue(now);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    public async Task MarkAuthenticatedAsync(DatabaseSession session, Guid id, DateTimeOffset now, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(session);
        await using var command = session.Command("UPDATE admin.sessions SET authenticated_at=$2 WHERE id=$1 AND revoked_at IS NULL AND expires_at>$2");
        command.Parameters.AddWithValue(id);
        command.Parameters.AddWithValue(now);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    public async Task CleanupAsync(DatabaseSession session, DateTimeOffset now, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(session);
        // One statement per command: positional parameters can't span several statements.
        foreach (var sql in new[]
        {
            "DELETE FROM admin.challenges WHERE id IN (SELECT id FROM admin.challenges WHERE expires_at<=$1 OR used_at IS NOT NULL LIMIT 500)",
            "DELETE FROM admin.sessions WHERE id IN (SELECT id FROM admin.sessions WHERE expires_at<=$1 OR revoked_at IS NOT NULL LIMIT 200)",
        })
        {
            await using var command = session.Command(sql);
            command.Parameters.AddWithValue(now);
            await command.ExecuteNonQueryAsync(cancellationToken);
        }
    }

    public async Task AppendAsync(DatabaseSession session, AuditEntry entry, DateTimeOffset occurredAt, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(session);
        ArgumentNullException.ThrowIfNull(entry);
        await using var command = session.Command("""
            INSERT INTO admin.audit_log(occurred_at,actor,area,action,target,before,after,reason,outcome) VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9)
            """);
        command.Parameters.AddWithValue(occurredAt);
        command.Parameters.AddWithValue(entry.Actor);
        command.Parameters.AddWithValue(entry.Area);
        command.Parameters.AddWithValue(entry.Action);
        command.Parameters.Add(new() { Value = (object?)entry.Target ?? DBNull.Value, NpgsqlDbType = NpgsqlDbType.Text });
        command.Parameters.Add(new() { Value = (object?)entry.BeforeJson ?? DBNull.Value, NpgsqlDbType = NpgsqlDbType.Jsonb });
        command.Parameters.Add(new() { Value = (object?)entry.AfterJson ?? DBNull.Value, NpgsqlDbType = NpgsqlDbType.Jsonb });
        command.Parameters.Add(new() { Value = (object?)entry.Reason ?? DBNull.Value, NpgsqlDbType = NpgsqlDbType.Text });
        command.Parameters.AddWithValue(entry.Outcome);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<AuditRecord>> QueryAsync(AuditFilter filter, long? beforeId, int limit, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(filter);
        await using var session = await database.BeginAsync(cancellationToken);
        await using var command = session.Command("""
            SELECT id,occurred_at,actor,area,action,target,outcome,reason,before::text,after::text FROM admin.audit_log
            WHERE ($1::text IS NULL OR area=$1) AND ($2::text IS NULL OR actor=$2)
              AND ($3::timestamptz IS NULL OR occurred_at>=$3) AND ($4::timestamptz IS NULL OR occurred_at<$4)
              AND ($5::bigint IS NULL OR id<$5)
            ORDER BY id DESC LIMIT $6
            """);
        command.Parameters.Add(new() { Value = (object?)filter.Area ?? DBNull.Value, NpgsqlDbType = NpgsqlDbType.Text });
        command.Parameters.Add(new() { Value = (object?)filter.Actor ?? DBNull.Value, NpgsqlDbType = NpgsqlDbType.Text });
        command.Parameters.Add(new() { Value = (object?)filter.From ?? DBNull.Value, NpgsqlDbType = NpgsqlDbType.TimestampTz });
        command.Parameters.Add(new() { Value = (object?)filter.Until ?? DBNull.Value, NpgsqlDbType = NpgsqlDbType.TimestampTz });
        command.Parameters.Add(new() { Value = (object?)beforeId ?? DBNull.Value, NpgsqlDbType = NpgsqlDbType.Bigint });
        command.Parameters.AddWithValue(limit);
        var rows = new List<AuditRecord>();
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            rows.Add(new AuditRecord(reader.GetInt64(0), reader.GetFieldValue<DateTimeOffset>(1), reader.GetString(2), reader.GetString(3), reader.GetString(4),
                reader.IsDBNull(5) ? null : reader.GetString(5), reader.GetString(6), reader.IsDBNull(7) ? null : reader.GetString(7),
                reader.IsDBNull(8) ? null : reader.GetString(8), reader.IsDBNull(9) ? null : reader.GetString(9)));
        }
        return rows;
    }

    private static string Purpose(ChallengePurpose purpose) => purpose == ChallengePurpose.SignIn ? "signin" : "reauth";
}
