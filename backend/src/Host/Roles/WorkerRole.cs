using FitnessBuddy.Host.Platform;
using FitnessBuddy.Host.Observability;

namespace FitnessBuddy.Host.Roles;

/// <summary>The <c>worker</c> role: outbox delivery and scheduled jobs (from S04).</summary>
internal static class WorkerRole
{
    public static async Task<int> RunAsync(string[] args)
    {
        var builder = Microsoft.Extensions.Hosting.Host.CreateApplicationBuilder(args);
        builder.AddFbPlatform();
        builder.AddFbObservability("worker");
        builder.Services.AddHostedService<IdleWorker>();

        using var host = builder.Build();
        await host.RunAsync();
        return 0;
    }
}

/// <summary>Keeps the worker process alive until the first jobs arrive (S04).</summary>
internal sealed partial class IdleWorker(ILogger<IdleWorker> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        LogIdle(logger);
        try
        {
            await Task.Delay(Timeout.Infinite, stoppingToken);
        }
        catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
        {
            // Shutdown requested.
        }
    }

    [LoggerMessage(Level = LogLevel.Information, Message = "Worker started: no jobs until S04")]
    private static partial void LogIdle(ILogger logger);
}
