using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.Modules.Identity.Contracts;
using Npgsql;
using NpgsqlTypes;

namespace FitnessBuddy.Modules.Identity.Infrastructure;

/// <summary>Runs on the caller's console session (fb_admin); the application login can't execute these functions.</summary>
internal sealed class PostgresIdentityAdminControls : IIdentityAdminControls
{
    public async Task<AccountControlState?> StateAsync(DatabaseSession session, Guid user, CancellationToken cancellationToken)
    {
        await using var command = Command(session, "SELECT status,anonymous,disabled_at,deletion_requested_at,deletion_attempts,deletion_available_at,deletion_last_error FROM identity.admin_control_state($1)", user);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken)) { return null; }
        return new AccountControlState(reader.GetString(0), reader.GetBoolean(1), Time(reader, 2), Time(reader, 3),
            reader.IsDBNull(4) ? null : reader.GetInt32(4), Time(reader, 5), reader.IsDBNull(6) ? null : reader.GetString(6));
    }

    public async Task<IReadOnlyList<ControlDevice>> DevicesAsync(DatabaseSession session, Guid user, DateTimeOffset now, CancellationToken cancellationToken)
    {
        await using var command = Command(session, "SELECT device_key,platform,app_version,last_seen_at,active_sessions FROM identity.admin_device_keys($1,$2)", user, now);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        var rows = new List<ControlDevice>();
        while (await reader.ReadAsync(cancellationToken))
        {
            rows.Add(new ControlDevice(reader.GetString(0), reader.IsDBNull(1) ? null : reader.GetString(1), reader.IsDBNull(2) ? null : reader.GetString(2),
                Time(reader, 3), reader.GetInt64(4)));
        }
        return rows;
    }

    public async Task<AccountLock?> LockAsync(DatabaseSession session, Guid user, CancellationToken cancellationToken)
    {
        await using var command = Command(session, "SELECT is_disabled,deletion_pending FROM identity.admin_lock_account($1)", user);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        return await reader.ReadAsync(cancellationToken) ? new AccountLock(reader.GetBoolean(0), reader.GetBoolean(1)) : null;
    }

    public async Task<RevokeOutcome?> RevokeAsync(DatabaseSession session, Guid user, string? deviceKey, DateTimeOffset now, CancellationToken cancellationToken)
    {
        await using var command = Command(session, "SELECT device_found,revoked_sessions FROM identity.admin_revoke_sessions($1,$2,$3)",
            user, new NpgsqlParameter { NpgsqlDbType = NpgsqlDbType.Text, Value = (object?)deviceKey ?? DBNull.Value }, now);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        return await reader.ReadAsync(cancellationToken) ? new RevokeOutcome(reader.GetBoolean(0), reader.GetInt32(1)) : null;
    }

    public async Task<DisableOutcome?> SetDisabledAsync(DatabaseSession session, Guid user, bool disabled, DateTimeOffset now, CancellationToken cancellationToken)
    {
        await using var command = Command(session, "SELECT was_disabled,revoked_sessions,outcome FROM identity.admin_set_disabled($1,$2,$3)", user, disabled, now);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        return await reader.ReadAsync(cancellationToken)
            ? new DisableOutcome(reader.GetBoolean(0), reader.GetInt32(1), reader.GetString(2) == "deletion-pending") : null;
    }

    public async Task<DeletionRequestOutcome?> RequestDeletionAsync(DatabaseSession session, Guid user, DateTimeOffset now, CancellationToken cancellationToken)
    {
        await using var command = Command(session, "SELECT was_disabled,revoked_sessions,created FROM identity.admin_request_deletion($1,$2)", user, now);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        return await reader.ReadAsync(cancellationToken) ? new DeletionRequestOutcome(reader.GetBoolean(0), reader.GetInt32(1), reader.GetBoolean(2)) : null;
    }

    private static DateTimeOffset? Time(NpgsqlDataReader reader, int ordinal) =>
        reader.IsDBNull(ordinal) ? null : reader.GetFieldValue<DateTimeOffset>(ordinal);

    private static NpgsqlCommand Command(DatabaseSession session, string sql, params object[] values)
    {
        var command = session.Command(sql);
        foreach (var value in values) { command.Parameters.Add(value is NpgsqlParameter parameter ? parameter : new NpgsqlParameter { Value = value }); }
        return command;
    }
}

/// <summary>The api role's runner side (fb_app): discovery returns ids only; failures are recorded only while the intent exists.</summary>
internal sealed class PostgresOperatorDeletions(NpgsqlDataSource source, TimeProvider clock) : IIdentityOperatorDeletions
{
    public async Task<IReadOnlyList<Guid>> DueAsync(DateTimeOffset now, int limit, CancellationToken cancellationToken)
    {
        await using var command = source.CreateCommand("SELECT identity.due_operator_deletions($1,$2)");
        command.Parameters.AddWithValue(now); command.Parameters.AddWithValue(limit);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        var rows = new List<Guid>();
        while (await reader.ReadAsync(cancellationToken)) { rows.Add(reader.GetGuid(0)); }
        return rows;
    }

    public async Task<bool> RecordFailureAsync(DatabaseSession session, string code, CancellationToken cancellationToken)
    {
        var user = session.UserId ?? throw new InvalidOperationException("Missing deletion owner.");
        await using var command = session.Command("SELECT identity.record_operator_deletion_failure($1,$2,$3)");
        command.Parameters.AddWithValue(user); command.Parameters.AddWithValue(code); command.Parameters.AddWithValue(clock.GetUtcNow());
        return (bool)(await command.ExecuteScalarAsync(cancellationToken))!;
    }
}
