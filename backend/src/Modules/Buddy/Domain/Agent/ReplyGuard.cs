using System.Globalization;
using System.Text;
using System.Text.RegularExpressions;

namespace FitnessBuddy.Modules.Buddy.Domain;

internal enum GuardIssue { BareNumber, UnknownFact, BannedWord }

/// <summary>A checked model text: the rendered text (claims filled in), the issues found, and the claims it referenced.</summary>
internal sealed record GuardResult(string Rendered, GuardIssue[] Issues, Claim[] Referenced)
{
    public bool Clean => Issues.Length == 0;
}

/// <summary>
/// Code-filled claims and the guards on model text (AI-175, AI-142, SF-020; 06 §7). The model writes <c>{fact:k3}</c>; code
/// renders value, unit and the code-made label together ("640 kcal left today"). Any other number in the model's own words,
/// outside the whitelist (clock times, calendar dates, day/week counts, integers 1–10 not followed by a unit), an unknown fact
/// ID or a moral word about food is an issue; the caller rewrites once, then falls back to a template.
/// </summary>
internal static partial class ReplyGuard
{
    public static GuardResult Check(string text, IReadOnlyList<Claim> claims, string massUnit, string lengthUnit)
    {
        var issues = new HashSet<GuardIssue>(); var referenced = new List<Claim>();
        var byId = claims.ToDictionary(c => c.Id, StringComparer.Ordinal);
        var rendered = FactRef().Replace(text, m =>
        {
            if (!byId.TryGetValue(m.Groups[1].Value, out var claim)) { issues.Add(GuardIssue.UnknownFact); return "§"; }
            referenced.Add(claim); return Render(claim, massUnit, lengthUnit);
        });
        var own = Normalize(FactRef().Replace(text, " § "));
        if (BareNumbers(own)) { issues.Add(GuardIssue.BareNumber); }
        if (Banned().IsMatch(own)) { issues.Add(GuardIssue.BannedWord); }
        return new(Spaces().Replace(rendered, " ").Trim(), [.. issues.Order()], [.. referenced.Distinct()]);
    }

    /// <summary>A claim as words: value and unit in the profile's units, then its label ("2,100 kcal target today").</summary>
    public static string Render(Claim claim, string massUnit, string lengthUnit)
    {
        if (claim.Unit == "date" || claim.Value is null)
        {
            var day = claim.Date?.ToString("MMM d", CultureInfo.InvariantCulture) ?? "an unknown day";
            return $"{claim.Label} on {day}".Trim();
        }
        var v = claim.Value.Value;
        var value = claim.Unit switch
        {
            "kcal" => Number(v, 0) + " kcal",
            "g" => Number(v, Math.Abs(v) < 10 ? 1 : 0) + " g",
            "kg" when massUnit == "lb" => Number(v * 2.2046226218, 1) + " lb",
            "kg" => Number(v, 1) + " kg",
            "cm" when lengthUnit == "in" => Number(v / 2.54, 1) + " in",
            "cm" => Number(v, 1) + " cm",
            "percent" => Number(v, 1) + "%",
            "count" => Number(v, 0),
            _ => Number(v, 1) + " " + claim.Unit,
        };
        return claim.Label.Length > 0 ? value + " " + claim.Label : value;
    }

    private static string Number(double value, int digits) =>
        Math.Round(value, digits, MidpointRounding.AwayFromZero).ToString(digits == 0 ? "#,0" : "#,0.#", CultureInfo.InvariantCulture);

    private static bool BareNumbers(string text)
    {
        // Calendar dates and clock times first (2026-11-06, 6/11, 6/11/2026, 07:30, 7 pm).
        var rest = Whitelisted().Replace(text, " ");
        foreach (Match m in NumberToken().Matches(rest))
        {
            var after = rest[(m.Index + m.Length)..];
            var before = rest[..m.Index];
            if (DayCount().IsMatch(after)) { continue; }
            if (MonthAfter().IsMatch(after) || MonthBefore().IsMatch(before)) { continue; }
            var small = !m.Value.Contains('.', StringComparison.Ordinal) && !m.Value.Contains(',', StringComparison.Ordinal)
                && int.TryParse(m.Value, NumberStyles.None, CultureInfo.InvariantCulture, out var n) && n is >= 1 and <= 10;
            if (small && !UnitAfter().IsMatch(after)) { continue; }
            return true;
        }
        return false;
    }

    private static string Normalize(string text)
    {
        var sb = new StringBuilder(text.Length);
        foreach (var c in text)
        {
            sb.Append(c switch { >= '٠' and <= '٩' => (char)('0' + (c - '٠')), >= '۰' and <= '۹' => (char)('0' + (c - '۰')), '٫' => '.', _ => c });
        }
        return sb.ToString();
    }

    [GeneratedRegex(@"\{\s*fact\s*:\s*([A-Za-z0-9]{1,12})\s*\}")] private static partial Regex FactRef();
    // Digits glued to a letter on the left are part of a name ("B25", "Coke Zero 330ml" still counts: the number starts a token).
    [GeneratedRegex(@"(?<![\p{L}0-9_.,])[0-9]+(?:[.,][0-9]+)*")] private static partial Regex NumberToken();
    [GeneratedRegex(@"\b[0-9]{4}-[0-9]{2}-[0-9]{2}\b|\b[0-9]{1,2}/[0-9]{1,2}(?:/[0-9]{2,4})?\b|\b[0-9]{1,2}:[0-9]{2}\b|\b[0-9]{1,2}\s?(?:am|pm|a\.m\.|p\.m\.)", RegexOptions.IgnoreCase)]
    private static partial Regex Whitelisted();
    [GeneratedRegex(@"^\s*(?:days?|weeks?|weekdays?|nights?)\b", RegexOptions.IgnoreCase)] private static partial Regex DayCount();
    [GeneratedRegex(@"^(?:st|nd|rd|th)?\s*(?:of\s+)?(?:jan|feb|mar|apr|may|jun|jul|aug|sep|sept|oct|nov|dec)[a-z]*\b", RegexOptions.IgnoreCase)] private static partial Regex MonthAfter();
    [GeneratedRegex(@"\b(?:jan|feb|mar|apr|may|jun|jul|aug|sep|sept|oct|nov|dec)[a-z]*\.?\s*$", RegexOptions.IgnoreCase)] private static partial Regex MonthBefore();
    [GeneratedRegex(@"^\s*(?:kcal|cal|calories?|kj|mg|g|grams?|gr|kg|kgs|kilos?|lbs?|pounds?|oz|ml|l|lit(?:er|re)s?|cm|inch(?:es)?|%|percent|cups?|tsp|teaspoons?|tbsp|tablespoons?|servings?|portions?|pieces?|pcs?|plates?|loaf|loaves|slices?|scoops?|handfuls?)\b|^\s*%", RegexOptions.IgnoreCase)]
    private static partial Regex UnitAfter();
    [GeneratedRegex(@"\b(?:cheat(?:s|ed|ing)?|guilt(?:y|ily)?|sinful|clean[\s-]eating|junk(?:\s+food)?|(?:good|bad)\s+foods?|naughty|bad\s+(?:choices?|for\s+you))\b", RegexOptions.IgnoreCase)]
    private static partial Regex Banned();
    [GeneratedRegex(@"[ \t]{2,}")] private static partial Regex Spaces();
}
