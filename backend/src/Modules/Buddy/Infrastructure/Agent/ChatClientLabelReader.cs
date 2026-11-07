using System.ClientModel;
using System.Diagnostics;
using System.Diagnostics.Metrics;
using System.Text.Json;
using FitnessBuddy.Modules.Buddy.Application;
using FitnessBuddy.Modules.Buddy.Domain;
using Microsoft.Extensions.AI;
using Microsoft.Extensions.Options;
using OpenAI.Responses;

namespace FitnessBuddy.Modules.Buddy.Infrastructure;

/// <summary>
/// The label read over <see cref="IChatClient"/> (B26 WP5, 06 §8): one Responses call with the photo and a JSON schema built from
/// <see cref="LabelReading"/>, low effort, <c>store:false</c>, no tools, no retries. Spans and metrics carry the task, model,
/// prompt version, outcome and tokens only; the photo and the reply are never logged.
/// </summary>
internal sealed class ChatClientLabelReader(IChatClient client, TimeProvider clock, IOptions<BuddyAgentOptions> options) : ILabelReader
{
    private static readonly ActivitySource Activities = new("FitnessBuddy.Buddy");
    private static readonly Meter Metrics = new("FitnessBuddy.Buddy");
    private static readonly Histogram<double> Duration = Metrics.CreateHistogram<double>("buddy.label.duration", "s");
    private static readonly string Prompt = Read();
    private static readonly Lazy<string> Schema = new(() => AIJsonUtilities.CreateJsonSchema(typeof(LabelReading), serializerOptions: AgentTools.Json).GetRawText());

    public async Task<LabelRead> ReadAsync(string imageBase64, CancellationToken cancellationToken)
    {
        var start = clock.GetTimestamp();
        using var activity = Activities.StartActivity("label", ActivityKind.Client);
        activity?.SetTag("buddy.task", "label"); activity?.SetTag("gen_ai.provider.name", "openai");
        activity?.SetTag("gen_ai.request.model", OpenAIClientFactory.Model); activity?.SetTag("buddy.prompt.version", ExtractLabel.PromptVersion);
        using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(options.Value.StepTimeoutSeconds), clock);
        using var linked = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken, timeout.Token);
        var status = AgentModelStatus.Unavailable; LabelReading? reading = null; TokenUsage? usage = null;
        try
        {
            List<ChatMessage> messages = [new(ChatRole.System, Prompt),
                new(ChatRole.User, [new TextContent("Read this label."), new DataContent(Convert.FromBase64String(imageBase64), "image/jpeg")])];
            var response = await client.GetResponseAsync(messages, Options(), linked.Token);
            if (response.Usage is { InputTokenCount: >= 0, OutputTokenCount: >= 0 } u) { usage = new(u.InputTokenCount.Value, u.CachedInputTokenCount ?? 0, u.OutputTokenCount.Value); }
            if (Completed(response))
            {
                reading = JsonSerializer.Deserialize<LabelReading>(response.Text, AgentTools.Json);
                status = reading is null ? AgentModelStatus.Unavailable : AgentModelStatus.Success;
            }
            else { status = response.FinishReason == ChatFinishReason.Length ? AgentModelStatus.Incomplete : AgentModelStatus.Refused; }
        }
        catch (OperationCanceledException) { status = cancellationToken.IsCancellationRequested ? AgentModelStatus.Cancelled : AgentModelStatus.Timeout; }
        catch (ClientResultException) { status = AgentModelStatus.Unavailable; }
        catch (HttpRequestException) { status = AgentModelStatus.Unavailable; }
        catch (JsonException) { status = AgentModelStatus.Unavailable; }
        catch (FormatException) { status = AgentModelStatus.Unavailable; }
        decimal? cost = usage is { CachedInput: >= 0 } && usage.CachedInput <= usage.Input
            ? ((usage.Input - usage.CachedInput) * .10m + usage.CachedInput * .01m + usage.Output * .50m) / 1_000_000m : null;
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

#pragma warning disable OPENAI001
    private static bool Completed(ChatResponse response) => response.RawRepresentation is ResponseResult { Status: ResponseStatus.Completed }
        && !response.Messages.SelectMany(m => m.Contents).Any(c => c is ErrorContent);
    private static ChatOptions Options() => new()
    {
        ModelId = OpenAIClientFactory.Model,
        MaxOutputTokens = 1500,
        Reasoning = new ReasoningOptions { Effort = ReasoningEffort.Low },
        RawRepresentationFactory = _ => new CreateResponseOptions
        {
            StoredOutputEnabled = false,
            TextOptions = new ResponseTextOptions { TextFormat = ResponseTextFormat.CreateJsonSchemaFormat("label_reading", BinaryData.FromString(Schema.Value), null, false) },
        },
    };
#pragma warning restore OPENAI001
}
