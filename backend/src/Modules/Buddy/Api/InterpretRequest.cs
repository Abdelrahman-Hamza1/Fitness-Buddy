using System.ComponentModel.DataAnnotations;
using System.Text.RegularExpressions;
using System.Text.Json.Serialization;
using FitnessBuddy.Modules.Buddy.Domain;

namespace FitnessBuddy.Modules.Buddy.Api;

[JsonUnmappedMemberHandling(JsonUnmappedMemberHandling.Disallow)]
public sealed partial record InterpretRequest(Guid RequestId, [property: MinLength(1), MaxLength(1000)] string Text,
    DateTimeOffset Now, [property: Range(-840, 840)] int TzOffsetMin, BuddyRamadan Ramadan,
    BuddySlot[] Slots, Guid? ActiveProposal, BuddyContext Context) : IValidatableObject
{
    public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
    {
        if (!V7(RequestId) || ActiveProposal is { } active && !V7(active)) { yield return Error("Use UUIDv7 message and proposal IDs.", "requestId"); }
        if (string.IsNullOrWhiteSpace(Text)) { yield return Error("A message is required.", "text"); }
        if (Ramadan is null || !Optional(Ramadan.Fajr) || !Optional(Ramadan.Maghrib)) { yield return Error("Invalid Ramadan context.", "ramadan"); }
        if (Slots is null || Slots.Length > 12 || Slots.Any(s => s is null || !Reference(s.Id) || !Short(s.Name) || !Optional(s.Window)) || !Distinct(Slots.Select(s => s.Id)))
        { yield return Error("Use at most 12 valid slots.", "slots"); }
        if (Context is null || !ValidContext(Context)) { yield return Error("Context exceeds its bounded lists or contains invalid values.", "context"); }
        else if (Context.ActiveCard is not null && ActiveProposal is null) { yield return Error("An active card needs its active proposal.", "context"); }
    }
    private static ValidationResult Error(string message, string key) => new(message, [key]);
    // Client-minted IDs (message, proposal) are UUIDv7. Context reference IDs only point back at the phone's rows, which
    // include deterministic UUIDv5 natural IDs (TD-070, e.g. default meal slots): any non-nil UUID; never sent to the model.
    private static bool V7(Guid id) => id.ToString("D")[14] == '7' && "89ab".Contains(id.ToString("D")[19], StringComparison.Ordinal);
    private static bool Reference(Guid id) => id != Guid.Empty;
    private static bool Short(string? s) => !string.IsNullOrWhiteSpace(s) && s.Length <= 200;
    private static bool Optional(string? s) => s is null || Short(s);
    private static bool ValidContext(BuddyContext c) =>
        c.PersonalFoods is { Length: <= 30 } && c.PersonalFoods.All(f => f is not null && Reference(f.Id)
            && f.Names is { Length: > 0 and <= 5 } && f.Names.All(Short) && f.Aliases is { Length: <= 10 } && f.Aliases.All(Short)
            && Short(f.State) && Valid(f.Nutrients) && f.Servings is { Length: <= 20 } && f.Servings.All(s => s is not null && Short(s.UnitCode) && Short(s.Source)
                && Positive(s.G) && Positive(s.Ml) && Positive(s.RangeLo) && Positive(s.RangeHi)))
        && Distinct(c.PersonalFoods.Select(f => f.Id))
        && Refs(c.SavedMeals) && Refs(c.OpenBatches) && Refs(c.CustomExercises)
        && c.Memory is { Length: <= 20 } && c.Memory.All(m => m is not null && Short(m.Kind) && Short(m.Key) && Short(m.Value))
        && c.RecentEntries is { Length: <= 30 } && c.RecentEntries.All(r => r is not null && Reference(r.Id) && Short(r.Slot) && Short(r.Name) && Positive(r.Grams))
        && Distinct(c.RecentEntries.Select(r => r.Id))
        && (c.ActiveCard is null || Optional(c.ActiveCard.Slot) && (c.ActiveCard.Time is null || Clock().IsMatch(c.ActiveCard.Time)) && c.ActiveCard.Lines is { Length: <= 30 }
            && c.ActiveCard.Lines.All(l => l is not null && Short(l.Name) && Positive(l.Amount) && Optional(l.UnitCode) && Optional(l.State)));
    private static bool Refs(BuddyNamedReference[]? refs) => refs is { Length: <= 20 } && refs.All(r => r is not null && Reference(r.Id) && Short(r.Name)) && Distinct(refs.Select(r => r.Id));
    private static bool Distinct(IEnumerable<Guid> ids) { var seen = new HashSet<Guid>(); return ids.All(seen.Add); }
    [GeneratedRegex(BuddyActiveCard.TimePattern)] private static partial Regex Clock();
    private static bool Positive(double? value) => value is null || double.IsFinite(value.Value) && value is > 0 and <= 100000;
    private static bool Valid(BuddyNutrientsRequest? n) => n is not null && new[] { n.Kcal, n.ProteinG, n.CarbsG, n.FatG, n.FiberG }.All(v => double.IsFinite(v) && v is >= 0 and <= 10000);
    internal InterpretInput ToInput() => new(RequestId, Text, Now, TzOffsetMin, new(Ramadan.Active, Ramadan.Fajr, Ramadan.Maghrib),
        Slots.Select(s => new MealSlot(s.Id, s.Name, s.Window)).ToArray(), ActiveProposal,
        new(Context.PersonalFoods.Select(f => new PersonalFood(f.Id, f.Names, f.Aliases, f.State,
            new(f.Nutrients.Kcal, f.Nutrients.ProteinG, f.Nutrients.CarbsG, f.Nutrients.FatG, f.Nutrients.FiberG),
            f.Servings.Select(s => new BuddyServing(s.UnitCode, s.G, s.Ml, s.RangeLo, s.RangeHi, s.Source)).ToArray())).ToArray(),
            Context.SavedMeals.Select(r => new NamedReference(r.Id, r.Name)).ToArray(), Context.OpenBatches.Select(r => new NamedReference(r.Id, r.Name)).ToArray(),
            Context.Memory.Select(m => new ContextMemory(m.Kind, m.Key, m.Value)).ToArray(), Context.RecentEntries.Select(r => new RecentEntry(r.Id, r.Date, r.Slot, r.Name, r.Grams)).ToArray(),
            Context.CustomExercises.Select(r => new NamedReference(r.Id, r.Name)).ToArray(),
            Context.ActiveCard is { } card ? new ActiveCard(card.Slot, card.Time, card.Lines.Select(l => new ActiveCardLine(l.Name, l.Amount, l.UnitCode, l.State)).ToArray()) : null));
}
public sealed record BuddyRamadan(bool Active, string? Fajr, string? Maghrib);
public sealed record BuddySlot(Guid Id, string Name, string? Window);
/// <remarks><c>ActiveCard</c> was added after B08 (B09a, A22 PA6), so it is optional: older apps omit it.</remarks>
public sealed record BuddyContext(BuddyPersonalFood[] PersonalFoods, BuddyNamedReference[] SavedMeals, BuddyNamedReference[] OpenBatches,
    BuddyMemory[] Memory, BuddyRecentEntry[] RecentEntries, BuddyNamedReference[] CustomExercises, BuddyActiveCard? ActiveCard = null);
/// <summary>The open proposal card a follow-up refers to (AI-044): names and amounts only, no IDs, no nutrients.</summary>
public sealed record BuddyActiveCard(string? Slot, [property: RegularExpression(BuddyActiveCard.TimePattern)] string? Time, BuddyActiveCardLine[] Lines)
{
    public const string TimePattern = "^([01][0-9]|2[0-3]):[0-5][0-9]$";
}
public sealed record BuddyActiveCardLine(string Name, double? Amount, string? UnitCode, string? State);
public sealed record BuddyPersonalFood(Guid Id, string[] Names, string[] Aliases, string State, BuddyNutrientsRequest Nutrients, BuddyServingRequest[] Servings);
public sealed record BuddyNamedReference(Guid Id, string Name);
public sealed record BuddyMemory(string Kind, string Key, string Value);
public sealed record BuddyRecentEntry(Guid Id, DateOnly Date, string Slot, string Name, double? Grams);
public sealed record BuddyNutrientsRequest(double Kcal, double ProteinG, double CarbsG, double FatG, double FiberG);
public sealed record BuddyServingRequest(string UnitCode, double? G, double? Ml, double? RangeLo, double? RangeHi, string Source);
