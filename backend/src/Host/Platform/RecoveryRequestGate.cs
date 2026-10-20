using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.BuildingBlocks.Recovery;
using Microsoft.Extensions.Options;
using Npgsql;

namespace FitnessBuddy.Host.Platform;

/// <summary>A separate bounded pool avoids requests exhausting the business pool while holding gate leases.</summary>
internal sealed class RecoveryRequestGate : IAsyncDisposable, IDisposable
{
    private readonly Lazy<NpgsqlDataSource> source;
    private readonly RecoveryBarrier recovery;
    public RecoveryRequestGate(IOptions<DatabaseOptions> options, RecoveryBarrier recovery)
    {
        this.recovery = recovery;
        source = new Lazy<NpgsqlDataSource>(() => DatabaseConfiguration.CreateSource(new NpgsqlConnectionStringBuilder(options.Value.Application)
        { ApplicationName = "fitness-buddy-recovery-gate", MaxPoolSize = 8, MinPoolSize = 0 }.ConnectionString));
    }

    public async Task<DatabaseSession> EnterAsync(CancellationToken cancellationToken)
    {
        var session = new DatabaseSession();
        try
        {
            await session.BeginAsync(source.Value, null, cancellationToken);
            await RecoveryBarrier.LockAsync(session, exclusive: false, cancellationToken);
            await recovery.VerifyAsync(session, cancellationToken);
            return session;
        }
        catch { await session.DisposeAsync(); throw; }
    }

    public void Dispose() { if (source.IsValueCreated) { source.Value.Dispose(); } }

    public async ValueTask DisposeAsync()
    { if (source.IsValueCreated) { await source.Value.DisposeAsync(); } }
}
