import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

final _period = RamadanPeriod(
  hijriYear: 1447,
  start: LocalDate(2026, 2, 18),
  end: LocalDate(2026, 3, 19),
);

ComparisonDay _day(LocalDate date, double kcal, {bool incomplete = false}) =>
    (date: date, kcal: kcal, entryCount: 3, incomplete: incomplete);

void main() {
  test('IN-008 intake, trend and workouts: Ramadan so far vs the month '
      'before', () {
    final before = [
      for (var i = 1; i <= 30; i++) _day(_period.start.plusDays(-i), 2200),
      _day(_period.start.plusDays(-31), 9000), // outside the month before
    ];
    final ramadan = [
      for (var i = 0; i < 10; i++) _day(_period.start.plusDays(i), 1900),
      _day(_period.start.plusDays(10), 500, incomplete: true),
    ];
    final today = _period.start.plusDays(10);
    final c = RamadanComparison.compute(
      period: _period,
      today: today,
      days: [...before, ...ramadan],
      // 80 kg on the day before the month before, −0.02 kg/day.
      trendOn: (d) => 80 - _period.start.plusDays(-31).daysUntil(d) * .02,
      workoutDates: [
        _period.start.plusDays(-20),
        _period.start.plusDays(-10),
        _period.start.plusDays(-3),
        _period.start.plusDays(2),
      ],
    );
    expect(c.inProgress, isTrue);
    expect(c.ramadan.days, 11);
    expect(c.ramadan.loggedDays, 10, reason: 'the incomplete day is left out');
    expect(c.ramadan.averageKcal, closeTo(1900, .01));
    expect(c.before.days, 30);
    expect(c.before.loggedDays, 30);
    expect(c.before.averageKcal, closeTo(2200, .01));
    expect(c.before.trendChangeKg, closeTo(-.6, 1e-9));
    expect(c.ramadan.trendChangeKg, closeTo(-.22, 1e-9));
    expect(c.before.workouts, 3);
    expect(c.ramadan.workoutsPerWeek, closeTo(7 / 11, 1e-9));
  });

  test('after Ramadan the whole month is compared; unknown trend is null', () {
    final c = RamadanComparison.compute(
      period: _period,
      today: LocalDate(2026, 4, 1),
      days: const [],
      trendOn: (_) => null,
      workoutDates: const [],
    );
    expect(c.inProgress, isFalse);
    expect(c.ramadan.days, 30);
    expect(c.ramadan.averageKcal, isNull);
    expect(c.ramadan.trendChangeKg, isNull);
  });

  test('shown from the first day until 30 days after the end', () {
    expect(
      RamadanComparison.shownOn(LocalDate(2026, 2, 17), [_period]),
      isNull,
    );
    expect(
      RamadanComparison.shownOn(LocalDate(2026, 2, 18), [_period]),
      _period,
    );
    expect(
      RamadanComparison.shownOn(LocalDate(2026, 4, 18), [_period]),
      _period,
    );
    expect(
      RamadanComparison.shownOn(LocalDate(2026, 4, 19), [_period]),
      isNull,
    );
  });

  test('before the first day it refuses', () {
    expect(
      () => RamadanComparison.compute(
        period: _period,
        today: LocalDate(2026, 2, 1),
        days: const [],
        trendOn: (_) => null,
        workoutDates: const [],
      ),
      throwsArgumentError,
    );
  });
}
