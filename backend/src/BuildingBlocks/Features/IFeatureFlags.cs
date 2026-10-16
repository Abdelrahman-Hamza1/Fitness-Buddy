namespace FitnessBuddy.BuildingBlocks.Features;

/// <summary>Server-side feature flags. A flag that isn't configured is off.</summary>
public interface IFeatureFlags
{
    bool IsEnabled(string name);
}
