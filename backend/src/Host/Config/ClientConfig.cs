using System.Collections.ObjectModel;
using System.ComponentModel.DataAnnotations;

namespace FitnessBuddy.Host.Config;

/// <summary>Server-controlled settings for the app (contract schema <c>ClientConfig</c>).</summary>
/// <param name="MinimumAppVersion">The oldest app version (<c>MAJOR.MINOR.PATCH</c>) the server still serves.</param>
/// <param name="FeatureFlags">Feature flags by name. A missing flag means off.</param>
/// <param name="Thresholds">Numeric client thresholds by name. A missing threshold means the app's built-in default.</param>
internal sealed record ClientConfig(
    [property: RegularExpression(ClientConfig.SemVerPattern)] string MinimumAppVersion,
    IReadOnlyDictionary<string, bool> FeatureFlags,
    IReadOnlyDictionary<string, double> Thresholds)
{
    /// <summary>
    /// <c>MAJOR.MINOR.PATCH</c> without leading zeros. The attribute only documents it: the generated
    /// OpenAPI document carries it as <c>pattern</c>, which must equal the contract's.
    /// </summary>
    internal const string SemVerPattern = @"^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$";

    /// <summary>
    /// Hard-coded until the Account module owns configuration (S02 D11, A6). No invented flags or
    /// thresholds: empty maps are honest.
    /// </summary>
    public static ClientConfig Defaults { get; } = new(
        MinimumAppVersion: "0.1.0",
        FeatureFlags: ReadOnlyDictionary<string, bool>.Empty,
        Thresholds: ReadOnlyDictionary<string, double>.Empty);
}
