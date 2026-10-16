using System.Net;
using System.Text.Json;
using FitnessBuddy.Host.Tests.Infrastructure;

namespace FitnessBuddy.Host.Tests.Http;

// Rules 04 §4.2 "Versioning" (the 426 gate) and "Client headers", as problems per 04 §4.2 "Errors" (S03 plan D9).
public sealed class ClientHeadersTests(ApiFactory factory) : IClassFixture<ApiFactory>
{
    [Fact]
    [Trait("Rule", "04.4.2-errors")]
    public async Task Old_app_version_gets_426_upgrade_required_problem()
    {
        using var client = factory.CreateClient();
        using var response = await client.FetchAsync(Api.Get("/v1/_probe/ok", appVersion: "0.0.9"));

        var problem = await Api.ProblemAsync(response, 426);
        Assert.Equal("/errors/upgrade-required", problem.GetProperty("type").GetString());
        Assert.Equal("Upgrade required", problem.GetProperty("title").GetString());
        Assert.Equal("This app version is no longer supported. Update the app.", problem.GetProperty("detail").GetString());
        Assert.False(response.Headers.Contains("Upgrade"));
    }

    [Fact]
    [Trait("Rule", "04.4.2-versioning")]
    public async Task Config_is_exempt_from_the_version_gate_and_returns_the_configured_minimum()
    {
        await using var custom = ApiFactory.With(new Dictionary<string, string?> { ["Clients:MinimumAppVersion"] = "2.3.4" });
        using var client = custom.CreateClient();
        using var response = await client.FetchAsync(Api.Get("/v1/config", appVersion: "0.0.1"));

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        using var json = JsonDocument.Parse(await response.Content.ReadAsStringAsync(Api.Ct));
        Assert.Equal("2.3.4", json.RootElement.GetProperty("minimumAppVersion").GetString());
    }

    [Fact]
    [Trait("Rule", "04.4.2-versioning")]
    public async Task Kill_switch_wins_over_a_malformed_platform_header()
    {
        using var client = factory.CreateClient();
        using var request = Api.Get("/v1/_probe/ok", appVersion: "0.0.9");
        request.Headers.Remove("X-Platform");
        request.Headers.Add("X-Platform", "web");
        request.Headers.Remove("X-Device-Id");
        using var response = await client.SendAsync(request, Api.Ct);

        var problem = await Api.ProblemAsync(response, 426);
        Assert.Equal("/errors/upgrade-required", problem.GetProperty("type").GetString());
    }

    public static TheoryData<string, string?, string> InvalidHeaders => new()
    {
        { "X-App-Version", null, "x-app-version" },
        { "X-App-Version", "1.2", "x-app-version" },
        { "X-App-Version", "01.2.3", "x-app-version" },
        { "X-App-Version", "1.2.3-beta", "x-app-version" },
        { "X-Platform", null, "x-platform" },
        { "X-Platform", "Android", "x-platform" },
        { "X-Platform", "web", "x-platform" },
        { "X-Device-Id", null, "x-device-id" },
        { "X-Device-Id", "not-a-uuid", "x-device-id" },
        { "X-Device-Id", "0192a5d47c3e7b1a9f2e3c4d5e6f7a8b", "x-device-id" },
    };

    [Theory]
    [MemberData(nameof(InvalidHeaders))]
    [Trait("Rule", "04.4.2-errors")]
    public async Task Missing_or_invalid_client_headers_get_400_with_header_keys(string header, string? value, string key)
    {
        using var client = factory.CreateClient();
        using var request = Api.Get("/v1/_probe/ok");
        request.Headers.Remove(header);
        if (value is not null)
        {
            request.Headers.TryAddWithoutValidation(header, value);
        }

        using var response = await client.SendAsync(request, Api.Ct);

        var problem = await Api.ProblemAsync(response, 400);
        Assert.Equal("/errors/validation-failed", problem.GetProperty("type").GetString());
        Assert.Equal([key], Api.ErrorKeys(problem));
        if (value is not null)
        {
            Assert.DoesNotContain(value, problem.GetRawText(), StringComparison.Ordinal);
        }
    }

    [Fact]
    [Trait("Rule", "04.4.2-errors")]
    public async Task All_missing_client_headers_are_reported_together()
    {
        using var client = factory.CreateClient();
        using var response = await client.GetAsync(new Uri("/v1/_probe/ok", UriKind.Relative), Api.Ct);

        var problem = await Api.ProblemAsync(response, 400);
        Assert.Equal(["x-app-version", "x-device-id", "x-platform"], Api.ErrorKeys(problem));
    }

    [Fact]
    [Trait("Rule", "04.4.2-versioning")]
    public async Task Current_app_version_passes_the_gate()
    {
        using var client = factory.CreateClient();
        using var response = await client.FetchAsync(Api.Get("/v1/_probe/ok", appVersion: "0.1.0"));

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }
}
