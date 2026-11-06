using FitnessBuddy.BuildingBlocks.Clients;

namespace FitnessBuddy.Modules.Account.Application;

/// <summary>The client configuration as the Application layer sees it.</summary>
internal sealed record ClientConfiguration(
    AppVersion MinimumAppVersion,
    IReadOnlyDictionary<string, bool> FeatureFlags,
    IReadOnlyDictionary<string, double> Thresholds);

/// <summary>
/// Use case: read the client configuration. The minimum version is the one the 426 gate uses (same port), and the flags and
/// thresholds come from the published remote config (B23), so <c>/v1/config</c> keeps its response shape.
/// </summary>
internal sealed class GetClientConfig(IClientCompatibility compatibility, IRuntimeConfig config)
{
    public ClientConfiguration Handle()
    {
        var current = config.Current;
        return new ClientConfiguration(compatibility.MinimumAppVersion, current.FeatureFlags, current.Thresholds);
    }
}
