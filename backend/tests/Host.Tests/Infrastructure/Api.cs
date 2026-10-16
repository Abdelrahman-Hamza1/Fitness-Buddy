using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;

namespace FitnessBuddy.Host.Tests.Infrastructure;

/// <summary>Requests with valid client headers, and helpers to read problem responses.</summary>
internal static partial class Api
{
    public const string DeviceId = "0192a5d4-7c3e-7b1a-9f2e-3c4d5e6f7a8b";

    public static CancellationToken Ct => TestContext.Current.CancellationToken;

    public static HttpRequestMessage Request(HttpMethod method, string path, string? json = null, string appVersion = "0.1.0", string? peer = null)
    {
        var request = new HttpRequestMessage(method, path);
        request.Headers.Add("X-App-Version", appVersion);
        request.Headers.Add("X-Platform", "android");
        request.Headers.Add("X-Device-Id", DeviceId);
        if (peer is not null)
        {
            request.Headers.Add(TestPeerStartupFilter.HeaderName, peer);
        }

        if (json is not null)
        {
            request.Content = new StringContent(json, Encoding.UTF8, "application/json");
        }

        return request;
    }

    public static HttpRequestMessage Get(string path, string appVersion = "0.1.0", string? peer = null) =>
        Request(HttpMethod.Get, path, appVersion: appVersion, peer: peer);

    public static async Task<HttpResponseMessage> FetchAsync(this HttpClient client, HttpRequestMessage request)
    {
        using (request)
        {
            return await client.SendAsync(request, Ct);
        }
    }

    /// <summary>Asserts the response is <c>application/problem+json</c> with <paramref name="status"/>, and returns the body.</summary>
    public static async Task<JsonElement> ProblemAsync(HttpResponseMessage response, int status)
    {
        var text = await response.Content.ReadAsStringAsync(Ct);
        Assert.True((int)response.StatusCode == status, $"Expected {status}, got {(int)response.StatusCode}: {text}");
        Assert.Equal(new MediaTypeHeaderValue("application/problem+json").MediaType, response.Content.Headers.ContentType?.MediaType);
        using var json = JsonDocument.Parse(text);
        var root = json.RootElement.Clone();
        Assert.Equal(status, root.GetProperty("status").GetInt32());
        Assert.Matches(TraceIdRegex(), root.GetProperty("traceId").GetString());
        return root;
    }

    public static string RequestId(HttpResponseMessage response) =>
        Assert.Single(response.Headers.GetValues("X-Request-Id"));

    public static IReadOnlyList<string> ErrorKeys(JsonElement problem) =>
        [.. problem.GetProperty("errors").EnumerateObject().Select(p => p.Name).Order(StringComparer.Ordinal)];

    public static IReadOnlyList<string> MemberNames(JsonElement problem) =>
        [.. problem.EnumerateObject().Select(p => p.Name).Order(StringComparer.Ordinal)];

    [GeneratedRegex("^[0-9a-f]{32}$")]
    public static partial Regex TraceIdRegex();
}
