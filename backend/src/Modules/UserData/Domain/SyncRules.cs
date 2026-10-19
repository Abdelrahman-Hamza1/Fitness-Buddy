using System.Globalization;
using System.Text.RegularExpressions;

namespace FitnessBuddy.Modules.UserData.Domain;

internal static partial class SyncRules
{
    public const string HlcPattern = "^[0-9]{13}-[0-9]{5}-[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$";
    public const string CursorPattern = "^(0|[1-9][0-9]{0,18})$";

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
