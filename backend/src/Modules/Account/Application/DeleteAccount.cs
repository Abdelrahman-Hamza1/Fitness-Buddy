namespace FitnessBuddy.Modules.Account.Application;

internal enum DeletionResult { Deleted, Unauthorized, Unavailable }

internal interface IAccountDeletion
{
    Task<DeletionResult> DeleteAsync(Guid userId, Guid sessionId, CancellationToken cancellationToken);
}

/// <summary>The API supplies only the validated principal, never an account identifier from input.</summary>
internal sealed class DeleteAccount(IAccountDeletion store)
{
    public Task<DeletionResult> ExecuteAsync(Guid userId, Guid sessionId, CancellationToken cancellationToken) =>
        store.DeleteAsync(userId, sessionId, cancellationToken);
}
