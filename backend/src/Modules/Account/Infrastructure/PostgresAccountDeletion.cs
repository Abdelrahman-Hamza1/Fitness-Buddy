using FitnessBuddy.BuildingBlocks.Ids;
using FitnessBuddy.BuildingBlocks.Jobs;
using FitnessBuddy.BuildingBlocks.Messaging;
using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.BuildingBlocks.Recovery;
using FitnessBuddy.BuildingBlocks.Web.Modules;
using FitnessBuddy.Modules.Account.Application;
using FitnessBuddy.Modules.Identity.Contracts;
using Npgsql;

namespace FitnessBuddy.Modules.Account.Infrastructure;

internal sealed class PostgresAccountDeletion(NpgsqlDataSource source, RecoveryBarrier recovery, IIdentityAccess identity,
    IEnumerable<IIdentityDeletion> deletionCapabilities, IEnumerable<IModule> modules, QueueProcessor dispatcher,
    TimeProvider clock, IIdGenerator ids) : IAccountDeletion
{
    public async Task<DeletionResult> DeleteAsync(Guid userId, Guid sessionId, CancellationToken cancellationToken)
    {
        var capabilities = deletionCapabilities.ToArray();
        var required = modules.Select(module => module.UserData.Eraser).Where(name => name is not null).Cast<string>().ToArray();
        if (modules.Any(module => module.UserData.UserTables.Length > 0 && module.UserData.Eraser is null) ||
            capabilities.Length != 1 || required.Length == 0 || !dispatcher.HasHandlers(UserErasure.EventType, required))
        { return DeletionResult.Unavailable; }
        await using var session = new DatabaseSession();
        await session.BeginAsync(source, userId, cancellationToken);
        await RecoveryBarrier.LockAsync(session, exclusive: true, cancellationToken);
        Guid previous;
        try { previous = await recovery.VerifyAsync(session, cancellationToken); }
        catch (RecoveryUnavailableException) { return DeletionResult.Unavailable; }
        await UserLifecycleLock.AcquireAsync(session, userId, cancellationToken);
        if (!await identity.CheckActiveAsync(session, userId, sessionId, false, cancellationToken)) { return DeletionResult.Unauthorized; }
        await session.Transaction.SaveAsync("erasure", cancellationToken);
        var reserved = false;
        var commitAttempted = false;
        try
        {
            // External durable fence always precedes any erasure effect and the database commit.
            var nextGeneration = ids.NewId();
            recovery.File.Write(nextGeneration);
            reserved = true;
            await RecoveryBarrier.SetDatabaseAsync(session, nextGeneration, cancellationToken);
            if (!await capabilities[0].BeginAsync(session, sessionId, cancellationToken))
            { throw new InvalidOperationException("Inactive erasure principal."); }
            var payload = new UserErasure(userId);
            var eventId = await new QueueWriter(session, clock, ids).PublishAsync(UserErasure.EventType, payload, cancellationToken);
            await using (var intent = session.Command("INSERT INTO account.deletion_requests(user_id,event_id,requested_at) VALUES($1,$2,$3)"))
            {
                intent.Parameters.AddWithValue(userId); intent.Parameters.AddWithValue(eventId); intent.Parameters.AddWithValue(clock.GetUtcNow());
                await intent.ExecuteNonQueryAsync(cancellationToken);
            }
            await dispatcher.DispatchWithinTransactionAsync(eventId, session, cancellationToken);
            await OpsErasure.DeleteUserAsync(session, cancellationToken);
            commitAttempted = true;
            await session.CommitAsync(cancellationToken);
            return DeletionResult.Deleted;
        }
        catch
        {
            if (reserved && !commitAttempted)
            {
                // Rollback to a savepoint retains the exclusive recovery lock. Reconcile ONLY a known
                // pre-commit failure, never an ambiguous commit/connection loss (B06 D7).
                await session.Transaction.RollbackAsync("erasure", CancellationToken.None);
                await recovery.ReconcileKnownRollbackAsync(session, previous, CancellationToken.None);
            }
            throw;
        }
    }
}
