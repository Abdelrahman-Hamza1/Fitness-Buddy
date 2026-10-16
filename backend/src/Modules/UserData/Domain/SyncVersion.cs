using System.Text.Json;

namespace FitnessBuddy.Modules.UserData.Domain;

internal sealed record SyncVersion(string Entity, Guid Id, int SchemaVersion, string Hlc, Guid DeviceId, DateTimeOffset? DeletedAt, JsonElement Payload);
internal sealed record StoredVersion(SyncVersion Version, string ServerSeq);
internal sealed record VersionResult(string Entity, Guid Id, string Hlc, string Status, string? Reason);
internal sealed record VersionPage(IReadOnlyList<StoredVersion> Changes, string NextCursor);
internal sealed record PushOutcome(IReadOnlyList<VersionResult> Results, DateTimeOffset ServerTime);
