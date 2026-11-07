using System.ClientModel;
using System.Diagnostics;
using System.Diagnostics.Metrics;
using System.Text.Json;
using FitnessBuddy.Modules.Buddy.Application;
using FitnessBuddy.Modules.Buddy.Domain;
using Microsoft.Extensions.AI;
using OpenAI.Responses;

namespace FitnessBuddy.Modules.Buddy.Infrastructure;

/// <summary>
/// One agent step over <see cref="IChatClient"/> (TD-124): declared tools only, no automatic invocation, no retries or fallback,
/// Responses API with <c>store:false</c> and low effort. The static system prompt and tool declarations come first for prompt
/// caching. Spans carry the task, model, prompt version, outcome and tokens only; content capture stays off.
/// </summary>
internal sealed class ChatClientAgentModel(IChatClient client, TimeProvider clock) : IAgentModel
{
    private static readonly ActivitySource Activities = new("FitnessBuddy.Buddy");
    private static readonly Meter Metrics = new("FitnessBuddy.Buddy");
    private static readonly Histogram<double> Duration = Metrics.CreateHistogram<double>("buddy.agent.step.duration", "s");

    public async Task<AgentModelResult> SendAsync(AgentModelRequest request, CancellationToken cancellationToken)
    {
        var start = clock.GetTimestamp();
        using var activity = Activities.StartActivity("agent.step", ActivityKind.Client);
        activity?.SetTag("buddy.task", "agent"); activity?.SetTag("gen_ai.provider.name", "openai");
        activity?.SetTag("gen_ai.request.model", OpenAIClientFactory.Model); activity?.SetTag("buddy.prompt.version", AgentPrompt.Version);
        using var timeout = new CancellationTokenSource(request.Timeout, clock);
        using var linked = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken, timeout.Token);
        var status = AgentModelStatus.Unavailable; var text = ""; AgentToolCall[] calls = []; TokenUsage? usage = null;
        try
        {
            var response = await client.GetResponseAsync(Messages(request), Options(request), linked.Token);
            if (response.Usage is { InputTokenCount: >= 0, OutputTokenCount: >= 0 } u) { usage = new(u.InputTokenCount.Value, u.CachedInputTokenCount ?? 0, u.OutputTokenCount.Value); }
            var contents = response.Messages.SelectMany(m => m.Contents).ToArray();
            calls = contents.OfType<FunctionCallContent>()
                .Select(c => new AgentToolCall(c.CallId, c.Name, JsonSerializer.Serialize(c.Arguments ?? new Dictionary<string, object?>(), AIJsonUtilities.DefaultOptions))).ToArray();
            text = string.Concat(contents.OfType<TextContent>().Select(t => t.Text));
            status = Completed(response, contents) ? AgentModelStatus.Success
                : response.FinishReason == ChatFinishReason.Length ? AgentModelStatus.Incomplete : AgentModelStatus.Refused;
        }
        catch (OperationCanceledException) { status = cancellationToken.IsCancellationRequested ? AgentModelStatus.Cancelled : AgentModelStatus.Timeout; }
        catch (ClientResultException) { status = AgentModelStatus.Unavailable; }
        catch (HttpRequestException) { status = AgentModelStatus.Unavailable; }
        catch (JsonException) { status = AgentModelStatus.Unavailable; }
        decimal? cost = usage is { CachedInput: >= 0 } && usage.CachedInput <= usage.Input
            ? ((usage.Input - usage.CachedInput) * .10m + usage.CachedInput * .01m + usage.Output * .50m) / 1_000_000m : null;
        var elapsed = clock.GetElapsedTime(start).TotalMilliseconds;
        activity?.SetTag("buddy.outcome", status.ToString()); activity?.SetTag("gen_ai.usage.input_tokens", usage?.Input); activity?.SetTag("gen_ai.usage.output_tokens", usage?.Output);
        Duration.Record(elapsed / 1000, new KeyValuePair<string, object?>("buddy.outcome", status.ToString()));
        return new(status, text, calls, usage, cost, elapsed);
    }

    private static List<ChatMessage> Messages(AgentModelRequest request)
    {
        var messages = new List<ChatMessage> { new(ChatRole.System, request.System) };
        for (var i = 0; i < request.Transcript.Count; i++)
        {
            var m = request.Transcript[i];
            switch (m.Role)
            {
                case AgentRole.User:
                    var contents = new List<AIContent> { new TextContent(m.Text ?? "") };
                    // The photo goes with the user's message (transcript entry 1, after the context) in round 0 only; it is never sealed.
                    if (request.ImageBase64 is { } image && i == TurnContextBuilder.MessageIndex)
                    { contents.Add(new DataContent(Convert.FromBase64String(image), "image/jpeg")); }
                    messages.Add(new(ChatRole.User, contents));
                    break;
                case AgentRole.Assistant:
                    var parts = new List<AIContent>();
                    if (!string.IsNullOrEmpty(m.Text)) { parts.Add(new TextContent(m.Text)); }
                    parts.AddRange(m.Calls.Select(c => new FunctionCallContent(c.CallId, c.Name,
                        JsonSerializer.Deserialize<Dictionary<string, object?>>(c.ArgumentsJson, AIJsonUtilities.DefaultOptions))));
                    messages.Add(new(ChatRole.Assistant, parts));
                    break;
                default:
                    messages.Add(new(ChatRole.Tool, m.Results.Select(r => (AIContent)new FunctionResultContent(r.CallId, r.ResultJson)).ToList()));
                    break;
            }
        }
        return messages;
    }

#pragma warning disable OPENAI001
    private static bool Completed(ChatResponse response, AIContent[] contents) => response.RawRepresentation is ResponseResult { Status: ResponseStatus.Completed }
        && !contents.Any(c => c is ErrorContent);
    private static ChatOptions Options(AgentModelRequest request) => new()
    {
        ModelId = OpenAIClientFactory.Model,
        MaxOutputTokens = request.MaxOutputTokens,
        Reasoning = new ReasoningOptions { Effort = ReasoningEffort.Low },
        Tools = request.Tools.Select(t => (AITool)AIFunctionFactory.CreateDeclaration(t.Name, t.Description, t.Schema)).ToList(),
        ToolMode = request.Tools.Count > 0 ? ChatToolMode.Auto : ChatToolMode.None,
        AllowMultipleToolCalls = true,
        RawRepresentationFactory = _ => new CreateResponseOptions { StoredOutputEnabled = false },
    };
#pragma warning restore OPENAI001
}
