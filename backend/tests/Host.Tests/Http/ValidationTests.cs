using FitnessBuddy.Host.Tests.Infrastructure;

namespace FitnessBuddy.Host.Tests.Http;

// Rule 04 §4.2 "Errors": every 400 is /errors/validation-failed with an `errors` map (S03 plan D1, D2).
public sealed class ValidationTests(ApiFactory factory) : IClassFixture<ApiFactory>
{
    private const string ValidBody = """{"name":"oats","items":[{"qty":1}],"child":{"code":"ab"}}""";

    [Fact]
    [Trait("Rule", "04.4.2-errors")]
    public async Task Valid_body_passes_validation()
    {
        using var client = factory.CreateClient();
        using var response = await client.FetchAsync(Api.Request(HttpMethod.Post, "/v1/_probe/validate", ValidBody));

        Assert.Equal(System.Net.HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    [Trait("Rule", "04.4.2-errors")]
    public async Task Invalid_body_gets_400_validation_failed_with_camelCase_errors()
    {
        using var client = factory.CreateClient();
        const string body = """{"name":"","items":[{"qty":1},{"qty":0}],"child":{"code":"too-long-code"}}""";
        using var response = await client.FetchAsync(Api.Request(HttpMethod.Post, "/v1/_probe/validate", body));

        var problem = await Api.ProblemAsync(response, 400);
        Assert.Equal("/errors/validation-failed", problem.GetProperty("type").GetString());
        Assert.Equal("One or more validation errors occurred.", problem.GetProperty("title").GetString());
        Assert.Equal(["child.code", "items[1].qty", "name"], Api.ErrorKeys(problem));
        Assert.False(problem.TryGetProperty("requestId", out _));
    }

    [Theory]
    [InlineData("""{"name":""")]
    [InlineData("""not json""")]
    [InlineData("""{"name":"oats","items":[{"qty":"12"}],"child":{"code":"ab"}}""")]
    [InlineData("""{"items":[{"qty":1}],"child":{"code":"ab"}}""")]
    [InlineData("""{"name":null,"items":[{"qty":1}],"child":{"code":"ab"}}""")]
    [Trait("Rule", "04.4.2-errors")]
    public async Task Malformed_json_gets_400_validation_failed_with_empty_errors_and_fixed_detail(string body)
    {
        using var client = factory.CreateClient();
        using var response = await client.FetchAsync(Api.Request(HttpMethod.Post, "/v1/_probe/validate", body));

        var problem = await Api.ProblemAsync(response, 400);
        Assert.Equal("/errors/validation-failed", problem.GetProperty("type").GetString());
        Assert.Equal("The request could not be read.", problem.GetProperty("detail").GetString());
        Assert.Empty(Api.ErrorKeys(problem));
    }

    // Development throws BadHttpRequestException (ThrowOnBadRequest), so the exception handler writes this one.
    [Fact]
    [Trait("Rule", "04.4.2-errors")]
    public async Task Malformed_json_in_Development_gets_the_same_problem()
    {
        await using var development = ApiFactory.With(new Dictionary<string, string?>(), environment: "Development");
        using var client = development.CreateClient();
        using var response = await client.FetchAsync(Api.Request(HttpMethod.Post, "/v1/_probe/validate", """{"name":"CANARY-BODY"""));

        var problem = await Api.ProblemAsync(response, 400);
        Assert.Equal("/errors/validation-failed", problem.GetProperty("type").GetString());
        Assert.Equal("The request could not be read.", problem.GetProperty("detail").GetString());
        Assert.Empty(Api.ErrorKeys(problem));
        Assert.DoesNotContain("CANARY", problem.GetRawText(), StringComparison.Ordinal);
    }

    [Fact]
    [Trait("Rule", "04.4.2-errors")]
    public async Task Failed_parameter_binding_gets_400_validation_failed_with_empty_errors()
    {
        using var client = factory.CreateClient();
        using var response = await client.FetchAsync(Api.Get("/v1/_probe/count?n=CANARY-QUERY"));

        var problem = await Api.ProblemAsync(response, 400);
        Assert.Equal("/errors/validation-failed", problem.GetProperty("type").GetString());
        Assert.Empty(Api.ErrorKeys(problem));
        Assert.DoesNotContain("CANARY", problem.GetRawText(), StringComparison.Ordinal);
    }
}
