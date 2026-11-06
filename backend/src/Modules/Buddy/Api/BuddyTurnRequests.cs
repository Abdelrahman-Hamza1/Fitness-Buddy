using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace FitnessBuddy.Modules.Buddy.Api;

// B25 WP1: the agent turn request bodies (06 §3.1–§3.2, §4.2, §6.3). Public because the validation
// generator only sees public types; enums used by requests are public for the same reason. The Domain
// keeps its own internal copies for the response side (inward dependencies only).

public enum BuddyTurnMode { Chat, WeeklyReview }
public enum BuddyHistoryRole { User, Buddy }
public enum BuddyOutcomeStatus { Confirmed, Edited, Discarded, Pending }
public enum BuddyPriorCardStatus { Confirmed, Discarded, Pending }
public enum BuddyPersonalKind { PersonalFood, SavedMeal, Batch, Usual }
public enum BuddyMassUnit { Kg, Lb }
public enum BuddyLengthUnit { Cm, In }
public enum BuddyEnergyUnit { Kcal }
public enum BuddyPhoneToolError { BudgetExceeded, UnsupportedPlan, InvalidArgs, Unavailable }
public enum BuddyBodyUnit { Kg, Cm, Percent }
public enum BuddyClaimMetric { Kcal, Protein, Carbs, Fat, Fiber, Weight, WeightTrend, Measurement, Workouts, Sets, Volume, ExerciseLastDate, ExercisePr, WeighIns, LoggedDays }
public enum BuddyClaimOperation { Total, Average, Remaining, Latest, Change, Count, Max, Min, Last }
public enum BuddyClaimUnit { Kcal, G, Kg, Cm, Percent, Count, Date }
public enum BuddyLinkScreen { Diary, WeightGraph, Progress, Exercise, Workout }

/// <summary>Starts a turn (06 §3.1). <c>turnId</c> is the chat message ID and equals the Idempotency-Key.</summary>
[JsonUnmappedMemberHandling(JsonUnmappedMemberHandling.Disallow)]
public sealed record BuddyTurnStart(Guid TurnId, BuddyTurnMode Mode, BuddyTurnMessage Message,
    [property: MaxLength(12)] BuddyHistoryEntry[] History, BuddyConversationSummary? Summary, BuddyCompaction? Compact,
    [property: MaxLength(20)] BuddyPersonalItem[] Personal, BuddyTurnProfile Profile, BuddyTurnSnapshot Snapshot,
    BuddyTurnReference? AckTurn, BuddyPriorAttempt? PriorAttempt, bool Trace);

public sealed record BuddyTurnMessage([property: MinLength(1), MaxLength(2000)] string Text, [property: MaxLength(400000)] string? Image);
public sealed record BuddyHistoryEntry(Guid MessageId, BuddyHistoryRole Role, [property: MaxLength(1000)] string Text,
    [property: MaxLength(6)] BuddyOutcome[] Outcomes);
public sealed record BuddyOutcome(Guid ProposalId, [property: MaxLength(32)] string Kind, BuddyOutcomeStatus Status, [property: MaxLength(120)] string Label);
public sealed record BuddyConversationSummary([property: MaxLength(1500)] string Text, [property: Range(1, int.MaxValue)] int Revision, Guid Watermark);
public sealed record BuddyCompaction([property: MinLength(1), MaxLength(24)] BuddyHistoryEntry[] Evicted, [property: Range(0, int.MaxValue)] int PreviousRevision);
public sealed record BuddyPersonalItem(Guid Ref, BuddyPersonalKind Kind, [property: MinLength(1), MaxLength(5)] string[] Names,
    [property: MaxLength(10)] string[] Aliases, [property: MaxLength(32)] string? State, BuddyNutrientsRequest? Per100,
    [property: MaxLength(20)] BuddyServingRequest[] Servings, [property: MaxLength(10)] BuddyPortionFacts[] Portions);
public sealed record BuddyPortionFacts([property: MaxLength(120)] string Label, double? G, BuddyNutrientsRequest Nutrients);
public sealed record BuddyTurnProfile([property: MaxLength(30)] BuddyMemory[] Memory, [property: MaxLength(20)] BuddyHabitDefault[] Defaults,
    bool Halal, BuddyUnits Units, BuddyRamadan Ramadan);
public sealed record BuddyHabitDefault([property: MaxLength(32)] string Kind, [property: MaxLength(200)] string Subject, [property: MaxLength(200)] string Value);
public sealed record BuddyUnits(BuddyMassUnit Mass, BuddyLengthUnit Length, BuddyEnergyUnit Energy);
public sealed record BuddyTurnSnapshot(DateTimeOffset Now, [property: Range(-840, 840)] int TzOffsetMin, [property: MaxLength(12)] BuddySlot[] Slots,
    BuddyDayTotals Today, [property: MaxLength(5)] BuddyOpenCard[] OpenCards);
public sealed record BuddyDayTotals(double Kcal, double ProteinG, double CarbsG, double FatG, double FiberG, BuddyDayTargets? Targets);
public sealed record BuddyDayTargets(double? Kcal, double? ProteinG, double? CarbsG, double? FatG, double? FiberG);
public sealed record BuddyOpenCard(Guid ProposalId, [property: Range(1, int.MaxValue)] int Revision, [property: MaxLength(32)] string Kind,
    [property: MaxLength(200)] string Summary);
public sealed record BuddyTurnReference(Guid TurnId);
public sealed record BuddyPriorAttempt([property: Range(1, 2)] int Attempt, [property: MaxLength(12)] BuddyPriorCard[] Cards);
public sealed record BuddyPriorCard(Guid ProposalId, BuddyPriorCardStatus Status, [property: MaxLength(120)] string Line);

/// <summary>Answers a paused round's phone tools (06 §3.2): exactly the pending call IDs, each once.</summary>
[JsonUnmappedMemberHandling(JsonUnmappedMemberHandling.Disallow)]
public sealed record BuddyTurnContinue(Guid TurnId, [property: Range(1, 3)] int Round, [property: MinLength(1), MaxLength(262144)] string Continuation,
    [property: MinLength(1), MaxLength(6)] BuddyPhoneToolResult[] Results, BuddyPriorAttempt? PriorAttempt);

[JsonPolymorphic(TypeDiscriminatorPropertyName = "name")]
[JsonDerivedType(typeof(BuddyFindMyFoodsResult), "findMyFoods")]
[JsonDerivedType(typeof(BuddyReadDiaryResult), "readDiary")]
[JsonDerivedType(typeof(BuddyReadBodyResult), "readBody")]
[JsonDerivedType(typeof(BuddyReadWorkoutsResult), "readWorkouts")]
[JsonDerivedType(typeof(BuddyReadMemoryResult), "readMemory")]
[JsonDerivedType(typeof(BuddyQueryDataResult), "queryData")]
public abstract record BuddyPhoneToolResult(Guid CallId, bool Ok, BuddyPhoneToolError? Error);
public sealed record BuddyFindMyFoodsResult(Guid CallId, bool Ok, BuddyPhoneToolError? Error, BuddyFindMyFoodsData? Data) : BuddyPhoneToolResult(CallId, Ok, Error);
public sealed record BuddyReadDiaryResult(Guid CallId, bool Ok, BuddyPhoneToolError? Error, BuddyReadDiaryData? Data) : BuddyPhoneToolResult(CallId, Ok, Error);
public sealed record BuddyReadBodyResult(Guid CallId, bool Ok, BuddyPhoneToolError? Error, BuddyReadBodyData? Data) : BuddyPhoneToolResult(CallId, Ok, Error);
public sealed record BuddyReadWorkoutsResult(Guid CallId, bool Ok, BuddyPhoneToolError? Error, BuddyReadWorkoutsData? Data) : BuddyPhoneToolResult(CallId, Ok, Error);
public sealed record BuddyReadMemoryResult(Guid CallId, bool Ok, BuddyPhoneToolError? Error, BuddyReadMemoryData? Data) : BuddyPhoneToolResult(CallId, Ok, Error);
public sealed record BuddyQueryDataResult(Guid CallId, bool Ok, BuddyPhoneToolError? Error, BuddyQueryResultData? Data) : BuddyPhoneToolResult(CallId, Ok, Error);

// Phone-tool result data with the phone-enforced scope caps (06 §4.2). Local IDs here are swapped for handles by the server.
public sealed record BuddyFindMyFoodsData([property: MaxLength(20)] BuddyPersonalItem[] Items);
public sealed record BuddyReadDiaryData([property: MaxLength(40)] BuddyDiaryRow[] Entries, bool Truncated);
public sealed record BuddyDiaryRow(Guid Id, DateOnly Date, [property: MaxLength(200)] string Slot, [property: MaxLength(200)] string Name, double? Grams, double? Kcal);
public sealed record BuddyReadBodyData([property: MaxLength(31)] BuddyBodyValue[] Values, BuddyWeightTrend? Trend);
public sealed record BuddyBodyValue(DateOnly Date, [property: MaxLength(64)] string Metric, double Value, BuddyBodyUnit Unit);
public sealed record BuddyWeightTrend(DateOnly From, DateOnly To, double StartKg, double EndKg, double ChangeKg, double? WeeklyChangeKg,
    [property: Range(0, 400)] int WeighIns);
public sealed record BuddyReadWorkoutsData([property: MaxLength(15)] BuddyWorkoutSessionRow[] Sessions, [property: MaxLength(20)] BuddyExercisePr[] Prs);
public sealed record BuddyWorkoutSessionRow(Guid Id, DateOnly Date, [property: MaxLength(120)] string? Name,
    [property: MaxLength(30)] BuddyWorkoutExerciseRow[] Exercises);
public sealed record BuddyWorkoutExerciseRow([property: MaxLength(64)] string ExerciseRef, [property: MaxLength(200)] string Name,
    [property: MaxLength(50)] BuddySetRow[] Sets);
public sealed record BuddySetRow(int? Reps, double? Kg, int? DurationSeconds, double? DistanceMeters);
public sealed record BuddyExercisePr([property: MaxLength(64)] string ExerciseRef, [property: MaxLength(200)] string Name, double? Kg, int? Reps, DateOnly Date);
public sealed record BuddyReadMemoryData([property: MaxLength(30)] BuddyMemory[] Items);
public sealed record BuddyQueryResultData([property: MaxLength(20)] BuddyClaimValue[] Claims, BuddyCoverage Coverage, BuddyQueryLink? Link);
/// <summary>A computed number from the device's QueryEngine; the server assigns the claim ID and renders the label (06 §4, §7).</summary>
public sealed record BuddyClaimValue(BuddyClaimMetric Metric, BuddyClaimOperation Operation, double? Value, DateOnly? Date, BuddyClaimUnit Unit,
    Guid? WorkoutId, [property: MaxLength(64)] string? ExerciseRef, [property: MaxLength(64)] string? MuscleGroup);
public sealed record BuddyCoverage([property: Range(0, 400)] int Days, [property: Range(0, 400)] int LoggedDays);
public sealed record BuddyQueryLink(BuddyLinkScreen Screen, DateOnly? Date, DateOnly? From, DateOnly? To, [property: MaxLength(64)] string? ExerciseRef, Guid? WorkoutId);
