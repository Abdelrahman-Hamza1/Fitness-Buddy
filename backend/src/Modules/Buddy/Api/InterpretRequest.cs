using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;
using FitnessBuddy.Modules.Buddy.Domain;

namespace FitnessBuddy.Modules.Buddy.Api;

[JsonUnmappedMemberHandling(JsonUnmappedMemberHandling.Disallow)]
public sealed record InterpretRequest(Guid RequestId, [property: MinLength(1), MaxLength(1000)] string Text,
    DateTimeOffset Now, [property: Range(-840, 840)] int TzOffsetMin, BuddyRamadan Ramadan,
    BuddySlot[] Slots, Guid? ActiveProposal, BuddyContext Context) : IValidatableObject
{
    public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
    {
        if (!Uuid(RequestId) || ActiveProposal is { } active && !Uuid(active)) { yield return Error("Use UUIDv7 message and proposal IDs.", "requestId"); }
        if (string.IsNullOrWhiteSpace(Text)) { yield return Error("A message is required.", "text"); }
        if (Ramadan is null || !Optional(Ramadan.Fajr) || !Optional(Ramadan.Maghrib)) { yield return Error("Invalid Ramadan context.", "ramadan"); }
        if (Slots is null || Slots.Length > 12 || Slots.Any(s => s is null || !Uuid(s.Id) || !Short(s.Name) || !Optional(s.Window))) { yield return Error("Use at most 12 valid slots.", "slots"); }
        if (Context is null || !ValidContext(Context)) { yield return Error("Context exceeds its bounded lists or contains invalid values.", "context"); }
    }
    private static ValidationResult Error(string message, string key) => new(message, [key]);
    private static bool Uuid(Guid id) => id.ToString("D")[14] == '7' && "89ab".Contains(id.ToString("D")[19], StringComparison.Ordinal);
    private static bool Short(string? s) => !string.IsNullOrWhiteSpace(s) && s.Length <= 200;
    private static bool Optional(string? s) => s is null || Short(s);
    private static bool ValidContext(BuddyContext c) =>
        c.PersonalFoods is { Length: <= 30 } && c.PersonalFoods.All(f => f is not null && Uuid(f.Id)
            && f.Names is { Length: > 0 and <= 5 } && f.Names.All(Short) && f.Aliases is { Length: <= 10 } && f.Aliases.All(Short)
            && Short(f.State) && Valid(f.Nutrients) && f.Servings is { Length: <= 20 } && f.Servings.All(s => s is not null && Short(s.UnitCode) && Short(s.Source)
                && Positive(s.G) && Positive(s.Ml) && Positive(s.RangeLo) && Positive(s.RangeHi)))
        && c.PersonalFoods.Select(f => f.Id).Distinct().Count() == c.PersonalFoods.Length
        && Refs(c.SavedMeals) && Refs(c.OpenBatches) && Refs(c.CustomExercises)
        && c.Memory is { Length: <= 20 } && c.Memory.All(m => m is not null && Short(m.Kind) && Short(m.Key) && Short(m.Value))
        && c.RecentEntries is { Length: <= 30 } && c.RecentEntries.All(r => r is not null && Uuid(r.Id) && Short(r.Slot) && Short(r.Name) && Positive(r.Grams));
    private static bool Refs(BuddyNamedReference[]? refs) => refs is { Length: <= 20 } && refs.All(r => r is not null && Uuid(r.Id) && Short(r.Name));
    private static bool Positive(double? value) => value is null || double.IsFinite(value.Value) && value is > 0 and <= 100000;
    private static bool Valid(BuddyNutrientsRequest? n) => n is not null && new[] { n.Kcal, n.ProteinG, n.CarbsG, n.FatG, n.FiberG }.All(v => double.IsFinite(v) && v is >= 0 and <= 10000);
    internal InterpretInput ToInput() => new(RequestId, Text, Now, TzOffsetMin, new(Ramadan.Active, Ramadan.Fajr, Ramadan.Maghrib),
        Slots.Select(s => new MealSlot(s.Id, s.Name, s.Window)).ToArray(), ActiveProposal,
        new(Context.PersonalFoods.Select(f => new PersonalFood(f.Id, f.Names, f.Aliases, f.State,
            new(f.Nutrients.Kcal, f.Nutrients.ProteinG, f.Nutrients.CarbsG, f.Nutrients.FatG, f.Nutrients.FiberG),
            f.Servings.Select(s => new BuddyServing(s.UnitCode, s.G, s.Ml, s.RangeLo, s.RangeHi, s.Source)).ToArray())).ToArray(),
            Context.SavedMeals.Select(r => new NamedReference(r.Id, r.Name)).ToArray(), Context.OpenBatches.Select(r => new NamedReference(r.Id, r.Name)).ToArray(),
            Context.Memory.Select(m => new ContextMemory(m.Kind, m.Key, m.Value)).ToArray(), Context.RecentEntries.Select(r => new RecentEntry(r.Id, r.Date, r.Slot, r.Name, r.Grams)).ToArray(),
            Context.CustomExercises.Select(r => new NamedReference(r.Id, r.Name)).ToArray()));
}
public sealed record BuddyRamadan(bool Active, string? Fajr, string? Maghrib);
public sealed record BuddySlot(Guid Id, string Name, string? Window);
public sealed record BuddyContext(BuddyPersonalFood[] PersonalFoods, BuddyNamedReference[] SavedMeals, BuddyNamedReference[] OpenBatches,
    BuddyMemory[] Memory, BuddyRecentEntry[] RecentEntries, BuddyNamedReference[] CustomExercises);
public sealed record BuddyPersonalFood(Guid Id, string[] Names, string[] Aliases, string State, BuddyNutrientsRequest Nutrients, BuddyServingRequest[] Servings);
public sealed record BuddyNamedReference(Guid Id, string Name);
public sealed record BuddyMemory(string Kind, string Key, string Value);
public sealed record BuddyRecentEntry(Guid Id, DateOnly Date, string Slot, string Name, double? Grams);
public sealed record BuddyNutrientsRequest(double Kcal, double ProteinG, double CarbsG, double FatG, double FiberG);
public sealed record BuddyServingRequest(string UnitCode, double? G, double? Ml, double? RangeLo, double? RangeHi, string Source);
