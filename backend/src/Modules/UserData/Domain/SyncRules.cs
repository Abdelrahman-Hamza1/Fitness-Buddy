using System.Collections.Frozen;
using System.Globalization;
using System.Text.RegularExpressions;

namespace FitnessBuddy.Modules.UserData.Domain;

internal static partial class SyncRules
{
    public const string HlcPattern = "^[0-9]{13}-[0-9]{5}-[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$";
    public const string CursorPattern = "^(0|[1-9][0-9]{0,18})$";

    // TD-114 (A62 D23): entities whose newer schema versions carry facts an older writer would erase
    // (diaryEntry/savedMealItem v2 estimate flags, dayMark v2 day estimate). A version below the
    // stored document's schema version is refused whatever its HLC, so an old build editing its v1
    // copy can't overwrite v2. weighIn keeps plain last-write-wins across versions.
    public static readonly FrozenSet<string> DowngradeProtected = FrozenSet.Create(StringComparer.Ordinal, "dayMark", "diaryEntry", "savedMealItem");

    public static bool IsRefusedDowngrade(string entity, int incomingSchemaVersion, int storedSchemaVersion) =>
        incomingSchemaVersion < storedSchemaVersion && DowngradeProtected.Contains(entity);

    public static bool IsHlc(string text) => HlcRegex().IsMatch(text) && text.Length == 56;

    public static string? InvalidReason(SyncVersion version, DateTimeOffset now)
    {
        if (version.Entity.Length is < 1 or > 64 || version.SchemaVersion < 1 ||
            !IsHlc(version.Hlc) || version.Hlc[20..] != version.DeviceId.ToString()) { return "unsupported"; }
        var wall = long.Parse(version.Hlc.AsSpan(0, 13), CultureInfo.InvariantCulture);
        return wall > now.ToUnixTimeMilliseconds() + 300_000 ? "clockDrift" : null;
    }

    [GeneratedRegex(HlcPattern, RegexOptions.CultureInvariant)]
    private static partial Regex HlcRegex();
}
