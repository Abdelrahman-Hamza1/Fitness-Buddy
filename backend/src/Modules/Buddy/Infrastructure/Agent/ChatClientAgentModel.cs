using System.Diagnostics;
using System.Diagnostics.Metrics;
using System.Text.Json;
using FitnessBuddy.Modules.Buddy.Application;
using FitnessBuddy.Modules.Buddy.Domain;
using Microsoft.Extensions.AI;

namespace FitnessBuddy.Modules.Buddy.Infrastructure;

/// <summary>
/// One agent step over <see cref="IChatClient"/> (TD-124): declared tools only, no automatic invocation, no retries. The
/// provider (TD-129) shapes the request (OpenAI: Responses, <c>store:false</c>, low effort; Claude: <c>between_tools</c>,
/// effort, cache breakpoints), decides completion and prices usage. The static system prompt and tool declarations come first
/// for prompt caching. Spans carry the task, provider, model, prompt version, outcome and tokens only; content capture stays off.
/// </summary>
internal sealed class ChatClientAgentModel(IChatClient client, BuddyProvider provider, TimeProvider clock) : IAgentModel
{
    private static readonly ActivitySource Activities = new("FitnessBuddy.Buddy");
    private static readonly Meter Metrics = new("FitnessBuddy.Buddy");
    private static readonly Histogram<double> Duration = Metrics.CreateHistogram<double>("buddy.agent.step.duration", "s");

    public IReadOnlyList<AgentToolSpec> Declared(IReadOnlyList<AgentToolSpec> tools, IReadOnlyList<AgentMessage> transcript) => provider.Declared(tools, transcript);

    public async Task<AgentModelResult> SendAsync(AgentModelRequest request, CancellationToken cancellationToken)
    {
        var start = clock.GetTimestamp();
        using var activity = Activities.StartActivity("agent.step", ActivityKind.Client);
        activity?.SetTag("buddy.task", "agent"); activity?.SetTag("gen_ai.provider.name", provider.Name);
        activity?.SetTag("gen_ai.request.model", provider.Model); activity?.SetTag("buddy.prompt.version", AgentPrompt.Version);
        using var timeout = new CancellationTokenSource(request.Timeout, clock);
        using var linked = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken, timeout.Token);
        var status = AgentModelStatus.Unavailable; var text = ""; AgentToolCall[] calls = []; TokenUsage? usage = null; decimal? cost = null;
        try
        {
            var messages = Messages(request); provider.MarkPrefix(messages);
            var response = await client.GetResponseAsync(messages, provider.AgentOptions(request), linked.Token);
            usage = BuddyProvider.Usage(response);
            if (usage is not null) { cost = provider.Cost(usage, response.Usage!); }
            var contents = response.Messages.SelectMany(m => m.Contents).ToArray();
            calls = contents.OfType<FunctionCallContent>()
                .Select(c => new AgentToolCall(c.CallId, c.Name, JsonSerializer.Serialize(c.Arguments ?? new Dictionary<string, object?>(), AIJsonUtilities.DefaultOptions))).ToArray();
            text = string.Concat(contents.OfType<TextContent>().Select(t => t.Text));
            // A refusal (Claude stop_reason refusal → ContentFilter) and any other unfinished stop take the Refused path.
            status = provider.Completed(response) ? AgentModelStatus.Success
                : response.FinishReason == ChatFinishReason.Length ? AgentModelStatus.Incomplete : AgentModelStatus.Refused;
        }
        catch (OperationCanceledException) { status = cancellationToken.IsCancellationRequested ? AgentModelStatus.Cancelled : AgentModelStatus.Timeout; }
        catch (Exception e) when (provider.TransportFailure(e)) { status = linked.IsCancellationRequested && !cancellationToken.IsCancellationRequested ? AgentModelStatus.Timeout : AgentModelStatus.Unavailable; }
        var elapsed = clock.GetElapsedTime(start).TotalMilliseconds;
        activity?.SetTag("buddy.outcome", status.ToString()); activity?.SetTag("gen_ai.usage.input_tokens", usage?.Input); activity?.SetTag("gen_ai.usage.output_tokens", usage?.Output);
        Duration.Record(elapsed / 1000, new KeyValuePair<string, object?>("buddy.outcome", status.ToString()));
        return new(status, text, calls, usage, cost, elapsed);
    }

    private List<ChatMessage> Messages(AgentModelRequest request)
    {
        var messages = new List<ChatMessage> { provider.System(request.System) };
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
}
