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

    /// <summary>Exact-email lookups per IP and minute (AD-002, B23 P2).</summary>
    [Range(1, 10000)]
    public int LookupPermitPerMinute { get; set; } = 10;

    /// <summary>The API's base URL inside the stack (e.g. <c>http://api:8080</c>); the Overview probes its <c>/health/ready</c>. Empty: not shown.</summary>
    public string ApiReadyUrl { get; set; } = "";

    /// <summary>The controller's backup status file (<c>{completedAt, ok}</c>), mounted read-only. Empty: not shown.</summary>
    public string BackupStatusFile { get; set; } = "";

    /// <summary>Optional dashboard links on the Overview (AD-010); hidden when empty. Only http(s) URLs are accepted.</summary>
    public string GrafanaUrl { get; set; } = "";

    public string SentryUrl { get; set; } = "";

    public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
    {
        if (!string.IsNullOrEmpty(AllowListFile) && !Path.IsPathFullyQualified(AllowListFile))
        {
            yield return new ValidationResult("Must be an absolute path.", [nameof(AllowListFile)]);
        }
        if (!string.IsNullOrEmpty(BackupStatusFile) && !Path.IsPathFullyQualified(BackupStatusFile))
        {
            yield return new ValidationResult("Must be an absolute path.", [nameof(BackupStatusFile)]);
        }
        foreach (var (name, value) in new[] { (nameof(ApiReadyUrl), ApiReadyUrl), (nameof(GrafanaUrl), GrafanaUrl), (nameof(SentryUrl), SentryUrl) })
        {
            if (value.Length > 0 && !(Uri.TryCreate(value, UriKind.Absolute, out var uri) && (uri.Scheme == Uri.UriSchemeHttp || uri.Scheme == Uri.UriSchemeHttps)))
            {
                yield return new ValidationResult("Must be an absolute http(s) URL.", [name]);
            }
        }
    }
}
