using FitnessBuddy.BuildingBlocks.Clients;
using Microsoft.Extensions.Options;

namespace FitnessBuddy.Modules.Account.Application;

/// <summary>The client configuration as the Application layer sees it.</summary>
internal sealed record ClientConfiguration(
    AppVersion MinimumAppVersion,
    IReadOnlyDictionary<string, bool> FeatureFlags,
    IReadOnlyDictionary<string, double> Thresholds);

/// <summary>Use case: read the client configuration. The minimum version is the one the 426 gate uses.</summary>
internal sealed class GetClientConfig(
    IOptionsMonitor<ClientCompatibilityOptions> compatibility,
    IOptionsMonitor<ClientConfigOptions> clientConfig)
{
    public ClientConfiguration Handle()
    {
        var config = clientConfig.CurrentValue;
        return new ClientConfiguration(
            compatibility.CurrentValue.GetMinimumAppVersion(),
            config.FeatureFlags.AsReadOnly(),
            config.Thresholds.AsReadOnly());
    }
}
