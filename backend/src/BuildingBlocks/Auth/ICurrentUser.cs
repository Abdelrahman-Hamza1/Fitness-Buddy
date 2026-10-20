namespace FitnessBuddy.BuildingBlocks.Auth;

/// <summary>
/// The authenticated user of the current request. Data access is scoped by <see cref="UserId"/>, never by an ID
/// from the request body (04 §6). B04 supplies the validated, live session through the Host.
/// </summary>
public interface ICurrentUser
{
    Guid? UserId { get; }

    Guid? SessionId { get; }

    bool IsAuthenticated { get; }
}
