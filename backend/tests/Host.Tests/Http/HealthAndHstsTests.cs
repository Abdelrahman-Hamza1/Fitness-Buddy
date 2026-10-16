using System.Net;
using FitnessBuddy.Host.Tests.Infrastructure;
using Microsoft.AspNetCore.Mvc.Testing;

namespace FitnessBuddy.Host.Tests.Http;

// Rules 08 §4 "Deploys" (kamal-proxy probes /health/ready) and 09 §4 "Transport" (HSTS).
public sealed class HealthAndHstsTests
{
    [Theory]
    [InlineData("/health/live")]
    [InlineData("/health/ready")]
    [Trait("Rule", "08.4-deploys")]
    public async Task Health_live_and_ready_return_200_without_client_headers_and_are_not_rate_limited(string path)
    {
        await using var factory = ApiFactory.With(new Dictionary<string, string?> { ["RateLimiting:PerIp:PermitLimit"] = "1" });
        using var client = factory.CreateClient();
        for (var i = 0; i < 3; i++)
        {
            using var response = await client.GetAsync(new Uri(path, UriKind.Relative), Api.Ct);
            Assert.Equal(HttpStatusCode.OK, response.StatusCode);
            Assert.Equal("Healthy", await response.Content.ReadAsStringAsync(Api.Ct));
        }
    }

    [Fact]
    [Trait("Rule", "09.4-transport")]
    public async Task Hsts_header_is_sent_outside_Development_over_https()
    {
        await using var factory = ApiFactory.With(new Dictionary<string, string?>());
        using var client = factory.CreateClient(new WebApplicationFactoryClientOptions { BaseAddress = new Uri("https://api.fitness-buddy.test") });
        using var response = await client.GetAsync(new Uri("/health/live", UriKind.Relative), Api.Ct);

        Assert.Equal("max-age=31536000", Assert.Single(response.Headers.GetValues("Strict-Transport-Security")));
    }

    [Fact]
    [Trait("Rule", "09.4-transport")]
    public async Task Hsts_header_is_not_sent_in_Development()
    {
        await using var factory = ApiFactory.With(new Dictionary<string, string?>(), environment: "Development");
        using var client = factory.CreateClient(new WebApplicationFactoryClientOptions { BaseAddress = new Uri("https://api.fitness-buddy.test") });
        using var response = await client.GetAsync(new Uri("/health/live", UriKind.Relative), Api.Ct);

        Assert.False(response.Headers.Contains("Strict-Transport-Security"));
    }
}
