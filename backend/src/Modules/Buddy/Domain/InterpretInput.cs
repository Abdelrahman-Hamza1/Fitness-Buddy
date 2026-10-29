using System.Text.Json.Serialization;

namespace FitnessBuddy.Modules.Buddy.Domain;

internal sealed record PersonalFood(Guid Id, string[] Names, string[] Aliases, string State, BuddyNutrients Nutrients, BuddyServing[] Servings);
internal sealed record NamedReference(Guid Id, string Name);
internal sealed record ContextMemory(string Kind, string Key, string Value);
internal sealed record RecentEntry(Guid Id, DateOnly Date, string Slot, string Name, double? Grams);
internal sealed record MealSlot(Guid Id, string Name, string? Window);
internal sealed record RamadanContext(bool Active, string? Fajr, string? Maghrib);
internal sealed record ActiveCardLine(string Name, double? Amount, string? UnitCode, string? State);
internal sealed record ActiveCard(string? Slot, string? Time, ActiveCardLine[] Lines);
// ActiveCard is omitted when null, so the idempotency fingerprint of a request without it is unchanged (B09a WP1).
internal sealed record InterpretContext(PersonalFood[] PersonalFoods, NamedReference[] SavedMeals, NamedReference[] OpenBatches,
    ContextMemory[] Memory, RecentEntry[] RecentEntries, NamedReference[] CustomExercises,
    [property: JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)] ActiveCard? ActiveCard = null);
internal sealed record InterpretInput(Guid RequestId, string Text, DateTimeOffset Now, int TzOffsetMin,
    RamadanContext Ramadan, MealSlot[] Slots, Guid? ActiveProposal, InterpretContext Context);
