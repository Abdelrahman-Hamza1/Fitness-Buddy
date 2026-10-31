import 'package:fb_domain/fb_domain.dart';
import 'package:glados/glados.dart';

import '../helpers/property.dart';

final saturday = LocalDate(2026, 10, 17);
double sum(Iterable<double> values) => values.fold(0, (a, b) => a + b);

/// Every weekday at [kcal], with [days] overriding.
Map<DayOfWeek, double> week(
  double kcal, [
  Map<DayOfWeek, double> days = const {},
]) => {for (final d in DayOfWeek.values) d: days[d] ?? kcal};

void main() {
  test(
    'TG-040 TG-041 worked week consumes known intake and reserves unknown',
    () {
      final result = WeeklyBudget.calculate(
        planned: week(2000),
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
        planned: week(2000),
        floorKcal: 1500,
        today: saturday.plusDays(1),
        earlierIntake: [WeekIntake(date: saturday, kcal: 0)],
      );
      expect(knownZero.unknownDates, isEmpty);
      expect(knownZero.targets.values.first, closeTo(14000 / 6, 1e-7));
    },
  );

  test('TG-040 D-090 the budget is the sum of the planned days; without '
      'intake every day is exactly its planned number', () {
    final planned = week(2150, {DayOfWeek.friday: 2600});
    final result = WeeklyBudget.calculate(
      planned: planned,
      floorKcal: 1500,
      today: saturday,
    );
    expect(result.budgetKcal, 2150 * 6 + 2600);
    expect(result.targets[saturday.plusDays(6)], 2600);
    expect(result.targets[saturday], 2150);
    expect(result.carryKcal, 0);
  });

  test('TG-041 D-090 rebalancing spreads in proportion to the planned '
      'days', () {
    final result = WeeklyBudget.calculate(
      planned: week(2000, {DayOfWeek.friday: 3000}),
      floorKcal: 1200,
      today: saturday.plusDays(1),
      earlierIntake: [WeekIntake(date: saturday, kcal: 2700)],
    );
    // 700 over, spread 2000:…:3000 over the six days left (budget 15,000).
    const rest = 15000 - 2700;
    const m = rest / (2000 * 5 + 3000);
    expect(result.targets[saturday.plusDays(1)], closeTo(2000 * m, 1e-7));
    expect(result.targets[saturday.plusDays(6)], closeTo(3000 * m, 1e-7));
    expect(result.carryKcal, closeTo(0, 1e-7));
  });

  test(
    'TG-042 impossible remainder becomes over/under, never unsafe targets',
    () {
      for (final intake in [0.0, 3000.0]) {
        final result = WeeklyBudget.calculate(
          planned: week(2000),
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
    },
  );

  test('TG-042 A53 D4 each day moves at most ±25% of its own planned number; '
      'a day planned below the floor is never lowered further', () {
    final result = WeeklyBudget.calculate(
      planned: week(2000, {DayOfWeek.friday: 3000, DayOfWeek.thursday: 1300}),
      floorKcal: 1500,
      today: saturday.plusDays(1),
      earlierIntake: [WeekIntake(date: saturday, kcal: 9000)],
    );
    expect(result.targets[saturday.plusDays(6)], closeTo(2250, 1e-7));
    expect(result.targets[saturday.plusDays(5)], closeTo(1300, 1e-7));
    expect(result.targets[saturday.plusDays(1)], closeTo(1500, 1e-7));
    expect(result.carryKcal, greaterThan(0));
  });

  test('TG-044 rebalancing off keeps the planned days', () {
    final planned = WeeklyBudget.calculate(
      planned: week(2000, {DayOfWeek.monday: 2400}),
      floorKcal: 1500,
      today: saturday.plusDays(1),
      rebalancing: false,
      earlierIntake: [WeekIntake(date: saturday, kcal: 3000)],
    );
    expect(planned.targets[saturday.plusDays(1)], 2000);
    expect(planned.targets[saturday.plusDays(2)], 2400);
    expect(planned.carryKcal, closeTo(1000, 1e-7));
  });

  test('TG-040 week start and invalid dates/days are explicit', () {
    for (final start in DayOfWeek.values) {
      final result = WeeklyBudget.calculate(
        planned: week(2000),
        floorKcal: 2000,
        today: saturday,
        calendar: WeekCalendar(weekStart: start),
      );
      expect(result.weekStart.weekday, start);
      expect(result.targets.values, everyElement(greaterThanOrEqualTo(2000)));
    }
    for (final value in [double.nan, double.infinity, -.1, 0.0]) {
      expect(
        () => WeeklyBudget.calculate(
          planned: week(2000, {DayOfWeek.friday: value}),
          floorKcal: 1500,
          today: saturday,
        ),
        throwsArgumentError,
      );
    }
    expect(
      () => WeeklyBudget.calculate(
        planned: {DayOfWeek.friday: 2000},
        floorKcal: 1500,
        today: saturday,
      ),
      throwsArgumentError,
    );
    for (final value in [double.nan, -1.0, double.infinity]) {
      expect(
        () => WeekIntake(date: saturday, kcal: value),
        throwsArgumentError,
      );
    }
    for (final pastDate in [saturday.plusDays(-1), saturday.plusDays(1)]) {
      expect(
        () => WeeklyBudget.calculate(
          planned: week(2000),
          floorKcal: 1500,
          today: saturday.plusDays(1),
          earlierIntake: [WeekIntake(date: pastDate, kcal: 1)],
        ),
        throwsArgumentError,
      );
    }
    expect(
      () => WeeklyBudget.calculate(
        planned: week(2000),
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
    any.listWithLength(7, any.doubleInRange(.5, 2)),
    propertyRuns,
  ).test('TG-041 TG-042 SF-010 property: floor/bounds and residual identity', (
    base,
    elapsed,
    factors,
  ) {
    final floor = base * .6;
    final planned = {
      for (var i = 0; i < 7; i++) DayOfWeek.values[i]: base * factors[i],
    };
    final result = WeeklyBudget.calculate(
      planned: planned,
      floorKcal: floor,
      today: saturday.plusDays(elapsed),
      earlierIntake: [
        for (var i = 0; i < elapsed; i++)
          WeekIntake(date: saturday.plusDays(i), kcal: i.isEven ? base * 2 : 0),
      ],
    );
    for (final MapEntry(key: date, value: target) in result.targets.entries) {
      final p = planned[date.weekday]!;
      expect(target.isFinite, isTrue);
      expect(target, lessThanOrEqualTo(p * 1.25 + 1e-9));
      expect(target, greaterThanOrEqualTo(p * .75 - 1e-9));
      expect(target, greaterThanOrEqualTo((p < floor ? p : floor) - 1e-9));
    }
    expect(
      result.accountedPastKcal + sum(result.targets.values),
      closeTo(result.budgetKcal + result.carryKcal, 1e-6),
    );
  });

  Glados2(
    any.doubleInRange(1200, 6000),
    any.listWithLength(7, any.doubleInRange(.5, 2)),
    propertyRuns,
  ).test('D-090 property: without intake every day is its planned number', (
    base,
    factors,
  ) {
    final planned = {
      for (var i = 0; i < 7; i++) DayOfWeek.values[i]: base * factors[i],
    };
    for (final rebalancing in [true, false]) {
      final result = WeeklyBudget.calculate(
        planned: planned,
        floorKcal: base * .5,
        today: saturday,
        rebalancing: rebalancing,
      );
      for (final MapEntry(key: date, value: kcal) in result.targets.entries) {
        expect(kcal, planned[date.weekday]);
      }
      expect(result.budgetKcal, closeTo(sum(planned.values), 1e-9));
      expect(result.carryKcal, closeTo(0, 1e-7));
    }
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
      planned: week(base),
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
