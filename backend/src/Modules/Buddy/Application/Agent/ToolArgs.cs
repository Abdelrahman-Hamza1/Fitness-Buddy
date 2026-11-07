using FitnessBuddy.Modules.Buddy.Domain;

namespace FitnessBuddy.Modules.Buddy.Application;

// B25 WP4: the model-facing tool arguments (internal, versioned with agent-v1; TD-127). Handles (f1, p1, e1, m1, b1, c1, x1)
// stand for IDs; the server maps them. Nullable members are optional for the model.

// Server tools (06 §4.1).
internal sealed record SearchFoodsArgs(string Query, string? Arabic, FoodState? State, string? Kind, int? Limit);
internal sealed record GetDishArgs(string Dish);
internal sealed record LookupBarcodeArgs(string Code);
internal sealed record ComputeItem(string Food, double Amount, FoodUnit Unit);
internal sealed record ComputeArgs(ComputeItem[] Items);
// B26: shared exercise library search and the fit check for suggestions (06 §4.1).
internal sealed record ExerciseSearchArgs(string Query, int? Limit);
internal sealed record FitOption(string Label, FoodArg[] Items);
internal sealed record CheckFitArgs(FitOption[] Options);

// A food the user mentioned (the B08 food rules); `food` may name a search_foods or personal handle.
internal sealed record FoodEstimateArg(BuddyNutrients Low, BuddyNutrients High);
internal sealed record FoodArg(string Mention, string CanonicalNameEn, string? NameAr, double? Amount, FoodUnit? Unit, bool AmountExplicit, FoodState? State,
    string? Variant, double? ShareFraction, int? SharePeople, AmbiguityKind[]? Ambiguities, FoodEstimateArg? Estimate, string? Food);
internal sealed record MoveArg(string? DateHint, string? SlotHint, string? TimeHint);

// Action tools (06 §4.3); `replaces` names an open card (c1…) to update instead of creating one.
internal enum SavedMealOp { Log, Create }
internal enum BatchOp { Create, Portion, Close }
internal enum WeightUnit { Kg, Lb }
internal sealed record FoodLogArgs(FoodArg[] Items, string? TimeHint, string? SlotHint, string? DateHint, string? DishGroup, string? Replaces);
internal sealed record DiaryEditArgs(string[] Entries, string Mention, bool All, string? DateHint, string? SlotHint, double? Amount, FoodUnit? Unit,
    FoodArg? Replacement, MoveArg? Move, string? Replaces);
internal sealed record DiaryDeleteArgs(string[] Entries, string Mention, bool All, string? DateHint, string? SlotHint, string? Replaces);
internal sealed record DiaryCopyArgs(string? SourceDateHint, string? SourceSlotHint, string? SourceTimeHint, string? TargetDateHint, string? TargetSlotHint,
    string? TargetTimeHint, string? Replaces);
internal sealed record SavedMealArgs(SavedMealOp Op, string? Meal, string? Name, string? FromCard, string[]? Entries, string? DateHint, string? SlotHint,
    string? TimeHint, double? ShareFraction, int? SharePeople, string? Replaces);
internal sealed record BatchArgs(BatchOp Op, string? Batch, string? Name, FoodArg[]? Ingredients, double? CookedAmount, FoodUnit? CookedUnit, ParsedBatchPath? Path,
    double? PortionAmount, FoodUnit? PortionUnit, double? PortionFraction, int? PortionPeople, bool Rest, string? TimeHint, string? SlotHint, string? DateHint,
    string? Replaces);
internal sealed record StatedArg(ParsedNutrientBasis Basis, double? ServingG, double? ServingMl, double? Kcal, double? ProteinG, double? CarbsG, double? FatG, double? FiberG);
internal sealed record PersonalFoodArgs(string Name, string[]? Aliases, FoodArg[]? Components, StatedArg? Stated, string? Replaces);
internal sealed record MemoryArgs(ParsedMemoryOperation Operation, ParsedMemoryKind MemoryKind, string? Subject, ParsedMemoryDimension? Dimension,
    string? Value, double? Amount, FoodUnit? Unit, FoodArg? Food, string? Replaces);
internal sealed record WeighInArgs(double Value, WeightUnit Unit, string? TimeHint, string? DateHint, string? Replaces);
internal sealed record SuggestOption(string Label, string? SlotHint, FoodArg[] Items);
internal sealed record SuggestArgs(SuggestOption[] Options, string? Replaces);
// B26 (06 §4.3): workouts (WO-030–033), measurements and pasted imports (WB-030–032).
internal sealed record WorkoutSetArg(int? Reps, double? Weight, int? DurationSeconds, double? DistanceMeters);
internal sealed record WorkoutExerciseArg(string Mention, string? Exercise, string? Notation, WorkoutSetArg[]? Sets, WeightUnit? Unit, bool? PerDumbbell);
internal sealed record WorkoutArgs(string? Name, WorkoutExerciseArg[] Exercises, string? CopyFrom, string? DateHint, string? TimeHint, string? Replaces);
internal enum MeasurementKindArg { Waist, Chest, Hips, Arm, Thigh, Neck, BodyFat }
internal enum MeasurementUnitArg { Cm, In, Percent }
internal sealed record MeasurementArgs(MeasurementKindArg Kind, double Value, MeasurementUnitArg Unit, string? DateHint, string? TimeHint, string? Replaces);
internal enum ImportMetricArg { Weight, Measurement }
internal sealed record ImportRowArg(string Original, DateOnly? Date, double? Value, string? Unit);
internal sealed record ImportArgs(ImportMetricArg Metric, MeasurementKindArg? MeasurementKind, ImportRowArg[] Rows, string? Replaces);

// Phone tools (06 §4.2): the phone enforces their scopes whatever these say.
internal sealed record FindMyFoodsToolArgs(string Query, BuddyPersonalKindCode[]? Kinds);
internal sealed record ReadDiaryToolArgs(string? DateHint, DateOnly? From, DateOnly? To, string? SlotHint, string? Query);
internal sealed record ReadBodyToolArgs(DateOnly From, DateOnly To, BuddyBodyRead What);
internal sealed record ReadWorkoutsToolArgs(DateOnly From, DateOnly To, string? Exercise);
internal sealed record ReadMemoryToolArgs(string? Topic);
