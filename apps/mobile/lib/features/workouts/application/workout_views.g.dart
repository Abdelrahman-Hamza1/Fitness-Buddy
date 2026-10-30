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

String _$workoutHistoryHash() => r'a4e4e3b9bb43395ec7121b6b55a04a70ff34c79f';

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

/// The week containing [today], with trained days only (WO-024: no
/// "missed" days, ever).

@ProviderFor(workoutWeek)
final workoutWeekProvider = WorkoutWeekFamily._();

/// The week containing [today], with trained days only (WO-024: no
/// "missed" days, ever).

final class WorkoutWeekProvider
    extends
        $FunctionalProvider<
          AsyncValue<WorkoutWeek>,
          WorkoutWeek,
          FutureOr<WorkoutWeek>
        >
    with $FutureModifier<WorkoutWeek>, $FutureProvider<WorkoutWeek> {
  /// The week containing [today], with trained days only (WO-024: no
  /// "missed" days, ever).
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

String _$workoutWeekHash() => r'e8dc3501bf07cf504266ce4a36d5db373f897cfc';

/// The week containing [today], with trained days only (WO-024: no
/// "missed" days, ever).

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

  /// The week containing [today], with trained days only (WO-024: no
  /// "missed" days, ever).

  WorkoutWeekProvider call(LocalDate today) =>
      WorkoutWeekProvider._(argument: today, from: this);

  @override
  String toString() => r'workoutWeekProvider';
}

/// The workout row of [date] (D20, A37a: the logged branch only), or `null`
/// without a session (no-plan users see nothing until they log).

@ProviderFor(todayWorkout)
final todayWorkoutProvider = TodayWorkoutFamily._();

/// The workout row of [date] (D20, A37a: the logged branch only), or `null`
/// without a session (no-plan users see nothing until they log).

final class TodayWorkoutProvider
    extends
        $FunctionalProvider<
          AsyncValue<TodayWorkout?>,
          TodayWorkout?,
          FutureOr<TodayWorkout?>
        >
    with $FutureModifier<TodayWorkout?>, $FutureProvider<TodayWorkout?> {
  /// The workout row of [date] (D20, A37a: the logged branch only), or `null`
  /// without a session (no-plan users see nothing until they log).
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

String _$todayWorkoutHash() => r'04cbcda5e12f4b37d0f3566313f9fd55e1f42ac7';

/// The workout row of [date] (D20, A37a: the logged branch only), or `null`
/// without a session (no-plan users see nothing until they log).

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

  /// The workout row of [date] (D20, A37a: the logged branch only), or `null`
  /// without a session (no-plan users see nothing until they log).

  TodayWorkoutProvider call(LocalDate date) =>
      TodayWorkoutProvider._(argument: date, from: this);

  @override
  String toString() => r'todayWorkoutProvider';
}
