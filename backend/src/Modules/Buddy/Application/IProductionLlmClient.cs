using FitnessBuddy.Modules.Buddy.Domain;

namespace FitnessBuddy.Modules.Buddy.Application;

internal sealed record ProductionOutcome(LlmStatus Status, ParsedMessage? Message, TokenUsage? Usage, decimal? EstimatedUsd);
internal interface IProductionLlmClient
{
    Task<ProductionOutcome> ParseAsync(InterpretInput input, bool repair, CancellationToken cancellationToken);
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
