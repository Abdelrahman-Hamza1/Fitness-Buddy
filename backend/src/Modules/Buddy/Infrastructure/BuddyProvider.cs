using System.ClientModel;
using System.Text.Json;
using Anthropic.Exceptions;
using Anthropic.Models.Messages;
using FitnessBuddy.Modules.Buddy.Application;
using FitnessBuddy.Modules.Buddy.Domain;
using Microsoft.Extensions.AI;
using OpenAI.Responses;
using Beta = Anthropic.Models.Beta.Messages;

namespace FitnessBuddy.Modules.Buddy.Infrastructure;

/// <summary>
/// What differs between the Buddy providers (TD-129) behind the shared <see cref="IChatClient"/> adapters: names for spans and
/// the Usage rows, the request options, prompt-cache breakpoints, the completion check, the transport failures and the price.
/// The model ID is fixed per provider; the adapters stay provider-neutral.
/// </summary>
internal abstract class BuddyProvider
{
    public abstract string Name { get; }
    public abstract string Model { get; }

    /// <summary>The declarations a step carries for its callable tools (default: exactly those).</summary>
    public virtual IReadOnlyList<AgentToolSpec> Declared(IReadOnlyList<AgentToolSpec> tools, IReadOnlyList<AgentMessage> transcript) => tools;
    /// <summary>Options for one agent step over the declared tools (no automatic invocation, TD-124).</summary>
    public abstract ChatOptions AgentOptions(AgentModelRequest request);
    /// <summary>Options for the one structured label read (JSON schema, no tools).</summary>
    public abstract ChatOptions LabelOptions(string schemaJson);
    /// <summary>The label read's system prompt (the versioned <c>label-v1</c>, plus any provider framing).</summary>
    public virtual string LabelSystem(string prompt, string schemaJson) => prompt;
    /// <summary>The label reply's JSON text.</summary>
    public virtual string LabelJson(string text) => text;
    /// <summary>The system message (the agent prompt may carry a per-user tail after the static <see cref="AgentPrompt"/>).</summary>
    public virtual ChatMessage System(string system) => new(ChatRole.System, system);
    /// <summary>Marks where the next step of the same turn can reuse the prefix (no-op where caching is automatic).</summary>
    public virtual void MarkPrefix(List<ChatMessage> messages) { }
    /// <summary>True when the provider finished normally (a final answer or tool calls); otherwise length → Incomplete, else Refused.</summary>
    public abstract bool Completed(ChatResponse response);
    /// <summary>A provider or transport failure the adapters map to Unavailable.</summary>
    public abstract bool TransportFailure(Exception exception);
    /// <summary>Estimated USD from reported usage (null when the counts don't add up); <paramref name="details"/> has provider extras.</summary>
    public abstract decimal? Cost(TokenUsage usage, UsageDetails details);

    public static TokenUsage? Usage(ChatResponse response) => response.Usage is { InputTokenCount: >= 0, OutputTokenCount: >= 0 } u
        ? new(u.InputTokenCount.Value, u.CachedInputTokenCount ?? 0, u.OutputTokenCount.Value) : null;

    public static BuddyProvider From(BuddyOptions options) => options.Provider == BuddyOptions.Anthropic
        ? new AnthropicProvider(options.AnthropicEffort, options.AnthropicServerFallback) : new OpenAIProvider();

    protected static List<AITool> Declarations(IReadOnlyList<AgentToolSpec> tools)
        => tools.Select(t => (AITool)AIFunctionFactory.CreateDeclaration(t.Name, t.Description, t.Schema)).ToList();
}

/// <summary>OpenAI Responses (TD-035): <c>store:false</c>, low effort, automatic prompt caching. Unchanged from B25/B26.</summary>
internal sealed class OpenAIProvider : BuddyProvider
{
    public override string Name => "openai";
    public override string Model => OpenAIClientFactory.Model;

#pragma warning disable OPENAI001
    public override ChatOptions AgentOptions(AgentModelRequest request) => new()
    {
        ModelId = Model,
        MaxOutputTokens = request.MaxOutputTokens,
        Reasoning = new ReasoningOptions { Effort = ReasoningEffort.Low },
        Tools = Declarations(request.AllowToolCalls ? request.Tools : []),
        ToolMode = request.AllowToolCalls && request.Tools.Count > 0 ? ChatToolMode.Auto : ChatToolMode.None,
        AllowMultipleToolCalls = true,
        RawRepresentationFactory = _ => new CreateResponseOptions { StoredOutputEnabled = false },
    };

    public override ChatOptions LabelOptions(string schemaJson) => new()
    {
        ModelId = Model,
        MaxOutputTokens = 1500,
        Reasoning = new ReasoningOptions { Effort = ReasoningEffort.Low },
        RawRepresentationFactory = _ => new CreateResponseOptions
        {
            StoredOutputEnabled = false,
            TextOptions = new ResponseTextOptions { TextFormat = ResponseTextFormat.CreateJsonSchemaFormat("label_reading", BinaryData.FromString(schemaJson), null, false) },
        },
    };

    public override bool Completed(ChatResponse response) => response.RawRepresentation is ResponseResult { Status: ResponseStatus.Completed }
        && !response.Messages.SelectMany(m => m.Contents).Any(c => c is ErrorContent);
#pragma warning restore OPENAI001

    public override bool TransportFailure(Exception exception) => exception is ClientResultException or HttpRequestException or JsonException;

    public override decimal? Cost(TokenUsage usage, UsageDetails details) => usage.CachedInput >= 0 && usage.CachedInput <= usage.Input
        ? ((usage.Input - usage.CachedInput) * .10m + usage.CachedInput * .01m + usage.Output * .50m) / 1_000_000m : null;
}

/// <summary>
/// Claude Sonnet 5.5 over the Messages API (TD-129, B27 D1–D10): <c>thinking: between_tools</c> (thinking blocks are never sent
/// back, so the rebuilt history passes the preserved-thinking rules), <c>output_config.effort</c>, no sampling parameters,
/// <c>tool_choice</c> auto or none only, explicit cache breakpoints after the system prompt and on the last message.
/// </summary>
internal sealed class AnthropicProvider(string effort, bool serverFallback) : BuddyProvider
{
    public const string ModelId = "claude-sonnet-5-5";
    public const string FallbackBeta = "server-side-fallback-2026-07-01";

    public override string Name => "anthropic";
    public override string Model => ModelId;

    // A step without tools (a guard rewrite) whose history holds tool blocks still declares them: the API needs the
    // definitions, and unchanged tools keep the tools + system cache prefix. The agent budgets this list (Codex B27 #1).
    public override IReadOnlyList<AgentToolSpec> Declared(IReadOnlyList<AgentToolSpec> tools, IReadOnlyList<AgentMessage> transcript)
        => tools.Count > 0 ? tools : transcript.Any(m => m.Calls.Length > 0 || m.Results.Length > 0) ? AgentTools.Specs : [];

    public override ChatOptions AgentOptions(AgentModelRequest request)
    {
        var tools = request.Tools;
        return new()
        {
            ModelId = Model,
            MaxOutputTokens = request.MaxOutputTokens,
            Tools = tools.Count > 0 ? Declarations(tools) : null,
            // Sonnet 5.5 rejects forced tool use (any/tool): only auto or none ever reach it (none: declared, not callable).
            ToolMode = tools.Count == 0 ? null : request.AllowToolCalls ? ChatToolMode.Auto : ChatToolMode.None,
            AllowMultipleToolCalls = true,
            RawRepresentationFactory = _ => Params(request.MaxOutputTokens, effort),
        };
    }

    // The label schema has 19 nullable fields; Claude structured outputs allow at most 16 union-typed parameters (live 400,
    // 2026-11-07). So Claude gets the schema as an instruction in the cached system prompt and answers JSON text, which the
    // reader's existing parser and LabelRules check exactly as before (a malformed reply → Unavailable, no repair call).
    public override ChatOptions LabelOptions(string schemaJson) => new()
    {
        ModelId = Model,
        MaxOutputTokens = 1500,
        RawRepresentationFactory = _ => Params(1500, "low"),
    };

    public override string LabelSystem(string prompt, string schemaJson) => prompt
        + "\n\nOUTPUT: reply with exactly one JSON object and nothing else (no code fence, no prose). It must match this JSON Schema:\n" + schemaJson;

    public override string LabelJson(string text)
    {
        var json = text.Trim();
        if (json.StartsWith("```", StringComparison.Ordinal))
        {
            var open = json.IndexOf('\n'); var close = json.LastIndexOf("```", StringComparison.Ordinal);
            json = open > 0 && close > open ? json[(open + 1)..close].Trim() : json;
        }
        return json;
    }

    // Breakpoint 1 after the whole system prompt (tools render before system, so it caches tools + prompt). The system prompt
    // is shared by every user: agent-v1 plus the exercise library (catalog data); per-user context starts in the messages.
    public override ChatMessage System(string system) => new(ChatRole.System, [new TextContent(system).WithCacheControl(new CacheControlEphemeral())]);

    public override void MarkPrefix(List<ChatMessage> messages)
    {
        // The transcript never ends on an assistant turn (no prefill), so this is the user's message or the tool results.
        if (messages.Count > 1 && messages[^1].Contents.LastOrDefault() is { } last) { last.WithCacheControl(new CacheControlEphemeral()); }
    }

    public override bool Completed(ChatResponse response) => (response.FinishReason == ChatFinishReason.Stop || response.FinishReason == ChatFinishReason.ToolCalls)
        && !response.Messages.SelectMany(m => m.Contents).Any(c => c is ErrorContent);

    public override bool TransportFailure(Exception exception) => exception is AnthropicException or HttpRequestException or JsonException;

    public override decimal? Cost(TokenUsage usage, UsageDetails details)
    {
        // The adapter reports input = uncached + cache read + cache write, the read as cached and the write as an extra count.
        var read = usage.CachedInput;
        var written = details.AdditionalCounts?.TryGetValue("CacheCreationInputTokens", out var w) == true ? w : 0;
        if (read < 0 || written < 0 || read + written > usage.Input) { return null; }
        // platform.claude.com pricing (2026-11-07): $2/M input, $2.50/M 5-minute cache write, $0.10/M cache read, $10/M output.
        return ((usage.Input - read - written) * 2m + written * 2.5m + read * .10m + usage.Output * 10m) / 1_000_000m;
    }

    private Beta.MessageCreateParams Params(int maxTokens, string level)
    {
        var request = new Beta.MessageCreateParams
        {
            Model = Model,
            MaxTokens = maxTokens,
            Messages = [],
            Thinking = new Beta.BetaThinkingConfigBetweenTools(),
            OutputConfig = new Beta.BetaOutputConfig { Effort = level switch { "low" => Beta.Effort.Low, "high" => Beta.Effort.High, _ => Beta.Effort.Medium } },
        };
        return serverFallback ? request with { Fallbacks = new Beta.Default(), Betas = [FallbackBeta] } : request;
    }
}
