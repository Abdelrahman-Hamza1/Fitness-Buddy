import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

// Saturday-start weeks: 24–30 Oct 2026 is a whole week; 31 Oct starts the
// next one.
final LocalDate _weekStart = LocalDate(2026, 10, 24);

final DailyMacros _macros = MacroPlan.calculate(
  baseKcal: 2000,
  weightKg: 80,
).forDay(2000);

/// A logged day eating [kcal] with [protein] g and [fiber] g against a
/// 2,000 kcal target (and [_macros]' protein target).
ProgressDay _day(
  LocalDate date, {
  double kcal = 2000,
  double? protein,
  double fiber = 25,
  DayStatus status = DayStatus.logged,
  double? target = 2000,
  bool macros = true,
  int entries = 4,
}) => ProgressDay(
  date: date,
  eaten: Nutrients(
    kcal: kcal,
    protein: protein ?? _macros.proteinGrams,
    carbs: 200,
    fat: 60,
    fiber: fiber,
  ),
  entryCount: entries,
  status: status,
  targetKcal: target,
  targetMacros: macros && target != null ? _macros : null,
);

LocalDate _d(int i) => _weekStart.plusDays(i);

void main() {
  test('IN-001 a past week: averages, days within target (10 %), protein '
      'days hit, fiber, trend change and workouts', () {
    final p = _macros.proteinGrams;
    final days = [
      _day(_d(0), kcal: 2100, fiber: 20), //                within, protein hit
      _day(_d(1), kcal: 1800, protein: p - 1, fiber: 30), // within (edge)
      _day(_d(2), kcal: 2300), //                           over the band
      _day(_d(3), kcal: 1500, status: DayStatus.incomplete), // not counted
      _day(_d(4), entries: 0, status: DayStatus.unknown), //    not counted
      _day(_d(5), protein: p + 20),
      // Day 6 missing: unknown, never zero (TG-032).
      _day(_d(-1), kcal: 9000), // the week before: ignored
    ];
    const workouts = WeeklyWorkoutSummary(sessions: 3, planned: 4, prs: 2);
    final s = WeeklySummary.of(
      weekStart: _weekStart,
      today: LocalDate(2026, 11, 3),
      days: days,
      trendOn: (d) => d == _d(-1)
          ? 84.0
          : d == _d(6)
          ? 83.4
          : null,
      workouts: workouts,
    );
    expect(s.start, _weekStart);
    expect(s.end, _d(6));
    expect(s.elapsedDays, 7);
    expect(s.countedDays, 4);
    expect(s.targetDays, 4);
    expect(s.daysWithinTarget, 3); // 2100, 1800 (−10 %), 2000
    expect(s.averageKcal, closeTo((2100 + 1800 + 2300 + 2000) / 4, 1e-9));
    expect(s.averageTargetKcal, 2000);
    expect(s.proteinTargetDays, 4);
    expect(s.proteinDaysHit, 3);
    expect(s.averageFiber, 25);
    expect(s.trendChangeKg, closeTo(-0.6, 1e-9));
    expect(s.workouts, workouts);
    expect(s.isEmpty, isFalse);
  });

  test('IN-001 the current week counts only earlier days; the trend runs '
      'to today', () {
    final today = _d(3);
    final s = WeeklySummary.of(
      weekStart: _weekStart,
      today: today,
      days: [
        _day(_d(0)),
        _day(_d(1), kcal: 2500),
        _day(_d(2), status: DayStatus.unknown, entries: 0),
        _day(today, kcal: 300, status: DayStatus.inProgress),
      ],
      trendOn: (d) => d == today
          ? 85.2
          : d == _d(-1)
          ? 85.0
          : 99,
    );
    expect(s.elapsedDays, 3);
    expect(s.countedDays, 2);
    expect(s.daysWithinTarget, 1);
    expect(s.averageKcal, 2250);
    expect(s.trendChangeKg, closeTo(0.2, 1e-9));
    expect(s.workouts, isNull);
  });

  test('IN-001 a week with nothing logged: no averages, empty; days '
      'without targets count but give no target numbers', () {
    final empty = WeeklySummary.of(
      weekStart: _weekStart,
      today: _d(10),
      days: const [],
      trendOn: (_) => null,
      workouts: const WeeklyWorkoutSummary(sessions: 0, planned: null, prs: 0),
    );
    expect(empty.countedDays, 0);
    expect(empty.averageKcal, isNull);
    expect(empty.averageFiber, isNull);
    expect(empty.trendChangeKg, isNull);
    expect(empty.isEmpty, isTrue);

    final noTargets = WeeklySummary.of(
      weekStart: _weekStart,
      today: _d(10),
      days: [_day(_d(0), target: null), _day(_d(1), fiber: 35, target: null)],
      trendOn: (_) => null,
    );
    expect(noTargets.countedDays, 2);
    expect(noTargets.targetDays, 0);
    expect(noTargets.proteinTargetDays, 0);
    expect(noTargets.averageKcal, isNull);
    expect(noTargets.averageFiber, 30);
    expect(noTargets.isEmpty, isFalse);
  });

  test(
    'WO-043 D-085 a week with sessions but no plan has no planned count',
    () {
      final s = WeeklySummary.of(
        weekStart: _weekStart,
        today: _d(7),
        days: const [],
        trendOn: (_) => null,
        workouts: const WeeklyWorkoutSummary(
          sessions: 2,
          planned: null,
          prs: 0,
        ),
      );
      expect(s.workouts!.planned, isNull);
      expect(s.isEmpty, isFalse);
    },
  );

  test('a week starting after today is refused', () {
    expect(
      () => WeeklySummary.of(
        weekStart: _d(7),
        today: _d(6),
        days: const [],
        trendOn: (_) => null,
      ),
      throwsArgumentError,
    );
  });

  test('IN-001 any past week: week starts from the first data date to this '
      'week, newest first', () {
    const calendar = WeekCalendar();
    expect(
      WeeklySummary.weekStarts(
        earliest: LocalDate(2026, 10, 14),
        today: LocalDate(2026, 10, 31),
        calendar: calendar,
      ),
      [
        LocalDate(2026, 10, 31),
        LocalDate(2026, 10, 24),
        LocalDate(2026, 10, 17),
        LocalDate(2026, 10, 10),
      ],
    );
    expect(
      WeeklySummary.weekStarts(
        earliest: LocalDate(2026, 11, 5),
        today: LocalDate(2026, 10, 31),
        calendar: calendar,
      ),
      [LocalDate(2026, 10, 31)],
    );
  });
}
