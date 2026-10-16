using FitnessBuddy.Host.Platform;
using FitnessBuddy.Host.Observability;

namespace FitnessBuddy.Host.Roles;

/// <summary>The worker role runs the durable outbox and scheduled jobs against the application database login.</summary>
internal static class WorkerRole
{
    public static async Task<int> RunAsync(string[] args)
    {
        var builder = Microsoft.Extensions.Hosting.Host.CreateApplicationBuilder(args);
        builder.AddFbPlatform();
        builder.AddFbPersistence();
        builder.Services.AddHostedService<DatabaseWorker>();
        builder.AddFbObservability("worker");
        using var host = builder.Build();
        await host.RunAsync();
        return 0;
    }
}
