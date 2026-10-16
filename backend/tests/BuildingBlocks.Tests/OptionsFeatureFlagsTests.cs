using FitnessBuddy.BuildingBlocks.Features;
using Microsoft.Extensions.Options;

namespace FitnessBuddy.BuildingBlocks.Tests;

public sealed class OptionsFeatureFlagsTests
{
    [Fact]
    public void OptionsFeatureFlags_missing_flag_is_off()
    {
        var options = new FeatureFlagsOptions();
        options.Flags["buddyPhotos"] = true;
        options.Flags["darkLaunch"] = false;
        var flags = new OptionsFeatureFlags(new StaticOptionsMonitor<FeatureFlagsOptions>(options));

        Assert.True(flags.IsEnabled("buddyPhotos"));
        Assert.True(flags.IsEnabled("BUDDYPHOTOS"));
        Assert.False(flags.IsEnabled("darkLaunch"));
        Assert.False(flags.IsEnabled("neverConfigured"));
    }

    private sealed class StaticOptionsMonitor<T>(T value) : IOptionsMonitor<T>
    {
        public T CurrentValue => value;

        public T Get(string? name) => value;

        public IDisposable? OnChange(Action<T, string?> listener) => null;
    }
}
