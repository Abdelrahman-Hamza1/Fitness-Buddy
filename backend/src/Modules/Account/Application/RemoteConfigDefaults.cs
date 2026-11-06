using FitnessBuddy.BuildingBlocks.Clients;
using FitnessBuddy.BuildingBlocks.Features;
using FitnessBuddy.Modules.Account.Contracts;
using Microsoft.Extensions.Options;

namespace FitnessBuddy.Modules.Account.Application;

/// <summary>
/// The one canonical effective configuration (B23 P1, R#2): <c>Clients:MinimumAppVersion</c>, <c>Account:ClientConfig:*</c> and
/// <c>FeatureFlags:*</c>, plus the AI switch on unless configured. Every role reads the same keys (one compose anchor), so the
/// migrate role seeds version 1 with exactly what the API served before. The override is not part of it.
/// </summary>
internal sealed class RemoteConfigDefaults(IOptionsMonitor<ClientCompatibilityOptions> compatibility, IOptionsMonitor<ClientConfigOptions> client,
    IOptionsMonitor<FeatureFlagsOptions> flags)
{
    public RemoteConfigDocument Current
    {
        get
        {
            var server = new Dictionary<string, bool>(flags.CurrentValue.Flags, StringComparer.OrdinalIgnoreCase);
            server.TryAdd(RemoteConfigRules.AiSwitch, true);
            return new RemoteConfigDocument(compatibility.CurrentValue.MinimumAppVersion,
                new Dictionary<string, bool>(client.CurrentValue.FeatureFlags, StringComparer.Ordinal),
                new Dictionary<string, double>(client.CurrentValue.Thresholds, StringComparer.Ordinal), server);
        }
    }
}

/// <summary>The remote config in effect in this process (the newest published version, or the defaults).</summary>
internal interface IRuntimeConfig
{
    RemoteConfigDocument Current { get; }
}
