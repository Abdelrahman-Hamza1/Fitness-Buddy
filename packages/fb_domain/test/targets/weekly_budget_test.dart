import 'package:fb_domain/fb_domain.dart';
import 'package:glados/glados.dart';

import '../helpers/property.dart';

final saturday = LocalDate(2026, 10, 17);
double sum(Iterable<double> values) => values.fold(0, (a, b) => a + b);

void main() {
  test('TG-043 unplanned weights preserve unknown past reservations', () {
    for (final rebalance in [true, false]) {
      final ordinary = WeeklyBudget.calculate(
        baseKcal: 2000,
        floorKcal: 1500,
        today: saturday.plusDays(4),
        rebalancing: rebalance,
      );
      final workout = WeeklyBudget.calculate(
        baseKcal: 2000,
        floorKcal: 1500,
        today: saturday.plusDays(4),
        rebalancing: rebalance,
        remainingWeights: {DayOfWeek.wednesday: 2, DayOfWeek.saturday: 1000},
      );
      expect(workout.accountedPastKcal, ordinary.accountedPastKcal);
      expect(workout.unknownDates, ordinary.unknownDates);
      expect(workout.planned, ordinary.planned);
      expect(workout.targets[saturday.plusDays(4)], closeTo(2500, 1e-7));
      expect(
        sum(workout.targets.values),
        closeTo(sum(ordinary.targets.values), 1e-7),
      );
      expect(workout.carryKcal, closeTo(0, 1e-7));
    }
    expect(
      () => WeeklyBudget.calculate(
        baseKcal: 2000,
        floorKcal: 1500,
        today: saturday,
        remainingWeights: {DayOfWeek.friday: double.nan},
      ),
      throwsArgumentError,
    );
  });

  test(
    'TG-040 TG-041 worked week consumes known intake and reserves unknown',
    () {
      final result = WeeklyBudget.calculate(
        baseKcal: 2000,
        floorKcal: 1500,
        today: saturday.plusDays(3),
        earlierIntake: [
          WeekIntake(date: saturday, kcal: 2500),
          WeekIntake(date: saturday.plusDays(1), kcal: 100, complete: false),
        ],
      );
      expect(result.weekStart, saturday);
      expect(result.budgetKcal, 14000);
      expect(result.accountedPastKcal, closeTo(6500, 1e-7));
      expect(result.targets.length, 4);
      for (final kcal in result.targets.values) {
        expect(kcal, closeTo(1875, 1e-7));
      }
      expect(result.carryKcal, closeTo(0, 1e-7));
      expect(result.unknownDates, [saturday.plusDays(1), saturday.plusDays(2)]);
      expect(result.targets.clear, throwsUnsupportedError);
      expect(result.planned.clear, throwsUnsupportedError);
      expect(result.unknownDates.clear, throwsUnsupportedError);
      final knownZero = WeeklyBudget.calculate(
        baseKcal: 2000,
        floorKcal: 1500,
        today: saturday.plusDays(1),
        earlierIntake: [WeekIntake(date: saturday, kcal: 0)],
      );
      expect(knownZero.unknownDates, isEmpty);
      expect(knownZero.targets.values.first, closeTo(14000 / 6, 1e-7));
    },
  );

  test(
    'TG-042 impossible remainder becomes over/under, never unsafe targets',
    () {
      for (final intake in [0.0, 3000.0]) {
        final result = WeeklyBudget.calculate(
          baseKcal: 2000,
          floorKcal: 1800,
          today: saturday.plusDays(6),
          earlierIntake: [
            for (var i = 0; i < 6; i++)
              WeekIntake(date: saturday.plusDays(i), kcal: intake),
          ],
        );
        expect(
          result.targets.values.single,
          closeTo(intake == 0 ? 2500 : 1800, 1e-7),
        );
        expect(result.carryKcal, closeTo(intake == 0 ? -11500 : 5800, 1e-7));
      }
      for (final fixed in [false, true]) {
        expect(
          () => WeeklyBudget.calculate(
            baseKcal: 1000,
            floorKcal: 1600,
            today: saturday,
            fixed: fixed,
          ),
          throwsArgumentError,
        );
      }
    },
  );

  test(
    'TG-043 WO-060 shifting and unplanned workout redistribute same budget',
    () {
      final shifted = WeeklyBudget.calculate(
        baseKcal: 2000,
        floorKcal: 1500,
        today: saturday,
        weights: {DayOfWeek.friday: 2},
      );
      expect(shifted.targets[saturday.plusDays(6)], closeTo(2500, 1e-7));
      expect(sum(shifted.targets.values), closeTo(14000, 1e-7));
      final workout = WeeklyBudget.calculate(
        baseKcal: 2000,
        floorKcal: 1500,
        today: saturday.plusDays(4),
        weights: {DayOfWeek.wednesday: 2},
        earlierIntake: [
          for (var i = 0; i < 4; i++)
            WeekIntake(date: saturday.plusDays(i), kcal: 2000),
        ],
      );
      expect(workout.budgetKcal, shifted.budgetKcal);
      expect(sum(workout.targets.values), closeTo(6000, 1e-7));
      expect(workout.targets[saturday.plusDays(4)], closeTo(2500, 1e-7));
      final extremes = WeeklyBudget.calculate(
        baseKcal: 2000,
        floorKcal: 1500,
        today: saturday,
        weights: {DayOfWeek.saturday: .001, DayOfWeek.sunday: 1000},
      );
      expect(extremes.targets[saturday], closeTo(1500, 1e-7));
      expect(extremes.targets[saturday.plusDays(1)], closeTo(2500, 1e-7));
      expect(sum(extremes.targets.values), closeTo(14000, 1e-7));
    },
  );

  test(
    'TG-044 fixed mode ignores weights/intake; rebalancing off keeps plan',
    () {
      final fixed = WeeklyBudget.calculate(
        baseKcal: 2000,
        floorKcal: 1500,
        today: saturday.plusDays(1),
        fixed: true,
        weights: {DayOfWeek.friday: 2},
        earlierIntake: [WeekIntake(date: saturday, kcal: 3000)],
      );
      expect(fixed.targets.values, everyElement(2000));
      expect(fixed.carryKcal, 0);
      final planned = WeeklyBudget.calculate(
        baseKcal: 2000,
        floorKcal: 1500,
        today: saturday.plusDays(1),
        rebalancing: false,
        earlierIntake: [WeekIntake(date: saturday, kcal: 3000)],
      );
      expect(planned.targets.values, everyElement(closeTo(2000, 1e-7)));
      expect(planned.carryKcal, closeTo(1000, 1e-7));
    },
  );

  test('TG-040 week start and invalid dates/weights are explicit', () {
    for (final start in DayOfWeek.values) {
      final result = WeeklyBudget.calculate(
        baseKcal: 2000,
        floorKcal: 2000,
        today: saturday,
        calendar: WeekCalendar(weekStart: start),
      );
      expect(result.weekStart.weekday, start);
      expect(result.targets.values, everyElement(greaterThanOrEqualTo(2000)));
    }
    for (final value in [
      double.nan,
      double.infinity,
      -.1,
      0.0,
      .0001,
      1001.0,
    ]) {
      expect(
        () => WeeklyBudget.calculate(
          baseKcal: 2000,
          floorKcal: 1500,
          today: saturday,
          weights: {DayOfWeek.friday: value},
        ),
        throwsArgumentError,
      );
    }
    for (final value in [double.nan, -1.0, double.infinity]) {
      expect(
        () => WeekIntake(date: saturday, kcal: value),
        throwsArgumentError,
      );
    }
    for (final pastDate in [saturday.plusDays(-1), saturday.plusDays(1)]) {
      expect(
        () => WeeklyBudget.calculate(
          baseKcal: 2000,
          floorKcal: 1500,
          today: saturday.plusDays(1),
          earlierIntake: [WeekIntake(date: pastDate, kcal: 1)],
        ),
        throwsArgumentError,
      );
    }
    expect(
      () => WeeklyBudget.calculate(
        baseKcal: 2000,
        floorKcal: 1500,
        today: saturday.plusDays(1),
        earlierIntake: [
          WeekIntake(date: saturday, kcal: 1),
          WeekIntake(date: saturday, kcal: 2),
        ],
      ),
      throwsArgumentError,
    );
  });

  Glados3(
    any.doubleInRange(1200, 6000),
    any.intInRange(0, 7),
    any.listWithLength(7, any.doubleInRange(.001, 1000)),
    propertyRuns,
  ).test('TG-041 TG-042 SF-010 property: floor/bounds and residual identity', (
    base,
    elapsed,
    weights,
  ) {
    final floor = base * .9;
    final result = WeeklyBudget.calculate(
      baseKcal: base,
      floorKcal: floor,
      today: saturday.plusDays(elapsed),
      weights: {for (var i = 0; i < 7; i++) DayOfWeek.values[i]: weights[i]},
      earlierIntake: [
        for (var i = 0; i < elapsed; i++)
          WeekIntake(date: saturday.plusDays(i), kcal: i.isEven ? base * 2 : 0),
      ],
    );
    for (final target in result.targets.values) {
      expect(target.isFinite, isTrue);
      expect(target, greaterThanOrEqualTo(floor));
      expect(target, lessThanOrEqualTo(base * 1.25));
      expect(target, greaterThanOrEqualTo(base * .75));
    }
    expect(
      result.accountedPastKcal + sum(result.targets.values),
      closeTo(result.budgetKcal + result.carryKcal, 1e-7),
    );
  });

  Glados2(
    any.doubleInRange(1200, 6000),
    any.listWithLength(7, any.doubleInRange(.001, 1000)),
    propertyRuns,
  ).test('TG-043 property: weighted shifting preserves weekly total', (
    base,
    weights,
  ) {
    final result = WeeklyBudget.calculate(
      baseKcal: base,
      floorKcal: base * .95,
      today: saturday,
      weights: {for (var i = 0; i < 7; i++) DayOfWeek.values[i]: weights[i]},
    );
    expect(sum(result.targets.values), closeTo(base * 7, 1e-7));
    expect(result.carryKcal, closeTo(0, 1e-7));
  });

  Glados2(
    any.doubleInRange(1200, 6000),
    any.intInRange(0, 7),
    propertyRuns,
  ).test('TG-041 property: feasible rebalancing preserves budget', (
    base,
    elapsed,
  ) {
    final result = WeeklyBudget.calculate(
      baseKcal: base,
      floorKcal: base * .75,
      today: saturday.plusDays(elapsed),
      earlierIntake: [
        for (var i = 0; i < elapsed; i++)
          WeekIntake(date: saturday.plusDays(i), kcal: base + base * .01),
      ],
    );
    expect(result.carryKcal, closeTo(0, 1e-7));
    expect(
      result.accountedPastKcal + sum(result.targets.values),
      closeTo(base * 7, 1e-7),
    );
  });
}
