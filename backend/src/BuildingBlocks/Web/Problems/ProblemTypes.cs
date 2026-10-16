namespace FitnessBuddy.BuildingBlocks.Web.Problems;

/// <summary>
/// The error type catalogue (contracts/README.md, golden bodies in contracts/testdata/problems/). Clients compare
/// <c>type</c> exactly: never rename or remove one within an API version.
/// </summary>
public static class ProblemTypes
{
    public const string ValidationFailed = "/errors/validation-failed";
    public const string RateLimited = "/errors/rate-limited";
    public const string VersionConflict = "/errors/version-conflict";
    public const string UpgradeRequired = "/errors/upgrade-required";

    public static IReadOnlyList<string> All { get; } = [ValidationFailed, RateLimited, VersionConflict, UpgradeRequired];
}

/// <summary>The <c>title</c> that goes with each catalogue type (the golden bodies hold the same strings).</summary>
public static class ProblemTitles
{
    public const string ValidationFailed = "One or more validation errors occurred.";
    public const string RateLimited = "Too many requests";
    public const string VersionConflict = "Version conflict";
    public const string UpgradeRequired = "Upgrade required";
}
