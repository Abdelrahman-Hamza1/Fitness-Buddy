using FitnessBuddy.Host.Platform;
using FitnessBuddy.Host.Observability;

namespace FitnessBuddy.Host.Roles;

/// <summary>The worker role runs the durable outbox and scheduled jobs on its own database login, fb_worker (B23b).</summary>
internal static class WorkerRole
{
    public static async Task<int> RunAsync(string[] args)
    {
        var builder = Microsoft.Extensions.Hosting.Host.CreateApplicationBuilder(args);
        builder.AddFbPlatform();
        builder.AddFbPersistence(worker: true);
        builder.Services.AddHostedService<DatabaseWorker>();
        // B23: the heartbeat with the item in progress, for the console (AD-010, AD-014).
        builder.Services.AddSingleton<FitnessBuddy.BuildingBlocks.Jobs.WorkerActivity>();
        builder.Services.AddHostedService<FitnessBuddy.BuildingBlocks.Jobs.WorkerHeartbeatService>();
        FitnessBuddy.Modules.Account.AccountModule.AddRuntimeConfigPolling(builder.Services);
        builder.AddFbObservability("worker");
        using var host = builder.Build();
        await host.RunAsync();
        return 0;
    }
}
