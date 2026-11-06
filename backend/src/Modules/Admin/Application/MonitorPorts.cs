namespace FitnessBuddy.Modules.Admin.Application;

/// <summary>The API's readiness as the console sees it: null when no probe URL is configured.</summary>
internal interface IApiHealth
{
    Task<bool?> ReadyAsync(CancellationToken cancellationToken);
}

/// <summary>The last backup the controller recorded. <paramref name="CompletedAt"/> is null when the file is missing or unreadable.</summary>
internal sealed record BackupState(DateTimeOffset? CompletedAt, bool Ok);

/// <summary>The backup status file: null when none is configured.</summary>
internal interface IBackupStatus
{
    BackupState? Read();
}
