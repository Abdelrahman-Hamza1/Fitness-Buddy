using System.Net;
using FitnessBuddy.Host.Tests.Infrastructure;
using Microsoft.Extensions.DependencyInjection;

namespace FitnessBuddy.Host.Tests.Http;

// Behaviour only a real Kestrel server shows (TestServer enforces no body limit and has no drain).
// Rules 04 §4.2 "Size limits" and 08 §4 "Deploys" (in-flight requests drain on SIGTERM).
public sealed class KestrelTests
{
    [Fact]
    [Trait("Rule", "04.4.2-size-limits")]
    public async Task Body_over_256KB_gets_413_problem()
    {
        await using var factory = ApiFactory.With(new Dictionary<string, string?>());
        factory.UseKestrel(0);
        using var client = factory.CreateClient();
        var name = new string('a', 257 * 1024);
        using var response = await client.FetchAsync(Api.Request(HttpMethod.Post, "/v1/_probe/validate", Body(name)));

        var problem = await Api.ProblemAsync(response, 413);
        Assert.Equal(Api.RequestId(response), problem.GetProperty("traceId").GetString());
        Assert.False(response.Headers.Contains("Server"));
    }

    [Fact]
    [Trait("Rule", "04.4.2-size-limits")]
    public async Task Body_under_256KB_is_accepted()
    {
        await using var factory = ApiFactory.With(new Dictionary<string, string?>());
        factory.UseKestrel(0);
        using var client = factory.CreateClient();
        var name = new string('a', 200 * 1024);
        using var response = await client.FetchAsync(Api.Request(HttpMethod.Post, "/v1/_probe/validate", Body(name)));

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    private static string Body(string name) => "{\"name\":\"" + name + "\",\"items\":[],\"child\":{\"code\":\"a\"}}";

    [Fact]
    [Trait("Rule", "08.4-deploys")]
    public async Task In_flight_request_completes_during_graceful_shutdown()
    {
        var factory = ApiFactory.With(new Dictionary<string, string?>());
        factory.UseKestrel(0);
        // Not factory.CreateClient(): disposing the factory also disposes the clients it created.
        using var factoryClient = factory.CreateClient();
        using var client = new HttpClient { BaseAddress = factoryClient.BaseAddress };
        var signals = factory.Services.GetRequiredService<ProbeSignals>();

        var pending = client.FetchAsync(Api.Get("/v1/_probe/slow"));
        await signals.SlowRequestStarted.Task.WaitAsync(TimeSpan.FromSeconds(10), Api.Ct);
        var stopping = factory.DisposeAsync().AsTask();

        using var response = await pending;
        await stopping;
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }
}
