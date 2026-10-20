using System.Data;
using FitnessBuddy.BuildingBlocks.Ids;
using FitnessBuddy.BuildingBlocks.Persistence;
using Microsoft.Extensions.Options;
using Npgsql;

namespace FitnessBuddy.BuildingBlocks.Recovery;

/// <summary>Operator/migration-role only. Session lock spans initialization commit and module maintenance.</summary>
public static class RecoveryMaintenance
{
    public static async Task RunAsync(string migratorConnection, RecoveryOptions options, IIdGenerator ids, bool initialize,
        Func<CancellationToken, Task> maintenance, CancellationToken cancellationToken)
    {
        await using var source = DatabaseConfiguration.CreateSource(migratorConnection);
        await using var session = new DatabaseSession();
        await session.BeginAsync(source, null, cancellationToken);
        var locked = false;
        try
        {
            await using (var acquire = session.Command("SELECT pg_advisory_lock($1)"))
            { acquire.Parameters.AddWithValue(RecoveryBarrier.LockKey); await acquire.ExecuteNonQueryAsync(cancellationToken); locked = true; }
            var barrier = new RecoveryBarrier(Options.Create(options));
            object? current;
            await using (var read = session.Command("SELECT generation FROM ops.recovery WHERE singleton"))
            { current = await read.ExecuteScalarAsync(cancellationToken); }
            if (current is Guid) { await barrier.VerifyAsync(session, cancellationToken); }
            else if (current is DBNull && initialize && !barrier.File.Exists())
            {
                var generation = ids.NewId();
                barrier.File.Write(generation);
                await RecoveryBarrier.SetDatabaseAsync(session, generation, cancellationToken);
            }
            else { throw new RecoveryUnavailableException(); }
            // A later key/seed error must not turn an already durable initialization into an orphan marker.
            await session.CommitAsync(cancellationToken);
            await maintenance(cancellationToken);
        }
        finally
        {
            if (locked && session.Connection.State == ConnectionState.Open)
            {
                await using var release = new NpgsqlCommand("SELECT pg_advisory_unlock($1)", session.Connection);
                release.Parameters.AddWithValue(RecoveryBarrier.LockKey);
                await release.ExecuteNonQueryAsync(CancellationToken.None);
            }
        }
    }
}
