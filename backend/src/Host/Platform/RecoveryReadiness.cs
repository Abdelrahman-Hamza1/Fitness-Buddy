using Microsoft.Extensions.Diagnostics.HealthChecks;

namespace FitnessBuddy.Host.Platform;

internal sealed class RecoveryReadiness(RecoveryRequestGate gate) : IHealthCheck
{
    public async Task<HealthCheckResult> CheckHealthAsync(HealthCheckContext context, CancellationToken cancellationToken = default)
    {
        using var timeout = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        timeout.CancelAfter(TimeSpan.FromSeconds(2));
        try
        {
            await using var session = await gate.EnterAsync(timeout.Token);
            return HealthCheckResult.Healthy();
        }
        catch (Exception) when (!cancellationToken.IsCancellationRequested)
        { return HealthCheckResult.Unhealthy("recovery-state-unavailable"); }
    }
}
