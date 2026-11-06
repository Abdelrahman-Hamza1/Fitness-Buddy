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
    public Task<DeletionResult> DeleteAsync(Guid userId, Guid sessionId, CancellationToken cancellationToken) =>
        RunAsync(userId, sessionId, cancellationToken);

    public Task<DeletionResult> DeleteForOperatorAsync(Guid userId, CancellationToken cancellationToken) =>
        RunAsync(userId, null, cancellationToken);

    /// <summary>
    /// One coordinator for both principals (B24): the app's live session, or (<paramref name="sessionId"/> null) the operator's
    /// intent. Only the principal check differs; locks, fence, in-transaction erasure and reconciliation are B06's.
    /// </summary>
    private async Task<DeletionResult> RunAsync(Guid userId, Guid? sessionId, CancellationToken cancellationToken)
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
        // The app keeps its 503; the operator runner gets the exception, so it records 'recovery-unavailable' (review minor 2).
        catch (RecoveryUnavailableException) when (sessionId is not null) { return DeletionResult.Unavailable; }
        await UserLifecycleLock.AcquireAsync(session, userId, cancellationToken);
        if (sessionId is Guid live && !await identity.CheckActiveAsync(session, userId, live, false, cancellationToken)) { return DeletionResult.Unauthorized; }
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
            var begun = sessionId is Guid principal
                ? await capabilities[0].BeginAsync(session, principal, cancellationToken)
                : await capabilities[0].BeginOperatorAsync(session, cancellationToken);
            if (!begun)
            {
                if (sessionId is null) { throw new OperatorIntentMissingException(); }
                throw new InvalidOperationException("Inactive erasure principal.");
            }
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
        catch (Exception exception)
        {
            if (reserved && !commitAttempted)
            {
                // Rollback to a savepoint retains the exclusive recovery lock. Reconcile ONLY a known
                // pre-commit failure, never an ambiguous commit/connection loss (B06 D7).
                await session.Transaction.RollbackAsync("erasure", CancellationToken.None);
                await recovery.ReconcileKnownRollbackAsync(session, previous, CancellationToken.None);
                // The operator's intent is missing or not due yet: nothing changed, the generation is back.
                if (exception is OperatorIntentMissingException) { return DeletionResult.Unauthorized; }
            }
            throw;
        }
    }

    private sealed class OperatorIntentMissingException : Exception;
}
