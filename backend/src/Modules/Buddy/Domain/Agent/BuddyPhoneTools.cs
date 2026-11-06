using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace FitnessBuddy.Modules.Buddy.Domain;

// B25 WP1: phone-tool calls sent in a `phoneTools` event (06 §4.2). The phone runs them under its own scopes
// and disclosure budget whatever the arguments say. Handles are already mapped back to local IDs here.

internal enum BuddyPersonalKindCode { PersonalFood, SavedMeal, Batch, Usual }
internal enum BuddyBodyRead { Weight, Trend, Measurements }

[JsonPolymorphic(TypeDiscriminatorPropertyName = "name")]
[JsonDerivedType(typeof(BuddyFindMyFoodsCall), "findMyFoods")]
[JsonDerivedType(typeof(BuddyReadDiaryCall), "readDiary")]
[JsonDerivedType(typeof(BuddyReadBodyCall), "readBody")]
[JsonDerivedType(typeof(BuddyReadWorkoutsCall), "readWorkouts")]
[JsonDerivedType(typeof(BuddyReadMemoryCall), "readMemory")]
[JsonDerivedType(typeof(BuddyQueryDataCall), "queryData")]
internal abstract record BuddyPhoneToolCall(Guid CallId);
internal sealed record BuddyFindMyFoodsCall(Guid CallId, BuddyFindMyFoodsArgs Args) : BuddyPhoneToolCall(CallId);
internal sealed record BuddyReadDiaryCall(Guid CallId, BuddyReadDiaryArgs Args) : BuddyPhoneToolCall(CallId);
internal sealed record BuddyReadBodyCall(Guid CallId, BuddyReadBodyArgs Args) : BuddyPhoneToolCall(CallId);
internal sealed record BuddyReadWorkoutsCall(Guid CallId, BuddyReadWorkoutsArgs Args) : BuddyPhoneToolCall(CallId);
internal sealed record BuddyReadMemoryCall(Guid CallId, BuddyReadMemoryArgs Args) : BuddyPhoneToolCall(CallId);
internal sealed record BuddyQueryDataCall(Guid CallId, BuddyQueryPlan Args) : BuddyPhoneToolCall(CallId);

internal sealed record BuddyFindMyFoodsArgs([property: MinLength(1), MaxLength(200)] string Query, [property: MaxLength(4)] BuddyPersonalKindCode[] Kinds);
internal sealed record BuddyReadDiaryArgs([property: RegularExpression(BuddyDayHints.Pattern)] string? DateHint, BuddyDateRange? Range,
    [property: MaxLength(200)] string? SlotHint, [property: MaxLength(200)] string? Query);
internal sealed record BuddyDateRange(DateOnly From, DateOnly To);
internal sealed record BuddyReadBodyArgs(BuddyDateRange Range, BuddyBodyRead What);
internal sealed record BuddyReadWorkoutsArgs(BuddyDateRange Range, [property: MaxLength(64)] string? ExerciseRef);
internal sealed record BuddyReadMemoryArgs([property: MaxLength(200)] string? Topic);

// The frozen QueryPlan grammar (06 §6.3). Flat with nullable members; valid combinations are checked by the
// device's QueryEngine, which answers ok:false unsupportedPlan otherwise.
internal enum BuddyQueryMetric { Kcal, Protein, Carbs, Fat, Fiber, Weight, WeightTrend, Measurement, Workouts, Sets, Volume, ExerciseLastDate, ExercisePr, WeighIns, LoggedDays }
internal enum BuddyQueryOp { Total, Average, Remaining, Latest, Change, Count, Max, Min, Last }
internal enum BuddyPeriodKind { Today, Yesterday, ThisWeek, LastWeek, ThisMonth, LastMonth, LastNDays, Since, Range }
internal enum BuddySinceEvent { RamadanStart, PhaseStart, Date }
internal sealed record BuddyQueryPlan(BuddyQueryMetric Metric, [property: MaxLength(64)] string? MeasurementType, BuddyQueryOp Op, BuddyQueryPeriod Period,
    BuddyQueryFilters? Filters);
internal sealed record BuddyQueryPeriod(BuddyPeriodKind Kind, [property: Range(1, 400)] int? Days, BuddySinceEvent? Since, DateOnly? From, DateOnly? To);
internal sealed record BuddyQueryFilters([property: MaxLength(200)] string? Slot, [property: MaxLength(64)] string? ExerciseRef,
    [property: MaxLength(64)] string? MuscleGroup, bool? CompleteDaysOnly, [property: MaxLength(7)] int[] Weekdays);
