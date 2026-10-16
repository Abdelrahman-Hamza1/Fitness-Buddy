using System.ComponentModel.DataAnnotations;

namespace FitnessBuddy.Host.Http;

/// <summary>The configuration section <c>RateLimiting:PerIp</c>: the fixed window of the <c>per-ip</c> policy (S03 plan D10).</summary>
internal sealed class PerIpRateLimitOptions
{
    public const string SectionName = "RateLimiting:PerIp";

    [Range(1, 100_000)]
    public int PermitLimit { get; set; } = 300;

    [Range(1, 3600)]
    public int WindowSeconds { get; set; } = 60;
}
