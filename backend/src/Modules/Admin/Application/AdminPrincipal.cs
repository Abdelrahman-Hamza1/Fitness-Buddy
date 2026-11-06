using FitnessBuddy.Modules.Admin.Domain;

namespace FitnessBuddy.Modules.Admin.Application;

/// <summary>The signed-in admin for one request. <see cref="GoogleSubject"/> is for re-auth matching only: never shown or logged.</summary>
internal sealed record AdminPrincipal(Guid SessionId, string Handle, string GoogleSubject, ConsoleRole Role, DateTimeOffset AuthenticatedAt)
{
    /// <summary>AD-007: a destructive or lock-out-capable action needs a sign-in less than 15 minutes old.</summary>
    public static readonly TimeSpan RecentSignIn = TimeSpan.FromMinutes(15);

    public bool SignedInRecently(DateTimeOffset now) => now - AuthenticatedAt < RecentSignIn;
}
