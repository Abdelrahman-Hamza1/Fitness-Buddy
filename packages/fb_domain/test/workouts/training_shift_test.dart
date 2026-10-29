import 'package:fb_domain/fb_domain.dart';
import 'package:glados/glados.dart';

import '../helpers/property.dart';

double _sum(Iterable<double> values) => values.fold(0, (a, b) => a + b);

void main() {
  const push = {DayOfWeek.saturday, DayOfWeek.sunday, DayOfWeek.tuesday};

  test('TG-043 planned training days get the training weight', () {
    expect(
      TrainingShift.weights(
        trainingDays: push,
        trainingWeight: 1.2,
        base: const {DayOfWeek.friday: 1.1},
      ),
      {
        DayOfWeek.friday: 1.1,
        DayOfWeek.saturday: 1.2,
        DayOfWeek.sunday: 1.2,
        DayOfWeek.tuesday: 1.2,
      },
    );
  });

  test('WO-061 an unplanned workout today joins the training days', () {
    final monday = LocalDate(2026, 10, 26);
    expect(monday.weekday, DayOfWeek.monday);
    expect(
      TrainingShift.remainingWeights(
        trainingDays: push,
        trainingWeight: 1.2,
        today: monday,
        loggedSessionDates: [monday],
      ),
      {
        DayOfWeek.saturday: 1.2,
        DayOfWeek.sunday: 1.2,
        DayOfWeek.tuesday: 1.2,
        DayOfWeek.monday: 1.2,
      },
    );
  });

  test('WO-061 a planned day or no workout today changes nothing', () {
    final tuesday = LocalDate(2026, 10, 27);
    final remaining = [
      TrainingShift.remainingWeights(
        trainingDays: push,
        trainingWeight: 1.2,
        today: tuesday,
        loggedSessionDates: [tuesday],
      ),
      TrainingShift.remainingWeights(
        trainingDays: push,
        trainingWeight: 1.2,
        today: tuesday.plusDays(1),
        loggedSessionDates: [tuesday.plusDays(-1)],
      ),
    ];
    expect(remaining, everyElement(isEmpty));
  });

  test('TG-043 the training weight is range-checked', () {
    expect(
      () => TrainingShift.weights(trainingDays: push, trainingWeight: 0),
      throwsArgumentError,
    );
  });

  Glados3(
    any.localDate,
    any.list(any.dayOfWeek),
    any.doubleInRange(1, 1.5),
    propertyRuns,
  ).test('WO-061 the weekly sum is preserved when a workout is logged on an '
      'unplanned day', (today, planned, trainingWeight) {
    final trainingDays = planned.toSet()..remove(today.weekday);
    final weights = TrainingShift.weights(
      trainingDays: trainingDays,
      trainingWeight: trainingWeight,
    );
    final remaining = TrainingShift.remainingWeights(
      trainingDays: trainingDays,
      trainingWeight: trainingWeight,
      today: today,
      loggedSessionDates: [today],
    );
    for (final rebalancing in [true, false]) {
      final week = WeeklyBudget.calculate(
        baseKcal: 2200,
        floorKcal: 1500,
        today: today,
        weights: weights,
        remainingWeights: remaining,
        rebalancing: rebalancing,
      );
      final total = week.accountedPastKcal + _sum(week.targets.values);
      expect(total, closeTo(week.budgetKcal, 0.01));
      // Workouts never add calories (WO-060).
      expect(week.budgetKcal, 2200 * 7);
    }
  });

  Glados3(
    any.localDate,
    any.list(any.intInRange(0, 6001)),
    any.list(any.dayOfWeek),
    propertyRuns,
  ).test('WO-061 A36 D5 when the bounds make exact allocation infeasible, the '
      'shift keeps A12 carry accounting unchanged', (today, intakes, planned) {
    const calendar = WeekCalendar();
    final start = calendar.weekStartOf(today);
    final earlier = [
      // Every earlier day known, so no planned reservation differs.
      for (var i = 0; i < start.daysUntil(today); i++)
        WeekIntake(
          date: start.plusDays(i),
          kcal: intakes.isEmpty ? 2200 : intakes[i % intakes.length] * 1.0,
        ),
    ];
    final trainingDays = planned.toSet()..remove(today.weekday);
    final weights = TrainingShift.weights(
      trainingDays: trainingDays,
      trainingWeight: 1.3,
    );
    final remaining = TrainingShift.remainingWeights(
      trainingDays: trainingDays,
      trainingWeight: 1.3,
      today: today,
      loggedSessionDates: [today],
    );
    WeekTargets week(
      Map<DayOfWeek, double> weights,
      Map<DayOfWeek, double> remaining,
    ) => WeeklyBudget.calculate(
      baseKcal: 2200,
      floorKcal: 1500,
      today: today,
      earlierIntake: earlier,
      weights: weights,
      remainingWeights: remaining,
    );
    final shifted = week(weights, remaining);
    final plain = week(const {}, const {});
    // The identity holds with or without the shift…
    for (final w in [shifted, plain]) {
      expect(
        w.accountedPastKcal + _sum(w.targets.values),
        closeTo(w.budgetKcal + w.carryKcal, 0.01),
      );
    }
    // …and the shift never changes the carry: an infeasible remainder
    // (all days clamped) is reported the same way.
    expect(shifted.carryKcal, closeTo(plain.carryKcal, 0.01));
    expect(shifted.accountedPastKcal, plain.accountedPastKcal);
  });

  test('TG-043 the training input validates its weight and compares by '
      'value', () {
    expect(
      () => TrainingShiftInput(plannedDays: push, weight: 0),
      throwsArgumentError,
    );
    final today = LocalDate(2026, 10, 26);
    final input = TrainingShiftInput(
      plannedDays: push,
      weight: 1.2,
      loggedDates: [today],
    );
    expect(
      input,
      TrainingShiftInput(plannedDays: push, weight: 1.2, loggedDates: [today]),
    );
    expect(input.weightsOver(const {})[DayOfWeek.saturday], 1.2);
    expect(input.remainingOver(const {}, today)[DayOfWeek.monday], 1.2);
  });
}
