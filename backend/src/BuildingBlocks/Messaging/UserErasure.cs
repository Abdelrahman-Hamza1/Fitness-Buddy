namespace FitnessBuddy.BuildingBlocks.Messaging;

/// <summary>Database-only account lifecycle event; envelope ID supplies deduplication identity.</summary>
public sealed record UserErasure(Guid UserId)
{
    public const string EventType = "account.user-erasure.v1";
}

/// <summary>Every installed module classifies all tables; user storage requires a registered eraser.</summary>
public sealed record UserDataOwnership(string[] UserTables, string[] GlobalTables, string? Eraser);
