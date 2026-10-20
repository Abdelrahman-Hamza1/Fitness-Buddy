namespace FitnessBuddy.BuildingBlocks.Auth;

/// <summary>An explicit unauthenticated principal for host-independent callers.</summary>
public sealed class AnonymousCurrentUser : ICurrentUser
{
    public Guid? UserId => null;

    public Guid? SessionId => null;

    public bool IsAuthenticated => false;
}
