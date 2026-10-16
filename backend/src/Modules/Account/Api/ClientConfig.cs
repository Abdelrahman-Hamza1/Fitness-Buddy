using System.ComponentModel.DataAnnotations;
using FitnessBuddy.BuildingBlocks.Clients;
using FitnessBuddy.Modules.Account.Application;

namespace FitnessBuddy.Modules.Account.Api;

/// <summary>Server-controlled settings for the app (contract schema <c>ClientConfig</c>).</summary>
/// <param name="MinimumAppVersion">The oldest app version (<c>MAJOR.MINOR.PATCH</c>) the server still serves.</param>
/// <param name="FeatureFlags">Feature flags by name. A missing flag means off.</param>
/// <param name="Thresholds">Numeric client thresholds by name. A missing threshold means the app's built-in default.</param>
internal sealed record ClientConfig(
    // Documents the contract's `pattern` in the generated OpenAPI document.
    [property: RegularExpression(AppVersion.Pattern)] string MinimumAppVersion,
    IReadOnlyDictionary<string, bool> FeatureFlags,
    IReadOnlyDictionary<string, double> Thresholds)
{
    public static ClientConfig From(ClientConfiguration configuration) =>
        new(configuration.MinimumAppVersion.ToString(), configuration.FeatureFlags, configuration.Thresholds);
}
