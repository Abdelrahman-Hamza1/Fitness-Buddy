using System.Reflection;
using FitnessBuddy.BuildingBlocks.Ids;
using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.BuildingBlocks.Recovery;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Npgsql;

namespace FitnessBuddy.BuildingBlocks.Jobs;

/// <summary>
/// This worker process: its instance id and the queue item type it is running right now (B23 R#11). The queue processor sets
/// it around a handler; the heartbeat reports it. Only closed type codes are kept, never a payload or a user.
/// </summary>
public sealed class WorkerActivity(TimeProvider clock, IIdGenerator ids)
{
    private sealed record Busy(Ops.QueueKind Kind, string Type, DateTimeOffset Since);

    private Busy? current;

    public Guid Instance { get; } = ids.NewId();

    public DateTimeOffset StartedAt { get; } = clock.GetUtcNow();

    /// <summary>The queue kind and type in progress and since when, or null when idle.</summary>
    public (Ops.QueueKind Kind, string Type, DateTimeOffset Since)? Current => Volatile.Read(ref current) is { } busy ? (busy.Kind, busy.Type, busy.Since) : null;

    /// <summary>Marks a job or an event handler of <paramref name="type"/> as in progress until the returned scope is disposed.</summary>
    public IDisposable Begin(Ops.QueueKind kind, string type)
    {
        var busy = new Busy(kind, type, clock.GetUtcNow());
        Volatile.Write(ref current, busy);
        return new Scope(this, busy);
    }

    private sealed class Scope(WorkerActivity owner, Busy busy) : IDisposable
    {
        public void Dispose() => Interlocked.CompareExchange(ref owner.current, null, busy);
    }
}

/// <summary>
/// Writes this worker's heartbeat (<c>ops.worker_heartbeats</c>) every 30 s with the item in progress, for the console's
/// Overview and Jobs windows. A failed beat is logged by error type and retried at the next interval; it never stops the worker.
/// </summary>
public sealed partial class WorkerHeartbeatService(NpgsqlDataSource source, WorkerActivity activity, TimeProvider clock, RecoveryBarrier recovery,
    ILogger<WorkerHeartbeatService> logger) : BackgroundService
{
    public static readonly TimeSpan Interval = TimeSpan.FromSeconds(30);

    private static readonly string Build = BuildVersion();

    /// <summary>One beat (the service calls it every <see cref="Interval"/>; tests call it directly).</summary>
    public async Task BeatAsync(CancellationToken cancellationToken)
    {
        var busy = activity.Current;
        await using var session = new DatabaseSession();
        await session.BeginAsync(source, null, cancellationToken);
        await RecoveryBarrier.LockAsync(session, exclusive: false, cancellationToken);
        await recovery.VerifyAsync(session, cancellationToken);
        await using var command = session.Command("""
            INSERT INTO ops.worker_heartbeats(instance,role,build,started_at,last_beat_at,busy_kind,busy_type,busy_since) VALUES($1,'worker',$2,$3,$4,$7,$5,$6)
            ON CONFLICT(instance) DO UPDATE SET last_beat_at=excluded.last_beat_at,busy_kind=excluded.busy_kind,busy_type=excluded.busy_type,busy_since=excluded.busy_since
            """);
        command.Parameters.AddWithValue(activity.Instance);
        command.Parameters.AddWithValue(Build);
        command.Parameters.AddWithValue(activity.StartedAt);
        command.Parameters.AddWithValue(clock.GetUtcNow());
        command.Parameters.AddWithValue(NpgsqlTypes.NpgsqlDbType.Varchar, (object?)busy?.Type ?? DBNull.Value);
        command.Parameters.AddWithValue(NpgsqlTypes.NpgsqlDbType.TimestampTz, (object?)busy?.Since ?? DBNull.Value);
        command.Parameters.AddWithValue(NpgsqlTypes.NpgsqlDbType.Text, busy is { } item ? Ops.OpsQueues.Code(item.Kind) : DBNull.Value);
        await command.ExecuteNonQueryAsync(cancellationToken);
        await session.CommitAsync(cancellationToken);
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            try { await BeatAsync(stoppingToken); }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested) { break; }
            catch (Exception exception) { LogBeatFailed(logger, exception.GetType().Name); }
            try { await Task.Delay(Interval, clock, stoppingToken); }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested) { break; }
        }
    }

    private static string BuildVersion()
    {
        var version = Assembly.GetEntryAssembly()?.GetCustomAttribute<AssemblyInformationalVersionAttribute>()?.InformationalVersion ?? "unknown";
        return version.Length > 64 ? version[..64] : version;
    }

    [LoggerMessage(Level = LogLevel.Warning, Message = "Worker heartbeat failed with {ErrorType}")]
    private static partial void LogBeatFailed(ILogger logger, string errorType);
}
