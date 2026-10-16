using FitnessBuddy.BuildingBlocks.Clients;

namespace FitnessBuddy.BuildingBlocks.Tests;

public sealed class AppVersionTests
{
    [Theory]
    [InlineData("0.1.0", 0, 1, 0)]
    [InlineData("1.0.0", 1, 0, 0)]
    [InlineData("10.20.30", 10, 20, 30)]
    [InlineData("2147483647.0.0", int.MaxValue, 0, 0)]
    public void AppVersion_parses_strict_semver(string text, int major, int minor, int patch)
    {
        Assert.True(AppVersion.TryParse(text, out var version));
        Assert.Equal(new AppVersion(major, minor, patch), version);
        Assert.Equal(text, version.ToString());
    }

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("1.0")]
    [InlineData("1")]
    [InlineData("1.0.0.0")]
    [InlineData("01.0.0")]
    [InlineData("1.00.0")]
    [InlineData("1.0.01")]
    [InlineData("1.0.0-beta")]
    [InlineData("1.0.0+build.1")]
    [InlineData("v1.0.0")]
    [InlineData(" 1.0.0")]
    [InlineData("1.0.0 ")]
    [InlineData("+1.0.0")]
    [InlineData("-1.0.0")]
    [InlineData("1..0")]
    [InlineData("1.0.")]
    [InlineData("١.٠.٠")]
    [InlineData("2147483648.0.0")]
    public void AppVersion_parses_strict_semver_and_rejects_leading_zeros_prerelease_and_two_parts(string? text)
    {
        Assert.False(AppVersion.TryParse(text, out _));
    }

    [Theory]
    [InlineData("0.10.0", "0.9.9")]
    [InlineData("1.0.0", "0.99.99")]
    [InlineData("0.1.10", "0.1.9")]
    [InlineData("2.0.0", "1.10.10")]
    public void AppVersion_compares_numerically(string higher, string lower)
    {
        Assert.True(AppVersion.TryParse(higher, out var high));
        Assert.True(AppVersion.TryParse(lower, out var low));

        Assert.True(high > low);
        Assert.True(low < high);
        Assert.True(high >= low);
        Assert.True(low <= high);
        Assert.True(high.CompareTo(low) > 0);
        Assert.Equal(0, high.CompareTo(high));
    }
}
