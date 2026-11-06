using System.Security.Cryptography;
using System.Text;
using FitnessBuddy.Modules.Identity.Application;
using FitnessBuddy.Modules.Identity.Contracts;
using Microsoft.Extensions.Options;
using Npgsql;
using NpgsqlTypes;

namespace FitnessBuddy.Modules.Identity.Infrastructure;

/// <summary>Runs on the admin role's data source (fb_admin); the application login can't execute these functions. The exact
/// email lookup keys the address like sign-in does (<see cref="EmailAddresses"/>), with the lookup key when it is configured.</summary>
internal sealed class PostgresIdentityAdminReads(NpgsqlDataSource source, IOptions<IdentityOptions> options) : IIdentityAdminReads
{
    public async Task<IReadOnlyList<InstallCount>> InstallsAsync(DateTimeOffset since, CancellationToken cancellationToken)
    {
        await using var command = source.CreateCommand("SELECT app_version,platform,installs FROM identity.admin_installs($1)");
        command.Parameters.AddWithValue(since);
        var rows = new List<InstallCount>();
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken)) { rows.Add(new InstallCount(reader.GetString(0), reader.GetString(1), reader.GetInt64(2))); }
        return rows;
    }

    public async Task<IReadOnlyList<AccountTypeCount>> AccountsByTypeAsync(CancellationToken cancellationToken)
    {
        await using var command = source.CreateCommand("SELECT account_type,status,accounts FROM identity.admin_accounts_by_type()");
        var rows = new List<AccountTypeCount>();
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken)) { rows.Add(new AccountTypeCount(reader.GetString(0), reader.GetString(1), reader.GetInt64(2))); }
        return rows;
    }

    public Task<IReadOnlyList<AdminAccount>> AccountPageAsync(string? type, Guid? before, int limit, CancellationToken cancellationToken) =>
        QueryAsync(type, before, limit, null, cancellationToken);

    public async Task<IReadOnlyList<AdminAccount>> AccountsAsync(IReadOnlyCollection<Guid> ids, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(ids);
        return ids.Count == 0 ? [] : await QueryAsync(null, null, 200, [.. ids], cancellationToken);
    }

    public async Task<EmailLookup> FindByEmailAsync(string email, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(email);
        var normalized = EmailAddresses.Normalize(email);
        var subject = EmailSubject(normalized);
        await using var command = source.CreateCommand("SELECT user_id FROM identity.admin_find_by_email($1,$2)");
        command.Parameters.AddWithValue(normalized);
        command.Parameters.AddWithValue(NpgsqlDbType.Text, (object?)subject ?? DBNull.Value);
        var rows = new List<Guid>();
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken)) { rows.Add(reader.GetGuid(0)); }
        return new EmailLookup(rows, subject is not null);
    }

    /// <summary>The email sign-in subject of an address (its keyed hash, as <c>identity.consume_email</c> stores it), or null
    /// when this process has no lookup key. A configured key that can't be read fails the lookup rather than hide accounts.</summary>
    private string? EmailSubject(string normalized)
    {
        if (string.IsNullOrEmpty(options.Value.PepperFile)) { return null; }
        var pepper = IdentitySecrets.ReadKey(options.Value.PepperFile);
        try { return Convert.ToHexStringLower(HMACSHA256.HashData(pepper, Encoding.UTF8.GetBytes(EmailAddresses.LookupDomain + "\0" + normalized))); }
        finally { CryptographicOperations.ZeroMemory(pepper); }
    }

    public async Task<IReadOnlyList<AdminDevice>> DevicesAsync(Guid user, DateTimeOffset now, CancellationToken cancellationToken)
    {
        await using var command = source.CreateCommand("SELECT platform,app_version,last_seen_at,active_sessions FROM identity.admin_devices($1,$2)");
        command.Parameters.AddWithValue(user);
        command.Parameters.AddWithValue(now);
        var rows = new List<AdminDevice>();
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            rows.Add(new AdminDevice(reader.IsDBNull(0) ? null : reader.GetString(0), reader.IsDBNull(1) ? null : reader.GetString(1),
                reader.IsDBNull(2) ? null : reader.GetFieldValue<DateTimeOffset>(2), reader.GetInt64(3)));
        }
        return rows;
    }

    private async Task<IReadOnlyList<AdminAccount>> QueryAsync(string? type, Guid? before, int limit, Guid[]? ids, CancellationToken cancellationToken)
    {
        await using var command = source.CreateCommand("""
            SELECT user_id,account_type,masked_email,email_state,status,created_at,last_seen_at,app_version,devices FROM identity.admin_accounts($1,$2,$3,$4)
            """);
        command.Parameters.AddWithValue(NpgsqlDbType.Text, (object?)type ?? DBNull.Value);
        command.Parameters.AddWithValue(NpgsqlDbType.Uuid, (object?)before ?? DBNull.Value);
        command.Parameters.AddWithValue(limit);
        command.Parameters.AddWithValue(NpgsqlDbType.Array | NpgsqlDbType.Uuid, (object?)ids ?? DBNull.Value);
        var rows = new List<AdminAccount>();
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            rows.Add(new AdminAccount(reader.GetGuid(0), reader.GetString(1), reader.IsDBNull(2) ? null : reader.GetString(2), reader.GetString(3),
                reader.GetString(4), reader.GetFieldValue<DateTimeOffset>(5), reader.IsDBNull(6) ? null : reader.GetFieldValue<DateTimeOffset>(6),
                reader.IsDBNull(7) ? null : reader.GetString(7), reader.GetInt64(8)));
        }
        return rows;
    }
}
