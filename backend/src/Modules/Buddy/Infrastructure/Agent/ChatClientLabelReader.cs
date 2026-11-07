using System.Diagnostics;
using System.Diagnostics.Metrics;
using System.Text.Json;
using FitnessBuddy.Modules.Buddy.Application;
using FitnessBuddy.Modules.Buddy.Domain;
using Microsoft.Extensions.AI;
using Microsoft.Extensions.Options;

namespace FitnessBuddy.Modules.Buddy.Infrastructure;

/// <summary>
/// The label read over <see cref="IChatClient"/> (B26 WP5, 06 §8): one call with the photo and a JSON schema built from
/// <see cref="LabelReading"/>, low effort, no tools, no retries; the provider (TD-129) shapes it (OpenAI <c>store:false</c> text
/// format; Claude gets the schema in its cached system prompt and answers JSON text, since the schema exceeds Claude's
/// structured-output union limit). Spans and metrics carry the task, provider, model, prompt version, outcome and
/// tokens only; the photo and the reply are never logged.
/// </summary>
internal sealed class ChatClientLabelReader(IChatClient client, BuddyProvider provider, TimeProvider clock, IOptions<BuddyAgentOptions> options) : ILabelReader
{
    private static readonly ActivitySource Activities = new("FitnessBuddy.Buddy");
    private static readonly Meter Metrics = new("FitnessBuddy.Buddy");
    private static readonly Histogram<double> Duration = Metrics.CreateHistogram<double>("buddy.label.duration", "s");
    private static readonly string Prompt = Read();
    private static readonly JsonSerializerOptions Strict = new(AgentTools.Json) { RespectRequiredConstructorParameters = true };
    private static readonly Lazy<string> Schema = new(() => AIJsonUtilities.CreateJsonSchema(typeof(LabelReading), serializerOptions: AgentTools.Json).GetRawText());

    public async Task<LabelRead> ReadAsync(string imageBase64, CancellationToken cancellationToken)
    {
        var start = clock.GetTimestamp();
        using var activity = Activities.StartActivity("label", ActivityKind.Client);
        activity?.SetTag("buddy.task", "label"); activity?.SetTag("gen_ai.provider.name", provider.Name);
        activity?.SetTag("gen_ai.request.model", provider.Model); activity?.SetTag("buddy.prompt.version", ExtractLabel.PromptVersion);
        using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(options.Value.StepTimeoutSeconds), clock);
        using var linked = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken, timeout.Token);
        var status = AgentModelStatus.Unavailable; LabelReading? reading = null; TokenUsage? usage = null; decimal? cost = null;
        try
        {
            List<ChatMessage> messages = [provider.System(provider.LabelSystem(Prompt, Schema.Value)),
                new(ChatRole.User, [new TextContent("Read this label."), new DataContent(Convert.FromBase64String(imageBase64), "image/jpeg")])];
            var response = await client.GetResponseAsync(messages, provider.LabelOptions(Schema.Value), linked.Token);
            usage = BuddyProvider.Usage(response);
            if (usage is not null) { cost = provider.Cost(usage, response.Usage!); }
            if (provider.Completed(response))
            {
                // Every property must be present (required constructor parameters) and every nested object and array element
                // non-null; anything less is a malformed reply → Unavailable (Codex B27 #2: Claude answers free JSON text).
                reading = JsonSerializer.Deserialize<LabelReading>(provider.LabelJson(response.Text), Strict);
                if (reading is not null && !LabelRules.Complete(reading)) { reading = null; }
                status = reading is null ? AgentModelStatus.Unavailable : AgentModelStatus.Success;
            }
            else { status = response.FinishReason == ChatFinishReason.Length ? AgentModelStatus.Incomplete : AgentModelStatus.Refused; }
        }
        catch (OperationCanceledException) { status = cancellationToken.IsCancellationRequested ? AgentModelStatus.Cancelled : AgentModelStatus.Timeout; }
        catch (Exception e) when (provider.TransportFailure(e) || e is JsonException or FormatException)
        { status = linked.IsCancellationRequested && !cancellationToken.IsCancellationRequested ? AgentModelStatus.Timeout : AgentModelStatus.Unavailable; }
        var elapsed = clock.GetElapsedTime(start).TotalMilliseconds;
        activity?.SetTag("buddy.outcome", status.ToString()); activity?.SetTag("gen_ai.usage.input_tokens", usage?.Input); activity?.SetTag("gen_ai.usage.output_tokens", usage?.Output);
        Duration.Record(elapsed / 1000, new KeyValuePair<string, object?>("buddy.outcome", status.ToString()));
        return new(status, reading, usage, cost, elapsed);
    }

    private static string Read()
    {
        using var stream = typeof(ChatClientLabelReader).Assembly.GetManifestResourceStream("FitnessBuddy.Modules.Buddy.Prompts.label-v1.txt")!;
        using var reader = new StreamReader(stream); return reader.ReadToEnd();
    }
}
