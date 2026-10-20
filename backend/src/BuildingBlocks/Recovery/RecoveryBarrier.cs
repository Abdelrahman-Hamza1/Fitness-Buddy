using FitnessBuddy.BuildingBlocks.Persistence;
using Microsoft.Extensions.Options;

namespace FitnessBuddy.BuildingBlocks.Recovery;

/// <summary>Take before user/queue locks. Shared readers exclude deletion/backup/restore, all on one host.</summary>
public sealed class RecoveryBarrier(IOptions<RecoveryOptions> options)
{
    // Also used by the private operator controller; a protocol constant, never a user-derived lock key.
    public const long LockKey = 460391206;
    public RecoveryFile File => new(options.Value.Directory);

    public static async Task LockAsync(DatabaseSession session, bool exclusive, CancellationToken cancellationToken)
    {
        await using var command = session.Command(exclusive ? "SELECT pg_advisory_xact_lock($1)" : "SELECT pg_advisory_xact_lock_shared($1)");
        command.Parameters.AddWithValue(LockKey);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    public async Task<Guid> VerifyAsync(DatabaseSession session, CancellationToken cancellationToken)
    {
        var live = File.Read();
        await using var command = session.Command("SELECT generation FROM ops.recovery WHERE singleton");
        if (await command.ExecuteScalarAsync(cancellationToken) is not Guid database || database != live)
        { throw new RecoveryUnavailableException(); }
        return live;
    }

    /// <summary>Only after rollback to a savepoint while the same exclusive lock is still held.</summary>
    public async Task ReconcileKnownRollbackAsync(DatabaseSession session, Guid previous, CancellationToken cancellationToken)
    {
        await using var command = session.Command("SELECT generation FROM ops.recovery WHERE singleton");
        if (await command.ExecuteScalarAsync(cancellationToken) is not Guid current || current != previous)
        { throw new RecoveryUnavailableException(); }
        File.Write(previous);
    }

    /// <summary>The caller holds the exclusive lock and commits this update with erasure effects.</summary>
    public static async Task SetDatabaseAsync(DatabaseSession session, Guid generation, CancellationToken cancellationToken)
    {
        await using var command = session.Command("UPDATE ops.recovery SET generation=$1 WHERE singleton");
        command.Parameters.AddWithValue(generation);
        if (await command.ExecuteNonQueryAsync(cancellationToken) != 1) { throw new RecoveryUnavailableException(); }
    }
}
