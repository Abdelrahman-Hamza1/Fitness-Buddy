using FitnessBuddy.Modules.Usage.Contracts;
using Npgsql;
using NpgsqlTypes;

namespace FitnessBuddy.Modules.Usage.Infrastructure;

/// <summary>Runs on the admin role's data source (fb_admin); the application login can't execute these functions.</summary>
internal sealed class PostgresUsageAdminReads(NpgsqlDataSource source) : IUsageAdminReads
{
    public async Task<UsageTotals> SpendAsync(DateOnly first, DateOnly last, CancellationToken cancellationToken)
    {
        await using var command = source.CreateCommand("SELECT calls,messages,estimated_usd FROM usage.admin_spend($1,$2)");
        command.Parameters.AddWithValue(first);
        command.Parameters.AddWithValue(last);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        await reader.ReadAsync(cancellationToken);
        return new UsageTotals(reader.GetInt64(0), reader.GetInt64(1), reader.GetDecimal(2));
    }

    public async Task<IReadOnlyDictionary<Guid, long>> UsesAsync(IReadOnlyCollection<Guid> users, DateOnly since, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(users);
        var uses = new Dictionary<Guid, long>();
        if (users.Count == 0) { return uses; }
        await using var command = source.CreateCommand("SELECT user_id,calls FROM usage.admin_uses($1,$2)");
        command.Parameters.AddWithValue(NpgsqlDbType.Array | NpgsqlDbType.Uuid, users.ToArray());
        command.Parameters.AddWithValue(since);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken)) { uses[reader.GetGuid(0)] = reader.GetInt64(1); }
        return uses;
    }
}
