
namespace FitnessBuddy.BuildingBlocks.Persistence;

/// <summary>Shared serialization for sync, user jobs and account erasure; take before row locks or sequences.</summary>
public static class UserLifecycleLock
{
    public static async Task<bool> TryAcquireAsync(DatabaseSession session, Guid userId, CancellationToken cancellationToken)
    {
        await using var command = session.Command("SELECT pg_try_advisory_xact_lock(hashtextextended($1, 4603912))");
        command.Parameters.AddWithValue(userId.ToString());
        return (bool)(await command.ExecuteScalarAsync(cancellationToken))!;
    }

    public static async Task AcquireAsync(DatabaseSession session, Guid userId, CancellationToken cancellationToken)
    {
        await using var command = session.Command("SELECT pg_advisory_xact_lock(hashtextextended($1, 4603912))");
        command.Parameters.AddWithValue(userId.ToString());
        await command.ExecuteNonQueryAsync(cancellationToken);
    }
}
