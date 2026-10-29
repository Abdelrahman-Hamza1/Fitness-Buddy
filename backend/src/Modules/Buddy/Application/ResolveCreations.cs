using FitnessBuddy.Modules.Buddy.Domain;
using static FitnessBuddy.Modules.Buddy.Application.IntentNames;

namespace FitnessBuddy.Modules.Buddy.Application;

/// <summary>
/// Memory statements, batches and personal foods (B09 D9–D12). Foods go through the shared resolver (D10); batch IDs come from
/// the request's openBatches (PA5). Nothing is applied or computed here: the app confirms, and owns remaining amounts (A26/A27).
/// </summary>
internal sealed class ResolveCreations(ResolveFoods foods)
{
    /// <summary>D10/D11: the subject food is carried only when it matches a real food, never an estimate. The server never applies a memory (TD-032).</summary>
    public async Task<BuddyIntent> MemoryAsync(ParsedIntent intent, InterpretInput input, string language, string script, CancellationToken ct)
    {
        var memory = intent.Memory!;
        BuddyFoodItem? food = null; var said = memory.Subject;
        if (intent.Items is [var subject])
        {
            var resolved = await foods.ResolveAsync(subject, input.Context.PersonalFoods, ct);
            food = resolved.Match is null ? null : resolved; // a real match never carries an estimate (B08 resolver)
            // A dropped food must not leave the statement about nothing: keep the user's words as the subject.
            if (food is null) { said ??= subject.Mention; }
        }
        return new BuddyMemoryChange(language, script,
            memory.Operation == ParsedMemoryOperation.Forget ? BuddyMemoryOperation.Forget : BuddyMemoryOperation.Remember,
            Enum.Parse<BuddyMemoryKind>(memory.MemoryKind.ToString()), said,
            memory.Dimension is { } dimension ? Enum.Parse<BuddyMemoryDimension>(dimension.ToString()) : null,
            memory.Value, Amount(memory.Amount, memory.Unit), food);
    }

    /// <summary>AI-100/DY-040: an unmatched ingredient without an estimate clarifies the whole batch; an estimate keeps its badge.</summary>
    public async Task<BuddyIntent> BatchAsync(ParsedIntent intent, InterpretInput input, string language, string script, CancellationToken ct)
    {
        var ingredients = await ResolveAllAsync(intent.Items, input, ct);
        if (ingredients.Any(ResolveFoods.Unmatched)) { return new BuddyClarify(language, script, "unmatchedFood"); }
        var batch = intent.Batch!;
        var path = batch.Path switch { ParsedBatchPath.Quick => BuddyBatchPath.Quick, ParsedBatchPath.Leftovers => BuddyBatchPath.Leftovers, _ => (BuddyBatchPath?)null };
        return new BuddyBatch(language, script, batch.Name, ingredients, Amount(batch.CookedAmount, batch.CookedUnit), path,
            Portion(intent.Portion), intent.TimeHint, intent.SlotHint, intent.DateHint);
    }

    /// <summary>AI-102/DY-043: exactly one of a portion or <c>rest</c>. PA8: no match or no open batches clarifies without a repair.</summary>
    public static BuddyIntent BatchPortion(ParsedIntent intent, InterpretInput input, string language, string script)
    {
        if (OpenBatch(intent, input) is not { } batchId) { return new BuddyClarify(language, script, "referenceNotFound"); }
        var rest = intent.Portion!.Rest;
        return new BuddyBatchPortion(language, script, batchId, rest ? null : Portion(intent.Portion), rest, intent.TimeHint, intent.SlotHint, intent.DateHint);
    }

    /// <summary>DY-044: the rest was thrown or given away; closes the batch without logging. PA8 as for portions.</summary>
    public static BuddyIntent BatchClose(ParsedIntent intent, InterpretInput input, string language, string script) =>
        OpenBatch(intent, input) is { } batchId ? new BuddyBatchClose(language, script, batchId) : new BuddyClarify(language, script, "referenceNotFound");

    /// <summary>
    /// AI-054: components resolve personal then catalog facts (an estimate keeps its badge; unmatched without one clarifies).
    /// <c>stated</c> figures are the user's own, already checked literally against the message (D9/TD-092); emitted as is, never filled.
    /// </summary>
    public async Task<BuddyIntent> PersonalFoodAsync(ParsedIntent intent, InterpretInput input, string language, string script, CancellationToken ct)
    {
        var components = await ResolveAllAsync(intent.Items, input, ct);
        if (components.Any(ResolveFoods.Unmatched)) { return new BuddyClarify(language, script, "unmatchedFood"); }
        var create = intent.Create!;
        var stated = intent.Stated is { } s
            ? new BuddyStatedNutrients(Enum.Parse<BuddyNutrientBasis>(s.Basis.ToString()), D(s.ServingG), D(s.ServingMl), D(s.Kcal), D(s.ProteinG), D(s.CarbsG), D(s.FatG), D(s.FiberG))
            : null;
        return new BuddyPersonalFoodCreate(language, script, create.Name, create.Aliases, components, stated);
    }

    private async Task<BuddyFoodItem[]> ResolveAllAsync(ParsedFood[] items, InterpretInput input, CancellationToken ct)
    {
        var resolved = new BuddyFoodItem[items.Length];
        for (var i = 0; i < items.Length; i++) { resolved[i] = await foods.ResolveAsync(items[i], input.Context.PersonalFoods, ct); }
        return resolved;
    }
    // Validation range-checked a non-null index against a non-empty list (D6, PA8).
    private static Guid? OpenBatch(ParsedIntent intent, InterpretInput input) =>
        intent.ListRef is { } index && input.Context.OpenBatches.Length > 0 ? input.Context.OpenBatches[index].Id : null;
    /// <summary>A user-stated amount (grams, plates, …); explicit by construction.</summary>
    internal static BuddyAmount? Amount(decimal? value, FoodUnit? unit) => value is { } v && unit is { } u ? new((double)v, Name(u), true) : null;
    /// <summary>AI-101/DY-041: grams or plates, or a share of the whole batch (fraction or people).</summary>
    internal static BuddyPortion? Portion(ParsedPortion? portion) => portion is null || portion.Rest ? null
        : new(Amount(portion.Amount, portion.Unit), portion.Fraction is null && portion.People is null ? null : new((double?)portion.Fraction, portion.People));
    private static double? D(decimal? value) => (double?)value;
}
