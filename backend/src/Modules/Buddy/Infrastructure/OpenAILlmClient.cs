using System.ClientModel;
using System.Diagnostics;
using System.Diagnostics.Metrics;
using System.Text.Json;
using FitnessBuddy.Modules.Buddy.Application;
using Microsoft.Extensions.AI;
using Microsoft.Extensions.Logging;
using OpenAI.Responses;

namespace FitnessBuddy.Modules.Buddy.Infrastructure;

internal sealed partial class OpenAILlmClient(IChatClient client, TimeProvider time,
    ILogger<OpenAILlmClient> logger, TimeSpan timeout) : ILlmClient
{
    private static readonly ActivitySource Activities = new("FitnessBuddy.Buddy");
    private static readonly Meter Metrics = new("FitnessBuddy.Buddy");
    private static readonly Histogram<double> Duration = Metrics.CreateHistogram<double>("gen_ai.client.operation.duration", "s");

    public async Task<LlmOutcome> InterpretAsync(string text, CancellationToken cancellationToken)
    {
        var start = time.GetTimestamp();
        if (string.IsNullOrWhiteSpace(text) || text.Length > InterpretProtocol.MaximumTextLength)
            return Finish(LlmStatus.InvalidInput, null, null, start);

        using var activity = Activities.StartActivity("interpret", ActivityKind.Client);
        activity?.SetTag("gen_ai.provider.name", "openai");
        activity?.SetTag("gen_ai.request.model", OpenAIClientFactory.Model);
        activity?.SetTag("buddy.prompt.version", InterpretProtocol.PromptVersion);
        using var deadline = new CancellationTokenSource(timeout, time);
        using var linked = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken, deadline.Token);
        try
        {
            var response = await client.GetResponseAsync(
                [new ChatMessage(ChatRole.System, InterpretProtocol.Prompt), new ChatMessage(ChatRole.User, text)],
                Options(), linked.Token);
            var usage = Usage(response.Usage);
            var status = response.FinishReason == ChatFinishReason.Length ? LlmStatus.Incomplete
                : response.Messages.SelectMany(message => message.Contents).Any(content => content is ErrorContent)
                    || response.FinishReason == ChatFinishReason.ContentFilter ? LlmStatus.Refused
                : Completed(response) ? LlmStatus.Success : LlmStatus.InvalidOutput;
            var interpretation = status == LlmStatus.Success ? InterpretProtocol.Parse(response.Text) : null;
            if (status == LlmStatus.Success && interpretation is null) status = LlmStatus.InvalidOutput;
            return Finish(status, interpretation, usage, start);
        }
        catch (OperationCanceledException)
        {
            return Finish(cancellationToken.IsCancellationRequested ? LlmStatus.Cancelled : LlmStatus.Timeout, null, null, start);
        }
        catch (ClientResultException exception)
        {
            return Finish(exception.Status == 429 ? LlmStatus.RateLimited : LlmStatus.Unavailable, null, null, start, exception.Status);
        }
        catch (HttpRequestException) { return Finish(LlmStatus.Unavailable, null, null, start); }
        catch (JsonException) { return Finish(LlmStatus.InvalidOutput, null, null, start); }
    }

#pragma warning disable OPENAI001 // SDK Responses options; request-shape tests guard the pinned version.
    // Responses can have a null generic finish reason on success; require its native terminal status.
    private static bool Completed(ChatResponse response) => response.RawRepresentation is ResponseResult raw
        && raw.Status == ResponseStatus.Completed;

    private static ChatOptions Options() => new()
    {
        ModelId = OpenAIClientFactory.Model,
        MaxOutputTokens = 1200,
        Reasoning = new ReasoningOptions { Effort = ReasoningEffort.Low },
        // IChatClient's generic schema mapping omits strict. Preserve native options for this provider feature.
        RawRepresentationFactory = _ => new CreateResponseOptions
        {
            StoredOutputEnabled = false,
            TextOptions = new ResponseTextOptions
            {
                TextFormat = ResponseTextFormat.CreateJsonSchemaFormat("buddy_interpret_v0",
                    BinaryData.FromString(InterpretProtocol.Schema.GetRawText()), null, true),
            },
        },
    };
#pragma warning restore OPENAI001

    private static TokenUsage? Usage(UsageDetails? usage) => usage is { InputTokenCount: >= 0, OutputTokenCount: >= 0 }
        ? new TokenUsage(usage.InputTokenCount.Value, usage.CachedInputTokenCount ?? 0, usage.OutputTokenCount.Value) : null;

    private LlmOutcome Finish(LlmStatus status, Domain.Interpretation? interpretation, TokenUsage? usage, long start, int? providerHttpStatus = null)
    {
        var elapsed = time.GetElapsedTime(start).TotalMilliseconds;
        var code = status.ToString();
        // Published standard short-context rates, 2026-10-16. Tokens include reasoning; this is an estimate, not billing.
        decimal? cost = usage is not null && usage.CachedInput >= 0 && usage.CachedInput <= usage.Input
            ? ((usage.Input - usage.CachedInput) * 0.10m + usage.CachedInput * 0.01m + usage.Output * 0.50m) / 1_000_000m : null;
        Activity.Current?.SetTag("buddy.outcome", code);
        Activity.Current?.SetTag("gen_ai.usage.input_tokens", usage?.Input);
        Activity.Current?.SetTag("gen_ai.usage.output_tokens", usage?.Output);
        Duration.Record(elapsed / 1000, new KeyValuePair<string, object?>("buddy.outcome", code));
        if (logger.IsEnabled(LogLevel.Information))
            LogOutcome(logger, code, OpenAIClientFactory.Model, InterpretProtocol.PromptVersion,
                elapsed, usage?.Input, usage?.Output, cost);
        return new(status, interpretation, OpenAIClientFactory.Model, InterpretProtocol.PromptVersion, elapsed, usage, cost, providerHttpStatus);
    }

    [LoggerMessage(Level = LogLevel.Information, Message = "Buddy {Outcome} model={Model} prompt={PromptVersion} elapsedMs={ElapsedMs} inputTokens={InputTokens} outputTokens={OutputTokens} estimatedUsd={EstimatedUsd}")]
    private static partial void LogOutcome(ILogger logger, string outcome, string model, string promptVersion,
        double elapsedMs, long? inputTokens, long? outputTokens, decimal? estimatedUsd);
}
