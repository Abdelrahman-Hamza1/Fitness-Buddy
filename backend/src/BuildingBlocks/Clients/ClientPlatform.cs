using System.Diagnostics.CodeAnalysis;

namespace FitnessBuddy.BuildingBlocks.Clients;

/// <summary>The app's platform, from the <c>X-Platform</c> header.</summary>
public enum ClientPlatform
{
    Android,
    Ios,
}

/// <summary>The wire names of <see cref="ClientPlatform"/> (contract parameter <c>Platform</c>: exactly these, case-sensitive).</summary>
public static class ClientPlatforms
{
    public const string Android = "android";
    public const string Ios = "ios";

    public static IReadOnlyList<string> WireNames { get; } = [Android, Ios];

    public static bool TryParse([NotNullWhen(true)] string? text, out ClientPlatform platform)
    {
        switch (text)
        {
            case Android:
                platform = ClientPlatform.Android;
                return true;
            case Ios:
                platform = ClientPlatform.Ios;
                return true;
            default:
                platform = default;
                return false;
        }
    }
}
