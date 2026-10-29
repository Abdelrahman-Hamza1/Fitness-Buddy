using System.ClientModel;
using System.Diagnostics;
using System.Diagnostics.Metrics;
using System.Text.Json;
using FitnessBuddy.Modules.Buddy.Application;
using FitnessBuddy.Modules.Buddy.Domain;
using Microsoft.Extensions.AI;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using OpenAI.Responses;

namespace FitnessBuddy.Modules.Buddy.Infrastructure;

internal sealed partial class ProductionLlmClient(IChatClient client, TimeProvider clock, IOptions<BuddyOptions> options,
    ILogger<ProductionLlmClient> logger) : IProductionLlmClient
{
    private static readonly ActivitySource Activities = new("FitnessBuddy.Buddy");
    private static readonly Meter Metrics = new("FitnessBuddy.Buddy");
    private static readonly Histogram<double> Duration = Metrics.CreateHistogram<double>("gen_ai.client.operation.duration", "s");
    public async Task<ProductionOutcome> ParseAsync(InterpretInput input, InvalidOutput? repairOf, CancellationToken cancellationToken)
    {
        var start = clock.GetTimestamp();
        using var activity = Activities.StartActivity("interpret", ActivityKind.Client);
        activity?.SetTag("gen_ai.provider.name", "openai"); activity?.SetTag("gen_ai.request.model", OpenAIClientFactory.Model);
        activity?.SetTag("buddy.prompt.version", ProductionProtocol.Version);
        using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(options.Value.TimeoutSeconds), clock);
        using var linked = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken, timeout.Token);
        var status = LlmStatus.Unavailable; ParsedMessage? message = null; TokenUsage? usage = null; InvalidOutput? invalid = null;
        try
        {
            var response = await client.GetResponseAsync([new(ChatRole.System, ProductionProtocol.Prompt + Repair(repairOf)),
                new(ChatRole.User, ProductionProtocol.Input(input))], Options(), linked.Token);
            if (response.Usage is { InputTokenCount: >= 0, OutputTokenCount: >= 0 } u) { usage = new(u.InputTokenCount.Value, u.CachedInputTokenCount ?? 0, u.OutputTokenCount.Value); }
            status = Completed(response) ? LlmStatus.InvalidOutput : response.FinishReason == ChatFinishReason.Length ? LlmStatus.Incomplete : LlmStatus.Refused;
            if (status == LlmStatus.InvalidOutput)
            {
                (message, invalid) = ProductionProtocol.Parse(response.Text, input); if (message is not null) { status = LlmStatus.Success; }
            }
        }
        catch (OperationCanceledException) { status = cancellationToken.IsCancellationRequested ? LlmStatus.Cancelled : LlmStatus.Timeout; }
        catch (ClientResultException e) { status = e.Status == 429 ? LlmStatus.RateLimited : LlmStatus.Unavailable; }
        catch (HttpRequestException) { status = LlmStatus.Unavailable; }
        catch (JsonException) { status = LlmStatus.InvalidOutput; invalid = InvalidOutput.Shape; }
        decimal? cost = usage is { CachedInput: >= 0 } && usage.CachedInput <= usage.Input
            ? ((usage.Input - usage.CachedInput) * .10m + usage.CachedInput * .01m + usage.Output * .50m) / 1_000_000m : null;
        var elapsed = clock.GetElapsedTime(start).TotalMilliseconds; var code = status.ToString();
        // A closed PA13 code, never content: it says which rule failed, not what the model wrote.
        var invalidCode = status == LlmStatus.InvalidOutput ? Name(invalid ?? InvalidOutput.Shape) : null;
        activity?.SetTag("buddy.outcome", code); activity?.SetTag("buddy.invalid_output", invalidCode); activity?.SetTag("gen_ai.usage.input_tokens", usage?.Input); activity?.SetTag("gen_ai.usage.output_tokens", usage?.Output);
        Duration.Record(elapsed / 1000, new KeyValuePair<string, object?>("buddy.outcome", code));
        if (logger.IsEnabled(LogLevel.Information)) { LogOutcome(logger, code, OpenAIClientFactory.Model, ProductionProtocol.Version, invalidCode, elapsed, usage?.Input, usage?.Output, cost); }
        return new(status, message, usage, cost, status == LlmStatus.InvalidOutput ? invalid ?? InvalidOutput.Shape : null);
    }
    // The repair names the failed rule by its closed code only; the invalid output itself is never echoed back.
    private static string Repair(InvalidOutput? code) => code is { } failed
        ? $"\nPrevious output was invalid ({Name(failed)}). Return a complete schema-valid interpretation that follows every rule above. Do not repeat an invalid structure."
        : "";
    private static string Name(InvalidOutput code) => JsonNamingPolicy.CamelCase.ConvertName(code.ToString());
#pragma warning disable OPENAI001
    private static bool Completed(ChatResponse response) => response.RawRepresentation is ResponseResult { Status: ResponseStatus.Completed }
        && !response.Messages.SelectMany(m => m.Contents).Any(c => c is ErrorContent);
    private ChatOptions Options() => new()
    {
        ModelId = OpenAIClientFactory.Model,
        MaxOutputTokens = options.Value.MaxOutputTokens,
        Reasoning = new ReasoningOptions { Effort = ReasoningEffort.Low },
        RawRepresentationFactory = _ => new CreateResponseOptions
        {
            StoredOutputEnabled = false,
            TextOptions = new ResponseTextOptions { TextFormat = ResponseTextFormat.CreateJsonSchemaFormat(ProductionProtocol.SchemaName, BinaryData.FromString(ProductionProtocol.Schema.GetRawText()), null, true) },
        },
    };
#pragma warning restore OPENAI001
    [LoggerMessage(Level = LogLevel.Information, Message = "Buddy {Outcome} model={Model} prompt={PromptVersion} invalid={InvalidOutput} elapsedMs={ElapsedMs} inputTokens={InputTokens} outputTokens={OutputTokens} estimatedUsd={EstimatedUsd}")]
    private static partial void LogOutcome(ILogger logger, string outcome, string model, string promptVersion, string? invalidOutput, double elapsedMs, long? inputTokens, long? outputTokens, decimal? estimatedUsd);
}
