using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.BuildingBlocks.Results;
using FitnessBuddy.Modules.Account.Application;
using FitnessBuddy.Modules.Account.Contracts;
using Microsoft.Extensions.Options;
using Npgsql;
using NpgsqlTypes;

namespace FitnessBuddy.Modules.Account.Infrastructure;

/// <summary>Published config versions on the caller's session (the console's fb_admin login writes; nothing here commits).</summary>
internal sealed class PostgresRemoteConfig(RemoteConfigDefaults defaults, IOptionsMonitor<FitnessBuddy.BuildingBlocks.Clients.ClientCompatibilityOptions> compatibility)
    : IRemoteConfigAdmin
{
    /// <summary>Transaction advisory lock serializing publishers (with the version primary key as the backstop).</summary>
    private const long PublishLock = 0x4642434f4e464947;

    public RemoteConfigDocument Defaults => defaults.Current;

    public string? ActiveOverride => compatibility.CurrentValue.GetOverride()?.ToString();

    public async Task<PublishedConfig?> CurrentAsync(DatabaseSession session, CancellationToken cancellationToken) =>
        First(await ReadAsync(session, "ORDER BY version DESC LIMIT 1", null, cancellationToken));

    public async Task<PublishedConfig?> VersionAsync(DatabaseSession session, int version, CancellationToken cancellationToken) =>
        First(await ReadAsync(session, "WHERE version=$1", version, cancellationToken));

    private static PublishedConfig? First(IReadOnlyList<PublishedConfig> rows) => rows.Count > 0 ? rows[0] : null;

    public Task<IReadOnlyList<PublishedConfig>> HistoryAsync(DatabaseSession session, int limit, int? before, CancellationToken cancellationToken) =>
        ReadAsync(session, "WHERE version < $2 ORDER BY version DESC LIMIT $1", Math.Clamp(limit, 1, 500), cancellationToken, before ?? int.MaxValue);

    public async Task<Result<PublishedConfig>> PublishAsync(DatabaseSession session, RemoteConfigDocument document, int expectedVersion, string actor,
        string reason, int? rolledBackFrom, DateTimeOffset now, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(session);
        ArgumentNullException.ThrowIfNull(document);
        if (string.IsNullOrWhiteSpace(reason) || reason.Trim().Length > 500)
        {
            return Error.Validation("config.reason", new Dictionary<string, string[]> { ["reason"] = ["A reason of 1–500 characters is required."] });
        }
        await using (var lockCommand = session.Command("SELECT pg_advisory_xact_lock($1)"))
        {
            lockCommand.Parameters.AddWithValue(PublishLock);
            await lockCommand.ExecuteNonQueryAsync(cancellationToken);
        }
        var current = await CurrentAsync(session, cancellationToken);
        if ((current?.Version ?? 0) != expectedVersion) { return Error.VersionConflict("config.stale", "The config changed since you started. Review the new diff."); }
        var errors = RemoteConfigRules.Validate(document, current?.Document ?? defaults.Current);
        if (errors.Count > 0) { return Error.Validation("config.invalid", new Dictionary<string, string[]> { ["document"] = [.. errors] }); }
        var published = new PublishedConfig(expectedVersion + 1, document, now, actor, reason.Trim(), rolledBackFrom);
        await using var insert = session.Command("""
            INSERT INTO account.config_versions(version,document,published_at,published_by,reason,rolled_back_from) VALUES($1,$2,$3,$4,$5,$6)
            """);
        insert.Parameters.AddWithValue(published.Version);
        insert.Parameters.Add(new NpgsqlParameter { Value = document.ToJson(), NpgsqlDbType = NpgsqlDbType.Jsonb });
        insert.Parameters.AddWithValue(now);
        insert.Parameters.AddWithValue(actor);
        insert.Parameters.AddWithValue(published.Reason);
        insert.Parameters.Add(new NpgsqlParameter { Value = (object?)rolledBackFrom ?? DBNull.Value, NpgsqlDbType = NpgsqlDbType.Integer });
        await insert.ExecuteNonQueryAsync(cancellationToken);
        return published;
    }

    /// <summary>
    /// B23: the migrate role seeds version 1 from the canonical defaults, once, when nothing is published. One transaction holding
    /// the publishers' advisory lock, so concurrent first-time migrators (and a publish) serialize: the second sees the row.
    /// </summary>
    public static async Task SeedAsync(string migratorConnection, RemoteConfigDocument defaults, DateTimeOffset now, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(defaults);
        await using var source = DatabaseConfiguration.CreateSource(migratorConnection);
        await using var connection = await source.OpenConnectionAsync(cancellationToken);
        await using var transaction = await connection.BeginTransactionAsync(cancellationToken);
        await using (var lockCommand = new NpgsqlCommand("SELECT pg_advisory_xact_lock($1)", connection, transaction))
        {
            lockCommand.Parameters.AddWithValue(PublishLock);
            await lockCommand.ExecuteNonQueryAsync(cancellationToken);
        }
        await using (var command = new NpgsqlCommand("""
            INSERT INTO account.config_versions(version,document,published_at,published_by,reason)
            SELECT 1,$1,$2,'seed','Seeded from the server configuration' WHERE NOT EXISTS(SELECT 1 FROM account.config_versions)
            """, connection, transaction))
        {
            command.Parameters.Add(new NpgsqlParameter { Value = defaults.ToJson(), NpgsqlDbType = NpgsqlDbType.Jsonb });
            command.Parameters.AddWithValue(now);
            await command.ExecuteNonQueryAsync(cancellationToken);
        }
        await transaction.CommitAsync(cancellationToken);
    }

    private static async Task<IReadOnlyList<PublishedConfig>> ReadAsync(DatabaseSession session, string tail, int? argument, CancellationToken cancellationToken,
        int? second = null)
    {
        ArgumentNullException.ThrowIfNull(session);
        await using var command = session.Command("SELECT version,document::text,published_at,published_by,reason,rolled_back_from FROM account.config_versions " + tail);
        if (argument is { } value) { command.Parameters.AddWithValue(value); }
        if (second is { } other) { command.Parameters.AddWithValue(other); }
        var rows = new List<PublishedConfig>();
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            var document = RemoteConfigDocument.FromJson(reader.GetString(1)) ?? throw new InvalidOperationException("Unreadable config version.");
            rows.Add(new PublishedConfig(reader.GetInt32(0), document, reader.GetFieldValue<DateTimeOffset>(2), reader.GetString(3), reader.GetString(4),
                reader.IsDBNull(5) ? null : reader.GetInt32(5)));
        }
        return rows;
    }
}
