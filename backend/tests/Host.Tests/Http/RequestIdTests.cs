using FitnessBuddy.Host.Tests.Infrastructure;

namespace FitnessBuddy.Host.Tests.Http;

// Rule 04 §4.2 "Tracing": X-Request-Id on every response = the W3C trace id = the problem's traceId (S03 plan D8 + A2).
public sealed class RequestIdTests(ApiFactory factory) : IClassFixture<ApiFactory>
{
    [Fact]
    [Trait("Rule", "04.4.2-tracing")]
    public async Task X_Request_Id_is_generated_and_equals_the_problem_traceId()
    {
        using var client = factory.CreateClient();
        using var first = await client.FetchAsync(Api.Get("/v1/_probe/throw"));
        using var second = await client.FetchAsync(Api.Get("/v1/_probe/throw"));

        var problem = await Api.ProblemAsync(first, 500);
        Assert.Matches(Api.TraceIdRegex(), Api.RequestId(first));
        Assert.Equal(Api.RequestId(first), problem.GetProperty("traceId").GetString());
        Assert.NotEqual(Api.RequestId(first), Api.RequestId(second));
    }

    [Fact]
    [Trait("Rule", "04.4.2-tracing")]
    public async Task X_Request_Id_is_the_trace_id_of_an_inbound_traceparent()
    {
        const string traceId = "4bf92f3577b34da6a3ce929d0e0e4736";
        using var client = factory.CreateClient();
        using var request = Api.Get("/v1/_probe/conflict");
        request.Headers.Add("traceparent", $"00-{traceId}-00f067aa0ba902b7-01");
        using var response = await client.SendAsync(request, Api.Ct);

        var problem = await Api.ProblemAsync(response, 412);
        Assert.Equal(traceId, Api.RequestId(response));
        Assert.Equal(traceId, problem.GetProperty("traceId").GetString());
    }

    [Theory]
    [InlineData("client-chosen-id")]
    [InlineData("4bf92f3577b34da6a3ce929d0e0e4736")]
    [InlineData("<script>")]
    [Trait("Rule", "04.4.2-tracing")]
    public async Task Inbound_X_Request_Id_is_ignored(string inbound)
    {
        using var client = factory.CreateClient();
        using var request = Api.Get("/v1/_probe/ok");
        request.Headers.TryAddWithoutValidation("X-Request-Id", inbound);
        using var response = await client.SendAsync(request, Api.Ct);

        var id = Api.RequestId(response);
        Assert.Matches(Api.TraceIdRegex(), id);
        Assert.NotEqual(inbound, id);
    }

    public static TheoryData<string, bool, int> Responses => new()
    {
        { "/v1/_probe/ok", true, 200 },
        { "/v1/_probe/ok", false, 400 },
        { "/v1/does-not-exist", true, 404 },
        { "/v1/_probe/throw", true, 500 },
        { "/health/live", false, 200 },
    };

    // 413 is covered in KestrelTests, 426 below, 429 in RateLimitTests.
    [Theory]
    [MemberData(nameof(Responses))]
    [Trait("Rule", "04.4.2-tracing")]
    public async Task X_Request_Id_is_present_on_200_400_404_413_426_429_500(string path, bool withHeaders, int status)
    {
        using var client = factory.CreateClient();
        using var request = withHeaders ? Api.Get(path) : new HttpRequestMessage(HttpMethod.Get, path);
        using var response = await client.SendAsync(request, Api.Ct);

        Assert.Equal(status, (int)response.StatusCode);
        Assert.Matches(Api.TraceIdRegex(), Api.RequestId(response));
    }

    [Fact]
    [Trait("Rule", "04.4.2-tracing")]
    public async Task X_Request_Id_is_present_on_426()
    {
        using var client = factory.CreateClient();
        using var response = await client.FetchAsync(Api.Get("/v1/_probe/ok", appVersion: "0.0.1"));

        var problem = await Api.ProblemAsync(response, 426);
        Assert.Equal(Api.RequestId(response), problem.GetProperty("traceId").GetString());
    }
}
