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

    // contracts/openapi.yaml: headers XRequestId and ProblemDetails.traceId
    private const string TraceIdPattern = "^[0-9a-f]{32}$";

    private static readonly Regex TraceId = new(TraceIdPattern, RegexOptions.None, TimeSpan.FromSeconds(1));

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
        Assert.Matches(TraceId, Assert.Single(response.Headers.GetValues("X-Request-Id")));

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

    [Fact]
    public async Task GetConfig_without_client_headers_returns_400_validation_problem()
    {
        using var client = factory.CreateClient();

        using var response = await client.GetAsync(new Uri("/v1/config", UriKind.Relative), TestContext.Current.CancellationToken);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        Assert.Equal("application/problem+json", response.Content.Headers.ContentType?.MediaType);
        var requestId = Assert.Single(response.Headers.GetValues("X-Request-Id"));
        await using var body = await response.Content.ReadAsStreamAsync(TestContext.Current.CancellationToken);
        using var json = await JsonDocument.ParseAsync(body, cancellationToken: TestContext.Current.CancellationToken);
        var root = json.RootElement;

        // ValidationProblemDetails: required type, title, status, errors; optional detail, instance, traceId.
        Assert.Equal("/errors/validation-failed", root.GetProperty("type").GetString());
        Assert.Equal(JsonValueKind.String, root.GetProperty("title").ValueKind);
        Assert.Equal(400, root.GetProperty("status").GetInt32());
        Assert.Equal(requestId, root.GetProperty("traceId").GetString());
        Assert.Matches(TraceId, requestId);
        Assert.Empty(root.EnumerateObject().Select(p => p.Name).Except(["type", "title", "status", "detail", "instance", "traceId", "errors"]));
        Assert.Equal(
            ["x-app-version", "x-device-id", "x-platform"],
            root.GetProperty("errors").EnumerateObject().Select(p => p.Name).Order(StringComparer.Ordinal));
        Assert.All(
            root.GetProperty("errors").EnumerateObject(),
            error => Assert.All(error.Value.EnumerateArray(), message => Assert.Equal(JsonValueKind.String, message.ValueKind)));
    }
}
