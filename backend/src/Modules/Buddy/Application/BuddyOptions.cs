namespace FitnessBuddy.Modules.Buddy.Application;

/// <summary>
/// Buddy on or off, the provider and its key file (config <c>Buddy</c>, TD-129): <c>openai</c> (default, <see cref="ApiKeyFile"/>)
/// or <c>anthropic</c> (<see cref="AnthropicApiKeyFile"/>). The agent's limits are <see cref="BuddyAgentOptions"/>.
/// </summary>
internal sealed class BuddyOptions
{
    public const string OpenAI = "openai";
    public const string Anthropic = "anthropic";

    public bool Enabled { get; set; }
    public string Provider { get; set; } = OpenAI;
    /// <summary>The OpenAI key file.</summary>
    public string ApiKeyFile { get; set; } = "";
    public string AnthropicApiKeyFile { get; set; } = "";
    /// <summary>Claude <c>output_config.effort</c> for agent steps: low, medium or high (<c>between_tools</c> rejects higher).</summary>
    public string AnthropicEffort { get; set; } = "medium";
    /// <summary>Claude server-side refusal fallback (<c>fallbacks: "default"</c>, beta). Off: TD-067/TD-124 say no provider fallback.</summary>
    public bool AnthropicServerFallback { get; set; }

    /// <summary>The active provider's key file.</summary>
    public string KeyFile => Provider == Anthropic ? AnthropicApiKeyFile : ApiKeyFile;

    // Server fallback stays rejected for now (Codex B27 #3): a fallback attempt runs and bills another model, reported in
    // usage.iterations, which the adapter doesn't aggregate; the ledger would record Sonnet usage and price. Allow it only
    // with per-attempt model, usage and pricing (and the owner's OK, TD-067).
    public bool Valid() => (Provider is OpenAI or Anthropic) && (AnthropicEffort is "low" or "medium" or "high") && !AnthropicServerFallback
        && (!Enabled || Path.IsPathFullyQualified(KeyFile));
}

/// <summary>A provider call's reported token counts.</summary>
internal sealed record TokenUsage(long Input, long CachedInput, long Output);
