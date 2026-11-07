using System.Globalization;

namespace FitnessBuddy.Modules.Buddy.Domain;

/// <summary>
/// The server's code arithmetic for <c>compute</c> and card summaries (06 §4.1): grams from a stated amount and the food's own
/// servings, nutrients from per-100 facts. Nothing here guesses: an amount it can't convert has no grams (the phone's
/// ProposalEngine still owns yields, fat lines and the card's totals, A21).
/// </summary>
internal static class CardMath
{
    public static double? Grams(BuddyCandidate food, double amount, string unit)
    {
        if (!double.IsFinite(amount) || amount <= 0) { return null; }
        switch (unit)
        {
            case "g": return amount;
            case "kg": return amount * 1000;
            case "ml": return food.DensityGPerMl is { } d ? amount * d : null;
            case "l": return food.DensityGPerMl is { } dl ? amount * 1000 * dl : null;
            default:
                var serving = food.Servings.FirstOrDefault(s => string.Equals(s.UnitCode, unit, StringComparison.OrdinalIgnoreCase));
                var each = serving?.G ?? (serving?.Ml is { } ml && food.DensityGPerMl is { } density ? ml * density : null);
                return each is { } g ? amount * g : null;
        }
    }

    public static BuddyNutrients Scale(BuddyNutrients per100, double grams) =>
        new(per100.Kcal * grams / 100, per100.ProteinG * grams / 100, per100.CarbsG * grams / 100, per100.FatG * grams / 100, per100.FiberG * grams / 100);

    public static BuddyNutrients Sum(IEnumerable<BuddyNutrients> items) => items.Aggregate(new BuddyNutrients(0, 0, 0, 0, 0),
        (a, b) => new(a.Kcal + b.Kcal, a.ProteinG + b.ProteinG, a.CarbsG + b.CarbsG, a.FatG + b.FatG, a.FiberG + b.FiberG));

    /// <summary>A food card's nutrients when every item has a real match and a convertible amount; null otherwise.</summary>
    public static BuddyNutrients? Card(IEnumerable<BuddyFoodItem> items)
    {
        var parts = new List<BuddyNutrients>();
        foreach (var item in items)
        {
            if (item.Match is not { } match || item.Amount is not { Value: { } value, Unit: { } unit } || item.Dimensions.Length > 0) { return null; }
            if (Grams(match, value, unit) is not { } grams) { return null; }
            var share = item.Share?.Fraction ?? (item.Share?.People is { } people and > 0 ? 1.0 / people : 1.0);
            parts.Add(Scale(match.Nutrients, grams * share));
        }
        return parts.Count > 0 ? Sum(parts) : null;
    }
}

/// <summary>Code-made claim labels (06 §4, §7): metric + operation + period, so a target can never read as what's left.</summary>
internal static class ClaimLabels
{
    public static string For(string metric, string operation, string? period)
    {
        var what = metric switch
        {
            "protein" or "carbs" or "fat" or "fiber" => metric,
            "weight" => "weight",
            "weightTrend" => "weight trend",
            "measurement" => "measurement",
            "workouts" => "workouts",
            "sets" => "sets",
            "volume" => "volume",
            "exercisePr" => "best",
            "weighIns" => "weigh-ins",
            "loggedDays" => "logged days",
            "exerciseLastDate" => "",
            _ => "",
        };
        var how = operation switch
        {
            "total" => "eaten",
            "average" => "average",
            "remaining" => "left",
            "latest" => "latest",
            "change" => "change",
            "count" => "",
            "max" => "highest",
            "min" => "lowest",
            "last" => "last done",
            "target" => "target",
            _ => operation,
        };
        if (metric is "sets" or "volume" && operation == "total") { how = "total"; }
        return string.Join(' ', new[] { what, how, Period(period) }.Where(s => s.Length > 0));
    }

    public static string Period(string? period) => period switch
    {
        null or "" => "",
        "today" => "today",
        "yesterday" => "yesterday",
        "thisWeek" => "this week",
        "lastWeek" => "last week",
        "thisMonth" => "this month",
        "lastMonth" => "last month",
        _ when period.StartsWith("lastNDays:", StringComparison.Ordinal) => $"over the last {period[10..]} days",
        _ when period.StartsWith("since:", StringComparison.Ordinal) => "since " + period[6..],
        _ when period.StartsWith("range:", StringComparison.Ordinal) => "from " + period[6..].Replace("..", " to ", StringComparison.Ordinal),
        _ => period,
    };

    /// <summary>The period of a QueryPlan as a compact code (for labels and trace).</summary>
    public static string Of(BuddyQueryPeriod p) => p.Kind switch
    {
        BuddyPeriodKind.LastNDays => string.Create(CultureInfo.InvariantCulture, $"lastNDays:{p.Days}"),
        BuddyPeriodKind.Since => "since:" + (p.Since == BuddySinceEvent.Date ? p.From?.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture)
            : p.Since == BuddySinceEvent.RamadanStart ? "the start of Ramadan" : "the start of this phase"),
        BuddyPeriodKind.Range => string.Create(CultureInfo.InvariantCulture, $"range:{p.From:yyyy-MM-dd}..{p.To:yyyy-MM-dd}"),
        _ => System.Text.Json.JsonNamingPolicy.CamelCase.ConvertName(p.Kind.ToString()),
    };
}
