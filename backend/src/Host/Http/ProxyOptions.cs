using System.ComponentModel.DataAnnotations;
using System.Net;

namespace FitnessBuddy.Host.Http;

/// <summary>
/// The configuration section <c>Proxy</c>: the networks whose <c>X-Forwarded-*</c> headers are trusted, in CIDR
/// notation (S03 plan D11). Loopback is always trusted. Production values arrive with the deploy (S05).
/// </summary>
internal sealed class ProxyOptions : IValidatableObject
{
    public const string SectionName = "Proxy";

    public List<string> TrustedNetworks { get; } = [];

    public IEnumerable<IPNetwork> GetTrustedNetworks() =>
        TrustedNetworks.Select(cidr => IPNetwork.TryParse(cidr, out var network)
            ? network
            : throw new InvalidOperationException($"{SectionName}:{nameof(TrustedNetworks)} has an invalid CIDR."));

    public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
    {
        for (var i = 0; i < TrustedNetworks.Count; i++)
        {
            if (!IPNetwork.TryParse(TrustedNetworks[i], out _))
            {
                yield return new ValidationResult($"Entry {i} is not a CIDR network (e.g. 172.16.0.0/12).", [nameof(TrustedNetworks)]);
            }
        }
    }
}
