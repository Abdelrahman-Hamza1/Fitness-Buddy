using FitnessBuddy.Modules.Buddy.Domain;
using static FitnessBuddy.Modules.Buddy.Application.IntentNames;

namespace FitnessBuddy.Modules.Buddy.Application;

/// <summary>
/// Diary edits, deletes, copies and saved meals (B09 D6/D7/D8, TD-091). The model links mentions to list positions;
/// this code maps them to request IDs and decides ambiguity. Every ID it emits comes from the request (PA5).
/// </summary>
internal sealed class ResolveReferences(ResolveFoods foods)
{
    private enum Outcome { Targets, Ambiguous, LocalLookup, NotFound }
    private readonly record struct Selection(Outcome Outcome, Guid[] Ids);

    public async Task<BuddyIntent> EditAsync(ParsedIntent intent, InterpretInput input, string language, string script, CancellationToken ct)
    {
        var selection = Select(intent.Reference!, input.Context.RecentEntries);
        if (selection.Outcome == Outcome.NotFound) { return new BuddyClarify(language, script, "referenceNotFound"); }
        BuddyFoodItem? replacement = null;
        if (intent.Items is [var food])
        {
            replacement = await foods.ResolveAsync(food, input.Context.PersonalFoods, ct);
            if (ResolveFoods.Unmatched(replacement)) { return new BuddyClarify(language, script, "unmatchedFood"); }
        }
        // The amount is the new absolute amount the user stated (relative edits are clarified by the model, PA15).
        var amount = intent.Portion is { Amount: { } value, Unit: { } unit } ? new BuddyAmount((double)value, Name(unit), true) : null;
        var patch = new BuddyDiaryPatch(amount, replacement, Hint(intent.Move));
        var reference = Reference(intent.Reference!);
        return selection.Outcome == Outcome.Ambiguous
            ? new BuddyAmbiguousReference(language, script, BuddyReferenceOperation.Edit, selection.Ids, reference, patch)
            : new BuddyDiaryEdit(language, script, selection.Ids, reference, patch);
    }

    public static BuddyIntent Delete(ParsedIntent intent, InterpretInput input, string language, string script)
    {
        var selection = Select(intent.Reference!, input.Context.RecentEntries);
        var reference = Reference(intent.Reference!);
        return selection.Outcome switch
        {
            Outcome.NotFound => new BuddyClarify(language, script, "referenceNotFound"),
            Outcome.Ambiguous => new BuddyAmbiguousReference(language, script, BuddyReferenceOperation.Delete, selection.Ids, reference, null),
            _ => new BuddyDiaryDelete(language, script, selection.Ids, reference),
        };
    }

    /// <summary>Top-level hints are the source meal, <c>move</c> the target (null members: today, the source's slot, now).</summary>
    public static BuddyIntent Copy(ParsedIntent intent, string language, string script) =>
        // R1 has no whole-day copy: a source without a slot is clarified, like the prompt's copy-without-a-meal rule.
        intent.SlotHint is null ? new BuddyClarify(language, script, "unclear")
            : new BuddyDiaryCopy(language, script, new(intent.DateHint, intent.SlotHint, intent.TimeHint), Hint(intent.Move) ?? new(null, null, null));

    public static BuddyIntent SavedMealLog(ParsedIntent intent, InterpretInput input, string language, string script)
    {
        var meals = input.Context.SavedMeals;
        // PA8: no matching name (null listRef) or no saved meals is a clarify without a repair; validation range-checked the index.
        if (intent.ListRef is not { } index || meals.Length == 0) { return new BuddyClarify(language, script, "referenceNotFound"); }
        var share = intent.Portion is { } portion ? new BuddyShare((double?)portion.Fraction, portion.People) : null;
        return new BuddySavedMealLog(language, script, meals[index].Id, intent.TimeHint, intent.SlotHint, intent.DateHint, share);
    }

    /// <summary>Exactly one source (contract): the request's active proposal, linked entries, or a day/slot for the app's lookup.</summary>
    public static BuddyIntent SavedMealCreate(ParsedIntent intent, InterpretInput input, string language, string script)
    {
        var create = intent.Create!;
        if (create.FromActiveProposal)
        {
            // PA8: "save this" with no card is a clarify without a repair.
            return input.ActiveProposal is { } proposal ? new BuddySavedMealCreate(language, script, create.Name, proposal, [], null)
                : new BuddyClarify(language, script, "referenceNotFound");
        }
        var reference = intent.Reference!;
        var selection = Select(reference, input.Context.RecentEntries);
        return selection.Outcome switch
        {
            Outcome.Targets => new BuddySavedMealCreate(language, script, create.Name, null, selection.Ids, null),
            Outcome.LocalLookup => new BuddySavedMealCreate(language, script, create.Name, null, [], new(reference.DateHint, reference.SlotHint, null)),
            // The contract has no ambiguity chip for saving; ask the user to say which entries.
            Outcome.Ambiguous => new BuddyClarify(language, script, "unclear"),
            _ => new BuddyClarify(language, script, "referenceNotFound"),
        };
    }

    /// <summary>
    /// AI-091 (D7, PA4, TD-091), in order: no link → the app's local lookup when the reference has a day/slot hint, else not found;
    /// scope all or a single link → the linked entries; several with a day/slot qualifier → ask; several unqualified → the newest
    /// (date, slot) group, which is the target when it has one entry and otherwise asks.
    /// </summary>
    private static Selection Select(ParsedReference reference, RecentEntry[] entries)
    {
        // Validation guaranteed distinct, in-range positions. recentEntries are documented newest first, so position orders same-day entries.
        var linked = reference.Refs.Order().ToArray();
        var qualified = reference.DateHint is not null || reference.SlotHint is not null;
        Guid[] Ids(IEnumerable<int> refs) => refs.Select(r => entries[r].Id).ToArray();
        if (linked.Length == 0) { return qualified ? new(Outcome.LocalLookup, []) : new(Outcome.NotFound, []); }
        if (reference.Scope == ParsedScope.All || linked.Length == 1) { return new(Outcome.Targets, Ids(linked)); }
        if (qualified) { return new(Outcome.Ambiguous, Ids(linked)); }
        var newest = entries[linked.OrderByDescending(r => entries[r].Date).First()];
        var group = linked.Where(r => entries[r].Date == newest.Date && string.Equals(entries[r].Slot, newest.Slot, StringComparison.Ordinal)).ToArray();
        return new(group.Length == 1 ? Outcome.Targets : Outcome.Ambiguous, Ids(group));
    }

    private static BuddyEntryReference Reference(ParsedReference r) =>
        new(r.Mention, r.DateHint, r.SlotHint, r.Scope == ParsedScope.All ? BuddyReferenceScope.All : BuddyReferenceScope.One);
    private static BuddyDayHint? Hint(ParsedMove? move) => move is null ? null : new(move.DateHint, move.SlotHint, move.TimeHint);
}
