using FitnessBuddy.BuildingBlocks.Auth;
using Npgsql;

namespace FitnessBuddy.BuildingBlocks.Persistence;

/// <summary>Starts user-scoped work from the authenticated principal, never an HTTP body or header user ID.</summary>
public sealed class UserDatabase(NpgsqlDataSource source, ICurrentUser currentUser, DatabaseSession session)
{
    public async Task<DatabaseSession> BeginAsync(CancellationToken cancellationToken)
    {
        if (!currentUser.IsAuthenticated || currentUser.UserId is not { } userId)
        {
            throw new InvalidOperationException("Authenticated database work requires a user.");
        }
        if (!session.IsActive) { await session.BeginAsync(source, userId, cancellationToken); }
        return session;
    }
}
