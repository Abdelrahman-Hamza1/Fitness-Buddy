using System.ComponentModel.DataAnnotations;

namespace FitnessBuddy.Modules.Buddy.Domain;

// B26 WP1: the label read (FD-040–042, 06 §8). One structured vision call; the app's review screen (A69) shows every value with
// its confidence and runs the FD-012 sanity check. Nothing is stored and nothing is written.

internal enum BuddyLabelBasis { Per100g, Per100ml, PerServing }
internal enum BuddyLabelConfidence { High, Medium, Low }

/// <summary>What the photo's nutrition panel says; <c>found</c> false when no panel could be read (every value null).</summary>
internal sealed record BuddyLabelExtraction(bool Found, BuddyLabelBasis? Basis, BuddyLabelServing? Serving, BuddyLabelText Name,
    BuddyLabelNutrients Nutrients, [property: MaxLength(20)] BuddyLabelOther[] Others);
/// <summary>A printed text (the product name guess), or null.</summary>
internal sealed record BuddyLabelText([property: MaxLength(120)] string? Value, BuddyLabelConfidence Confidence);
/// <summary>The serving as printed: amount and unit, its grams or millilitres when stated, and the printed label.</summary>
internal sealed record BuddyLabelServing([property: Range(0, 100000)] double? Amount, [property: MaxLength(16)] string? Unit,
    [property: Range(0, 100000)] double? G, [property: Range(0, 100000)] double? Ml, [property: MaxLength(120)] string? Label, BuddyLabelConfidence Confidence);
/// <summary>
/// Core and extra nutrients on the label's basis. <c>kcalFromKj</c>: the label gave only kJ and code converted it;
/// <c>sodiumFromSalt</c>: the label gave salt and code converted it to sodium.
/// </summary>
internal sealed record BuddyLabelNutrients(BuddyLabelValue Kcal, BuddyLabelValue ProteinG, BuddyLabelValue CarbsG, BuddyLabelValue FatG,
    BuddyLabelValue FiberG, BuddyLabelValue SugarG, BuddyLabelValue SaturatedFatG, BuddyLabelValue TransFatG, BuddyLabelValue SodiumMg,
    BuddyLabelValue CholesterolMg, bool KcalFromKj, bool SodiumFromSalt);
internal sealed record BuddyLabelValue([property: Range(0, 50000)] double? Value, BuddyLabelConfidence Confidence);
/// <summary>Another nutrient the label lists (vitamins, minerals…), as printed.</summary>
internal sealed record BuddyLabelOther([property: MinLength(1), MaxLength(60)] string Name, [property: Range(0, 100000)] double Value,
    [property: MaxLength(16)] string Unit, BuddyLabelConfidence Confidence);

// What the model returns (label-v1): a transcription. Code converts kJ, salt and mass units and drops impossible values.
internal enum LabelMassUnit { Mg, G }
internal sealed record LabelMass(double? Value, LabelMassUnit? Unit, BuddyLabelConfidence Confidence);
internal sealed record LabelReadNutrients(BuddyLabelValue Kcal, BuddyLabelValue Kj, BuddyLabelValue ProteinG, BuddyLabelValue CarbsG, BuddyLabelValue FatG,
    BuddyLabelValue FiberG, BuddyLabelValue SugarG, BuddyLabelValue SaturatedFatG, BuddyLabelValue TransFatG, LabelMass Sodium, LabelMass Salt, LabelMass Cholesterol);
internal sealed record LabelReading(bool Found, BuddyLabelBasis? Basis, BuddyLabelServing? Serving, BuddyLabelText Name, LabelReadNutrients Nutrients,
    BuddyLabelOther[]? Others);

/// <summary>
/// From the model's transcription to the public extraction (B26 D2): kJ → kcal (÷ 4.184) only when kcal is missing, salt →
/// sodium (× 400 mg per g) only when sodium is missing, g ↔ mg for sodium and cholesterol, and every value outside what a label
/// can say (negative, not finite, above the app's field maxima, more than 100 g per 100 g) becomes null with low confidence.
/// Strings are trimmed and capped. No other arithmetic: the FD-012 sanity check is the app's.
/// </summary>
internal static class LabelRules
{
    private static readonly BuddyLabelValue None = new(null, BuddyLabelConfidence.Low);

    /// <summary>The transcription is whole: every nested object and array element present (the parser checks the rest).</summary>
    public static bool Complete(LabelReading r) => r.Name is not null && r.Nutrients is { } n
        && new object?[] { n.Kcal, n.Kj, n.ProteinG, n.CarbsG, n.FatG, n.FiberG, n.SugarG, n.SaturatedFatG, n.TransFatG, n.Sodium, n.Salt, n.Cholesterol }.All(v => v is not null)
        && (r.Others ?? []).All(o => o is { Name: not null, Unit: not null });

    public static BuddyLabelExtraction Extract(LabelReading r)
    {
        if (!r.Found)
        {
            return new(false, null, null, new(null, BuddyLabelConfidence.Low),
                new(None, None, None, None, None, None, None, None, None, None, false, false), []);
        }
        var per100g = r.Basis == BuddyLabelBasis.Per100g;
        var n = r.Nutrients;
        BuddyLabelValue Grams(BuddyLabelValue? v) => Bound(v, per100g ? 100 : 5000);
        // Inputs are checked for being numbers at all; bounds apply to the converted value (Codex B26 #9).
        var kcal = Bound(n.Kcal, 20000); var fromKj = false;
        if (kcal.Value is null && Raw(n.Kj) is { } kj)
        {
            kcal = Bound(new(Math.Round(kj / 4.184, 0, MidpointRounding.AwayFromZero), n.Kj.Confidence), 20000); fromKj = kcal.Value is not null;
        }
        var sodium = Mg(n.Sodium); var fromSalt = false;
        if (sodium.Value is null && MgRaw(n.Salt) is { } saltMg)
        {
            sodium = Bound(new(Math.Round(saltMg / 2.5, 0, MidpointRounding.AwayFromZero), n.Salt.Confidence), 50000); fromSalt = sodium.Value is not null;
        }
        var others = (r.Others ?? []).Where(o => o is not null && !string.IsNullOrWhiteSpace(o.Name) && double.IsFinite(o.Value) && o.Value is >= 0 and <= 100000)
            .Take(20).Select(o => new BuddyLabelOther(Cap(o.Name, 60)!, o.Value, Cap(o.Unit, 16) ?? "", o.Confidence)).ToArray();
        var serving = r.Serving is { } s
            ? new BuddyLabelServing(Positive(s.Amount), Cap(s.Unit, 16), Positive(s.G), Positive(s.Ml), Cap(s.Label, 120), s.Confidence)
            : null;
        var name = Cap(r.Name?.Value, 120);
        return new(true, r.Basis, serving, new(name, name is null ? BuddyLabelConfidence.Low : r.Name!.Confidence),
            new(kcal, Grams(n.ProteinG), Grams(n.CarbsG), Grams(n.FatG), Grams(n.FiberG), Grams(n.SugarG), Grams(n.SaturatedFatG), Grams(n.TransFatG),
                sodium, Mg(n.Cholesterol), fromKj, fromSalt), others);
    }

    private static BuddyLabelValue Mg(LabelMass? m) => MgRaw(m) is { } mg ? Bound(new(mg, m!.Confidence), 50000) : None;

    /// <summary>A mass in milligrams before any destination bound: null unless a finite, non-negative value with a unit.</summary>
    private static double? MgRaw(LabelMass? m) => m is { Value: { } v, Unit: { } unit } && double.IsFinite(v) && v >= 0 ? (unit == LabelMassUnit.G ? v * 1000 : v) : null;

    private static double? Raw(BuddyLabelValue? v) => v is { Value: { } x } && double.IsFinite(x) && x >= 0 ? x : null;

    private static BuddyLabelValue Bound(BuddyLabelValue? v, double max) =>
        v is { Value: { } x } && double.IsFinite(x) && x >= 0 && x <= max ? v : None;

    private static double? Positive(double? v) => v is { } x && double.IsFinite(x) && x is > 0 and <= 100000 ? x : null;

    private static string? Cap(string? s, int n)
    {
        var t = s?.Trim();
        return string.IsNullOrEmpty(t) ? null : t.Length <= n ? t : t[..n];
    }
}
