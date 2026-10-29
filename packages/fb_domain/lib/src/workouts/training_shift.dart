import 'package:fb_domain/src/targets/target_profile.dart';
import 'package:fb_domain/src/time/local_date.dart';

/// Turns the weekly workout plan into calorie-shifting weights for the A12
/// `WeeklyBudget` (TG-043, WO-061, A36 D5). The budget stays the same
/// weekly sum; workouts never add calories (WO-060: there's no kcal input).
abstract final class TrainingShift {
  /// The weekday weights with each planned training day at [trainingWeight]
  /// (over [base], the user's other weekday weights).
  static Map<DayOfWeek, double> weights({
    required Set<DayOfWeek> trainingDays,
    required double trainingWeight,
    Map<DayOfWeek, double> base = const {},
  }) {
    TargetLimits.checkWeight(trainingWeight);
    return Map.unmodifiable({
      ...base,
      for (final day in trainingDays) day: trainingWeight,
    });
  }

  /// The remaining-days weights when a workout is logged today on a day the
  /// plan doesn't train (WO-061): today joins the training days and the rest
  /// of the week is redistributed. Empty when nothing changes (no workout
  /// today, or today is planned), so the engine keeps its plan.
  ///
  /// A session logged for an earlier day changes nothing ahead: that day's
  /// intake is already accounted by rebalancing.
  static Map<DayOfWeek, double> remainingWeights({
    required Set<DayOfWeek> trainingDays,
    required double trainingWeight,
    required LocalDate today,
    required Iterable<LocalDate> loggedSessionDates,
    Map<DayOfWeek, double> base = const {},
  }) {
    if (trainingDays.contains(today.weekday) ||
        !loggedSessionDates.contains(today)) {
      return const {};
    }
    return weights(
      trainingDays: {...trainingDays, today.weekday},
      trainingWeight: trainingWeight,
      base: base,
    );
  }
}

/// What the weekly workout plan contributes to calorie shifting (TG-043,
/// WO-061): the planned weekdays, the training-day weight the user chose,
/// and the dates of this week with a logged session.
final class TrainingShiftInput {
  /// Throws an `ArgumentError` for a weight outside the supported range.
  new({
    required Iterable<DayOfWeek> plannedDays,
    required this.weight,
    Iterable<LocalDate> loggedDates = const [],
  }) : plannedDays = Set.unmodifiable(plannedDays),
       loggedDates = Set.unmodifiable(loggedDates) {
    TargetLimits.checkWeight(weight);
  }

  /// The weekdays the plan trains.
  final Set<DayOfWeek> plannedDays;

  /// The training-day weight.
  final double weight;

  /// Dates with a live logged session.
  final Set<LocalDate> loggedDates;

  /// The weekday weights over [base] (see [TrainingShift.weights]).
  Map<DayOfWeek, double> weightsOver(Map<DayOfWeek, double> base) =>
      TrainingShift.weights(
        trainingDays: plannedDays,
        trainingWeight: weight,
        base: base,
      );

  /// The remaining-days weights on [today] over [base] (see
  /// [TrainingShift.remainingWeights]).
  Map<DayOfWeek, double> remainingOver(
    Map<DayOfWeek, double> base,
    LocalDate today,
  ) => TrainingShift.remainingWeights(
    trainingDays: plannedDays,
    trainingWeight: weight,
    today: today,
    loggedSessionDates: loggedDates,
    base: base,
  );

  @override
  bool operator ==(Object other) =>
      other is TrainingShiftInput &&
      other.weight == weight &&
      other.plannedDays.length == plannedDays.length &&
      other.plannedDays.containsAll(plannedDays) &&
      other.loggedDates.length == loggedDates.length &&
      other.loggedDates.containsAll(loggedDates);

  @override
  int get hashCode => Object.hash(
    weight,
    Object.hashAllUnordered(plannedDays),
    Object.hashAllUnordered(loggedDates),
  );
}
