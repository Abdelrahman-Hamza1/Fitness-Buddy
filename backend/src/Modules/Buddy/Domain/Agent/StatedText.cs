using System.Globalization;
using System.Text.RegularExpressions;

namespace FitnessBuddy.Modules.Buddy.Domain;

/// <summary>Whole-span containment: a needle counts only where the characters around it are no letter, digit or decimal point.</summary>
internal static class Spans
{
    public static bool Contains(string haystack, string needle)
    {
        if (needle.Length == 0) { return false; }
        for (var at = haystack.IndexOf(needle, StringComparison.Ordinal); at >= 0; at = haystack.IndexOf(needle, at + 1, StringComparison.Ordinal))
        {
            var before = at == 0 || !Glue(haystack[at - 1]) || !Glue(needle[0]);
            var end = at + needle.Length;
            var after = end == haystack.Length || !Glue(haystack[end]) || !Glue(needle[^1]);
            if (before && after) { return true; }
        }
        return false;
    }

    private static bool Glue(char c) => char.IsLetterOrDigit(c) || c == '.';
}

internal enum QuantityUnit { Plain, Minutes, Seconds, Km, Meters, Kg, Lb }
internal sealed record Quantity(decimal Value, QuantityUnit Unit);

/// <summary>
/// The quantities a piece of the user's text states, each bound to the unit written right after it (Codex B26 #4): "5 min" is
/// five minutes, never five kilometres. A number without a known unit is plain (reps, a set count, or a load in the profile unit).
/// </summary>
internal static partial class StatedQuantities
{
    public static Quantity[] Parse(string text) =>
        [.. Token().Matches(SetNotation.Normalize(text)).Select(m => new Quantity(decimal.Parse(m.Groups["n"].Value, NumberStyles.AllowDecimalPoint, CultureInfo.InvariantCulture), m.Groups["u"].Value switch
        {
            "min" or "mins" or "minute" or "minutes" => QuantityUnit.Minutes,
            "s" or "sec" or "secs" or "second" or "seconds" => QuantityUnit.Seconds,
            "km" or "kms" => QuantityUnit.Km,
            "m" or "meter" or "meters" or "metre" or "metres" => QuantityUnit.Meters,
            "kg" or "kgs" or "kilo" or "kilos" => QuantityUnit.Kg,
            "lb" or "lbs" or "pound" or "pounds" => QuantityUnit.Lb,
            _ => QuantityUnit.Plain,
        }))];

    [GeneratedRegex(@"(?<![0-9.])(?<n>[0-9]{1,6}(?:\.[0-9]{1,3})?)(?![0-9])(?:\s*(?<u>minutes?|mins?|seconds?|secs?|s|kms?|kilos?|kgs?|lbs?|pounds?|meters?|metres?|m)(?![a-z]))?")]
    private static partial Regex Token();
}

/// <summary>
/// A row date read by code from the pasted original (Codex B26 #7): ISO <c>2025-10-10</c>, or a month name with a day and a
/// four-digit year in either order ("oct 10 2025", "10 October, 2025", "Oct 10th, 2025"). Anything else, including numeric
/// day/month forms, is null: the app's review table flags it (WB-031). The model's date is never used.
/// </summary>
internal static partial class ImportDates
{
    public static DateOnly? Parse(string original)
    {
        var t = original.ToLowerInvariant();
        if (Iso().Match(t) is { Success: true } iso)
        {
            return Make(Int(iso, "y"), Int(iso, "m"), Int(iso, "d"));
        }
        if (MonthFirst().Match(t) is { Success: true } a && Month(a.Groups["mon"].Value) is { } m1) { return Make(Int(a, "y"), m1, Int(a, "d")); }
        if (DayFirst().Match(t) is { Success: true } b && Month(b.Groups["mon"].Value) is { } m2) { return Make(Int(b, "y"), m2, Int(b, "d")); }
        return null;
    }

    private static DateOnly? Make(int year, int month, int day) =>
        year is >= 1900 and <= 2200 && month is >= 1 and <= 12 && day >= 1 && day <= DateTime.DaysInMonth(year, month) ? new DateOnly(year, month, day) : null;

    private static int? Month(string name) =>
        Array.FindIndex(Months, m => name.StartsWith(m, StringComparison.Ordinal)) is var i and >= 0 ? i + 1 : null;

    private static readonly string[] Months = ["jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec"];
    private static int Int(Match m, string g) => int.Parse(m.Groups[g].Value, NumberStyles.None, CultureInfo.InvariantCulture);

    [GeneratedRegex(@"(?<![0-9])(?<y>[0-9]{4})-(?<m>[0-9]{1,2})-(?<d>[0-9]{1,2})(?![0-9])")] private static partial Regex Iso();
    [GeneratedRegex(@"\b(?<mon>jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\.?\s+(?<d>[0-9]{1,2})(?:st|nd|rd|th)?,?\s+(?<y>[0-9]{4})(?![0-9])")] private static partial Regex MonthFirst();
    [GeneratedRegex(@"(?<![0-9])(?<d>[0-9]{1,2})(?:st|nd|rd|th)?\s+(?:of\s+)?(?<mon>jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\.?,?\s+(?<y>[0-9]{4})(?![0-9])")] private static partial Regex DayFirst();
}
