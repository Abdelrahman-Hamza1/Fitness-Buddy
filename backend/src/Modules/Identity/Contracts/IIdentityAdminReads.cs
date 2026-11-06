namespace FitnessBuddy.Modules.Identity.Contracts;

/// <summary>
/// Content-free Identity counts for the admin console (B23, owner O1, TD-118). Implemented with <c>identity.admin_*</c> functions
/// that only the console login can run: counts, versions and platforms; never emails, subjects or device IDs.
/// </summary>
public interface IIdentityAdminReads
{
    /// <summary>Active accounts' devices seen since <paramref name="since"/>, by app version and platform.</summary>
    Task<IReadOnlyList<InstallCount>> InstallsAsync(DateTimeOffset since, CancellationToken cancellationToken);
}

/// <summary><paramref name="AppVersion"/> is the reported <c>MAJOR.MINOR.PATCH</c>; <paramref name="Platform"/> is <c>android</c> or <c>ios</c>.</summary>
public sealed record InstallCount(string AppVersion, string Platform, long Installs);
