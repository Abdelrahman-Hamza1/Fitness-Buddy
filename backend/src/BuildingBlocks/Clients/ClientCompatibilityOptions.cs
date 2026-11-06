using System.ComponentModel.DataAnnotations;

namespace FitnessBuddy.BuildingBlocks.Clients;

/// <summary>
/// The configuration section <c>Clients</c>. <see cref="MinimumAppVersion"/> drives both the 426 gate and
/// <c>/v1/config</c>'s <c>minimumAppVersion</c>, so the two can't disagree.
/// </summary>
public sealed class ClientCompatibilityOptions : IValidatableObject
{
    public const string SectionName = "Clients";

    [Required]
    public string MinimumAppVersion { get; set; } = string.Empty;

    /// <summary>
    /// B23 recovery switch (<c>Clients__MinimumAppVersionOverride</c>): when set, it wins over the published remote config, the
    /// database and the defaults, in the 426 gate and in <c>/v1/config</c>. Read from configuration only, so it works with the DB down.
    /// </summary>
    public string? MinimumAppVersionOverride { get; set; }

    /// <summary>The parsed override, or null when none is set. Valid once the options passed validation at startup.</summary>
    public AppVersion? GetOverride() =>
        string.IsNullOrWhiteSpace(MinimumAppVersionOverride) ? null
        : AppVersion.TryParse(MinimumAppVersionOverride, out var version) ? version
        : throw new InvalidOperationException($"{SectionName}:{nameof(MinimumAppVersionOverride)} is not a MAJOR.MINOR.PATCH version.");

    /// <summary>
    /// The parsed <see cref="MinimumAppVersion"/>. Valid once the options passed validation at startup. A method, not
    /// a property: options validation reads every property, and this one throws on an invalid value.
    /// </summary>
    public AppVersion GetMinimumAppVersion() =>
        AppVersion.TryParse(MinimumAppVersion, out var version)
            ? version
            : throw new InvalidOperationException($"{SectionName}:{nameof(MinimumAppVersion)} is not a MAJOR.MINOR.PATCH version.");

    public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
    {
        if (!AppVersion.TryParse(MinimumAppVersion, out _))
        {
            yield return new ValidationResult("Must be MAJOR.MINOR.PATCH without leading zeros.", [nameof(MinimumAppVersion)]);
        }

        if (!string.IsNullOrWhiteSpace(MinimumAppVersionOverride) && !AppVersion.TryParse(MinimumAppVersionOverride, out _))
        {
            yield return new ValidationResult("Must be MAJOR.MINOR.PATCH without leading zeros.", [nameof(MinimumAppVersionOverride)]);
        }
    }
}
