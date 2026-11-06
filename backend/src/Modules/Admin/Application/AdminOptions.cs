using System.ComponentModel.DataAnnotations;

namespace FitnessBuddy.Modules.Admin.Application;

/// <summary>The configuration section <c>Admin</c> (B23 P1, P2, P5). Nothing here is a secret; the allow-list file is a private mount.</summary>
internal sealed class AdminOptions : IValidatableObject
{
    public const string SectionName = "Admin";

    /// <summary>The console listener. Loopback by default; the container binds 0.0.0.0 and compose publishes it to loopback only.</summary>
    [Required]
    public string Url { get; set; } = "http://127.0.0.1:8081";

    /// <summary>The Google OAuth <b>Web</b> client ID the console signs in with (not the app's client IDs).</summary>
    [Required]
    public string GoogleClientId { get; set; } = "";

    /// <summary>Absolute path of the private allow-list JSON file (B23 P2).</summary>
    [Required]
    public string AllowListFile { get; set; } = "";

    /// <summary>Absolute session lifetime (B23 P2: 12 h, no sliding).</summary>
    [Range(1, 24)]
    public int SessionHours { get; set; } = 12;

    /// <summary>Sign-in and re-auth attempts per IP and minute.</summary>
    [Range(1, 10000)]
    public int SignInPermitPerMinute { get; set; } = 10;

    /// <summary>
    /// Sign-in and re-auth attempts per minute across all clients (B23 security review): a bound that holds even when a client
    /// varies its address (a trusted forwarding hop passes <c>X-Forwarded-For</c> on).
    /// </summary>
    [Range(1, 100000)]
    public int SignInPermitPerMinuteTotal { get; set; } = 30;

    public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
    {
        if (!string.IsNullOrEmpty(AllowListFile) && !Path.IsPathFullyQualified(AllowListFile))
        {
            yield return new ValidationResult("Must be an absolute path.", [nameof(AllowListFile)]);
        }
    }
}
