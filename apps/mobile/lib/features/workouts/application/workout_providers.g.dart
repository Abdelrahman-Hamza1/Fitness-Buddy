// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The weekly plan: planned weekday → template ID (WO-021).

@ProviderFor(weeklyPlan)
final weeklyPlanProvider = WeeklyPlanProvider._();

/// The weekly plan: planned weekday → template ID (WO-021).

final class WeeklyPlanProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<DayOfWeek, String>>,
          Map<DayOfWeek, String>,
          Stream<Map<DayOfWeek, String>>
        >
    with
        $FutureModifier<Map<DayOfWeek, String>>,
        $StreamProvider<Map<DayOfWeek, String>> {
  /// The weekly plan: planned weekday → template ID (WO-021).
  WeeklyPlanProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'weeklyPlanProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$weeklyPlanHash();

  @$internal
  @override
  $StreamProviderElement<Map<DayOfWeek, String>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<DayOfWeek, String>> create(Ref ref) {
    return weeklyPlan(ref);
  }
}

String _$weeklyPlanHash() => r'ad2150747ccefb9bf57bc1efc27f0dcf3c4b2c93';

/// Dates from [from] to [to] with a logged session.

@ProviderFor(loggedWorkoutDates)
final loggedWorkoutDatesProvider = LoggedWorkoutDatesFamily._();

/// Dates from [from] to [to] with a logged session.

final class LoggedWorkoutDatesProvider
    extends
        $FunctionalProvider<
          AsyncValue<Set<LocalDate>>,
          Set<LocalDate>,
          Stream<Set<LocalDate>>
        >
    with $FutureModifier<Set<LocalDate>>, $StreamProvider<Set<LocalDate>> {
  /// Dates from [from] to [to] with a logged session.
  LoggedWorkoutDatesProvider._({
    required LoggedWorkoutDatesFamily super.from,
    required (LocalDate, LocalDate) super.argument,
  }) : super(
         retry: null,
         name: r'loggedWorkoutDatesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$loggedWorkoutDatesHash();

  @override
  String toString() {
    return r'loggedWorkoutDatesProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<Set<LocalDate>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Set<LocalDate>> create(Ref ref) {
    final argument = this.argument as (LocalDate, LocalDate);
    return loggedWorkoutDates(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is LoggedWorkoutDatesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$loggedWorkoutDatesHash() =>
    r'443970f4371e052fbf89b04c742e3bb01d66cf8e';

/// Dates from [from] to [to] with a logged session.

final class LoggedWorkoutDatesFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<Set<LocalDate>>,
          (LocalDate, LocalDate)
        > {
  LoggedWorkoutDatesFamily._()
    : super(
        retry: null,
        name: r'loggedWorkoutDatesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Dates from [from] to [to] with a logged session.

  LoggedWorkoutDatesProvider call(LocalDate from, LocalDate to) =>
      LoggedWorkoutDatesProvider._(argument: (from, to), from: this);

  @override
  String toString() => r'loggedWorkoutDatesProvider';
}
