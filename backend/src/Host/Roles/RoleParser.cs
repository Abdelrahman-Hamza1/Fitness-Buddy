namespace FitnessBuddy.Host.Roles;

/// <summary>The process roles of the one image (04 §3.4, TD-022).</summary>
internal enum HostRole
{
    Api,
    Worker,
    Migrate,
}

internal static class RoleParser
{
    public const int UsageExitCode = 2;

    public const string Usage = "Usage: FitnessBuddy.Host [api|worker|migrate] [host options]. Default: api.";

    /// <summary>
    /// The role is <c>args[0]</c> when it doesn't start with <c>-</c>; otherwise it is <c>api</c>, so
    /// <c>WebApplicationFactory</c> and the build-time document tool (which pass only options) start the API.
    /// The role token is removed from the arguments handed to the host builder.
    /// </summary>
    public static bool TryParse(string[] args, out HostRole role, out string[] hostArgs)
    {
        ArgumentNullException.ThrowIfNull(args);
        role = HostRole.Api;
        hostArgs = args;
        if (args.Length == 0 || args[0].StartsWith('-'))
        {
            return true;
        }

        hostArgs = args[1..];
        switch (args[0])
        {
            case "api":
                return true;
            case "worker":
                role = HostRole.Worker;
                return true;
            case "migrate":
                role = HostRole.Migrate;
                return true;
            default:
                return false;
        }
    }
}
