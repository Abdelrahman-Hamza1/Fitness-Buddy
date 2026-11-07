using System.Globalization;
using System.Text;
using System.Text.RegularExpressions;

namespace FitnessBuddy.Modules.Buddy.Domain;

/// <summary>One parsed set: reps, the load (as written: added load for bodyweight exercises), its unit, or a cardio duration/distance.</summary>
internal sealed record NotationSet(int? Reps, double? Weight, BuddyLoadUnit? Unit, int? DurationSeconds, double? DistanceMeters);

/// <summary>What a notation says: its sets, or only a load (<c>"bench 82.5"</c> on a copied session).</summary>
internal sealed record NotationResult(NotationSet[] Sets, bool LoadOnly);

/// <summary>
/// The deterministic set-notation grammar (WO-031, B26 D6): code reads the numbers of a workout line, the model only says which
/// text belongs to which exercise. Covers <c>3x8 80</c>, <c>3×8@80kg</c>, <c>80x8x3</c>, <c>8,8,7 @80</c>, <c>80x8, 85x6, 85x5</c>,
/// <c>+10 3x8</c>, <c>3 sets of 8 at 80</c>, bodyweight <c>3x12</c>, a load alone (<c>82.5</c>), and cardio (<c>30 min</c>,
/// <c>5 km</c>, <c>25:30</c>). Anything else is null: the caller then accepts only numbers the user stated.
/// </summary>
internal static partial class SetNotation
{
    private const int MaxSets = 50;

    public static NotationResult? Parse(string? notation)
    {
        if (string.IsNullOrWhiteSpace(notation) || notation.Length > 200) { return null; }
        var t = Normalize(notation);
        if (Cardio(t) is { } cardio) { return new([cardio], false); }
        Match m;
        if ((m = SetsRepsLoad().Match(t)).Success)
        {
            return Repeat(Int(m, "s"), new(Int(m, "r"), Num(m, "w"), Unit(m), null, null));
        }
        if ((m = LoadThenSetsReps().Match(t)).Success)
        {
            return Repeat(Int(m, "s"), new(Int(m, "r"), Num(m, "w"), Unit(m), null, null));
        }
        if ((m = Triple().Match(t)).Success)
        {
            double a = Num(m, "a")!.Value; int b = Int(m, "b"); double c = Num(m, "c")!.Value;
            bool unitA = m.Groups["u"].Length > 0, unitC = m.Groups["u2"].Length > 0;
            // A unit says which end is the load (Codex B26 #8). Without one: 80x8x3 (load-sized first, small last) is
            // load × reps × sets, 3x8x80 the reverse; anything else is ambiguous and not read.
            var loadFirst = unitA && !unitC || !unitA && !unitC && a > 10 && c <= 10;
            var loadLast = unitC && !unitA || !unitA && !unitC && a <= 10 && c > 10;
            if (loadFirst && c == Math.Floor(c)) { return Repeat((int)c, new(b, a, Unit(m), null, null)); }
            if (loadLast && a == Math.Floor(a)) { return Repeat((int)a, new(b, c, Unit(m, "u2"), null, null)); }
            return null;
        }
        if ((m = RepsListAtLoad().Match(t)).Success)
        {
            var load = Num(m, "w"); var unit = Unit(m);
            var reps = m.Groups["reps"].Value.Split([',', '/'], StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
            return reps.Length is > 0 and <= MaxSets ? Valid(reps.Select(r => new NotationSet(I(r), load, unit, null, null)).ToArray()) : null;
        }
        if ((m = SetsOf().Match(t)).Success)
        {
            return Repeat(Int(m, "s"), new(Int(m, "r"), Num(m, "w"), Unit(m), null, null));
        }
        var items = t.Split([',', ';'], StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
        if (items.Length > 0 && items.All(i => LoadByReps().IsMatch(i)))
        {
            var sets = new List<NotationSet>();
            foreach (var item in items)
            {
                var p = LoadByReps().Match(item);
                double a = Num(p, "w")!.Value; int r = Int(p, "r");
                // A lone "3x12" without a unit is sets × reps (bodyweight); "80x8" is load × reps.
                if (items.Length == 1 && a <= 10 && a == Math.Floor(a) && p.Groups["u"].Length == 0) { return Repeat((int)a, new(r, null, null, null, null)); }
                sets.Add(new(r, a, Unit(p), null, null));
            }
            return sets.Count <= MaxSets ? Valid([.. sets]) : null;
        }
        if ((m = LoadOnly().Match(t)).Success && Num(m, "w") is { } only) { return new([new(null, only, Unit(m), null, null)], true); }
        return null;
    }

    /// <summary>
    /// Whether <paramref name="notation"/> appears in the message as a whole span, after the same normalization: the characters
    /// around it are no letter, digit or decimal point, so "3x8" never matches inside "13x8" (Codex B26 #5).
    /// </summary>
    public static bool InMessage(string notation, string message) => Spans.Contains(Normalize(message), Normalize(notation));

    private static NotationSet? Cardio(string t)
    {
        int? seconds = null; double? meters = null;
        if (Minutes().Match(t) is { Success: true } min) { seconds = Int(min, "n") * 60; }
        else if (Clock().Match(t) is { Success: true } clock) { seconds = Int(clock, "m") * 60 + Int(clock, "s"); }
        if (Km().Match(t) is { Success: true } km) { meters = Num(km, "n") * 1000; }
        else if (Meters().Match(t) is { Success: true } m) { meters = Num(m, "n"); }
        if (seconds is null && meters is null) { return null; }
        if (seconds is <= 0 or > 86_400 || meters is <= 0 or > 1_000_000) { return null; }
        return new(null, null, null, seconds, meters);
    }

    private static NotationResult? Repeat(int sets, NotationSet set) =>
        sets is >= 1 and <= MaxSets ? Valid(Enumerable.Repeat(set, sets).ToArray()) : null;

    private static NotationResult? Valid(NotationSet[] sets) =>
        sets.All(s => s.Reps is null or (>= 1 and <= 1000) && s.Weight is null or (>= 0 and <= 10000)) ? new(sets, false) : null;

    internal static string Normalize(string text)
    {
        var sb = new StringBuilder(text.Length);
        foreach (var c in text.ToLowerInvariant())
        {
            sb.Append(c switch
            {
                >= '٠' and <= '٩' => (char)('0' + (c - '٠')),
                >= '۰' and <= '۹' => (char)('0' + (c - '۰')),
                '٫' => '.',
                '×' or '✕' or '*' or 'х' => 'x',
                '،' => ',',
                '\t' or '\n' or '\r' => ' ',
                _ => c,
            });
        }
        return Spaces().Replace(sb.ToString(), " ").Trim();
    }

    private static int Int(Match m, string group) => I(m.Groups[group].Value);
    private static int I(string s) => int.Parse(s, NumberStyles.None, CultureInfo.InvariantCulture);
    private static double? Num(Match m, string group) =>
        m.Groups[group].Success && m.Groups[group].Length > 0 ? double.Parse(m.Groups[group].Value.TrimStart('+'), NumberStyles.AllowDecimalPoint | NumberStyles.AllowLeadingSign, CultureInfo.InvariantCulture) : null;
    private static BuddyLoadUnit? Unit(Match m, string group = "u") => m.Groups[group].Value switch
    {
        "" => null,
        var u when u.StartsWith('k') => BuddyLoadUnit.Kg,
        _ => BuddyLoadUnit.Lb,
    };

    private const string Load = @"(?<w>\+?[0-9]{1,4}(?:\.[0-9]{1,2})?)\s*(?<u>kgs?|kilos?|lbs?|pounds?)?";
    [GeneratedRegex(@"^(?<s>[0-9]{1,2})\s*x\s*(?<r>[0-9]{1,3})(?:\s*(?:@|at)\s*|\s+)" + Load + "$")] private static partial Regex SetsRepsLoad();
    [GeneratedRegex(@"^" + Load + @"\s+(?<s>[0-9]{1,2})\s*x\s*(?<r>[0-9]{1,3})$")] private static partial Regex LoadThenSetsReps();
    [GeneratedRegex(@"^(?<a>[0-9]{1,4}(?:\.[0-9]{1,2})?)\s*(?<u>kgs?|kilos?|lbs?|pounds?)?\s*x\s*(?<b>[0-9]{1,3})\s*x\s*(?<c>[0-9]{1,4}(?:\.[0-9]{1,2})?)\s*(?<u2>kgs?|kilos?|lbs?|pounds?)?$")] private static partial Regex Triple();
    [GeneratedRegex(@"^(?<reps>[0-9]{1,3}(?:\s*[,/]\s*[0-9]{1,3})+)\s*(?:@|at)\s*" + Load + "$")] private static partial Regex RepsListAtLoad();
    [GeneratedRegex(@"^(?<s>[0-9]{1,2})\s*sets?\s*(?:of|x)\s*(?<r>[0-9]{1,3})(?:\s*reps?)?(?:\s*(?:@|at|with)\s*" + Load + ")?$")] private static partial Regex SetsOf();
    [GeneratedRegex(@"^(?<w>[0-9]{1,4}(?:\.[0-9]{1,2})?)\s*(?<u>kgs?|kilos?|lbs?|pounds?)?\s*x\s*(?<r>[0-9]{1,3})$")] private static partial Regex LoadByReps();
    [GeneratedRegex(@"^" + Load + "$")] private static partial Regex LoadOnly();
    [GeneratedRegex(@"(?<![0-9.])(?<n>[0-9]{1,3})\s*(?:min|mins|minutes?)\b")] private static partial Regex Minutes();
    [GeneratedRegex(@"(?<![0-9:])(?<m>[0-9]{1,3}):(?<s>[0-5][0-9])(?![0-9:])")] private static partial Regex Clock();
    [GeneratedRegex(@"(?<![0-9.])(?<n>[0-9]{1,3}(?:\.[0-9]{1,2})?)\s*(?:km|kms|kilomet(?:er|re)s?)\b")] private static partial Regex Km();
    [GeneratedRegex(@"(?<![0-9.])(?<n>[0-9]{3,5})\s*(?:m|meters?|metres?)\b")] private static partial Regex Meters();
    [GeneratedRegex(@"\s+")] private static partial Regex Spaces();
}
