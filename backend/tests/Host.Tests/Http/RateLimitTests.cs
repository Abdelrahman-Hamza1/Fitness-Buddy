using System.Net;
using FitnessBuddy.Host.Http;
using FitnessBuddy.Host.Tests.Infrastructure;

namespace FitnessBuddy.Host.Tests.Http;

// Rule 04 §4.2 "Rate limits": 429 + Retry-After + RateLimit-Policy / RateLimit, per IP (S03 plan D10).
public sealed class RateLimitTests
{
    private static ApiFactory LimitedFactory(int permitLimit) => ApiFactory.With(new Dictionary<string, string?>
    {
        ["RateLimiting:PerIp:PermitLimit"] = $"{permitLimit}",
        ["RateLimiting:PerIp:WindowSeconds"] = "60",
    });

    [Fact]
    [Trait("Rule", "04.4.2-errors")]
    public async Task Rate_limited_request_gets_429_problem_with_Retry_After_and_RateLimit_headers()
    {
        await using var factory = LimitedFactory(2);
        using var client = factory.CreateClient();
        for (var i = 0; i < 2; i++)
        {
            using var ok = await client.FetchAsync(Api.Get("/v1/_probe/ok", peer: "192.0.2.10"));
            Assert.Equal(HttpStatusCode.OK, ok.StatusCode);
            Assert.False(ok.Headers.Contains("RateLimit"));
            Assert.False(ok.Headers.Contains("RateLimit-Policy"));
            Assert.False(ok.Headers.Contains("Retry-After"));
        }

        using var response = await client.FetchAsync(Api.Get("/v1/_probe/ok", peer: "192.0.2.10"));

        var problem = await Api.ProblemAsync(response, 429);
        Assert.Equal("/errors/rate-limited", problem.GetProperty("type").GetString());
        Assert.Equal("Too many requests", problem.GetProperty("title").GetString());
        Assert.Equal(["status", "title", "traceId", "type"], Api.MemberNames(problem));
        Assert.Equal(Api.RequestId(response), problem.GetProperty("traceId").GetString());

        var retryAfter = int.Parse(Assert.Single(response.Headers.GetValues("Retry-After")), System.Globalization.CultureInfo.InvariantCulture);
        Assert.InRange(retryAfter, 1, 60);
        Assert.Equal("\"per-ip\";q=2;w=60", Assert.Single(response.Headers.GetValues("RateLimit-Policy")));
        Assert.Equal($"\"per-ip\";r=0;t={retryAfter}", Assert.Single(response.Headers.GetValues("RateLimit")));
    }

    [Fact]
    [Trait("Rule", "04.4.2-rate-limits")]
    public async Task Rate_limit_partitions_by_client_ip_and_ipv6_slash_64()
    {
        await using var factory = LimitedFactory(1);
        using var client = factory.CreateClient();

        async Task<int> Status(string peer)
        {
            using var response = await client.FetchAsync(Api.Get("/v1/_probe/ok", peer: peer));
            return (int)response.StatusCode;
        }

        Assert.Equal(200, await Status("192.0.2.1"));
        Assert.Equal(429, await Status("192.0.2.1"));
        Assert.Equal(200, await Status("192.0.2.2"));
        Assert.Equal(429, await Status("::ffff:192.0.2.2"));

        Assert.Equal(200, await Status("2001:db8:1:2::1"));
        Assert.Equal(429, await Status("2001:db8:1:2:ffff:ffff:ffff:ffff"));
        Assert.Equal(200, await Status("2001:db8:1:3::1"));
    }

    [Theory]
    [InlineData(null, "unknown")]
    [InlineData("203.0.113.7", "203.0.113.7")]
    [InlineData("::ffff:203.0.113.7", "203.0.113.7")]
    [InlineData("2001:db8:aa:bb:1:2:3:4", "2001:db8:aa:bb::/64")]
    [Trait("Rule", "04.4.2-rate-limits")]
    public void Partition_key_is_the_ipv4_address_or_the_ipv6_slash_64(string? address, string expected)
    {
        Assert.Equal(expected, RateLimiting.PartitionKey(address is null ? null : IPAddress.Parse(address)));
    }
}
