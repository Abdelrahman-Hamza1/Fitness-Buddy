namespace FitnessBuddy.Modules.Account.Application;

internal enum DeletionResult { Deleted, Unauthorized, Unavailable }

internal interface IAccountDeletion
{
    Task<DeletionResult> DeleteAsync(Guid userId, Guid sessionId, CancellationToken cancellationToken);

    /// <summary>
    /// B24: the same deletion for an operator. The principal is the operator's committed, due deletion intent, checked by
    /// Identity's database capability; <see cref="DeletionResult.Unauthorized"/> when there's none (nothing changed). Unlike the
    /// app's call, a recovery state that doesn't verify throws <c>RecoveryUnavailableException</c> (nothing changed), so the
    /// runner can record the repair it needs.
    /// </summary>
    Task<DeletionResult> DeleteForOperatorAsync(Guid userId, CancellationToken cancellationToken);
}

/// <summary>The API supplies only the validated principal, never an account identifier from input.</summary>
internal sealed class DeleteAccount(IAccountDeletion store)
{
    public Task<DeletionResult> ExecuteAsync(Guid userId, Guid sessionId, CancellationToken cancellationToken) =>
        store.DeleteAsync(userId, sessionId, cancellationToken);
}
