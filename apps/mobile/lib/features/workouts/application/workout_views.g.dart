// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_views.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The local day the Workouts screens treat as today (new sessions, the
/// week strip, the date picker's limit).

@ProviderFor(workoutToday)
final workoutTodayProvider = WorkoutTodayProvider._();

/// The local day the Workouts screens treat as today (new sessions, the
/// week strip, the date picker's limit).

final class WorkoutTodayProvider
    extends $FunctionalProvider<LocalDate, LocalDate, LocalDate>
    with $Provider<LocalDate> {
  /// The local day the Workouts screens treat as today (new sessions, the
  /// week strip, the date picker's limit).
  WorkoutTodayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workoutTodayProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workoutTodayHash();

  @$internal
  @override
  $ProviderElement<LocalDate> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LocalDate create(Ref ref) {
    return workoutToday(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocalDate value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocalDate>(value),
    );
  }
}

String _$workoutTodayHash() => r'46e1f92961aceb1ab02c5d83e9d9d5e6eb469723';

/// Every live session, by date then ID (A37 D24).

@ProviderFor(allWorkoutSessions)
final allWorkoutSessionsProvider = AllWorkoutSessionsProvider._();

/// Every live session, by date then ID (A37 D24).

final class AllWorkoutSessionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Stored<WorkoutSessionDraft>>>,
          List<Stored<WorkoutSessionDraft>>,
          Stream<List<Stored<WorkoutSessionDraft>>>
        >
    with
        $FutureModifier<List<Stored<WorkoutSessionDraft>>>,
        $StreamProvider<List<Stored<WorkoutSessionDraft>>> {
  /// Every live session, by date then ID (A37 D24).
  AllWorkoutSessionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allWorkoutSessionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allWorkoutSessionsHash();

  @$internal
  @override
  $StreamProviderElement<List<Stored<WorkoutSessionDraft>>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Stored<WorkoutSessionDraft>>> create(Ref ref) {
    return allWorkoutSessions(ref);
  }
}

String _$allWorkoutSessionsHash() =>
    r'64354a407992adf7a1103e920f2f517c2448bc18';

/// The PR markers of the whole history (WO-042, D11).

@ProviderFor(workoutPrs)
final workoutPrsProvider = WorkoutPrsProvider._();

/// The PR markers of the whole history (WO-042, D11).

final class WorkoutPrsProvider
    extends
        $FunctionalProvider<
          AsyncValue<SessionPrs>,
          SessionPrs,
          FutureOr<SessionPrs>
        >
    with $FutureModifier<SessionPrs>, $FutureProvider<SessionPrs> {
  /// The PR markers of the whole history (WO-042, D11).
  WorkoutPrsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workoutPrsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workoutPrsHash();

  @$internal
  @override
  $FutureProviderElement<SessionPrs> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<SessionPrs> create(Ref ref) {
    return workoutPrs(ref);
  }
}

String _$workoutPrsHash() => r'5261363288134613249e8c078ee45ef494610de2';

/// The user's recent exercises, newest first, with their top set (A52 D3,
/// D-089): the picker's "Your recent".

@ProviderFor(recentExercises)
final recentExercisesProvider = RecentExercisesProvider._();

/// The user's recent exercises, newest first, with their top set (A52 D3,
/// D-089): the picker's "Your recent".

final class RecentExercisesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<RecentExercise>>,
          List<RecentExercise>,
          FutureOr<List<RecentExercise>>
        >
    with
        $FutureModifier<List<RecentExercise>>,
        $FutureProvider<List<RecentExercise>> {
  /// The user's recent exercises, newest first, with their top set (A52 D3,
  /// D-089): the picker's "Your recent".
  RecentExercisesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentExercisesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentExercisesHash();

  @$internal
  @override
  $FutureProviderElement<List<RecentExercise>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<RecentExercise>> create(Ref ref) {
    return recentExercises(ref);
  }
}

String _$recentExercisesHash() => r'e247889ecfa63ed4904d0fa9228f8eb6d75412d9';

/// Every session, newest first, summarized: the history list (WO-040).

@ProviderFor(workoutHistory)
final workoutHistoryProvider = WorkoutHistoryProvider._();

/// Every session, newest first, summarized: the history list (WO-040).

final class WorkoutHistoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SessionSummary>>,
          List<SessionSummary>,
          FutureOr<List<SessionSummary>>
        >
    with
        $FutureModifier<List<SessionSummary>>,
        $FutureProvider<List<SessionSummary>> {
  /// Every session, newest first, summarized: the history list (WO-040).
  WorkoutHistoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workoutHistoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workoutHistoryHash();

  @$internal
  @override
  $FutureProviderElement<List<SessionSummary>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<SessionSummary>> create(Ref ref) {
    return workoutHistory(ref);
  }
}

String _$workoutHistoryHash() => r'78ecb8173eaa789fd2eed91beeaef4da64ef5155';

/// The latest sessions, newest first (the Workouts tab, with Repeat).

@ProviderFor(recentWorkouts)
final recentWorkoutsProvider = RecentWorkoutsProvider._();

/// The latest sessions, newest first (the Workouts tab, with Repeat).

final class RecentWorkoutsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SessionSummary>>,
          List<SessionSummary>,
          FutureOr<List<SessionSummary>>
        >
    with
        $FutureModifier<List<SessionSummary>>,
        $FutureProvider<List<SessionSummary>> {
  /// The latest sessions, newest first (the Workouts tab, with Repeat).
  RecentWorkoutsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentWorkoutsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentWorkoutsHash();

  @$internal
  @override
  $FutureProviderElement<List<SessionSummary>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<SessionSummary>> create(Ref ref) {
    return recentWorkouts(ref);
  }
}

String _$recentWorkoutsHash() => r'b4e07af2a371a12e583d772ccc53cbad79c76e15';

/// The live templates, by name (WO-020).

@ProviderFor(workoutTemplates)
final workoutTemplatesProvider = WorkoutTemplatesProvider._();

/// The live templates, by name (WO-020).

final class WorkoutTemplatesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Stored<WorkoutTemplateDraft>>>,
          List<Stored<WorkoutTemplateDraft>>,
          Stream<List<Stored<WorkoutTemplateDraft>>>
        >
    with
        $FutureModifier<List<Stored<WorkoutTemplateDraft>>>,
        $StreamProvider<List<Stored<WorkoutTemplateDraft>>> {
  /// The live templates, by name (WO-020).
  WorkoutTemplatesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workoutTemplatesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workoutTemplatesHash();

  @$internal
  @override
  $StreamProviderElement<List<Stored<WorkoutTemplateDraft>>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Stored<WorkoutTemplateDraft>>> create(Ref ref) {
    return workoutTemplates(ref);
  }
}

String _$workoutTemplatesHash() => r'909c01463eb082a764ba2f563e5adce05bde39f0';

/// The weekly plan: each planned weekday's live template (WO-021). Empty
/// without a plan: a plan is never required (D-085).

@ProviderFor(workoutPlan)
final workoutPlanProvider = WorkoutPlanProvider._();

/// The weekly plan: each planned weekday's live template (WO-021). Empty
/// without a plan: a plan is never required (D-085).

final class WorkoutPlanProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<DayOfWeek, String>>,
          Map<DayOfWeek, String>,
          Stream<Map<DayOfWeek, String>>
        >
    with
        $FutureModifier<Map<DayOfWeek, String>>,
        $StreamProvider<Map<DayOfWeek, String>> {
  /// The weekly plan: each planned weekday's live template (WO-021). Empty
  /// without a plan: a plan is never required (D-085).
  WorkoutPlanProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workoutPlanProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workoutPlanHash();

  @$internal
  @override
  $StreamProviderElement<Map<DayOfWeek, String>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<DayOfWeek, String>> create(Ref ref) {
    return workoutPlan(ref);
  }
}

String _$workoutPlanHash() => r'136c00f3867b78eeca6b6fa451d2c9a24c66aada';

/// The week containing [today]: trained days, and plan hints for today and
/// later (WO-024: no "missed" days, ever).

@ProviderFor(workoutWeek)
final workoutWeekProvider = WorkoutWeekFamily._();

/// The week containing [today]: trained days, and plan hints for today and
/// later (WO-024: no "missed" days, ever).

final class WorkoutWeekProvider
    extends
        $FunctionalProvider<
          AsyncValue<WorkoutWeek>,
          WorkoutWeek,
          FutureOr<WorkoutWeek>
        >
    with $FutureModifier<WorkoutWeek>, $FutureProvider<WorkoutWeek> {
  /// The week containing [today]: trained days, and plan hints for today and
  /// later (WO-024: no "missed" days, ever).
  WorkoutWeekProvider._({
    required WorkoutWeekFamily super.from,
    required LocalDate super.argument,
  }) : super(
         retry: null,
         name: r'workoutWeekProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workoutWeekHash();

  @override
  String toString() {
    return r'workoutWeekProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<WorkoutWeek> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<WorkoutWeek> create(Ref ref) {
    final argument = this.argument as LocalDate;
    return workoutWeek(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkoutWeekProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workoutWeekHash() => r'e2791a7aea6f7506d23bc6398c7318d75632b2fa';

/// The week containing [today]: trained days, and plan hints for today and
/// later (WO-024: no "missed" days, ever).

final class WorkoutWeekFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<WorkoutWeek>, LocalDate> {
  WorkoutWeekFamily._()
    : super(
        retry: null,
        name: r'workoutWeekProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The week containing [today]: trained days, and plan hints for today and
  /// later (WO-024: no "missed" days, ever).

  WorkoutWeekProvider call(LocalDate today) =>
      WorkoutWeekProvider._(argument: today, from: this);

  @override
  String toString() => r'workoutWeekProvider';
}

/// The weekly plan's overview, or `null` without a plan (D-089).

@ProviderFor(workoutPlanOverview)
final workoutPlanOverviewProvider = WorkoutPlanOverviewProvider._();

/// The weekly plan's overview, or `null` without a plan (D-089).

final class WorkoutPlanOverviewProvider
    extends
        $FunctionalProvider<
          AsyncValue<PlanOverview?>,
          PlanOverview?,
          FutureOr<PlanOverview?>
        >
    with $FutureModifier<PlanOverview?>, $FutureProvider<PlanOverview?> {
  /// The weekly plan's overview, or `null` without a plan (D-089).
  WorkoutPlanOverviewProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workoutPlanOverviewProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workoutPlanOverviewHash();

  @$internal
  @override
  $FutureProviderElement<PlanOverview?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PlanOverview?> create(Ref ref) {
    return workoutPlanOverview(ref);
  }
}

String _$workoutPlanOverviewHash() =>
    r'9f9b3ab35764997628c5f189e42d2d3b252720d4';

/// The workout row of [date] (D20): its latest session; else, for today or
/// a later day, its planned template; else `null` (no-plan users see
/// nothing until they log; past days are never "missed").

@ProviderFor(todayWorkout)
final todayWorkoutProvider = TodayWorkoutFamily._();

/// The workout row of [date] (D20): its latest session; else, for today or
/// a later day, its planned template; else `null` (no-plan users see
/// nothing until they log; past days are never "missed").

final class TodayWorkoutProvider
    extends
        $FunctionalProvider<
          AsyncValue<TodayWorkout?>,
          TodayWorkout?,
          FutureOr<TodayWorkout?>
        >
    with $FutureModifier<TodayWorkout?>, $FutureProvider<TodayWorkout?> {
  /// The workout row of [date] (D20): its latest session; else, for today or
  /// a later day, its planned template; else `null` (no-plan users see
  /// nothing until they log; past days are never "missed").
  TodayWorkoutProvider._({
    required TodayWorkoutFamily super.from,
    required LocalDate super.argument,
  }) : super(
         retry: null,
         name: r'todayWorkoutProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$todayWorkoutHash();

  @override
  String toString() {
    return r'todayWorkoutProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<TodayWorkout?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TodayWorkout?> create(Ref ref) {
    final argument = this.argument as LocalDate;
    return todayWorkout(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TodayWorkoutProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$todayWorkoutHash() => r'76ca12cef83def06f467fbb867c5f0304a326498';

/// The workout row of [date] (D20): its latest session; else, for today or
/// a later day, its planned template; else `null` (no-plan users see
/// nothing until they log; past days are never "missed").

final class TodayWorkoutFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<TodayWorkout?>, LocalDate> {
  TodayWorkoutFamily._()
    : super(
        retry: null,
        name: r'todayWorkoutProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The workout row of [date] (D20): its latest session; else, for today or
  /// a later day, its planned template; else `null` (no-plan users see
  /// nothing until they log; past days are never "missed").

  TodayWorkoutProvider call(LocalDate date) =>
      TodayWorkoutProvider._(argument: date, from: this);

  @override
  String toString() => r'todayWorkoutProvider';
}

/// The page of exercise [exerciseId], or `null` when the library doesn't
/// know it (a removed custom exercise, D15).

@ProviderFor(exerciseProgress)
final exerciseProgressProvider = ExerciseProgressFamily._();

/// The page of exercise [exerciseId], or `null` when the library doesn't
/// know it (a removed custom exercise, D15).

final class ExerciseProgressProvider
    extends
        $FunctionalProvider<
          AsyncValue<ExerciseProgressView?>,
          ExerciseProgressView?,
          FutureOr<ExerciseProgressView?>
        >
    with
        $FutureModifier<ExerciseProgressView?>,
        $FutureProvider<ExerciseProgressView?> {
  /// The page of exercise [exerciseId], or `null` when the library doesn't
  /// know it (a removed custom exercise, D15).
  ExerciseProgressProvider._({
    required ExerciseProgressFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'exerciseProgressProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$exerciseProgressHash();

  @override
  String toString() {
    return r'exerciseProgressProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ExerciseProgressView?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ExerciseProgressView?> create(Ref ref) {
    final argument = this.argument as String;
    return exerciseProgress(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ExerciseProgressProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$exerciseProgressHash() => r'260a8e5da1f77650c1167d0ebed055019aaaa966';

/// The page of exercise [exerciseId], or `null` when the library doesn't
/// know it (a removed custom exercise, D15).

final class ExerciseProgressFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ExerciseProgressView?>, String> {
  ExerciseProgressFamily._()
    : super(
        retry: null,
        name: r'exerciseProgressProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The page of exercise [exerciseId], or `null` when the library doesn't
  /// know it (a removed custom exercise, D15).

  ExerciseProgressProvider call(String exerciseId) =>
      ExerciseProgressProvider._(argument: exerciseId, from: this);

  @override
  String toString() => r'exerciseProgressProvider';
}

/// Whether exercise [exerciseId]'s graph shows the estimated 1RM instead
/// of the heaviest set (WO-041: a toggle; the heaviest set by default).

@ProviderFor(ExerciseGraphE1rm)
final exerciseGraphE1rmProvider = ExerciseGraphE1rmFamily._();

/// Whether exercise [exerciseId]'s graph shows the estimated 1RM instead
/// of the heaviest set (WO-041: a toggle; the heaviest set by default).
final class ExerciseGraphE1rmProvider
    extends $NotifierProvider<ExerciseGraphE1rm, bool> {
  /// Whether exercise [exerciseId]'s graph shows the estimated 1RM instead
  /// of the heaviest set (WO-041: a toggle; the heaviest set by default).
  ExerciseGraphE1rmProvider._({
    required ExerciseGraphE1rmFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'exerciseGraphE1rmProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$exerciseGraphE1rmHash();

  @override
  String toString() {
    return r'exerciseGraphE1rmProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ExerciseGraphE1rm create() => ExerciseGraphE1rm();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ExerciseGraphE1rmProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$exerciseGraphE1rmHash() => r'9c9b503723bbca056d4b0fbb092e4fab227c3eae';

/// Whether exercise [exerciseId]'s graph shows the estimated 1RM instead
/// of the heaviest set (WO-041: a toggle; the heaviest set by default).

final class ExerciseGraphE1rmFamily extends $Family
    with $ClassFamilyOverride<ExerciseGraphE1rm, bool, bool, bool, String> {
  ExerciseGraphE1rmFamily._()
    : super(
        retry: null,
        name: r'exerciseGraphE1rmProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Whether exercise [exerciseId]'s graph shows the estimated 1RM instead
  /// of the heaviest set (WO-041: a toggle; the heaviest set by default).

  ExerciseGraphE1rmProvider call(String exerciseId) =>
      ExerciseGraphE1rmProvider._(argument: exerciseId, from: this);

  @override
  String toString() => r'exerciseGraphE1rmProvider';
}

/// Whether exercise [exerciseId]'s graph shows the estimated 1RM instead
/// of the heaviest set (WO-041: a toggle; the heaviest set by default).

abstract class _$ExerciseGraphE1rm extends $Notifier<bool> {
  late final _$args = ref.$arg as String;
  String get exerciseId => _$args;

  bool build(String exerciseId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// The workouts of the week starting on [weekStart] (WO-043, A37 D22):
/// sessions done, planned days only with a plan, PRs. For the weekly
/// summary and review (A39a); no display here.

@ProviderFor(weeklyWorkoutSummary)
final weeklyWorkoutSummaryProvider = WeeklyWorkoutSummaryFamily._();

/// The workouts of the week starting on [weekStart] (WO-043, A37 D22):
/// sessions done, planned days only with a plan, PRs. For the weekly
/// summary and review (A39a); no display here.

final class WeeklyWorkoutSummaryProvider
    extends
        $FunctionalProvider<
          AsyncValue<WeeklyWorkoutSummary>,
          WeeklyWorkoutSummary,
          FutureOr<WeeklyWorkoutSummary>
        >
    with
        $FutureModifier<WeeklyWorkoutSummary>,
        $FutureProvider<WeeklyWorkoutSummary> {
  /// The workouts of the week starting on [weekStart] (WO-043, A37 D22):
  /// sessions done, planned days only with a plan, PRs. For the weekly
  /// summary and review (A39a); no display here.
  WeeklyWorkoutSummaryProvider._({
    required WeeklyWorkoutSummaryFamily super.from,
    required LocalDate super.argument,
  }) : super(
         retry: null,
         name: r'weeklyWorkoutSummaryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$weeklyWorkoutSummaryHash();

  @override
  String toString() {
    return r'weeklyWorkoutSummaryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<WeeklyWorkoutSummary> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<WeeklyWorkoutSummary> create(Ref ref) {
    final argument = this.argument as LocalDate;
    return weeklyWorkoutSummary(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WeeklyWorkoutSummaryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$weeklyWorkoutSummaryHash() =>
    r'1b6705a4e7bd76db983e81e259e15260349573b1';

/// The workouts of the week starting on [weekStart] (WO-043, A37 D22):
/// sessions done, planned days only with a plan, PRs. For the weekly
/// summary and review (A39a); no display here.

final class WeeklyWorkoutSummaryFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<WeeklyWorkoutSummary>, LocalDate> {
  WeeklyWorkoutSummaryFamily._()
    : super(
        retry: null,
        name: r'weeklyWorkoutSummaryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The workouts of the week starting on [weekStart] (WO-043, A37 D22):
  /// sessions done, planned days only with a plan, PRs. For the weekly
  /// summary and review (A39a); no display here.

  WeeklyWorkoutSummaryProvider call(LocalDate weekStart) =>
      WeeklyWorkoutSummaryProvider._(argument: weekStart, from: this);

  @override
  String toString() => r'weeklyWorkoutSummaryProvider';
}
