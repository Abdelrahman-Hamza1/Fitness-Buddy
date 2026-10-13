using System.Net;
using System.Text.Json;
using System.Text.RegularExpressions;
using Microsoft.AspNetCore.Mvc.Testing;

namespace FitnessBuddy.Contract.Tests;

/// <summary><c>GET /v1/config</c> returns what contracts/openapi.yaml promises (<c>getConfig</c>).</summary>
public sealed class ConfigEndpointTests(WebApplicationFactory<Program> factory)
    : IClassFixture<WebApplicationFactory<Program>>
{
    // contracts/openapi.yaml: ClientConfig.minimumAppVersion.pattern
    private const string SemVerPattern = @"^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$";

    [Fact]
    public async Task GetConfig_returns_200_json_with_contract_shape()
    {
        using var client = factory.CreateClient();
        using var request = new HttpRequestMessage(HttpMethod.Get, "/v1/config");
        request.Headers.Add("X-App-Version", "0.1.0");
        request.Headers.Add("X-Platform", "android");
        request.Headers.Add("X-Device-Id", "0192a5d4-7c3e-7b1a-9f2e-3c4d5e6f7a8b");

        using var response = await client.SendAsync(request, TestContext.Current.CancellationToken);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Equal("application/json", response.Content.Headers.ContentType?.MediaType);

        await using var body = await response.Content.ReadAsStreamAsync(TestContext.Current.CancellationToken);
        using var json = await JsonDocument.ParseAsync(body, cancellationToken: TestContext.Current.CancellationToken);
        var root = json.RootElement;
        Assert.Equal(JsonValueKind.Object, root.ValueKind);
        Assert.Equal(
            ["featureFlags", "minimumAppVersion", "thresholds"],
            root.EnumerateObject().Select(p => p.Name).Order(StringComparer.Ordinal));

        var minimumAppVersion = root.GetProperty("minimumAppVersion");
        Assert.Equal(JsonValueKind.String, minimumAppVersion.ValueKind);
        Assert.Matches(new Regex(SemVerPattern, RegexOptions.None, TimeSpan.FromSeconds(1)), minimumAppVersion.GetString()!);
        Assert.Equal(JsonValueKind.Object, root.GetProperty("featureFlags").ValueKind);
        Assert.Equal(JsonValueKind.Object, root.GetProperty("thresholds").ValueKind);
    }
}
