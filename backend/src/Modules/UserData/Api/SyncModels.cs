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
    Dictionary<string, JsonElement> Payload)
{
    internal SyncVersion ToVersion() => new(Entity, Id, SchemaVersion, Hlc, DeviceId, DeletedAt, JsonSerializer.SerializeToElement(Payload));
}

public sealed record SyncPushRequest([property: MinLength(1), MaxLength(500)] SyncChange[] Changes);

internal sealed record SyncDocument(
    [property: MinLength(1), MaxLength(64)] string Entity,
    Guid Id,
    [property: Range(1, int.MaxValue)] int SchemaVersion,
    [property: RegularExpression(SyncRules.HlcPattern)] string Hlc,
    Guid DeviceId,
    DateTimeOffset? DeletedAt,
    Dictionary<string, JsonElement> Payload,
    [property: RegularExpression(SyncRules.CursorPattern)] string ServerSeq)
{
    public static SyncDocument From(StoredVersion row) => new(row.Version.Entity, row.Version.Id, row.Version.SchemaVersion,
        row.Version.Hlc, row.Version.DeviceId, row.Version.DeletedAt,
        row.Version.Payload.Deserialize<Dictionary<string, JsonElement>>()!, row.ServerSeq);
}

internal sealed record SyncPushResult(string Entity, Guid Id, string Hlc,
    [property: RegularExpression("^(accepted|stale|invalid)$")] string Status,
    [property: RegularExpression("^(clockDrift|versionConflict|unsupported)$")] string? Reason);
internal sealed record SyncPushResponse(SyncPushResult[] Results, DateTimeOffset ServerTime);
internal sealed record SyncPage(SyncDocument[] Changes, [property: RegularExpression(SyncRules.CursorPattern)] string NextCursor);
