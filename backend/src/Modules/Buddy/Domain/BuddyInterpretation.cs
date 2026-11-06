using System.ComponentModel.DataAnnotations;
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

/// <summary>Closed day-hint grammar (B09 D8): the app resolves it locally; the model only transcribes stated dates.</summary>
internal static class BuddyDayHints
{
    // The validation attributes on these response records shape the published schema only; ProductionProtocol.Valid(...) enforces them (WP2).
    public const string Pattern =
        "^(today|yesterday|daysAgo:([2-9]|[1-9][0-9]{1,2})|lastWeekday:(mon|tue|wed|thu|fri|sat|sun)|date:([0-9]{4}-)?(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01]))$";
}
internal enum BuddyReferenceScope { One, All }
internal enum BuddyReferenceOperation { Edit, Delete }
internal sealed record BuddyDayHint([property: RegularExpression(BuddyDayHints.Pattern)] string? DateHint, string? SlotHint, string? TimeHint);
internal sealed record BuddyEntryReference(string Mention, [property: RegularExpression(BuddyDayHints.Pattern)] string? DateHint, string? SlotHint,
    BuddyReferenceScope Scope);
internal sealed record BuddyDiaryPatch(BuddyAmount? Amount, BuddyFoodItem? Replacement, BuddyDayHint? Move);
internal enum BuddyMemoryOperation { Remember, Forget }
internal enum BuddyMemoryKind { Default, Portion, Alias, Brand, Nickname }
internal enum BuddyMemoryDimension { State, Fat, Variant, Portion }
internal enum BuddyBatchPath { Quick, Leftovers }
internal enum BuddyNutrientBasis { Per100g, Per100ml, PerServing }
internal sealed record BuddyPortion(BuddyAmount? Amount, BuddyShare? Share);
/// <summary>Transcribed user figures (TD-092): never computed or filled by the server.</summary>
internal sealed record BuddyStatedNutrients(BuddyNutrientBasis Basis, [property: Range(0d, 100000d)] double? ServingG, [property: Range(0d, 100000d)] double? ServingMl,
    [property: Range(0d, 10000d)] double? Kcal, [property: Range(0d, 10000d)] double? ProteinG, [property: Range(0d, 10000d)] double? CarbsG,
    [property: Range(0d, 10000d)] double? FatG, [property: Range(0d, 10000d)] double? FiberG);

[JsonPolymorphic(TypeDiscriminatorPropertyName = "kind")]
[JsonDerivedType(typeof(BuddyFoodLog), "foodLog")]
[JsonDerivedType(typeof(BuddyClarify), "clarify")]
[JsonDerivedType(typeof(BuddyOutOfScope), "outOfScope")]
[JsonDerivedType(typeof(BuddyMedical), "medical")]
[JsonDerivedType(typeof(BuddyWeighIn), "weighIn")]
[JsonDerivedType(typeof(BuddyDiaryEdit), "diaryEdit")]
[JsonDerivedType(typeof(BuddyDiaryDelete), "diaryDelete")]
[JsonDerivedType(typeof(BuddyAmbiguousReference), "ambiguousReference")]
[JsonDerivedType(typeof(BuddyDiaryCopy), "diaryCopy")]
[JsonDerivedType(typeof(BuddyMemoryChange), "memoryChange")]
[JsonDerivedType(typeof(BuddyBatch), "batch")]
[JsonDerivedType(typeof(BuddyBatchPortion), "batchPortion")]
[JsonDerivedType(typeof(BuddyBatchClose), "batchClose")]
[JsonDerivedType(typeof(BuddyPersonalFoodCreate), "personalFoodCreate")]
[JsonDerivedType(typeof(BuddySavedMealLog), "savedMealLog")]
[JsonDerivedType(typeof(BuddySavedMealCreate), "savedMealCreate")]
[JsonDerivedType(typeof(BuddyMeasurement), "measurement")]
[JsonDerivedType(typeof(BuddyWorkout), "workout")]
[JsonDerivedType(typeof(BuddyImportRows), "importRows")]
[JsonDerivedType(typeof(BuddySuggestion), "suggestion")]
internal abstract record BuddyIntent(string Language, string Script);
internal sealed record BuddyFoodLog(string Language, string Script, string? TimeHint, string? SlotHint,
    [property: RegularExpression(BuddyDayHints.Pattern)] string? DateHint, string? DishGroup, BuddyFoodItem[] Items) : BuddyIntent(Language, Script);
internal sealed record BuddyClarify(string Language, string Script, string Reason) : BuddyIntent(Language, Script);
internal sealed record BuddyOutOfScope(string Language, string Script, string Reason) : BuddyIntent(Language, Script);
internal sealed record BuddyMedical(string Language, string Script) : BuddyIntent(Language, Script);
internal sealed record BuddyWeighIn(string Language, string Script, double Value, string Unit, string? TimeHint,
    [property: RegularExpression(BuddyDayHints.Pattern)] string? DateHint) : BuddyIntent(Language, Script);
internal sealed record BuddyDiaryEdit(string Language, string Script, [property: MaxLength(30)] Guid[] Targets, BuddyEntryReference Reference,
    BuddyDiaryPatch Patch) : BuddyIntent(Language, Script);
internal sealed record BuddyDiaryDelete(string Language, string Script, [property: MaxLength(30)] Guid[] Targets, BuddyEntryReference Reference)
    : BuddyIntent(Language, Script);
internal sealed record BuddyAmbiguousReference(string Language, string Script, BuddyReferenceOperation Operation,
    [property: MinLength(2), MaxLength(30)] Guid[] Candidates, BuddyEntryReference Reference, BuddyDiaryPatch? Patch) : BuddyIntent(Language, Script);
internal sealed record BuddyDiaryCopy(string Language, string Script, BuddyDayHint Source, BuddyDayHint Target) : BuddyIntent(Language, Script);
internal sealed record BuddyMemoryChange(string Language, string Script, BuddyMemoryOperation Operation, BuddyMemoryKind MemoryKind, string? Subject,
    BuddyMemoryDimension? Dimension, string? Value, BuddyAmount? Amount, BuddyFoodItem? Food) : BuddyIntent(Language, Script);
internal sealed record BuddyBatch(string Language, string Script, string? Name, [property: MinLength(1), MaxLength(30)] BuddyFoodItem[] Ingredients,
    BuddyAmount? CookedWeight, BuddyBatchPath? Path, BuddyPortion? EatenNow, string? TimeHint, string? SlotHint,
    [property: RegularExpression(BuddyDayHints.Pattern)] string? DateHint) : BuddyIntent(Language, Script);
internal sealed record BuddyBatchPortion(string Language, string Script, Guid BatchId, BuddyPortion? Portion, bool Rest, string? TimeHint, string? SlotHint,
    [property: RegularExpression(BuddyDayHints.Pattern)] string? DateHint) : BuddyIntent(Language, Script);
internal sealed record BuddyBatchClose(string Language, string Script, Guid BatchId) : BuddyIntent(Language, Script);
internal sealed record BuddyPersonalFoodCreate(string Language, string Script, string Name, [property: MaxLength(5)] string[] Aliases,
    [property: MaxLength(30)] BuddyFoodItem[] Components, BuddyStatedNutrients? Stated) : BuddyIntent(Language, Script);
internal sealed record BuddySavedMealLog(string Language, string Script, Guid SavedMealId, string? TimeHint, string? SlotHint,
    [property: RegularExpression(BuddyDayHints.Pattern)] string? DateHint, BuddyShare? Share) : BuddyIntent(Language, Script);
internal sealed record BuddySavedMealCreate(string Language, string Script, string Name, Guid? ActiveProposal, [property: MaxLength(30)] Guid[] Targets,
    BuddyDayHint? Source) : BuddyIntent(Language, Script);

// B25 WP1: additive kinds for the agent (06 §4.3), defined now and emitted by B26 / A68. Interpret never emits them.
internal enum BuddyBodyMeasurementKind { Waist, Chest, Hips, Arm, Thigh, Neck, BodyFat, Custom }
internal enum BuddyMeasurementUnit { Cm, In, Percent }
internal enum BuddyLoadUnit { Kg, Lb }
internal enum BuddyImportMetric { Weight, Measurement }
internal sealed record BuddyMeasurement(string Language, string Script, BuddyBodyMeasurementKind MeasurementKind, Guid? CustomTypeId,
    [property: Range(0d, 100000d)] double Value, BuddyMeasurementUnit Unit, string? TimeHint,
    [property: RegularExpression(BuddyDayHints.Pattern)] string? DateHint) : BuddyIntent(Language, Script);
internal sealed record BuddyWorkout(string Language, string Script, [property: MaxLength(120)] string? Name, string? TimeHint,
    [property: RegularExpression(BuddyDayHints.Pattern)] string? DateHint, [property: MinLength(1), MaxLength(30)] BuddyWorkoutExercise[] Exercises)
    : BuddyIntent(Language, Script);
/// <summary><c>exerciseRef</c> is a library code or custom exercise UUID; <c>null</c> when nothing matched (WO-033).</summary>
internal sealed record BuddyWorkoutExercise([property: MaxLength(200)] string Mention, [property: MaxLength(64)] string? ExerciseRef,
    [property: MaxLength(50)] BuddyWorkoutSet[] Sets, [property: MaxLength(5)] string[] Assumptions);
internal sealed record BuddyWorkoutSet(int? Reps, [property: Range(0d, 10000d)] double? Weight, BuddyLoadUnit? Unit, bool PerDumbbell,
    int? DurationSeconds, double? DistanceMeters);
/// <summary>Pasted rows as read (WB-030–032); unit inference and plausibility flags are the app's.</summary>
internal sealed record BuddyImportRows(string Language, string Script, BuddyImportMetric Metric, BuddyBodyMeasurementKind? MeasurementKind,
    [property: MinLength(1), MaxLength(200)] BuddyImportRow[] Rows) : BuddyIntent(Language, Script);
internal sealed record BuddyImportRow(DateOnly? Date, double? Value, [property: MaxLength(16)] string? Unit, [property: MaxLength(200)] string Original);
/// <summary>2–4 ready food options (AI-120/121); a tap makes a food card, the app drops options that don't fit.</summary>
internal sealed record BuddySuggestion(string Language, string Script, [property: MinLength(2), MaxLength(4)] BuddySuggestionOption[] Options)
    : BuddyIntent(Language, Script);
internal sealed record BuddySuggestionOption([property: MaxLength(120)] string Label, string? SlotHint,
    [property: MinLength(1), MaxLength(10)] BuddyFoodItem[] Items);
internal sealed record BuddyInterpretation(string PromptVersion, string Model, BuddyIntent[] Intents);
