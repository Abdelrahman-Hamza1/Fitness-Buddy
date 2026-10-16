using Microsoft.Extensions.Options;

namespace FitnessBuddy.BuildingBlocks.Features;

/// <summary>The configuration section <c>FeatureFlags</c>: flag name → on/off.</summary>
public sealed class FeatureFlagsOptions
{
    public const string SectionName = "FeatureFlags";

    /// <summary>Configuration keys are case-insensitive, so flag names are too.</summary>
    public IDictionary<string, bool> Flags { get; } = new Dictionary<string, bool>(StringComparer.OrdinalIgnoreCase);
}

/// <summary><see cref="IFeatureFlags"/> read from <see cref="FeatureFlagsOptions"/> (reloads with the configuration).</summary>
public sealed class OptionsFeatureFlags(IOptionsMonitor<FeatureFlagsOptions> options) : IFeatureFlags
{
    public bool IsEnabled(string name) => options.CurrentValue.Flags.TryGetValue(name, out var enabled) && enabled;
}
