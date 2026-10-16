using Microsoft.Extensions.Diagnostics.HealthChecks;
using Npgsql;

namespace FitnessBuddy.Host.Platform;

internal sealed class DatabaseReadiness(NpgsqlDataSource source) : IHealthCheck
{
    public async Task<HealthCheckResult> CheckHealthAsync(HealthCheckContext context, CancellationToken cancellationToken = default)
    {
        using var timeout = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        timeout.CancelAfter(TimeSpan.FromSeconds(2));
        try
        {
            await using var command = source.CreateCommand("SELECT 1");
            command.CommandTimeout = 2;
            await command.ExecuteScalarAsync(timeout.Token);
            return HealthCheckResult.Healthy();
        }
        catch (Exception) when (!cancellationToken.IsCancellationRequested)
        {
            // Do not attach the driver's exception/connection string to health logs or response text.
            return HealthCheckResult.Unhealthy("database-unavailable");
        }
    }
}
