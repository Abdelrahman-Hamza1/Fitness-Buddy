using FitnessBuddy.Host.Tests.Infrastructure;
using Microsoft.Extensions.Options;

namespace FitnessBuddy.Host.Tests.Http;

// Rule 09 §4 "API hardening": invalid configuration stops the API at startup, not at the first request.
public sealed class StartupValidationTests
{
    [Theory]
    [InlineData("Proxy:TrustedNetworks:0", "10.0.0.0/33")]
    [InlineData("RateLimiting:PerIp:PermitLimit", "0")]
    [InlineData("RateLimiting:PerIp:WindowSeconds", "3601")]
    [Trait("Rule", "09.4-api-hardening")]
    public async Task Invalid_trusted_network_or_rate_limit_fails_startup(string key, string value)
    {
        await using var factory = ApiFactory.With(new Dictionary<string, string?> { [key] = value });

        var exception = Assert.ThrowsAny<Exception>(() => factory.CreateClient());

        Assert.Contains(Chain(exception), e => e is OptionsValidationException);
    }

    [Fact]
    [Trait("Rule", "09.4-api-hardening")]
    public void Invalid_trusted_network_fails_startup() =>
        Assert.Contains(Chain(Start("Proxy:TrustedNetworks:0", "nope")), e => e is OptionsValidationException);

    [Fact]
    [Trait("Rule", "09.4-api-hardening")]
    public void Invalid_minimum_app_version_fails_startup() =>
        Assert.Contains(Chain(Start("Clients:MinimumAppVersion", "01.0.0")), e => e is OptionsValidationException);

    private static Exception Start(string key, string value)
    {
        using var factory = ApiFactory.With(new Dictionary<string, string?> { [key] = value });
        return Assert.ThrowsAny<Exception>(() => factory.CreateClient());
    }

    private static IEnumerable<Exception> Chain(Exception exception)
    {
        for (Exception? current = exception; current is not null; current = current.InnerException)
        {
            yield return current;
            if (current is AggregateException aggregate)
            {
                foreach (var inner in aggregate.InnerExceptions.SelectMany(Chain))
                {
                    yield return inner;
                }
            }
        }
    }
}
