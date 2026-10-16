using FitnessBuddy.Modules.Buddy.Domain;

namespace FitnessBuddy.Modules.Buddy.Application;

/// <summary>Interpret text into proposal input only. Failures preserve the caller's pending message (AI-153).</summary>
internal interface ILlmClient
{
    Task<LlmOutcome> InterpretAsync(string text, CancellationToken cancellationToken);
}

internal enum LlmStatus { Success, InvalidInput, InvalidOutput, Refused, Incomplete, Timeout, Cancelled, RateLimited, Unavailable }
internal sealed record TokenUsage(long Input, long CachedInput, long Output);
internal sealed record LlmOutcome(LlmStatus Status, Interpretation? Interpretation, string Model,
    string PromptVersion, double ElapsedMs, TokenUsage? Usage, decimal? EstimatedUsd, int? ProviderHttpStatus = null);
