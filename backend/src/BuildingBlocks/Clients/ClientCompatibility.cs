using Microsoft.Extensions.Options;

namespace FitnessBuddy.BuildingBlocks.Clients;

/// <summary>
/// The minimum app version the server serves (the 426 kill switch). One port for the gate and <c>/v1/config</c>, so they can't
/// disagree (B23 P1). The Account module replaces the configuration-only default with the published remote config.
/// </summary>
public interface IClientCompatibility
{
    AppVersion MinimumAppVersion { get; }

    /// <summary>True while <c>Clients:MinimumAppVersionOverride</c> is set (recovery).</summary>
    bool OverrideActive { get; }
}

/// <summary>The configuration-only implementation: the override when set, else <c>Clients:MinimumAppVersion</c>.</summary>
public sealed class OptionsClientCompatibility(IOptionsMonitor<ClientCompatibilityOptions> options) : IClientCompatibility
{
    public AppVersion MinimumAppVersion => options.CurrentValue.GetOverride() ?? options.CurrentValue.GetMinimumAppVersion();

    public bool OverrideActive => options.CurrentValue.GetOverride() is not null;
}
