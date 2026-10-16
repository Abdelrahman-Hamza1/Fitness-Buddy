using System.Diagnostics;
using System.Net;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;
using FitnessBuddy.Modules.Buddy.Application;
using FitnessBuddy.Modules.Buddy.Infrastructure;
using Microsoft.Extensions.Logging;

namespace FitnessBuddy.Buddy.Tests;

// Real SDK -> IChatClient -> ILlmClient; transport fixtures are synthetic, never paid in tests.
public sealed class OpenAIContractTests
{
    private const string Canary = "private-message-canary";
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    [Theory]
    [InlineData("en-eggs", "English", "Latin")]
    [InlineData("ar-eggs", "Arabic", "Arabic")]
    [InlineData("az-eggs", "Arabic", "Arabizi")]
    [Trait("Req", "AI-010")]
    [Trait("Req", "AI-016")]
    [Trait("Req", "AC-041")]
    public async Task Adapter_native_request_and_three_script_responses_obey_port(string id, string language, string script)
    {
        using var transport = new WireHandler(await FixtureAsync(id));
        using var http = new HttpClient(transport);
        using var chat = OpenAIClientFactory.Create("key-canary-not-real", http);
        var logger = new CaptureLogger();
        var spans = new List<Activity>();
        using var listener = new ActivityListener
        {
            ShouldListenTo = source => source.Name == "FitnessBuddy.Buddy",
            Sample = (ref ActivityCreationOptions<ActivityContext> _) => ActivitySamplingResult.AllData,
            ActivityStopped = activity => spans.Add(activity),
        };
        ActivitySource.AddActivityListener(listener);
        var adapter = new OpenAILlmClient(chat, TimeProvider.System, logger, TimeSpan.FromSeconds(2));
        var outcome = await adapter.InterpretAsync(Canary, Ct);
        Assert.Equal(LlmStatus.Success, outcome.Status);
        Assert.Equal(language, outcome.Interpretation!.Language.ToString());
        Assert.Equal(script, outcome.Interpretation.Script.ToString());
        Assert.Equal(2, outcome.Interpretation.Intents[0].Items[0].Amount);
        Assert.Equal(new TokenUsage(100, 32, 60), outcome.Usage);
        Assert.Equal(0.00003712m, outcome.EstimatedUsd);
        Assert.Equal("gpt-6-luna", outcome.Model);
        Assert.Equal("interpret-v0", outcome.PromptVersion);
        Assert.Equal(1, transport.Calls);
        Assert.Equal("https://api.openai.com/v1/responses", transport.Uri);
        var request = JsonNode.Parse(transport.Request!)!;
        Assert.False(request["store"]!.GetValue<bool>());
        Assert.Equal("low", request["reasoning"]!["effort"]!.GetValue<string>());
        Assert.Equal(1200, request["max_output_tokens"]!.GetValue<int>());
        Assert.Equal("json_schema", request["text"]!["format"]!["type"]!.GetValue<string>());
        Assert.True(request["text"]!["format"]!["strict"]!.GetValue<bool>());
        Assert.Equal(InterpretProtocol.Schema.GetRawText(), JsonSerializer.Serialize(request["text"]!["format"]!["schema"]));
        Assert.DoesNotContain("key-canary", transport.Request!, StringComparison.Ordinal);
        foreach (var field in new[] { "user", "metadata", "previous_response_id", "conversation", "tools" })
            Assert.True(request[field] is null, field);
        Assert.Contains(Canary, transport.Request!, StringComparison.Ordinal);
        Assert.DoesNotContain(Canary, string.Join('|', logger.Messages), StringComparison.Ordinal);
        Assert.DoesNotContain(Canary, string.Join('|', spans.SelectMany(span => span.Tags)), StringComparison.Ordinal);
        Assert.Contains(logger.Messages, line => line.Contains("Success", StringComparison.Ordinal));
    }

    [Theory]
    [InlineData(429, "RateLimited")]
    [InlineData(500, "Unavailable")]
    [InlineData(401, "Unavailable")]
    [Trait("Req", "AI-153")]
    [Trait("Rule", "09.4-logging")]
    public async Task Provider_failure_is_content_free_and_never_retried(int status, string expected)
    {
        using var transport = new WireHandler("{\"error\":{\"message\":\"" + Canary + "\",\"type\":\"server_error\"}}", (HttpStatusCode)status);
        using var http = new HttpClient(transport);
        using var chat = OpenAIClientFactory.Create("offline-key", http);
        var logger = new CaptureLogger();
        var result = await new OpenAILlmClient(chat, TimeProvider.System, logger, TimeSpan.FromSeconds(2)).InterpretAsync(Canary, Ct);
        Assert.Equal(expected, result.Status.ToString());
        Assert.Equal(status, result.ProviderHttpStatus);
        Assert.Null(result.Interpretation);
        Assert.Equal(1, transport.Calls);
        Assert.DoesNotContain(Canary, JsonSerializer.Serialize(result), StringComparison.Ordinal);
        Assert.DoesNotContain(Canary, string.Join('|', logger.Messages), StringComparison.Ordinal);
    }

    [Theory]
    [InlineData("malformed", "InvalidOutput")]
    [InlineData("unknown", "InvalidOutput")]
    [InlineData("refusal", "Refused")]
    [InlineData("incomplete", "Incomplete")]
    [Trait("Req", "AI-070")]
    [Trait("Req", "AI-153")]
    public async Task Non_success_model_output_never_escapes_as_interpretation(string variant, string expected)
    {
        var response = JsonNode.Parse(await FixtureAsync("en-eggs"))!;
        if (variant == "incomplete")
        {
            response["status"] = "incomplete";
            response["incomplete_details"] = new JsonObject { ["reason"] = "max_output_tokens" };
        }
        else if (variant == "refusal")
            response["output"]![1]!["content"] = new JsonArray(new JsonObject { ["type"] = "refusal", ["refusal"] = Canary });
        else response["output"]![1]!["content"]![0]!["text"] = variant == "malformed" ? "{" : "{\"calories\":200}";
        using var transport = new WireHandler(response.ToJsonString());
        using var http = new HttpClient(transport);
        using var chat = OpenAIClientFactory.Create("offline-key", http);
        var result = await new OpenAILlmClient(chat, TimeProvider.System, new CaptureLogger(), TimeSpan.FromSeconds(2)).InterpretAsync(Canary, Ct);
        Assert.Equal(expected, result.Status.ToString());
        Assert.Null(result.Interpretation);
        Assert.Equal(1, transport.Calls);
        Assert.NotNull(result.Usage);
    }

    [Theory]
    [InlineData(false, "Timeout")]
    [InlineData(true, "Cancelled")]
    [Trait("Req", "AI-153")]
    public async Task Deadline_and_caller_cancellation_are_bounded_and_not_retried(bool cancel, string expected)
    {
        using var transport = new WireHandler("{}") { Wait = true };
        using var http = new HttpClient(transport);
        using var chat = OpenAIClientFactory.Create("offline-key", http);
        using var cancellation = CancellationTokenSource.CreateLinkedTokenSource(Ct);
        if (cancel) cancellation.Cancel();
        var result = await new OpenAILlmClient(chat, TimeProvider.System, new CaptureLogger(), TimeSpan.FromMilliseconds(20))
            .InterpretAsync(Canary, cancellation.Token);
        Assert.Equal(expected, result.Status.ToString());
        Assert.Null(result.Interpretation);
        Assert.InRange(transport.Calls, 0, 1);
    }

    [Fact]
    [Trait("Rule", "06.9-prompt-schema-versioning")]
    public async Task Generated_closed_schema_matches_committed_snapshot()
    {
        Assert.Equal(JsonNode.Parse(await File.ReadAllTextAsync(Path.Combine(AppContext.BaseDirectory, "schema.json"), Ct))!.ToJsonString(),
            JsonNode.Parse(InterpretProtocol.Schema.GetRawText())!.ToJsonString());
        Assert.Contains("interpret-v0", InterpretProtocol.Prompt, StringComparison.Ordinal);
        CheckObjects(JsonNode.Parse(InterpretProtocol.Schema.GetRawText())!);
    }

    private static void CheckObjects(JsonNode node)
    {
        if (node is JsonObject obj)
        {
            if (obj["properties"] is JsonObject props)
            {
                Assert.False(obj["additionalProperties"]!.GetValue<bool>());
                Assert.Equal(props.Select(pair => pair.Key), obj["required"]!.AsArray().Select(value => value!.GetValue<string>()));
            }
            foreach (var pair in obj) if (pair.Value is not null) CheckObjects(pair.Value);
        }
        if (node is JsonArray array) foreach (var item in array) if (item is not null) CheckObjects(item);
    }

    internal static Task<string> FixtureAsync(string id) => File.ReadAllTextAsync(Path.Combine(AppContext.BaseDirectory, "fixtures", id + ".json"), Ct);

    private sealed class WireHandler(string body, HttpStatusCode status = HttpStatusCode.OK) : HttpMessageHandler
    {
        public int Calls { get; private set; }
        public string? Uri { get; private set; }
        public string? Request { get; private set; }
        public bool Wait { get; init; }
        protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            Calls++;
            Uri = request.RequestUri!.AbsoluteUri;
            Request = await request.Content!.ReadAsStringAsync(cancellationToken);
            if (Wait) await Task.Delay(Timeout.InfiniteTimeSpan, cancellationToken);
            return new HttpResponseMessage(status) { Content = new StringContent(body, Encoding.UTF8, "application/json") };
        }
    }

    private sealed class CaptureLogger : ILogger<OpenAILlmClient>
    {
        public List<string> Messages { get; } = [];
        public IDisposable? BeginScope<TState>(TState state) where TState : notnull => null;
        public bool IsEnabled(LogLevel logLevel) => true;
        public void Log<TState>(LogLevel logLevel, EventId eventId, TState state, Exception? exception, Func<TState, Exception?, string> formatter)
            => Messages.Add(formatter(state, exception));
    }
}
