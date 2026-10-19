using System.ComponentModel.DataAnnotations;
using System.Text.Json;
using FitnessBuddy.Modules.UserData.Domain;

namespace FitnessBuddy.Modules.UserData.Api;

public sealed record SyncChange(
    [property: MinLength(1), MaxLength(64)] string Entity,
    Guid Id,
    [property: Range(1, int.MaxValue)] int SchemaVersion,
    [property: RegularExpression(SyncRules.HlcPattern)] string Hlc,
    Guid DeviceId,
    DateTimeOffset? DeletedAt,
    JsonElement Payload)
{
    internal SyncVersion ToVersion() => new(Entity, Id, SchemaVersion, Hlc, DeviceId, DeletedAt, Payload);
}

public sealed record SyncPushRequest([property: MinLength(1), MaxLength(500)] SyncChange[] Changes)
{
    public Guid? DatasetId { get; init; }
}

internal sealed record SyncDocument(
    [property: MinLength(1), MaxLength(64)] string Entity,
    Guid Id,
    [property: Range(1, int.MaxValue)] int SchemaVersion,
    [property: RegularExpression(SyncRules.HlcPattern)] string Hlc,
    Guid DeviceId,
    DateTimeOffset? DeletedAt,
    Dictionary<string, JsonElement> Payload,
    [property: RegularExpression(SyncRules.CursorPattern)] string ServerSeq, bool Compacted)
{
    public static SyncDocument From(StoredVersion row) => new(row.Version.Entity, row.Version.Id, row.Version.SchemaVersion,
        row.Version.Hlc, row.Version.DeviceId, row.Version.DeletedAt,
        row.Version.Payload.Deserialize<Dictionary<string, JsonElement>>()!, row.ServerSeq, row.Compacted);
}

internal sealed record SyncPushResult(string Entity, Guid Id, string Hlc,
    [property: RegularExpression("^(accepted|stale|invalid)$")] string Status,
    [property: RegularExpression("^(clockDrift|versionConflict|unsupported|invalidPayload|datasetMismatch)$")] string? Reason);
internal sealed record SyncPushResponse(SyncPushResult[] Results, DateTimeOffset ServerTime, Guid DatasetId);
internal sealed record SyncPage(SyncDocument[] Changes, [property: RegularExpression(SyncRules.CursorPattern)] string NextCursor, Guid DatasetId, DateTimeOffset ServerTime,
    [property: RegularExpression("^(datasetMismatch|cursorInvalid)$")] string? Reason);
