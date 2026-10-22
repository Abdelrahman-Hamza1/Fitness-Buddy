namespace FitnessBuddy.Modules.Buddy.Domain;

internal enum ParsedKind { FoodLog, Clarify, OutOfScope, Medical, WeighIn }
internal sealed record ParsedMessage(MessageLanguage Language, MessageScript Script, ParsedIntent[] Intents);
internal sealed record ParsedIntent(ParsedKind Kind, string? TimeHint, string? SlotHint, string? DishGroup,
    ParsedFood[] Items, WeighIn? WeighIn, DeclineReason? Reason);
internal sealed record ParsedFood(string Mention, string CanonicalNameEn, string? NameAr, decimal? Amount,
    FoodUnit? Unit, bool AmountExplicit, FoodState? State, string? Variant, Share? Share,
    AmbiguityKind[] Ambiguities, BuddyRange? Estimate);
