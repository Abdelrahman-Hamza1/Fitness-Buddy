namespace FitnessBuddy.BuildingBlocks.Recovery;

/// <summary>Protected live control state; never restore this directory from a database backup.</summary>
public sealed class RecoveryOptions
{
    public string Directory { get; set; } = "";
}

/// <summary>Only a fixed failure category crosses HTTP/log boundaries.</summary>
public sealed class RecoveryUnavailableException : Exception
{
    public RecoveryUnavailableException() : base("Protected recovery state is unavailable.") { }
}
