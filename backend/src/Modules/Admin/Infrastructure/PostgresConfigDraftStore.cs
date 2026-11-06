using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.Modules.Account.Contracts;
using FitnessBuddy.Modules.Admin.Application;
using NpgsqlTypes;

namespace FitnessBuddy.Modules.Admin.Infrastructure;

/// <summary>The single config draft row (<c>admin.config_draft</c>); every save bumps its revision (R#3).</summary>
internal sealed class PostgresConfigDraftStore : IConfigDraftStore
{
    public async Task<ConfigDraft?> GetAsync(DatabaseSession session, bool forUpdate, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(session);
        await using var command = session.Command("SELECT base_version,revision,document::text,document_sha256,updated_by,updated_at FROM admin.config_draft"
            + (forUpdate ? " FOR UPDATE" : ""));
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken)) { return null; }
        var document = RemoteConfigDocument.FromJson(reader.GetString(2));
        if (document is null) { return null; }
        return new ConfigDraft(reader.GetInt32(0), reader.GetInt64(1), document, Convert.ToHexStringLower((byte[])reader[3]), reader.GetString(4),
            reader.GetFieldValue<DateTimeOffset>(5));
    }

    public async Task<long> SaveAsync(DatabaseSession session, int baseVersion, RemoteConfigDocument document, string hash, string actor, DateTimeOffset now,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(session);
        ArgumentNullException.ThrowIfNull(document);
        await using var command = session.Command("""
            INSERT INTO admin.config_draft(singleton,base_version,revision,document,document_sha256,updated_by,updated_at) VALUES(true,$1,1,$2,$3,$4,$5)
            ON CONFLICT(singleton) DO UPDATE SET base_version=EXCLUDED.base_version,revision=admin.config_draft.revision+1,document=EXCLUDED.document,
              document_sha256=EXCLUDED.document_sha256,updated_by=EXCLUDED.updated_by,updated_at=EXCLUDED.updated_at
            RETURNING revision
            """);
        command.Parameters.AddWithValue(baseVersion);
        command.Parameters.Add(new() { Value = document.ToJson(), NpgsqlDbType = NpgsqlDbType.Jsonb });
        command.Parameters.AddWithValue(Convert.FromHexString(hash));
        command.Parameters.AddWithValue(actor);
        command.Parameters.AddWithValue(now);
        return (long)(await command.ExecuteScalarAsync(cancellationToken))!;
    }

    public async Task DeleteAsync(DatabaseSession session, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(session);
        await using var command = session.Command("DELETE FROM admin.config_draft");
        await command.ExecuteNonQueryAsync(cancellationToken);
    }
}
