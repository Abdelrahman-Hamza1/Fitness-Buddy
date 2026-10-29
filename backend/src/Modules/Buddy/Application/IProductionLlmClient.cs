using FitnessBuddy.Modules.Buddy.Domain;

namespace FitnessBuddy.Modules.Buddy.Application;

/// <summary><c>Invalid</c> is the closed PA13 code of an invalid output (never content); null otherwise.</summary>
internal sealed record ProductionOutcome(LlmStatus Status, ParsedMessage? Message, TokenUsage? Usage, decimal? EstimatedUsd, InvalidOutput? Invalid = null);
internal interface IProductionLlmClient
{
    // repairOf: null for the first attempt; the first attempt's invalid-output code for B08's single repair.
    Task<ProductionOutcome> ParseAsync(InterpretInput input, InvalidOutput? repairOf, CancellationToken cancellationToken);
}
internal sealed class BuddyOptions
{
    public bool Enabled { get; set; }
    public string ApiKeyFile { get; set; } = "";
    public int MaxOutputTokens { get; set; } = 1600;
    public int TimeoutSeconds { get; set; } = 20;
    public int Concurrency { get; set; } = 2;
    public int RegisteredDailyCalls { get; set; } = 100;
    public int GuestDailyCalls { get; set; } = 30;
}
