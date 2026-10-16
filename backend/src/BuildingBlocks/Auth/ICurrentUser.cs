namespace FitnessBuddy.BuildingBlocks.Auth;

/// <summary>
/// The authenticated user of the current request. Data access is scoped by <see cref="UserId"/>, never by an ID
/// from the request body (04 §6). Every request is anonymous until authentication arrives (S24).
/// </summary>
public interface ICurrentUser
{
    Guid? UserId { get; }

    bool IsAuthenticated { get; }
}
