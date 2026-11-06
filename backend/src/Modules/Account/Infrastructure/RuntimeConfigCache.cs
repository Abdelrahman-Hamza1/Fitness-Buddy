using FitnessBuddy.BuildingBlocks.Clients;
using FitnessBuddy.BuildingBlocks.Features;
using FitnessBuddy.Modules.Account.Application;
using FitnessBuddy.Modules.Account.Contracts;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Npgsql;

namespace FitnessBuddy.Modules.Account.Infrastructure;

/// <summary>
/// The published remote config in this process (B23 P1). Until the first successful read, and while nothing is published, it
/// serves the configuration defaults; after a read it keeps the last good version while the database is unreachable. The
/// minimum-version override from configuration always wins. Refreshed by <see cref="RuntimeConfigPoller"/>.
/// </summary>
internal sealed partial class RuntimeConfigCache(IServiceProvider services, RemoteConfigDefaults defaults, IOptionsMonitor<ClientCompatibilityOptions> options,
    ILogger<RuntimeConfigCache> logger) : IRuntimeConfig, IClientCompatibility, IFeatureFlags
{
    private volatile Snapshot? published;
    private bool failing;

    public int? Version => published?.Version;

    public RemoteConfigDocument Current => published?.Document ?? defaults.Current;

    public AppVersion MinimumAppVersion =>
        options.CurrentValue.GetOverride() ?? (AppVersion.TryParse(Current.MinimumAppVersion, out var version) ? version : options.CurrentValue.GetMinimumAppVersion());

    public bool OverrideActive => options.CurrentValue.GetOverride() is not null;

    public bool IsEnabled(string name) => Current.ServerFlags.TryGetValue(name, out var enabled) && enabled;

    /// <summary>Reads the newest version. Never throws for a database problem; it keeps the last good value and logs a state change once.</summary>
    public async Task RefreshAsync(CancellationToken cancellationToken)
    {
        try
        {
            // Resolved on first refresh only: building the gate (or the build-time document) must not open a data source.
            var source = (NpgsqlDataSource)(services.GetService(typeof(NpgsqlDataSource)) ?? throw new InvalidOperationException("No data source."));
            await using var command = source.CreateCommand("SELECT version,document::text FROM account.config_versions ORDER BY version DESC LIMIT 1");
            await using var reader = await command.ExecuteReaderAsync(cancellationToken);
            if (await reader.ReadAsync(cancellationToken))
            {
                var version = reader.GetInt32(0);
                if (published?.Version != version)
                {
                    var document = RemoteConfigDocument.FromJson(reader.GetString(1));
                    if (document is null || !AppVersion.TryParse(document.MinimumAppVersion, out _)) { LogUnreadable(logger, version); }
                    else { published = new Snapshot(version, document); LogLoaded(logger, version); }
                }
            }
            if (failing) { failing = false; LogRecovered(logger); }
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested) { throw; }
        catch (Exception exception) when (exception is NpgsqlException or InvalidOperationException or TimeoutException or ArgumentException)
        {
            if (!failing) { failing = true; LogFailed(logger, exception.GetType().Name); }
        }
    }

    private sealed record Snapshot(int Version, RemoteConfigDocument Document);

    [LoggerMessage(Level = LogLevel.Information, Message = "Remote config version {Version} in effect")]
    private static partial void LogLoaded(ILogger logger, int version);

    [LoggerMessage(Level = LogLevel.Error, Message = "Remote config version {Version} is unreadable; keeping the previous one")]
    private static partial void LogUnreadable(ILogger logger, int version);

    [LoggerMessage(Level = LogLevel.Warning, Message = "Remote config can't be read ({ErrorType}); keeping the last good value")]
    private static partial void LogFailed(ILogger logger, string errorType);

    [LoggerMessage(Level = LogLevel.Information, Message = "Remote config readable again")]
    private static partial void LogRecovered(ILogger logger);
}

/// <summary>Polls the newest remote-config version (default every 5 s, <c>Account:RemoteConfig:PollSeconds</c>).</summary>
internal sealed class RuntimeConfigPoller(RuntimeConfigCache cache, IOptions<RemoteConfigPollOptions> options, TimeProvider clock) : Microsoft.Extensions.Hosting.BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var interval = TimeSpan.FromSeconds(Math.Clamp(options.Value.PollSeconds, 1, 300));
        while (!stoppingToken.IsCancellationRequested)
        {
            await cache.RefreshAsync(stoppingToken);
            try { await Task.Delay(interval, clock, stoppingToken); }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested) { return; }
        }
    }
}

internal sealed class RemoteConfigPollOptions
{
    public const string SectionName = "Account:RemoteConfig";

    public int PollSeconds { get; set; } = 5;
}
