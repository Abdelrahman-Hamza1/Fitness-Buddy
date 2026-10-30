import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

String _id(int value) =>
    '0199e3c2-5b1a-7000-8000-${value.toRadixString(16).padLeft(12, '0')}';

// Saturday-start weeks; today is Friday 30 October 2026.
final LocalDate _today = LocalDate(2026, 10, 30);
final LocalDate _from = LocalDate(2026, 10, 3); // a Saturday

const _profile = ProfileRecord(
  heightInputUnit: HeightInputUnit.centimeter,
  sex: FormulaSex.male,
  birthYear: 1990,
  heightCm: 180,
  activity: ActivityLevel.sedentary,
);

TargetSettingsRecord _version(
  int id,
  LocalDate from, {
  double base = 2200,
  TargetMode mode = TargetMode.weekly,
}) => TargetSettingsRecord(
  id: _id(id),
  revision: 1,
  effectiveFrom: from,
  baseKcal: base,
  basisWeightKg: 85,
  mode: mode,
);

Nutrients _food(double kcal) => Nutrients(
  kcal: kcal,
  protein: kcal / 20,
  carbs: kcal / 8,
  fat: kcal / 30,
  fiber: 20,
);

DayLog _log(
  LocalDate date,
  double kcal, {
  int entries = 4,
  bool incomplete = false,
}) => DayLog(
  date: date,
  totals: entries == 0 ? Nutrients.zero : _food(kcal),
  entryCount: entries,
  incomplete: incomplete,
);

ProgressDay _day(
  LocalDate date, {
  double kcal = 2000,
  int entries = 4,
  DayStatus? status,
  double? target = 2200,
}) => ProgressDay(
  date: date,
  eaten: entries == 0 ? Nutrients.zero : _food(kcal),
  entryCount: entries,
  status: status ?? (entries > 0 ? DayStatus.logged : DayStatus.unknown),
  targetKcal: target,
);

void main() {
  test("IN-002 G10 each day's target equals TargetsTimeline.day", () {
    // Weekly mode from 8 Oct, fixed mode from 20 Oct (a settings change
    // mid-range); the days before 8 Oct have no target.
    final settings = [
      _version(1, LocalDate(2026, 10, 8)),
      _version(2, LocalDate(2026, 10, 20), base: 2100, mode: TargetMode.fixed),
    ];
    final goals = [
      GoalPhaseRecord(
        weightInputUnit: MassUnit.kilogram,
        id: _id(50),
        revision: 1,
        start: LocalDate(2026, 9, 1),
        type: GoalType.lose,
        expression: GoalExpression.targetRate(78, 0.5),
      ),
    ];
    // Rebalancing: over- and under-eaten days, an unknown day and an
    // incomplete earlier day in the weekly weeks.
    final logs = [
      for (var d = _from; !d.isAfter(_today); d = d.plusDays(1))
        if (d.day % 7 != 2)
          _log(
            d,
            1500 + (d.day * 97) % 1200,
            incomplete: d.day == 13 || d.day == 27,
          ),
    ];
    // The trend changes across the range; nothing before 5 Oct.
    double? trendOn(LocalDate d) => d.isBefore(LocalDate(2026, 10, 5))
        ? null
        : d.isBefore(LocalDate(2026, 10, 15))
        ? 86.0
        : 84.6 - d.day / 100;
    // Training on Mondays and Wednesdays, over two weeks of the range; a
    // logged unplanned workout on Saturday 10 Oct (same-day adjustment).
    final training = TrainingShiftInput(
      plannedDays: {DayOfWeek.monday, DayOfWeek.wednesday},
      weight: 1.3,
      loggedDates: {
        LocalDate(2026, 10, 10),
        LocalDate(2026, 10, 12),
        LocalDate(2026, 10, 19),
      },
    );
    final days = ProgressSeries.build(
      from: _from,
      to: LocalDate(2026, 11, 7),
      today: _today,
      settings: settings,
      profile: _profile,
      goals: goals,
      trendOn: trendOn,
      logs: logs,
      training: training,
    );

    expect(days.first.date, _from);
    expect(days.last.date, _today, reason: 'never past today');
    expect(days, hasLength(28));
    final intake = [
      for (final log in logs)
        DayIntake(
          date: log.date,
          kcal: log.totals.kcal,
          entryCount: log.entryCount,
          incomplete: log.incomplete,
        ),
    ];
    for (final day in days) {
      final expected = TargetsTimeline.day(
        date: day.date,
        settings: settings,
        profile: _profile,
        goals: goals,
        bodyWeightKg: trendOn(day.date),
        intake: intake,
        training: training,
      );
      expect(day.targetKcal, expected?.day.kcal, reason: '${day.date}');
      expect(
        day.targetMacros?.proteinGrams,
        expected?.day.macros.proteinGrams,
        reason: '${day.date}',
      );
      expect(
        day.targetMacros?.carbsGrams,
        expected?.day.macros.carbsGrams,
        reason: '${day.date}',
      );
    }
    // Before setup: no target.
    expect(days.take(5).map((d) => d.targetKcal), everyElement(isNull));
    // Weekly mode rebalances (targets vary within a week), fixed doesn't.
    final weekly = {
      for (final d in days)
        if (!d.date.isBefore(LocalDate(2026, 10, 10)) &&
            d.date.isBefore(LocalDate(2026, 10, 17)))
          d.targetKcal!.round(),
    };
    expect(weekly.length, greaterThan(1));
    final fixed = {
      for (final d in days)
        if (!d.date.isBefore(LocalDate(2026, 10, 20))) d.targetKcal,
    };
    expect(fixed, hasLength(1));
  });

  test('IN-002 DY-004 TG-032 day status: logged, incomplete, unknown, today '
      'in progress', () {
    final days = ProgressSeries.build(
      from: _today.plusDays(-3),
      to: _today,
      today: _today,
      settings: const [],
      trendOn: (_) => null,
      logs: [
        _log(_today.plusDays(-3), 1800),
        _log(_today.plusDays(-2), 900, incomplete: true),
        _log(_today, 600),
      ],
    );
    expect(days.map((d) => d.status), [
      DayStatus.logged,
      DayStatus.incomplete,
      DayStatus.unknown,
      DayStatus.inProgress,
    ]);
    // Unknown is never zero intake to draw (TG-032); the marked day keeps
    // its logged intake.
    expect(days[2].hasIntake, isFalse);
    expect(days[1].eaten.kcal, 900);
    expect(days.map((d) => d.counted), [true, false, false, false]);
    // A mark on today wins over "in progress".
    expect(
      ProgressSeries.statusOf(
        date: _today,
        today: _today,
        entryCount: 2,
        incomplete: true,
      ),
      DayStatus.incomplete,
    );
  });

  test('IN-009 buckets: daily to 62 days, weekly from the week start to 366, '
      'monthly beyond; averages over counted days only', () {
    expect(ProgressBuckets.sizeFor(7), ProgressBucketSize.day);
    expect(ProgressBuckets.sizeFor(62), ProgressBucketSize.day);
    expect(ProgressBuckets.sizeFor(63), ProgressBucketSize.week);
    expect(ProgressBuckets.sizeFor(366), ProgressBucketSize.week);
    expect(ProgressBuckets.sizeFor(367), ProgressBucketSize.month);

    // 70 days from a Wednesday: weekly bars, the first one partial (Wed–Fri)
    // and aligned to the Saturday week start after it.
    final start = LocalDate(2026, 8, 19);
    final days = [
      for (var i = 0; i < 70; i++)
        _day(
          start.plusDays(i),
          kcal: i.isEven ? 2000 : 2400,
          entries: i == 1 ? 0 : 3,
          target: i.isEven ? 2100 : 2300,
        ),
    ];
    final weeks = ProgressBuckets.of(days);
    expect(weeks.first.size, ProgressBucketSize.week);
    expect(weeks.first.start, start);
    expect(weeks.first.end, LocalDate(2026, 8, 21));
    expect(weeks[1].start.weekday, DayOfWeek.saturday);
    expect(weeks[1].end.daysUntil(weeks[1].start), -6);
    // First week: days 0 (2000/2100) and 2 (2000/2100) counted; day 1 is
    // unknown.
    expect(weeks.first.countedDays, 2);
    expect(weeks.first.uncountedDays, 1);
    expect(weeks.first.avgKcal, 2000);
    expect(weeks.first.avgTargetKcal, 2100);
    expect(weeks.first.status, isNull);

    // 400 days: calendar-month bars; a month with nothing counted is empty.
    final long = [
      for (var i = 0; i < 400; i++)
        _day(
          LocalDate(2025, 9, 1).plusDays(i),
          entries: LocalDate(2025, 9, 1).plusDays(i).month == 12 ? 0 : 2,
        ),
    ];
    final months = ProgressBuckets.of(long);
    expect(months.first.size, ProgressBucketSize.month);
    expect(months.first.start, LocalDate(2025, 9, 1));
    expect(months.first.end, LocalDate(2025, 9, 30));
    final december = months.firstWhere((b) => b.start.month == 12);
    expect(december.avgKcal, isNull);
    expect(december.avgTargetKcal, isNull);
    expect(december.countedDays, 0);
    expect(december.uncountedDays, 31);
  });

  test('DY-004 IN-002 an incomplete day with logged intake keeps its intake '
      'and target on its daily bar and is left out of the weekly average', () {
    final sat = LocalDate(2026, 10, 24);
    final week = [
      _day(sat),
      _day(
        sat.plusDays(1),
        kcal: 800,
        target: 2300,
        status: DayStatus.incomplete,
      ),
      _day(sat.plusDays(2), kcal: 2400),
    ];
    final daily = ProgressBuckets.of(week);
    expect(daily[1].size, ProgressBucketSize.day);
    expect(daily[1].status, DayStatus.incomplete);
    expect(daily[1].avgKcal, 800);
    expect(daily[1].avgTargetKcal, 2300);
    expect(daily[1].avgEaten!.kcal, 800);
    expect(daily[1].countedDays, 0);

    // The same days inside a weekly bar: only the counted two average.
    final long = [
      for (var i = 0; i < 63; i++)
        _day(sat.plusDays(-63 + i), kcal: 1000, target: 1000),
      ...week,
    ];
    final weeks = ProgressBuckets.of(long);
    final last = weeks.last;
    expect(last.size, ProgressBucketSize.week);
    expect(last.start, sat);
    expect(last.countedDays, 2);
    expect(last.uncountedDays, 1);
    expect(last.avgKcal, 2200);
    expect(last.avgTargetKcal, 2200);
  });
}
