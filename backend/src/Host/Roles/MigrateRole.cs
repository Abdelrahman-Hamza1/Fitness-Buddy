using FitnessBuddy.Host.Platform;
using FitnessBuddy.Host.Observability;

namespace FitnessBuddy.Host.Roles;

/// <summary>The <c>migrate</c> role: a one-shot command that applies database migrations before a deploy (08 §4, from S04).</summary>
internal static partial class MigrateRole
{
    public static Task<int> RunAsync(string[] args)
    {
        var builder = Microsoft.Extensions.Hosting.Host.CreateApplicationBuilder(args);
        builder.AddFbPlatform();
        builder.AddFbObservability("migrate");

        using var host = builder.Build();
        var logger = host.Services.GetRequiredService<ILoggerFactory>().CreateLogger(typeof(MigrateRole).FullName!);
        LogNothingToDo(logger);
        return Task.FromResult(0);
    }

    [LoggerMessage(Level = LogLevel.Information, Message = "Migrate: no migrations until S04")]
    private static partial void LogNothingToDo(ILogger logger);
}
