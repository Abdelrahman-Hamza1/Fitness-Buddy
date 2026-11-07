using System.Net;
using System.Text;
using System.Text.Json.Nodes;
using FitnessBuddy.Modules.Buddy.Application;
using FitnessBuddy.Modules.Buddy.Domain;
using FitnessBuddy.Modules.Buddy.Infrastructure;
using Microsoft.Extensions.Options;

namespace FitnessBuddy.Persistence.Tests;

// B27 (TD-129): provider selection and the Claude request shape on the wire, with a fake transport (no network, no key).
// Sonnet 5.5 rejects sampling parameters, forced tool choice and thinking "disabled"; a refusal must take the failure path.
[Trait("Rule", "B27-provider")]
public sealed class BuddyProviderTests
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;
    private static readonly string Key = string.Concat("offline", new string('k', 24));
    private const string Tail = "\nEXERCISES: synthetic list";

    [Fact]
    public void Options_validate_provider_effort_and_the_active_key_file_only()
    {
        Assert.True(new BuddyOptions { Enabled = true, ApiKeyFile = "/k/openai" }.Valid());
        Assert.True(new BuddyOptions { Enabled = true, Provider = "anthropic", AnthropicApiKeyFile = "/k/claude" }.Valid());
        Assert.False(new BuddyOptions { Enabled = true, Provider = "anthropic", ApiKeyFile = "/k/openai" }.Valid());
        Assert.False(new BuddyOptions { Enabled = true, Provider = "anthropic", AnthropicApiKeyFile = "relative" }.Valid());
        Assert.False(new BuddyOptions { Provider = "claude" }.Valid());
        Assert.False(new BuddyOptions { AnthropicEffort = "max" }.Valid());
        // Codex B27 #3: per-attempt fallback usage and pricing aren't recorded yet, so the option can't be turned on.
        Assert.False(new BuddyOptions { Provider = "anthropic", AnthropicServerFallback = true }.Valid());
        Assert.True(new BuddyOptions().Valid());
        Assert.IsType<OpenAIProvider>(BuddyProvider.From(new BuddyOptions()));
        Assert.IsType<AnthropicProvider>(BuddyProvider.From(new BuddyOptions { Provider = "anthropic" }));
    }

    [Fact]
    public async Task Claude_step_sends_between_tools_effort_auto_tools_and_two_cache_breakpoints_and_maps_tool_calls()
    {
        var wire = new Wire(Reply("""[{"type":"tool_use","id":"toolu_1","name":"search_foods","input":{"query":"egg"}}]""", "tool_use"));
        var result = await Model(wire).SendAsync(Request(AgentTools.Specs), Ct);

        Assert.Equal(AgentModelStatus.Success, result.Status);
        Assert.Equal("search_foods", Assert.Single(result.Calls).Name);
        Assert.Equal(new TokenUsage(1300, 1000, 50), result.Usage);
        Assert.Equal((100 * 2m + 200 * 2.5m + 1000 * .10m + 50 * 10m) / 1_000_000m, result.EstimatedUsd);
        var body = wire.Body!;
        Assert.Equal("claude-sonnet-5-5", (string?)body["model"]);
        foreach (var banned in new[] { "temperature", "top_p", "top_k", "fallbacks" }) { Assert.False(body.ContainsKey(banned), banned); }
        Assert.Equal("""{"type":"between_tools"}""", body["thinking"]!.ToJsonString());
        Assert.Equal("medium", (string?)body["output_config"]!["effort"]);
        Assert.Equal("auto", (string?)body["tool_choice"]!["type"]);
        Assert.Equal(AgentTools.Specs.Count, body["tools"]!.AsArray().Count);
        var system = Assert.Single(body["system"]!.AsArray());
        Assert.Equal(AgentPrompt.Text + Tail, (string?)system!["text"]);
        Assert.Equal("ephemeral", (string?)system["cache_control"]!["type"]);
        var messages = body["messages"]!.AsArray();
        Assert.Equal("user", (string?)messages[^1]!["role"]);
        Assert.Equal("ephemeral", (string?)messages[^1]!["content"]!.AsArray()[^1]!["cache_control"]!["type"]);
        Assert.Equal(2, CountBreakpoints(body));
        Assert.DoesNotContain(wire.Betas, b => b.Contains("fallback", StringComparison.Ordinal));
    }

    [Fact]
    public async Task Claude_rewrite_without_tools_still_declares_them_with_tool_choice_none()
    {
        var wire = new Wire(Reply("""[{"type":"text","text":"ok"}]""", "end_turn"));
        var ledger = new CeilingLedger(long.MaxValue);
        var result = await Agent(Model(wire), ledger).SendAsync(Run(), [], Ct, RewriteTranscript);

        Assert.Equal(AgentModelStatus.Success, result.Status);
        Assert.Equal("ok", result.Text);
        Assert.Equal("none", (string?)wire.Body!["tool_choice"]!["type"]);
        Assert.Equal(AgentTools.Specs.Count, wire.Body["tools"]!.AsArray().Count);
    }

    [Fact]
    public async Task A_rewrite_reservation_counts_the_tool_declarations_Claude_will_send()
    {
        // Codex B27 #1: the rewrite's bound must include the restored declarations, so near the ceiling it is refused.
        var openai = new ChatClientAgentModel(OpenAIClientFactory.Create(Key, new HttpClient(new Wire(null))), new OpenAIProvider(), TimeProvider.System);
        var probe = new CeilingLedger(long.MaxValue);
        await Agent(openai, probe).ReserveAsync(Run(), RewriteTranscript, [], Ct);
        var withoutTools = probe.Projected!.Value;
        await Agent(Model(new Wire(null)), probe).ReserveAsync(Run(), RewriteTranscript, [], Ct);
        var withTools = probe.Projected!.Value;
        var declarations = AgentTools.Specs.Sum(t => System.Text.Encoding.UTF8.GetByteCount(t.Name + t.Description + t.Schema.GetRawText())) / 2;
        Assert.Equal(withoutTools + declarations, withTools, tolerance: 2);

        var ceiling = withoutTools + 100; // room for the text-only rewrite, not for ~15k tokens of schemas
        Assert.Equal(SendGate.Reserved, await Agent(openai, new CeilingLedger(ceiling)).ReserveAsync(Run(), RewriteTranscript, [], Ct));
        Assert.Equal(SendGate.Limit, await Agent(Model(new Wire(null)), new CeilingLedger(ceiling)).ReserveAsync(Run(), RewriteTranscript, [], Ct));
    }

    [Fact]
    public async Task Claude_summary_without_tool_history_sends_no_tools_and_no_tool_choice()
    {
        var wire = new Wire(Reply("""[{"type":"text","text":"summary"}]""", "end_turn"));
        await Agent(Model(wire), new CeilingLedger(long.MaxValue)).SendAsync(Run(), [], Ct, [AgentMessage.User("summarise")]);
        Assert.False(wire.Body!.ContainsKey("tools"));
        Assert.False(wire.Body.ContainsKey("tool_choice"));
    }

    [Theory]
    [InlineData("refusal", "Refused")]
    [InlineData("max_tokens", "Incomplete")]
    [InlineData("pause_turn", "Refused")]
    public async Task Claude_unfinished_stops_take_the_failure_paths(string stop, string expected)
    {
        var wire = new Wire(Reply("[]", stop));
        Assert.Equal(expected, (await Model(wire).SendAsync(Request(AgentTools.Specs), Ct)).Status.ToString());
    }

    [Fact]
    public async Task Claude_provider_errors_are_unavailable_and_the_fallback_wire_shape_is_ready_but_rejected_by_options()
    {
        var down = new Wire(null);
        Assert.Equal(AgentModelStatus.Unavailable, (await Model(down).SendAsync(Request(AgentTools.Specs), Ct)).Status);
        var wire = new Wire(Reply("""[{"type":"text","text":"hi"}]""", "end_turn"));
        await Model(wire, new AnthropicProvider("low", serverFallback: true)).SendAsync(Request(AgentTools.Specs), Ct);
        Assert.Equal("default", (string?)wire.Body!["fallbacks"]);
        Assert.Equal("low", (string?)wire.Body["output_config"]!["effort"]);
        Assert.Contains(AnthropicProvider.FallbackBeta, wire.Betas);
    }

    [Fact]
    public async Task Claude_label_read_puts_the_schema_in_the_cached_system_prompt_and_parses_fenced_json()
    {
        var none = new BuddyLabelValue(null, BuddyLabelConfidence.Low); var mass = new LabelMass(null, null, BuddyLabelConfidence.Low);
        var reading = System.Text.Json.JsonSerializer.Serialize(new LabelReading(false, null, null, new(null, BuddyLabelConfidence.Low),
            new(none, none, none, none, none, none, none, none, none, mass, mass, mass), []), AgentTools.Json);
        var wire = new Wire(Reply(new JsonArray(new JsonObject { ["type"] = "text", ["text"] = "```json\n" + reading + "\n```" }).ToJsonString(), "end_turn"));
        var reader = new ChatClientLabelReader(Client(wire), new AnthropicProvider("medium", false), TimeProvider.System, Options.Create(new BuddyAgentOptions()));
        var read = await reader.ReadAsync(Convert.ToBase64String([0xFF, 0xD8, 0xFF, 0xD9]), Ct);

        Assert.Equal(AgentModelStatus.Success, read.Status);
        Assert.False(read.Reading!.Found);
        var body = wire.Body!;
        // Claude allows at most 16 union-typed fields in output_config.format (live 400, 2026-11-07); the label has 19.
        Assert.Null(body["output_config"]!["format"]);
        Assert.Equal("low", (string?)body["output_config"]!["effort"]);
        Assert.Equal("""{"type":"between_tools"}""", body["thinking"]!.ToJsonString());
        var system = Assert.Single(body["system"]!.AsArray())!;
        Assert.Contains("\"perServing\"", (string?)system["text"], StringComparison.Ordinal);
        Assert.Equal("ephemeral", (string?)system["cache_control"]!["type"]);
        Assert.Equal("image", (string?)body["messages"]![0]!["content"]!.AsArray()[1]!["type"]);
        Assert.False(body.ContainsKey("tools"));
    }

    [Theory]
    [InlineData("""{"found":true}""")]
    [InlineData("""{"found":true,"basis":"per100g","serving":null,"name":{"value":null,"confidence":"low"},"nutrients":null,"others":[]}""")]
    [InlineData("""{"found":true,"basis":"per100g","serving":null,"name":{"value":null,"confidence":"low"},"nutrients":{"kcal":{"value":400,"confidence":"high"}},"others":[]}""")]
    [InlineData("""{"found":true,"basis":"per100g","serving":null,"name":{"value":null,"confidence":"low"},"nutrients":{"kcal":null,"kj":null,"proteinG":null,"carbsG":null,"fatG":null,"fiberG":null,"sugarG":null,"saturatedFatG":null,"transFatG":null,"sodium":null,"salt":null,"cholesterol":null},"others":[]}""")]
    [InlineData("""{"found":true,"basis":"per100g","serving":null,"name":null,"nutrients":{},"others":[null]}""")]
    public async Task Incomplete_label_json_is_unavailable_not_success(string json)
    {
        // Codex B27 #2: Claude answers free JSON text; a partial transcription must not reach LabelRules.
        var wire = new Wire(Reply(new JsonArray(new JsonObject { ["type"] = "text", ["text"] = json }).ToJsonString(), "end_turn"));
        var reader = new ChatClientLabelReader(Client(wire), new AnthropicProvider("medium", false), TimeProvider.System, Options.Create(new BuddyAgentOptions()));
        var read = await reader.ReadAsync(Convert.ToBase64String([0xFF, 0xD8, 0xFF, 0xD9]), Ct);
        Assert.Equal(AgentModelStatus.Unavailable, read.Status);
        Assert.Null(read.Reading);
    }

    [Fact]
    public void A_null_other_nutrient_is_incomplete()
    {
        var none = new BuddyLabelValue(null, BuddyLabelConfidence.Low); var mass = new LabelMass(null, null, BuddyLabelConfidence.Low);
        var whole = new LabelReading(true, BuddyLabelBasis.Per100g, null, new(null, BuddyLabelConfidence.Low),
            new(none, none, none, none, none, none, none, none, none, mass, mass, mass), []);
        Assert.True(LabelRules.Complete(whole));
        Assert.False(LabelRules.Complete(whole with { Others = [null!] }));
        Assert.False(LabelRules.Complete(whole with { Nutrients = whole.Nutrients with { Salt = null! } }));
    }

    [Fact]
    public async Task OpenAI_step_is_unchanged_store_false_low_effort()
    {
        var wire = new Wire(null);
        var model = new ChatClientAgentModel(OpenAIClientFactory.Create(Key, new HttpClient(wire)), new OpenAIProvider(), TimeProvider.System);
        Assert.Equal(AgentModelStatus.Unavailable, (await model.SendAsync(Request(AgentTools.Specs), Ct)).Status);
        Assert.Equal(false, (bool?)wire.Body!["store"]);
        Assert.Equal("gpt-6-luna", (string?)wire.Body["model"]);
        Assert.Equal("low", (string?)wire.Body["reasoning"]!["effort"]);
    }

    private static readonly AgentMessage[] RewriteTranscript = [AgentMessage.User("context"), AgentMessage.User("2 eggs"),
        new(AgentRole.Assistant, null, [new("call_1", "search_foods", """{"query":"egg"}""")], []),
        AgentMessage.Tools([new("call_1", """{"ok":true}""")]), AgentMessage.User("rewrite")];

    private static TurnRun Run() => new(Guid.CreateVersion7(), false, 0, 1, new(DateTimeOffset.UtcNow, 0, 0, 0), new TurnWorkspace(), null, [], [], null);

    // Only ReserveAsync/SendAsync run: the other collaborators are unused here.
    private static BuddyAgent Agent(IAgentModel model, IAgentLedger ledger) => new(ledger, model, null!, null!, null!, null!, TimeProvider.System,
        Options.Create(new BuddyAgentOptions()), null!, Microsoft.Extensions.Logging.Abstractions.NullLogger<BuddyAgent>.Instance);

    /// <summary>Admits a send only when its projected input fits <paramref name="ceiling"/> (the real ledger's input check).</summary>
    private sealed class CeilingLedger(long ceiling) : IAgentLedger
    {
        public long? Projected { get; private set; }
        public Task<SendGate> ReserveSendAsync(Guid turnId, int round, int attempt, bool guest, BuddyAgentOptions limits, long projectedInput, CancellationToken cancellationToken)
        { Projected = projectedInput; return Task.FromResult(projectedInput <= ceiling ? SendGate.Reserved : SendGate.Limit); }
        public Task RecordSendAsync(Guid turnId, long reservedInput, TokenUsage? usage, decimal? estimatedUsd, CancellationToken cancellationToken) => Task.CompletedTask;
        public Task<TurnBudget?> ReadBudgetAsync(Guid turnId, CancellationToken cancellationToken) => Task.FromResult<TurnBudget?>(null);
        public Task<RoundGate> BeginStartAsync(Guid turnId, Guid? ackTurn, bool guest, CancellationToken cancellationToken) => throw new NotSupportedException();
        public Task<RoundGate> BeginContinueAsync(Guid turnId, int round, int producerAttempt, PhoneDisclosure disclosure, CancellationToken cancellationToken) => throw new NotSupportedException();
        public Task CompleteRoundAsync(Guid turnId, int round, int attempt, bool cancelled, CancellationToken cancellationToken) => throw new NotSupportedException();
        public Task<RoundGate> ReserveLabelAsync(bool guest, CancellationToken cancellationToken) => throw new NotSupportedException();
        public Task RecordLabelAsync(TokenUsage? usage, decimal? estimatedUsd, CancellationToken cancellationToken) => throw new NotSupportedException();
    }

    private static ChatClientAgentModel Model(Wire wire, AnthropicProvider? provider = null)
        => new(Client(wire), provider ?? new AnthropicProvider("medium", false), TimeProvider.System);

    private static Microsoft.Extensions.AI.IChatClient Client(Wire wire) => AnthropicClientFactory.Create(Key, new HttpClient(wire), TimeSpan.FromSeconds(30));

    private static AgentModelRequest Request(IReadOnlyList<AgentToolSpec> tools, AgentMessage[]? transcript = null)
        => new(AgentPrompt.Text + Tail, transcript ?? [AgentMessage.User("context"), AgentMessage.User("2 eggs and toast")], null, tools, 2000, TimeSpan.FromSeconds(20));

    private static string Reply(string content, string stop) => $$$"""
        {"id":"msg_1","type":"message","role":"assistant","model":"claude-sonnet-5-5","content":{{{content}}},"stop_reason":"{{{stop}}}","stop_sequence":null,
         "usage":{"input_tokens":100,"output_tokens":50,"cache_read_input_tokens":1000,"cache_creation_input_tokens":200}}
        """;

    private static int CountBreakpoints(JsonNode? node) => node switch
    {
        JsonObject o => (o.ContainsKey("cache_control") ? 1 : 0) + o.Sum(p => CountBreakpoints(p.Value)),
        JsonArray a => a.Sum(CountBreakpoints),
        _ => 0,
    };

    /// <summary>Captures the request body and anthropic-beta headers; answers the canned reply, or 503 when null.</summary>
    private sealed class Wire(string? reply) : HttpMessageHandler
    {
        public JsonObject? Body { get; private set; }
        public List<string> Betas { get; } = [];
        protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            Body = JsonNode.Parse(await request.Content!.ReadAsStringAsync(cancellationToken))!.AsObject();
            if (request.Headers.TryGetValues("anthropic-beta", out var betas)) { Betas.AddRange(betas.SelectMany(b => b.Split(','))); }
            return reply is null ? new HttpResponseMessage(HttpStatusCode.ServiceUnavailable) { Content = new StringContent("{}", Encoding.UTF8, "application/json") }
                : new HttpResponseMessage(HttpStatusCode.OK) { Content = new StringContent(reply, Encoding.UTF8, "application/json") };
        }
    }
}
