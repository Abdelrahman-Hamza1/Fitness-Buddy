using System.Globalization;
using System.Text.RegularExpressions;

namespace FitnessBuddy.Modules.Admin.Domain;

/// <summary>
/// Pure rules for the account controls (B24, AD-007, AD-011). Account controls take reason <b>codes</b>, never free text
/// (R#7), so no email or user content can enter an audit row next to an account id.
/// </summary>
internal static partial class AccountControlRules
{
    /// <summary>The closed reason codes, in the order the form lists them.</summary>
    public static readonly IReadOnlyList<string> ReasonCodes = ["owner-request", "test-account", "security", "abuse", "support", "other"];

    public static bool IsReason(string? code) => code is not null && ReasonCodes.Contains(code, StringComparer.Ordinal);

    /// <summary>AD-007: the typed account id must be this account's (any UUID spelling, surrounding spaces ignored).</summary>
    public static bool TypedIdMatches(string? typed, Guid account) =>
        typed is { Length: > 0 and <= 64 } && Guid.TryParse(typed.Trim(), out var parsed) && parsed == account;

    /// <summary>An opaque device key: 32 lowercase hex characters.</summary>
    public static bool IsDeviceKey(string? key) => key is not null && DeviceKeyPattern().IsMatch(key);

    /// <summary>
    /// The Buddy limit field: empty = the default (null), else a whole number 0–1000 (0 = Buddy off for this account).
    /// </summary>
    public static bool TryParseLimit(string? input, out int? dailyCalls)
    {
        dailyCalls = null;
        if (string.IsNullOrWhiteSpace(input)) { return true; }
        if (!int.TryParse(input.Trim(), NumberStyles.None, CultureInfo.InvariantCulture, out var value) || value > 1000) { return false; }
        dailyCalls = value;
        return true;
    }

    [GeneratedRegex("^[0-9a-f]{32}$", RegexOptions.CultureInvariant)]
    private static partial Regex DeviceKeyPattern();
}
