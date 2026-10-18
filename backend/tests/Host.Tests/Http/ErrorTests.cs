using FitnessBuddy.Host.Tests.Infrastructure;

namespace FitnessBuddy.Host.Tests.Http;

// Rule 04 §4.2 "Errors": RFC 9457 problems with type and title always set, and no internals.
public sealed class ErrorTests(ApiFactory factory) : IClassFixture<ApiFactory>
{
    [Theory]
    [InlineData("/v1/config", 400)]
    [InlineData("/v1/does-not-exist", 404)]
    [InlineData("/v1/_probe/throw", 500)]
    [InlineData("/v1/me", 401)]
    [Trait("Rule", "04.4.2-errors")]
    public async Task Unsupported_accept_still_returns_contract_problem_json(string path, int status)
    {
        using var client = factory.CreateClient();
        using var request = path == "/v1/config" ? new HttpRequestMessage(HttpMethod.Get, path) : Api.Get(path);
        request.Headers.Accept.ParseAdd("text/html");
        using var response = await client.FetchAsync(request);
        await Api.ProblemAsync(response, status);
    }

    [Fact]
    [Trait("Rule", "04.4.2-errors")]
    public async Task Unhandled_exception_gets_500_with_traceId_and_X_Request_Id_and_no_internals()
    {
        using var client = factory.CreateClient();
        using var response = await client.FetchAsync(Api.Get("/v1/_probe/throw"));

        var problem = await Api.ProblemAsync(response, 500);
        Assert.Equal("https://tools.ietf.org/html/rfc9110#section-15.6.1", problem.GetProperty("type").GetString());
        Assert.Equal("An error occurred while processing your request.", problem.GetProperty("title").GetString());
        Assert.Equal(["status", "title", "traceId", "type"], Api.MemberNames(problem));
        Assert.Equal(Api.RequestId(response), problem.GetProperty("traceId").GetString());

        var raw = problem.GetRawText();
        Assert.DoesNotContain("CANARY", raw, StringComparison.Ordinal);
        Assert.DoesNotContain(nameof(InvalidOperationException), raw, StringComparison.Ordinal);
        Assert.DoesNotContain("ProbeModule", raw, StringComparison.Ordinal);
        Assert.DoesNotContain(" at ", raw, StringComparison.Ordinal);
    }

    [Fact]
    [Trait("Rule", "04.4.2-errors")]
    public async Task Unknown_route_gets_404_problem_with_type_and_title()
    {
        using var client = factory.CreateClient();
        using var response = await client.FetchAsync(Api.Get("/v1/does-not-exist"));

        var problem = await Api.ProblemAsync(response, 404);
        Assert.Equal("https://tools.ietf.org/html/rfc9110#section-15.5.5", problem.GetProperty("type").GetString());
        Assert.Equal("Not Found", problem.GetProperty("title").GetString());
    }

    [Fact]
    [Trait("Rule", "04.4.2-errors")]
    public async Task Error_result_from_a_handler_maps_to_version_conflict_412()
    {
        using var client = factory.CreateClient();
        using var response = await client.FetchAsync(Api.Get("/v1/_probe/conflict"));

        var problem = await Api.ProblemAsync(response, 412);
        Assert.Equal("/errors/version-conflict", problem.GetProperty("type").GetString());
        Assert.Equal("Version conflict", problem.GetProperty("title").GetString());
        Assert.DoesNotContain("probe.version_conflict", problem.GetRawText(), StringComparison.Ordinal);
    }
}
