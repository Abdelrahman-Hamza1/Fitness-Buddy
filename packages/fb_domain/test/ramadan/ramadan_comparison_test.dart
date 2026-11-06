import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

final _period = RamadanPeriod(
  hijriYear: 1447,
  start: LocalDate(2026, 2, 18),
  end: LocalDate(2026, 3, 19),
);

ComparisonDay _day(
  LocalDate date,
  double kcal, {
  bool incomplete = false,
  bool estimated = false,
  bool dayEstimate = false,
}) => (
  date: date,
  kcal: kcal,
  entryCount: dayEstimate ? 0 : 3,
  incomplete: incomplete,
  estimated: estimated || dayEstimate,
  dayEstimate: dayEstimate,
);

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

  test('D25 Ramadan side with a meal estimate is marked estimated; the '
      'average includes it', () {
    final c = RamadanComparison.compute(
      period: _period,
      today: _period.start.plusDays(2),
      days: [
        _day(_period.start, 2000),
        _day(_period.start.plusDays(1), 1000, estimated: true),
        _day(_period.start.plusDays(-1), 2400),
      ],
      trendOn: (_) => null,
      workoutDates: const [],
    );
    expect(c.ramadan.estimated, isTrue);
    expect(c.ramadan.averageKcal, 1500);
    expect(c.before.estimated, isFalse);
  });

  test('DY-006 D25 Ramadan comparison admits day-estimate days (entryCount '
      '0) and marks the side estimated', () {
    final empty = (
      date: _period.start.plusDays(2),
      kcal: 0.0,
      entryCount: 0,
      incomplete: false,
      estimated: false,
      dayEstimate: false,
    );
    final c = RamadanComparison.compute(
      period: _period,
      today: _period.start.plusDays(3),
      days: [
        _day(_period.start, 2000),
        _day(_period.start.plusDays(1), 2600, dayEstimate: true),
        empty,
        _day(_period.start.plusDays(-1), 2400),
        _day(_period.start.plusDays(-2), 1800, dayEstimate: true),
        _day(
          _period.start.plusDays(-3),
          900,
          dayEstimate: true,
          incomplete: true,
        ),
      ],
      trendOn: (_) => null,
      workoutDates: const [],
    );
    // A meal-estimate day and a day-estimate day both count; an empty day
    // and an incomplete one don't.
    expect(c.ramadan.loggedDays, 2);
    expect(c.ramadan.averageKcal, 2300);
    expect(c.ramadan.estimated, isTrue);
    expect(c.before.loggedDays, 2);
    expect(c.before.averageKcal, 2100);
    expect(c.before.estimated, isTrue);
  });
}
