using FitnessBuddy.Modules.Buddy.Domain;
using FitnessBuddy.Modules.Catalog.Contracts;
using static FitnessBuddy.Modules.Buddy.Application.IntentNames;

namespace FitnessBuddy.Modules.Buddy.Application;

/// <summary>
/// Maps a validated parsed message to the public intents (B09 3.2): foods via <see cref="ResolveFoods"/>, diary references and saved
/// meals via <see cref="ResolveReferences"/>, memory, batches and personal foods via <see cref="ResolveCreations"/>.
/// No writes or totals (03 §5.3); every emitted ID comes from the request (PA5).
/// </summary>
internal sealed class ResolveInterpretation(IFoodResolver catalog)
{
    private readonly ResolveFoods foods = new(catalog);

    public async Task<BuddyInterpretation> ResolveAsync(ParsedMessage parsed, InterpretInput input, CancellationToken ct)
    {
        var references = new ResolveReferences(foods); var creations = new ResolveCreations(foods);
        var intents = new List<BuddyIntent>();
        var language = Name(parsed.Language); var script = Name(parsed.Script);
        foreach (var intent in parsed.Intents)
        {
            intents.Add(intent.Kind switch
            {
                ParsedKind.FoodLog => await FoodLogAsync(intent, input, language, script, ct),
                ParsedKind.WeighIn => new BuddyWeighIn(language, script, (double)intent.WeighIn!.Value, intent.WeighIn.Unit, intent.TimeHint, intent.DateHint),
                ParsedKind.Medical => new BuddyMedical(language, script),
                ParsedKind.OutOfScope when intent.Reason == DeclineReason.Medical => new BuddyMedical(language, script),
                ParsedKind.OutOfScope => new BuddyOutOfScope(language, script, Name(intent.Reason!.Value)),
                ParsedKind.Clarify => new BuddyClarify(language, script, Name(intent.Reason!.Value)),
                ParsedKind.DiaryEdit => await references.EditAsync(intent, input, language, script, ct),
                ParsedKind.DiaryDelete => ResolveReferences.Delete(intent, input, language, script),
                ParsedKind.DiaryCopy => ResolveReferences.Copy(intent, language, script),
                ParsedKind.SavedMealLog => ResolveReferences.SavedMealLog(intent, input, language, script),
                ParsedKind.SavedMealCreate => ResolveReferences.SavedMealCreate(intent, input, language, script),
                ParsedKind.MemoryChange => await creations.MemoryAsync(intent, input, language, script, ct),
                ParsedKind.Batch => await creations.BatchAsync(intent, input, language, script, ct),
                ParsedKind.BatchPortion => ResolveCreations.BatchPortion(intent, input, language, script),
                ParsedKind.BatchClose => ResolveCreations.BatchClose(intent, input, language, script),
                ParsedKind.PersonalFoodCreate => await creations.PersonalFoodAsync(intent, input, language, script, ct),
                // A kind this server doesn't know degrades to a closed clarify, never a crash (validation rejects these first).
                _ => new BuddyClarify(language, script, "unsupported"),
            });
        }
        return new(ParsedGrammar.Version, "gpt-6-luna", intents.ToArray());
    }

    private async Task<BuddyIntent> FoodLogAsync(ParsedIntent intent, InterpretInput input, string language, string script, CancellationToken ct)
    {
        var items = new List<BuddyFoodItem>();
        foreach (var food in intent.Items) { items.Add(await foods.ResolveAsync(food, input.Context.PersonalFoods, ct)); }
        return items.Any(ResolveFoods.Unmatched) ? new BuddyClarify(language, script, "unmatchedFood")
            : new BuddyFoodLog(language, script, intent.TimeHint, intent.SlotHint, intent.DateHint, intent.DishGroup, items.ToArray());
    }
}
