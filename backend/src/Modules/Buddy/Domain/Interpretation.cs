namespace FitnessBuddy.Modules.Buddy.Domain;

// Internal provider data, not API DTOs. There is no nutrition or write operation in this grammar (AI-070/036).
internal enum MessageLanguage { English, Arabic, Mixed }
internal enum MessageScript { Latin, Arabic, Arabizi, Mixed }
internal enum IntentKind { FoodLog, WeighIn, Workout, Clarify, OutOfScope }
internal enum FoodUnit { G, Kg, Ml, L, Piece, Tsp, Tbsp, Cup, Plate, Loaf, Serving }
internal enum FoodState { Raw, Cooked, Dry, Drained, Fried }
internal enum AmbiguityKind { State, Fat, Variant, Portion }
internal enum DeclineReason { Unclear, Unsupported, Medical, OffTopic }

internal sealed record Interpretation(MessageLanguage Language, MessageScript Script, Intent[] Intents);
internal sealed record Intent(IntentKind Kind, string? TimeHint, string? SlotHint, FoodItem[] Items,
    WeighIn? WeighIn, Exercise[] Exercises, DeclineReason? Reason);
internal sealed record FoodItem(string Mention, string CanonicalNameEn, string? NameAr,
    decimal? Amount, FoodUnit? Unit, bool AmountExplicit, FoodState? State, string? Variant,
    Share? Share, AmbiguityKind[] Ambiguities);
internal sealed record Share(decimal? Fraction, int? People);
internal sealed record WeighIn(decimal Value, string Unit);
internal sealed record Exercise(string Name, ExerciseSet[] Sets);
internal sealed record ExerciseSet(int Count, int Reps, decimal? Weight, string? Unit);
