namespace FitnessBuddy.BuildingBlocks.Auth;

/// <summary>The <see cref="ICurrentUser"/> until S24: nobody is signed in.</summary>
public sealed class AnonymousCurrentUser : ICurrentUser
{
    public Guid? UserId => null;

    public bool IsAuthenticated => false;
}
