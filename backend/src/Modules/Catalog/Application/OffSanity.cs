namespace FitnessBuddy.Modules.Catalog.Application;

/// <summary>Raw per-100 and per-serving numbers of one OFF product, before any correction (nulls = not published).
/// Energy is kcal; kJ fields are kept apart so a kJ-in-kcal mistake can be seen.</summary>
internal sealed record OffRaw(double? Kcal, double? Kj, double? ProteinG, double? CarbsG, double? FatG, double? FiberG, double? AlcoholG,
    double? ServingG, double? ServingKcal, double? ServingKj, double? ServingProteinG, double? ServingCarbsG, double? ServingFatG, double? ServingFiberG);

/// <summary>The outcome of <see cref="OffSanity.Check"/>: rejects are never served; warnings ask the user to compare with the label.</summary>
internal sealed record OffVerdict(string[] Rejects, string[] Warnings)
{
    public bool Rejected => Rejects.Length > 0;
}

/// <summary>B22: automatic sanity checks on Open Food Facts products (OFF is crowd-sourced). Pure code, no I/O.
/// <see cref="Normalize"/> repairs the two provable mistakes (kJ stored as kcal, per-serving stored as per-100) and records
/// each repair by rule name. <see cref="Check"/> then rejects impossible or unusable rows and warns on an energy that
/// doesn't fit the macros. Thresholds are the FD-012 ones the app and the catalog build use (`SanityTolerance` in
/// <c>fb_domain</c>), not new numbers.</summary>
internal static class OffSanity
{
    public const string KjConverted = "kj-converted";
    public const string KjInKcal = "kj-in-kcal";
    public const string PerServingScaled = "per-serving-scaled";
    public const string PerServingInPer100 = "per-serving-in-per100";
    public const string Negative = "negative-value";
    public const string MissingEnergy = "missing-energy";
    public const string MissingMacros = "missing-macros";
    public const string EnergyTooHigh = "energy-too-high";
    public const string MacrosTooHeavy = "macros-too-heavy";
    public const string EnergyMacrosMismatch = "energy-macros-mismatch";

    // FD-012 (fb_domain SanityTolerance defaults).
    private const double OkKcal = 15, OkFraction = 0.15, MaxKcalPer100 = 920, MaxMacroGramsPer100g = 105;
    private const double KjPerKcal = 4.184;

    public static (OffNutrients Per100, string[] Corrections) Normalize(OffRaw raw)
    {
        var corrections = new List<string>();
        var kcal = raw.Kcal;
        var (protein, carbs, fat, fiber) = (raw.ProteinG, raw.CarbsG, raw.FatG, raw.FiberG);

        // kJ mistakes (per 100).
        if (kcal is null && raw.Kj is { } kj) { kcal = kj / KjPerKcal; corrections.Add(KjConverted); }
        else if (kcal is { } stated && raw.Kj is { } kjStated && kjStated > 20 && Math.Abs(stated - kjStated) <= 0.02 * kjStated)
        {
            kcal = kjStated / KjPerKcal; corrections.Add(KjInKcal);
        }
        else if (kcal is { } k && protein is { } p && carbs is { } c && fat is { } f && Derived(p, c, f, 0) is var m && m >= 20
            && Math.Abs(k - m * KjPerKcal) <= 0.10 * m * KjPerKcal)
        {
            kcal = k / KjPerKcal; corrections.Add(KjInKcal);
        }

        if (raw.ServingG is { } grams and > 0)
        {
            var factor = 100 / grams;
            var servingKcal = raw.ServingKcal ?? raw.ServingKj / KjPerKcal;
            var servingHasMacros = raw.ServingProteinG is not null || raw.ServingCarbsG is not null || raw.ServingFatG is not null;
            if (protein is null && carbs is null && fat is null && servingHasMacros)
            {
                // Only per-serving data: scale it to per 100.
                protein = Scale(raw.ServingProteinG, factor); carbs = Scale(raw.ServingCarbsG, factor); fat = Scale(raw.ServingFatG, factor);
                fiber ??= Scale(raw.ServingFiberG, factor);
                kcal ??= Scale(servingKcal, factor);
                corrections.Add(PerServingScaled);
            }
            else if (Math.Abs(grams - 100) >= 10 && kcal is { } per100 && servingKcal is { } perServing && Same(per100, perServing)
                && SameOrAbsent(protein, raw.ServingProteinG) && SameOrAbsent(carbs, raw.ServingCarbsG) && SameOrAbsent(fat, raw.ServingFatG)
                && (protein is not null || carbs is not null || fat is not null))
            {
                // The "per 100" numbers equal the per-serving ones of a serving that isn't 100: they are per serving.
                kcal = Scale(kcal, factor); protein = Scale(protein, factor); carbs = Scale(carbs, factor); fat = Scale(fat, factor); fiber = Scale(fiber, factor);
                corrections.Add(PerServingInPer100);
            }
        }
        return (new OffNutrients(Round(kcal), Round(protein), Round(carbs), Round(fat), Round(fiber), Round(raw.AlcoholG)), [.. corrections]);
    }

    public static OffVerdict Check(OffNutrients n, string basis)
    {
        var rejects = new List<string>();
        var warnings = new List<string>();
        double?[] all = [n.Kcal, n.ProteinG, n.CarbsG, n.FatG, n.FiberG, n.AlcoholG];
        if (all.Any(v => v is { } x && (!double.IsFinite(x) || x < 0))) { rejects.Add(Negative); }
        if (n.Kcal is null) { rejects.Add(MissingEnergy); }
        if (n.ProteinG is null && n.CarbsG is null && n.FatG is null) { rejects.Add(MissingMacros); }
        if (n.Kcal > MaxKcalPer100) { rejects.Add(EnergyTooHigh); }
        if (rejects.Count > 0) { return new([.. rejects], []); }

        var (p, c, f, fiber, alcohol) = (n.ProteinG ?? 0, n.CarbsG ?? 0, n.FatG ?? 0, n.FiberG ?? 0, n.AlcoholG ?? 0);
        var kcal = n.Kcal!.Value;
        var baseKcal = Derived(p, c, f, alcohol);
        var separate = baseKcal + 2 * fiber;
        var useSeparate = Math.Abs(kcal - separate) < Math.Abs(kcal - baseKcal);
        // Dense liquids legitimately exceed 100 g of macros per 100 ml, so the mass check is for grams only.
        if (basis == "g" && p + c + f + (useSeparate ? fiber : 0) > MaxMacroGramsPer100g) { return new([MacrosTooHeavy], []); }
        // Some macro unknown: the energy can't be compared (the app already treats it as incomplete).
        if (n.ProteinG is not null && n.CarbsG is not null && n.FatG is not null)
        {
            var expected = useSeparate ? separate : baseKcal;
            if (Math.Abs(kcal - expected) > Math.Max(OkKcal, OkFraction * Math.Max(kcal, expected))) { warnings.Add(EnergyMacrosMismatch); }
        }
        return new([], [.. warnings]);
    }

    private static double Derived(double p, double c, double f, double alcohol) => 4 * p + 4 * c + 9 * f + 7 * alcohol;
    private static double? Scale(double? value, double factor) => value * factor;
    private static double? Round(double? value) => value is { } v && double.IsFinite(v) ? Math.Round(v, 3) : value;
    private static bool Same(double a, double b) => Math.Abs(a - b) <= Math.Max(0.5, 0.02 * Math.Max(a, b));
    private static bool SameOrAbsent(double? per100, double? serving) => per100 is null || serving is null || Same(per100.Value, serving.Value);
}
