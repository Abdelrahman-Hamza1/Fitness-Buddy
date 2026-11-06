using FitnessBuddy.Modules.Identity.Contracts;
using Npgsql;

namespace FitnessBuddy.Modules.Identity.Infrastructure;

/// <summary>Runs on the admin role's data source (fb_admin); the application login can't execute these functions.</summary>
internal sealed class PostgresIdentityAdminReads(NpgsqlDataSource source) : IIdentityAdminReads
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
}
