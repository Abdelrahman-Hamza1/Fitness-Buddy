using FitnessBuddy.BuildingBlocks.Features;
using FitnessBuddy.Modules.Buddy.Domain;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace FitnessBuddy.Modules.Buddy.Application;

/// <summary>The model's label transcription, or why there is none (content-free).</summary>
internal sealed record LabelRead(AgentModelStatus Status, LabelReading? Reading, TokenUsage? Usage, decimal? EstimatedUsd, double ElapsedMs);

/// <summary>One structured vision call over a label photo (06 §8, label-v1); no tools, no retries.</summary>
internal interface ILabelReader
{
    Task<LabelRead> ReadAsync(string imageBase64, CancellationToken cancellationToken);
}

internal enum LabelStatus { Ok, Unauthorized, Limited, Unavailable }
internal sealed record LabelOutcome(LabelStatus Status, BuddyLabelExtraction? Extraction = null, int? Limit = null);

/// <summary>
/// <c>POST /v1/buddy/label</c> (FD-040–042, B26 WP5): reserve one allowance message and one send (no provider call when denied),
/// one vision call, record its usage, then code turns the transcription into the public extraction (B26 D2). Nothing is stored.
/// The log line holds the outcome, model, prompt version, timing and tokens only.
/// </summary>
internal sealed partial class ExtractLabel(IAgentLedger ledger, ILabelReader reader, AgentConcurrency concurrency, IOptions<BuddyOptions> buddy,
    IFeatureFlags flags, ILogger<ExtractLabel> logger)
{
    public const string PromptVersion = "label-v1";

    public async Task<LabelOutcome> ExecuteAsync(string imageBase64, bool guest, CancellationToken cancellationToken)
    {
        if (!buddy.Value.Enabled || !flags.IsEnabled("buddy.ai")) { return new(LabelStatus.Unavailable); }
        if (!concurrency.Enter()) { return new(LabelStatus.Unavailable); }
        try
        {
            var gate = await ledger.ReserveLabelAsync(guest, cancellationToken);
            if (gate.Status == RoundGateStatus.Unauthorized) { return new(LabelStatus.Unauthorized); }
            if (gate.Status == RoundGateStatus.Limited) { return new(LabelStatus.Limited, Limit: gate.Limit); }
            var read = await reader.ReadAsync(imageBase64, cancellationToken);
            using (var persist = new CancellationTokenSource(TimeSpan.FromSeconds(5)))
            { await ledger.RecordLabelAsync(read.Usage, read.EstimatedUsd, persist.Token); }
            var ok = read.Status == AgentModelStatus.Success && read.Reading is not null;
            LogRead(logger, ok ? "ok" : BuddyAgent.JsonCode(read.Status), read.Reading?.Found, PromptVersion, read.ElapsedMs, read.Usage?.Input, read.Usage?.Output);
            return ok ? new(LabelStatus.Ok, LabelRules.Extract(read.Reading!)) : new(LabelStatus.Unavailable);
        }
        finally { concurrency.Leave(); }
    }

    [LoggerMessage(Level = LogLevel.Information, Message = "Buddy label outcome={Outcome} found={Found} prompt={PromptVersion} elapsedMs={ElapsedMs} inputTokens={InputTokens} outputTokens={OutputTokens}")]
    private static partial void LogRead(ILogger logger, string outcome, bool? found, string promptVersion, double elapsedMs, long? inputTokens, long? outputTokens);
}
