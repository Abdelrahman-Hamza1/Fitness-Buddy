namespace FitnessBuddy.Modules.Buddy.Domain;

/// <summary>The production grammar (B09 D5): its prompt, schema snapshot and every resolved interpretation carry this version (PA10).</summary>
internal static class ParsedGrammar
{
    public const string Version = "interpret-v2";
}

// Internal provider output, not API DTOs (public shapes are mapped in ResolveInterpretation and never change with a prompt).
// One flat intent object with grouped nullable sub-objects, not an anyOf union (D5). There is no ambiguity kind:
// ambiguousReference is public-only and decided by server policy over the linked candidates (D7, TD-091).
internal enum ParsedKind
{
    FoodLog, Clarify, OutOfScope, Medical, WeighIn,
    DiaryEdit, DiaryDelete, DiaryCopy, SavedMealLog, SavedMealCreate, MemoryChange, Batch, BatchPortion, BatchClose, PersonalFoodCreate,
}
internal enum ParsedScope { One, All }
internal enum ParsedMemoryOperation { Remember, Forget }
internal enum ParsedMemoryKind { Default, Portion, Alias, Brand, Nickname }
internal enum ParsedMemoryDimension { State, Fat, Variant, Portion }
internal enum ParsedBatchPath { Quick, Leftovers }
internal enum ParsedNutrientBasis { Per100g, Per100ml, PerServing }

internal sealed record ParsedMessage(MessageLanguage Language, MessageScript Script, ParsedIntent[] Intents);
internal sealed record ParsedIntent(ParsedKind Kind, string? TimeHint, string? SlotHint, string? DateHint, string? DishGroup,
    ParsedFood[] Items, WeighIn? WeighIn, DeclineReason? Reason,
    ParsedReference? Reference, ParsedMove? Move, int? ListRef, ParsedPortion? Portion, ParsedMemory? Memory,
    ParsedBatch? Batch, ParsedCreate? Create, ParsedStated? Stated);
internal sealed record ParsedFood(string Mention, string CanonicalNameEn, string? NameAr, decimal? Amount,
    FoodUnit? Unit, bool AmountExplicit, FoodState? State, string? Variant, Share? Share,
    AmbiguityKind[] Ambiguities, BuddyRange? Estimate);
/// <summary>Diary entries the message refers to: <c>refs</c> are recentEntries list positions (D6), never IDs.</summary>
internal sealed record ParsedReference(int[] Refs, string Mention, ParsedScope Scope, string? DateHint, string? SlotHint);
internal sealed record ParsedMove(string? DateHint, string? SlotHint, string? TimeHint);
internal sealed record ParsedPortion(decimal? Amount, FoodUnit? Unit, decimal? Fraction, int? People, bool Rest);
internal sealed record ParsedMemory(ParsedMemoryOperation Operation, ParsedMemoryKind MemoryKind, string? Subject,
    ParsedMemoryDimension? Dimension, string? Value, decimal? Amount, FoodUnit? Unit);
internal sealed record ParsedBatch(string? Name, decimal? CookedAmount, FoodUnit? CookedUnit, ParsedBatchPath? Path);
internal sealed record ParsedCreate(string Name, string[] Aliases, bool FromActiveProposal);
/// <summary>User-stated figures, transcribed only (TD-092): each non-null value must appear literally in the message.</summary>
internal sealed record ParsedStated(ParsedNutrientBasis Basis, decimal? ServingG, decimal? ServingMl, decimal? Kcal, decimal? ProteinG,
    decimal? CarbsG, decimal? FatG, decimal? FiberG);

/// <summary>Closed invalid-output codes (PA13). Logged and traced as codes only, never content.</summary>
internal enum InvalidOutput { Shape, Bounds, MixedGroups, RefRange, DayHint, StatedNotLiteral, ClosedValue, Food }
