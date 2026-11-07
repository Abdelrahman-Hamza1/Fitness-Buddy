namespace FitnessBuddy.Modules.Buddy.Domain;

// Internal model-facing value types shared by the agent tools and resolvers, not API DTOs. There is no nutrition or write operation in this grammar (AI-070/036).
internal enum MessageLanguage { English, Arabic, Mixed }
internal enum MessageScript { Latin, Arabic, Arabizi, Mixed }
internal enum FoodUnit { G, Kg, Ml, L, Piece, Tsp, Tbsp, Cup, Plate, Loaf, Serving }
internal enum FoodState { Raw, Cooked, Dry, Drained, Fried }
internal enum AmbiguityKind { State, Fat, Variant, Portion }
internal enum DeclineReason { Unclear, Unsupported, Medical, OffTopic }

internal sealed record Share(decimal? Fraction, int? People);
internal sealed record WeighIn(decimal Value, string Unit);
