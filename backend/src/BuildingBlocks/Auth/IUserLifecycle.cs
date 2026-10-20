using FitnessBuddy.BuildingBlocks.Persistence;

namespace FitnessBuddy.BuildingBlocks.Auth;

/// <summary>Recheck trusted request/session or durable worker ownership after the common user lock.</summary>
public interface IUserLifecycle
{
    Task<bool> IsActiveAsync(DatabaseSession session, Guid? sessionId, CancellationToken cancellationToken);
}
