using FitnessBuddy.Host.Tests.Infrastructure;

namespace FitnessBuddy.Host.Tests.Http;

// Rule 09 §4 "API hardening": the client address behind kamal-proxy is trusted only from known networks (S03 plan D11).
public sealed class ForwardedHeadersTests
{
    [Theory]
    [InlineData("10.1.2.3", "203.0.113.7 https")]
    [InlineData("127.0.0.1", "203.0.113.7 https")]
    [InlineData("198.51.100.9", "198.51.100.9 http")]
    [Trait("Rule", "09.4-api-hardening")]
    public async Task Forwarded_for_is_honoured_from_a_trusted_network_and_ignored_otherwise(string peer, string expected)
    {
        await using var factory = ApiFactory.With(new Dictionary<string, string?> { ["Proxy:TrustedNetworks:0"] = "10.1.0.0/16" });
        using var client = factory.CreateClient();
        using var request = Api.Get("/v1/_probe/peer", peer: peer);
        request.Headers.Add("X-Forwarded-For", "198.18.0.1, 203.0.113.7");
        request.Headers.Add("X-Forwarded-Proto", "https");
        using var response = await client.SendAsync(request, Api.Ct);

        Assert.Equal($$"""{"value":"{{expected}}"}""", await response.Content.ReadAsStringAsync(Api.Ct));
    }
}
