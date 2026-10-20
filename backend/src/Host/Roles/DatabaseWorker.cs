using FitnessBuddy.BuildingBlocks.Jobs;

namespace FitnessBuddy.Host.Roles;

internal sealed partial class DatabaseWorker(IServiceScopeFactory scopes, TimeProvider clock,
    ILogger<DatabaseWorker> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var registered = false;
        while (!stoppingToken.IsCancellationRequested)
        {
            var work = false;
            try
            {
                await using var scope = scopes.CreateAsyncScope();
                var scheduler = scope.ServiceProvider.GetRequiredService<JobScheduler>();
                if (!registered)
                {
                    await scheduler.RegisterAsync(new JobSchedule("ops.cleanup", "*/5 * * * *", OpsCleanupJob.Type), stoppingToken);
                    registered = true;
                }
                work = await scheduler.TickAsync(stoppingToken);
                var processor = scope.ServiceProvider.GetRequiredService<QueueProcessor>();
                work |= await processor.DispatchOutboxAsync(stoppingToken);
                work |= await processor.RunJobAsync(stoppingToken);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested) { break; }
            catch (Exception exception) { LogFailure(logger, exception.GetType().Name); }
            if (!work)
            {
                try { await Task.Delay(TimeSpan.FromSeconds(1), clock, stoppingToken); }
                catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested) { break; }
            }
        }
    }

    [LoggerMessage(Level = LogLevel.Warning, Message = "Worker poll failed with {ErrorCode}")]
    private static partial void LogFailure(ILogger logger, string errorCode);
}
