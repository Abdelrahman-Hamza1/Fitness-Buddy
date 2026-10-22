using System.Text.Json.Serialization;

namespace FitnessBuddy.Modules.Buddy.Domain;

internal sealed record BuddyNutrients(double Kcal, double ProteinG, double CarbsG, double FatG, double FiberG);
internal sealed record BuddyRange(BuddyNutrients Low, BuddyNutrients High);
internal sealed record BuddyServing(string UnitCode, double? G, double? Ml, double? RangeLo, double? RangeHi, string Source);
internal sealed record BuddyCandidate(string Key, string NameEn, string? NameAr, string State, string Source,
    BuddyNutrients Nutrients, BuddyRange? Ranges, BuddyServing[] Servings, double? DensityGPerMl, string? YieldGroup);
internal sealed record BuddyAmount(double? Value, string? Unit, bool Explicit);
internal sealed record BuddyShare(double? Fraction, int? People);
internal sealed record BuddyDimensionOption(string Value, string? CandidateKey, double? Amount, string? Unit, BuddyCandidate? Candidate);
internal sealed record BuddyDimension(string Kind, string? StatedValue, BuddyDimensionOption[] Options);
internal sealed record BuddyEstimate(BuddyRange Range, string Reason);
internal sealed record BuddyFoodItem(string Mention, BuddyCandidate? Match, BuddyCandidate[] Alternatives,
    BuddyAmount Amount, BuddyShare? Share, BuddyDimension[] Dimensions, BuddyEstimate? Estimate);

[JsonPolymorphic(TypeDiscriminatorPropertyName = "kind")]
[JsonDerivedType(typeof(BuddyFoodLog), "foodLog")]
[JsonDerivedType(typeof(BuddyClarify), "clarify")]
[JsonDerivedType(typeof(BuddyOutOfScope), "outOfScope")]
[JsonDerivedType(typeof(BuddyMedical), "medical")]
[JsonDerivedType(typeof(BuddyWeighIn), "weighIn")]
internal abstract record BuddyIntent(string Language, string Script);
internal sealed record BuddyFoodLog(string Language, string Script, string? TimeHint, string? SlotHint,
    string? DishGroup, BuddyFoodItem[] Items) : BuddyIntent(Language, Script);
internal sealed record BuddyClarify(string Language, string Script, string Reason) : BuddyIntent(Language, Script);
internal sealed record BuddyOutOfScope(string Language, string Script, string Reason) : BuddyIntent(Language, Script);
internal sealed record BuddyMedical(string Language, string Script) : BuddyIntent(Language, Script);
internal sealed record BuddyWeighIn(string Language, string Script, double Value, string Unit, string? TimeHint) : BuddyIntent(Language, Script);
internal sealed record BuddyInterpretation(string PromptVersion, string Model, BuddyIntent[] Intents);
