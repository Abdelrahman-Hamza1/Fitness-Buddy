namespace FitnessBuddy.Modules.Account.Application;

/// <summary>The configuration section <c>Account:ClientConfig</c>: what <c>/v1/config</c> returns besides the minimum version.</summary>
internal sealed class ClientConfigOptions
{
    public const string SectionName = "Account:ClientConfig";

    public Dictionary<string, bool> FeatureFlags { get; } = new(StringComparer.Ordinal);

    public Dictionary<string, double> Thresholds { get; } = new(StringComparer.Ordinal);
}
