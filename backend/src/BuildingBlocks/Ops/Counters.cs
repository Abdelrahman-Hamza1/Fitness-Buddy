using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.BuildingBlocks.Recovery;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Npgsql;
using NpgsqlTypes;

namespace FitnessBuddy.BuildingBlocks.Ops;

/// <summary>
/// An in-memory tally of global counters (B23 R#9): adding is lock-free on the request path, and <see cref="Drain"/> hands the
/// batch to one flush. Bounded: past <see cref="MaxKeys"/> distinct keys new keys are dropped. Counts can be lost on a crash or
/// a failed flush, so the console calls them approximate.
/// </summary>
public sealed class CounterBatch<TKey> where TKey : notnull
{
    public const int MaxKeys = 10_000;

    private System.Collections.Concurrent.ConcurrentDictionary<TKey, long> counts = new();

    public void Add(TKey key, long amount = 1)
    {
        var current = Volatile.Read(ref counts);
        if (current.Count >= MaxKeys && !current.ContainsKey(key)) { return; }
        current.AddOrUpdate(key, amount, (_, value) => value + amount);
    }

    /// <summary>Takes everything counted so far and starts a new batch.</summary>
    public IReadOnlyList<KeyValuePair<TKey, long>> Drain() => [.. Interlocked.Exchange(ref counts, new()).Where(pair => pair.Value > 0)];
}

/// <summary>A batched counter that <see cref="CounterFlushService"/> writes out periodically. Implementations write one upsert per batch.</summary>
public interface ICounterFlush
{
    Task FlushAsync(CancellationToken cancellationToken);
}

/// <summary>
/// Flushes every <see cref="ICounterFlush"/> once a minute and once more on shutdown (api role only). A failed flush is logged by
/// error type and its batch dropped; it never reaches a request.
/// </summary>
public sealed partial class CounterFlushService(IEnumerable<ICounterFlush> flushes, TimeProvider clock, ILogger<CounterFlushService> logger) : BackgroundService
{
    public static readonly TimeSpan Interval = TimeSpan.FromSeconds(60);

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            try { await Task.Delay(Interval, clock, stoppingToken); }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested) { break; }
            await FlushAllAsync(stoppingToken);
        }
    }

    public override async Task StopAsync(CancellationToken cancellationToken)
    {
        await base.StopAsync(cancellationToken);
        using var timeout = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        timeout.CancelAfter(TimeSpan.FromSeconds(5));
        await FlushAllAsync(timeout.Token);
    }

    private async Task FlushAllAsync(CancellationToken cancellationToken)
    {
        foreach (var flush in flushes)
        {
            try { await flush.FlushAsync(cancellationToken); }
            catch (Exception exception) { LogFlushFailed(logger, flush.GetType().Name, exception.GetType().Name); }
        }
    }

    [LoggerMessage(Level = LogLevel.Warning, Message = "Counter flush {Counter} failed with {ErrorType}; the batch was dropped")]
    private static partial void LogFlushFailed(ILogger logger, string counter, string errorType);
}

/// <summary>Server errors (5xx) per hour and status, for the console's Overview (B23 P4). Health probes aren't counted.
/// The data source is resolved on the first flush, so recording needs no database (and the pipeline builds without one).</summary>
public sealed class ServerErrorCounter(Func<NpgsqlDataSource> source, TimeProvider clock, RecoveryBarrier recovery) : ICounterFlush
{
    private readonly CounterBatch<(DateTimeOffset Hour, int Status)> batch = new();

    public void Record(int status)
    {
        if (status is < 500 or > 599) { return; }
        var now = clock.GetUtcNow();
        batch.Add((new DateTimeOffset(now.Year, now.Month, now.Day, now.Hour, 0, 0, TimeSpan.Zero), status));
    }

    public async Task FlushAsync(CancellationToken cancellationToken)
    {
        var rows = batch.Drain();
        if (rows.Count == 0) { return; }
        await using var session = new DatabaseSession();
        await session.BeginAsync(source(), null, cancellationToken);
        await RecoveryBarrier.LockAsync(session, exclusive: false, cancellationToken);
        await recovery.VerifyAsync(session, cancellationToken);
        // Add-only, and the role is the calling login's (B23b): the API can't write or erase another role's counts.
        await using var command = session.Command("SELECT ops.count_http_errors($1,$2,$3)");
        command.Parameters.AddWithValue(NpgsqlDbType.Array | NpgsqlDbType.TimestampTz, rows.Select(row => row.Key.Hour).ToArray());
        command.Parameters.AddWithValue(NpgsqlDbType.Array | NpgsqlDbType.Integer, rows.Select(row => row.Key.Status).ToArray());
        command.Parameters.AddWithValue(NpgsqlDbType.Array | NpgsqlDbType.Bigint, rows.Select(row => row.Value).ToArray());
        await command.ExecuteNonQueryAsync(cancellationToken);
        await session.CommitAsync(cancellationToken);
    }
}
