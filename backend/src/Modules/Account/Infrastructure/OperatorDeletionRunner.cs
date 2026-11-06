using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.BuildingBlocks.Recovery;
using FitnessBuddy.Modules.Account.Application;
using FitnessBuddy.Modules.Identity.Contracts;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Npgsql;

namespace FitnessBuddy.Modules.Account.Infrastructure;

/// <summary>
/// B24 (TD-122 candidate): runs the operator deletions the console requested, in the api role, which already holds the
/// application login, the Identity secrets and the writable recovery state the B06 coordinator needs; the console keeps
/// only its own login. Each due intent goes through the unchanged coordinator with the operator principal.
/// <list type="bullet">
/// <item>Nothing escapes: an item's failure is recorded (closed code, backoff) and the next item runs; a tick's failure waits
/// and retries; only shutdown ends the loop.</item>
/// <item>No false completion: success is the intent erased with the account in the deletion transaction. A failure is
/// recorded only while the intent still exists, so after an ambiguous commit that landed, nothing is recreated.</item>
/// </list>
/// Logs carry outcome codes and error types only, never an account id.
/// </summary>
internal sealed partial class OperatorDeletionRunner(IServiceScopeFactory scopes, IIdentityOperatorDeletions deletions, NpgsqlDataSource source,
    IOptions<OperatorDeletionOptions> options, IHostEnvironment environment, TimeProvider clock, ILogger<OperatorDeletionRunner> logger) : BackgroundService
{
    public const int MaxPerTick = 10;

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        // Tests run the runner directly (RunOnceAsync); an api factory must never delete another test's accounts.
        if (!options.Value.Enabled || environment.IsEnvironment("Testing")) { return; }
        var interval = TimeSpan.FromSeconds(Math.Clamp(options.Value.PollSeconds, 1, 300));
        while (!stoppingToken.IsCancellationRequested)
        {
            var delay = interval;
            try { await RunOnceAsync(stoppingToken); }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested) { return; }
            catch (Exception exception)
            {
                LogTickFailed(logger, exception.GetType().Name);
                delay = TimeSpan.FromSeconds(30);
            }
            try { await Task.Delay(delay, clock, stoppingToken); }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested) { return; }
        }
    }

    /// <summary>One pass over at most <see cref="MaxPerTick"/> due intents; returns how many accounts were deleted.</summary>
    internal async Task<int> RunOnceAsync(CancellationToken cancellationToken)
    {
        var due = await deletions.DueAsync(clock.GetUtcNow(), MaxPerTick, cancellationToken);
        var deleted = 0;
        foreach (var user in due)
        {
            cancellationToken.ThrowIfCancellationRequested();
            string? failure = null;
            try
            {
                await using var scope = scopes.CreateAsyncScope();
                var result = await scope.ServiceProvider.GetRequiredService<IAccountDeletion>().DeleteForOperatorAsync(user, cancellationToken);
                switch (result)
                {
                    case DeletionResult.Deleted: deleted++; LogOutcome(logger, "deleted"); break;
                    case DeletionResult.Unavailable: failure = "unavailable"; break;
                    // The intent vanished or isn't due (another runner, or the app deleted first): nothing to record.
                    default: LogOutcome(logger, "skipped"); break;
                }
            }
            catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested) { throw; }
            catch (RecoveryUnavailableException) { failure = "recovery-unavailable"; }
            catch (Exception exception)
            {
                LogItemFailed(logger, exception.GetType().Name);
                failure = "failed";
            }
            if (failure is not null) { await RecordFailureAsync(user, failure, cancellationToken); }
        }
        return deleted;
    }

    private async Task RecordFailureAsync(Guid user, string code, CancellationToken cancellationToken)
    {
        try
        {
            await using var session = new DatabaseSession();
            await session.BeginAsync(source, user, cancellationToken);
            var recorded = await deletions.RecordFailureAsync(session, code, cancellationToken);
            await session.CommitAsync(cancellationToken);
            LogOutcome(logger, recorded ? code : "gone");
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested) { throw; }
        catch (Exception exception) { LogRecordFailed(logger, exception.GetType().Name); }
    }

    [LoggerMessage(Level = LogLevel.Information, Message = "Operator deletion: {Outcome}")]
    private static partial void LogOutcome(ILogger logger, string outcome);

    [LoggerMessage(Level = LogLevel.Warning, Message = "Operator deletion attempt failed: {ErrorType}")]
    private static partial void LogItemFailed(ILogger logger, string errorType);

    [LoggerMessage(Level = LogLevel.Warning, Message = "Operator deletion failure not recorded: {ErrorType}")]
    private static partial void LogRecordFailed(ILogger logger, string errorType);

    [LoggerMessage(Level = LogLevel.Warning, Message = "Operator deletion pass failed: {ErrorType}")]
    private static partial void LogTickFailed(ILogger logger, string errorType);
}

internal sealed class OperatorDeletionOptions
{
    public const string SectionName = "Account:OperatorDeletion";

    public bool Enabled { get; set; } = true;

    public int PollSeconds { get; set; } = 5;
}
