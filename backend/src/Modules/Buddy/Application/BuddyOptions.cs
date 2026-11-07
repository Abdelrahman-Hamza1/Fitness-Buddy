namespace FitnessBuddy.Modules.Buddy.Application;

/// <summary>Buddy on or off and the provider key file (config <c>Buddy</c>); the agent's limits are <see cref="BuddyAgentOptions"/>.</summary>
internal sealed class BuddyOptions
{
    public bool Enabled { get; set; }
    public string ApiKeyFile { get; set; } = "";
}

/// <summary>A provider call's reported token counts.</summary>
internal sealed record TokenUsage(long Input, long CachedInput, long Output);
