using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.Modules.Usage.Contracts;
using NpgsqlTypes;

namespace FitnessBuddy.Modules.Usage.Infrastructure;

/// <summary>Runs on the caller's console session (fb_admin); the application login can't execute these functions.</summary>
internal sealed class PostgresUsageAdminControls : IUsageAdminControls
{
    public async Task<int?> DailyLimitAsync(DatabaseSession session, Guid user, CancellationToken cancellationToken)
    {
        await using var command = session.Command("SELECT usage.admin_daily_limit($1)");
        command.Parameters.AddWithValue(user);
        return await command.ExecuteScalarAsync(cancellationToken) is int calls ? calls : null;
    }

    public async Task<int?> SetDailyLimitAsync(DatabaseSession session, Guid user, int? dailyCalls, DateTimeOffset now, CancellationToken cancellationToken)
    {
        if (dailyCalls is < 0 or > IUsageAdminControls.MaxDailyCalls) { throw new ArgumentOutOfRangeException(nameof(dailyCalls)); }
        await using var command = session.Command("SELECT usage.admin_set_daily_limit($1,$2,$3)");
        command.Parameters.AddWithValue(user);
        command.Parameters.Add(new Npgsql.NpgsqlParameter { NpgsqlDbType = NpgsqlDbType.Integer, Value = (object?)dailyCalls ?? DBNull.Value });
        command.Parameters.AddWithValue(now);
        return await command.ExecuteScalarAsync(cancellationToken) is int previous ? previous : null;
    }
}
