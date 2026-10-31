import 'package:fb_domain/fb_domain.dart';
import 'package:glados/glados.dart';

import '../helpers/property.dart';

String _id(int value) =>
    '0199e3c2-5b1a-7000-8000-${value.toRadixString(16).padLeft(12, '0')}';

// A Saturday-start week: Sat 24 … Fri 30 October 2026.
final LocalDate _sat = LocalDate(2026, 10, 24);
final LocalDate _sun = _sat.plusDays(1);
final LocalDate _mon = _sat.plusDays(2);
final LocalDate _tue = _sat.plusDays(3);
final LocalDate _wed = _sat.plusDays(4);
final LocalDate _thu = _sat.plusDays(5);

// Resting energy at w kg on 2026: 10w + 950 (80 kg → 1,750, 90 kg → 1,850).
const _profile = ProfileRecord(
  heightInputUnit: HeightInputUnit.centimeter,
  sex: FormulaSex.male,
  birthYear: 1990,
  heightCm: 180,
  activity: ActivityLevel.sedentary,
);

TargetSettingsRecord _version({
  int id = 1,
  int revision = 1,
  LocalDate? from,
  double base = 2000,
  double basis = 80,
  TargetMode mode = TargetMode.weekly,
  bool manual = false,
  bool acknowledged = false,
  Map<DayOfWeek, double> dayFactors = const {},
}) => TargetSettingsRecord(
  id: _id(id),
  revision: revision,
  effectiveFrom: from ?? _sat.plusDays(-14),
  baseKcal: base,
  basisWeightKg: basis,
  mode: mode,
  manual: manual,
  acknowledged: acknowledged,
  dayFactors: dayFactors,
);

GoalPhaseRecord _goal(
  GoalExpression expression, {
  GoalType type = GoalType.lose,
  LocalDate? start,
  int id = 50,
}) => GoalPhaseRecord(
  weightInputUnit: MassUnit.kilogram,
  id: _id(id),
  revision: 1,
  start: start ?? _sat.plusDays(-30),
  type: type,
  expression: expression,
);

DayIntake _ate(LocalDate date, double kcal, {int entries = 3}) =>
    DayIntake(date: date, kcal: kcal, entryCount: entries);

DayTargets? _day(
  LocalDate date, {
  List<TargetSettingsRecord>? settings,
  ProfileRecord? profile = _profile,
  List<GoalPhaseRecord> goals = const [],
  double? weight,
  List<DayIntake> intake = const [],
}) => TargetsTimeline.day(
  date: date,
  settings: settings ?? [_version()],
  profile: profile,
  goals: goals,
  bodyWeightKg: weight,
  intake: intake,
);

void main() {
  test('TG-040 TG-041 TargetsTimeline equals TargetPlan.day for a '
      'Saturday-start week (base 2,000, Sunday known +500, Monday no '
      'entries, Tuesday incomplete)', () {
    final result = _day(
      _wed,
      intake: [
        _ate(_sat, 2000),
        _ate(_sun, 2500),
        DayIntake(date: _mon, kcal: 0, entryCount: 0),
        DayIntake(date: _tue, kcal: 900, entryCount: 2, incomplete: true),
      ],
    )!;
    final expected = TargetPlan(baseKcal: 2000, floorKcal: 1750).day(
      date: _wed,
      weightKg: 80,
      earlierIntake: [
        WeekIntake(date: _sat, kcal: 2000),
        WeekIntake(date: _sun, kcal: 2500),
        WeekIntake(date: _tue, kcal: 900, complete: false),
      ],
    );
    expect(result.day.kcal, expected.kcal);
    expect(result.day.kcal, closeTo(5500 / 3, 1e-6));
    expect(result.day.macros.proteinGrams, expected.macros.proteinGrams);
    expect(result.day.macros.carbsGrams, expected.macros.carbsGrams);
    expect(result.day.week!.targets, expected.week!.targets);
    expect(result.floorKcal, 1750);
    expect(result.weightKg, 80);
    expect(result.raisedToFloor, isFalse);
    expect(result.issues, isEmpty);
    expect(result.version, _version());
    expect(result.week!.kcal, closeTo(500, 1e-9));
    expect(result.week!.uncountedDays, 2);
    expect(result.issues.clear, throwsUnsupportedError);
  });

  test('TG-032 a day with no entries and an incomplete day are never '
      'counted as zero: reserved at plan and reported as uncounted', () {
    final result = _day(
      _wed,
      intake: [
        DayIntake(date: _sun, kcal: 0, entryCount: 0),
        DayIntake(date: _mon, kcal: 300, entryCount: 1, incomplete: true),
        // A known zero (entries with no calories) does count.
        _ate(_tue, 0, entries: 2),
      ],
    )!;
    final week = result.day.week!;
    expect(week.unknownDates, [_sat, _sun, _mon]);
    // Unknown days hold their planned 2,000; the known zero counts as 0.
    expect(week.accountedPastKcal, closeTo(6000, 1e-9));
    expect(result.week!.uncountedDays, 3);
    expect(result.week!.kcal, closeTo(-2000, 1e-9));
    // Treating them as zero would have produced a much higher target.
    final asZero = _day(
      _wed,
      intake: [_ate(_sat, 0), _ate(_sun, 0), _ate(_mon, 0), _ate(_tue, 0)],
    )!;
    expect(asZero.day.week!.accountedPastKcal, 0);
    expect(asZero.week!.uncountedDays, 0);
    // Other weeks' and later days are ignored; the last entry for a date wins.
    final ignored = _day(
      _wed,
      intake: [
        _ate(_sat.plusDays(-1), 9000),
        _ate(_wed, 9000),
        _ate(_thu, 9000),
        _ate(_sun, 9000),
        _ate(_sun, 2000),
      ],
    )!;
    expect(ignored.week!.kcal, closeTo(0, 1e-9));
    expect(ignored.week!.uncountedDays, 3);
  });

  test('D6 days before the first version are left out and not reported as '
      'uncounted', () {
    final result = _day(
      _wed,
      settings: [_version(from: _mon)],
      intake: [_ate(_sat, 4000), _ate(_sun, 4000), _ate(_mon, 2300)],
    )!;
    final expected = TargetPlan(baseKcal: 2000, floorKcal: 1750).day(
      date: _wed,
      weightKg: 80,
      earlierIntake: [WeekIntake(date: _mon, kcal: 2300)],
    );
    expect(result.day.kcal, expected.kcal);
    // Sat/Sun are reserved at plan, not counted; Tuesday is uncounted.
    expect(result.day.week!.unknownDates, [_sat, _sun, _tue]);
    expect(result.week!.uncountedDays, 1);
    expect(result.week!.kcal, closeTo(300, 1e-9));
    // A mid-week first setup starts the week on track.
    final first = _day(_mon, settings: [_version(from: _mon)])!;
    expect(first.week!.kcal, 0);
    expect(first.week!.uncountedDays, 0);
    expect(first.day.kcal, closeTo(2000, 1e-6));
  });

  test('HM-002 week position is the sum of eaten minus planned over known '
      'complete earlier days; 0 on the first day; positive over, negative '
      'under', () {
    final shifted = [
      _version(dayFactors: {DayOfWeek.friday: 1.3}),
    ];
    final firstDay = _day(_sat, settings: shifted, intake: [_ate(_sat, 5000)])!;
    expect(firstDay.week!.kcal, 0);
    expect(firstDay.week!.uncountedDays, 0);

    final planned = firstDay.day.week!.planned;
    expect(planned[_sat], 2000);
    expect(planned[_sat.plusDays(6)], closeTo(2600, 1e-9));
    final over = _day(
      _mon,
      settings: shifted,
      intake: [_ate(_sat, 2400), _ate(_sun, 2000)],
    )!;
    expect(
      over.week!.kcal,
      closeTo(2400 - planned[_sat]! + 2000 - planned[_sun]!, 1e-9),
    );
    expect(over.week!.kcal, greaterThan(0));
    final under = _day(
      _mon,
      settings: shifted,
      intake: [_ate(_sat, 1500), _ate(_sun, 1600)],
    )!;
    expect(under.week!.kcal, lessThan(0));
    expect(
      under.week!.kcal,
      closeTo(3100 - planned[_sat]! - planned[_sun]!, 1e-9),
    );
  });

  test('TG-044 fixed mode returns the base and no week position', () {
    final result = _day(
      _wed,
      settings: [_version(mode: TargetMode.fixed, base: 2100)],
      intake: [_ate(_sat, 4000)],
    )!;
    expect(result.day.kcal, 2100);
    expect(result.day.week, isNull);
    expect(result.week, isNull);
  });

  test("PA1 a null body weight falls back to the version's basis weight; a "
      'given trend weight is used for floor and macros', () {
    // The default version's basis weight is 80 kg.
    final fallback = _day(_wed, settings: [_version()])!;
    expect(fallback.weightKg, 80);
    expect(fallback.floorKcal, 1750);
    expect(fallback.day.macros.proteinGrams, closeTo(1.8 * 80, 1e-9));
    final trend = _day(_wed, settings: [_version()], weight: 90)!;
    expect(trend.weightKg, 90);
    expect(trend.floorKcal, 1850);
    expect(trend.day.macros.proteinGrams, closeTo(1.8 * 90, 1e-9));
    // The stored base stays the base (weigh-ins never rewrite it).
    expect(trend.version.baseKcal, 2000);
  });

  test('SF-010 a generated base below the recomputed floor (higher trend '
      'weight) is raised and flagged', () {
    final settings = [_version(base: 1800, mode: TargetMode.fixed)];
    expect(_day(_wed, settings: settings)!.day.kcal, 1800);
    final raised = _day(_wed, settings: settings, weight: 90)!;
    expect(raised.floorKcal, 1850);
    expect(raised.day.kcal, 1850);
    expect(raised.raisedToFloor, isTrue);
    expect(raised.issues, isEmpty);
    // Weekly: no day goes below the risen floor.
    final weekly = _day(
      _wed,
      settings: [_version(base: 1800)],
      weight: 90,
      intake: [_ate(_sat, 4000), _ate(_sun, 4000)],
    )!;
    expect(weekly.raisedToFloor, isTrue);
    for (final kcal in weekly.day.week!.targets.values) {
      expect(kcal, greaterThanOrEqualTo(1850 - 1e-9));
    }
  });

  test('SF-012 an acknowledged fixed manual target below the floor is '
      'returned as is; any other below-floor manual target is raised and '
      'flagged manualNeedsReview', () {
    final kept = _day(
      _wed,
      settings: [
        _version(
          base: 1300,
          manual: true,
          acknowledged: true,
          mode: TargetMode.fixed,
        ),
      ],
    )!;
    expect(kept.day.kcal, 1300);
    expect(kept.day.manual, isTrue);
    expect(kept.day.acknowledged, isTrue);
    expect(kept.raisedToFloor, isFalse);
    expect(kept.issues, isEmpty);
    expect(kept.week, isNull);
    for (final (version, weight) in [
      (_version(base: 1300, manual: true, acknowledged: true), null),
      (_version(base: 1300, manual: true, mode: TargetMode.fixed), null),
      (_version(base: 1800, manual: true), 90.0),
    ]) {
      final result = _day(_wed, settings: [version], weight: weight)!;
      expect(result.raisedToFloor, isTrue);
      expect(result.issues, {TargetIssue.manualNeedsReview});
      expect(result.day.kcal, greaterThanOrEqualTo(result.floorKcal - 1e-9));
    }
    // A manual target above the floor needs nothing.
    final fine = _day(_wed, settings: [_version(base: 2200, manual: true)])!;
    expect(fine.issues, isEmpty);
    expect(fine.raisedToFloor, isFalse);
  });

  test('PA3 a goal whose deadline has passed, or whose target weight is '
      'already '
      'passed, gives goalNeedsUpdate instead of throwing', () {
    final fixed = [_version(mode: TargetMode.fixed)];
    for (final goal in [
      _goal(GoalExpression.targetDate(70, _tue)),
      _goal(GoalExpression.targetDate(70, _wed)),
      _goal(GoalExpression.targetRate(85, .5)),
      _goal(GoalExpression.targetRate(80, .5)),
      _goal(GoalExpression.weekly(.5)),
    ]) {
      final result = _day(_wed, settings: fixed, goals: [goal])!;
      expect(result.issues, {TargetIssue.goalNeedsUpdate});
      expect(result.day.kcal, 2000);
    }
    for (final goal in [
      _goal(GoalExpression.targetDate(70, _thu)),
      _goal(GoalExpression.targetRate(75, .5)),
      _goal(GoalExpression.weekly(0), type: GoalType.maintain),
    ]) {
      expect(_day(_wed, settings: fixed, goals: [goal])!.issues, isEmpty);
    }
    // The trend weight decides: at 69 kg a 70 kg loss target is passed.
    expect(
      _day(
        _wed,
        settings: fixed,
        goals: [_goal(GoalExpression.targetRate(70, .5))],
        weight: 69,
      )!.issues,
      {TargetIssue.goalNeedsUpdate},
    );
    expect(
      TargetsTimeline.resolve(
        _goal(GoalExpression.weekly(-.5)),
        weightKg: 80,
        date: _wed,
      )!.requestedKgPerWeek,
      -.5,
    );
  });

  test('PA3 explain drops the goal line for an unresolvable goal and '
      'reports '
      'manualNeedsReview instead of throwing for an unacknowledged manual '
      'value below a risen floor', () {
    final passed = TargetsTimeline.explain(
      date: _wed,
      settings: [_version(from: _wed)],
      profile: _profile,
      goals: [_goal(GoalExpression.targetDate(70, _tue))],
    )!;
    expect(passed.goal, isNull);
    expect(passed.issues, {TargetIssue.goalNeedsUpdate});
    // Without a goal line the calculation is maintenance.
    expect(passed.calculated.kcal, closeTo(1750 * 1.2, 1e-9));
    expect(passed.calculated.requestedKgPerWeek, 0);
    expect(passed.manual, isNull);

    // Written at 1,760 when the floor was 1,750; the height then rose, so
    // the floor is 1,812.5 and the unacknowledged value can't be computed.
    final risen = TargetsTimeline.explain(
      date: _wed,
      settings: [_version(from: _wed, base: 1760, manual: true)],
      profile: _profile.copyWith(heightCm: 190),
      goals: [_goal(GoalExpression.weekly(-.5))],
    )!;
    expect(risen.calculated.floorKcal, 1812.5);
    expect(risen.manual, isNull);
    expect(risen.goal, isNotNull);
    expect(risen.issues, {TargetIssue.manualNeedsReview});
  });

  test('A12 PA5 a midweek revision: Monday uses the Saturday version, '
      'Thursday the Wednesday version', () {
    final saturday = _version(from: _sat);
    final wednesday = _version(id: 2, from: _wed, base: 2400);
    final settings = [wednesday, saturday];
    final monday = _day(_mon, settings: settings)!;
    expect(monday.version, saturday);
    expect(monday.day.kcal, closeTo(2000, 1e-6));
    final thursday = _day(_thu, settings: settings)!;
    expect(thursday.version, wednesday);
    expect(thursday.day.kcal, closeTo(2400, 1e-6));
    // Same date: the higher revision, then the higher ID wins.
    final revised = _version(id: 3, from: _wed, revision: 2, base: 2200);
    expect(
      TargetsTimeline.versionOn([revised, wednesday, saturday], _thu),
      revised,
    );
    expect(
      TargetsTimeline.versionOn([
        _version(id: 4, from: _wed, revision: 2),
        revised,
      ], _thu)!.id,
      _id(4),
    );
    expect(TargetsTimeline.versionOn(settings, _sat.plusDays(-1)), isNull);
  });

  test("TG-050 macros use the active phase's target weight, else the body "
      'weight', () {
    double protein(List<GoalPhaseRecord> goals) =>
        _day(_wed, goals: goals, weight: 90)!.day.macros.proteinGrams;
    expect(
      protein([_goal(GoalExpression.targetRate(70, .5))]),
      closeTo(1.8 * 70, 1e-9),
    );
    expect(
      protein([_goal(GoalExpression.targetDate(72, LocalDate(2027, 6, 1)))]),
      closeTo(1.8 * 72, 1e-9),
    );
    expect(
      protein([_goal(GoalExpression.weekly(-.5))]),
      closeTo(1.8 * 90, 1e-9),
    );
    expect(protein([]), closeTo(1.8 * 90, 1e-9));
    // A phase that ended before the date is not active.
    final ended = _goal(GoalExpression.targetRate(70, .5))
        .withEnd(_sat.plusDays(-1));
    expect(protein([ended]), closeTo(1.8 * 90, 1e-9));
    expect(TargetsTimeline.phaseOn([ended], _wed), isNull);
    expect(TargetsTimeline.phaseOn([ended], _sat.plusDays(-1)), ended);
  });

  test('PA3 an implausible synced basis weight (1e5) or height (1e6) gives '
      'null from day and explain, never a throw', () {
    for (final (settings, profile) in [
      ([_version(basis: 100000)], _profile),
      ([_version()], _profile.copyWith(heightCm: 1000000)),
    ]) {
      expect(_day(_wed, settings: settings, profile: profile), isNull);
      expect(
        TargetsTimeline.explain(
          date: _wed,
          settings: settings,
          profile: profile,
        ),
        isNull,
      );
    }
    // A floor just below the technical bound plans fine, but rebalancing
    // four eaten-nothing days lifts Wednesday past it: still null.
    expect(
      _day(
        _wed,
        settings: [_version(basis: 89905)],
        intake: [
          for (final date in [_sat, _sun, _mon, _tue])
            DayIntake(date: date, kcal: 0, entryCount: 1),
        ],
      ),
      isNull,
    );
  });

  test('D6 no profile, or no version effective on the date → null', () {
    expect(_day(_wed, profile: null), isNull);
    expect(_day(_wed, settings: []), isNull);
    expect(_day(_wed, settings: [_version(from: _thu)]), isNull);
    // A profile that can't be evaluated on the date (born after it).
    expect(_day(_wed, profile: _profile.copyWith(birthYear: 2027)), isNull);
    expect(
      TargetsTimeline.explain(date: _wed, settings: [], profile: _profile),
      isNull,
    );
    expect(
      TargetsTimeline.explain(
        date: _wed,
        settings: [_version()],
        profile: null,
      ),
      isNull,
    );
    expect(
      TargetsTimeline.explain(
        date: _wed,
        settings: [_version()],
        profile: _profile.copyWith(birthYear: 2027),
      ),
      isNull,
    );
  });

  test('TG-021 explain reproduces the stored base of the version in effect '
      'today from its basis weight and effective date; for a manual version '
      'it gives the calculated value, the manual value and its warnings', () {
    final goal = _goal(GoalExpression.weekly(-.5));
    final stored = TargetCalculator.calculate(
      profile: _profile.toProfile(84.2),
      goal: TargetsTimeline.resolve(goal, weightKg: 84.2, date: _wed)!,
      date: _wed,
    );
    final today = _version(from: _wed, base: stored.kcal, basis: 84.2);
    final explained = TargetsTimeline.explain(
      date: _wed,
      settings: [
        _version(from: _sat),
        today,
      ],
      profile: _profile,
      goals: [goal],
    )!;
    expect(explained.version, today);
    expect(explained.calculated.kcal, today.baseKcal);
    expect(explained.calculated.restingKcal, stored.restingKcal);
    expect(explained.goal!.requestedKgPerWeek, -.5);
    expect(explained.manual, isNull);
    expect(explained.issues, isEmpty);
    expect(explained.issues.clear, throwsUnsupportedError);
    // An older version is explained on its own effective date.
    final older = TargetsTimeline.explain(
      date: _mon,
      settings: [
        _version(from: LocalDate(2025, 12, 31)),
        today,
      ],
      profile: _profile,
    )!;
    expect(older.calculated.restingKcal, 10 * 80 + 1125 - 5 * 35 + 5);
    expect(older.goal, isNull);
    expect(older.issues, isEmpty);

    final manual = TargetsTimeline.explain(
      date: _wed,
      settings: [
        _version(
          from: _wed,
          base: 1000,
          manual: true,
          acknowledged: true,
          mode: TargetMode.fixed,
        ),
      ],
      profile: _profile,
      goals: [goal],
    )!;
    expect(manual.calculated.manual, isFalse);
    expect(manual.calculated.acknowledged, isFalse);
    // 2,100 − 550 is below the 1,750 floor, so the calculation clamps.
    expect(manual.calculated.kcal, 1750);
    expect(manual.calculated.warnings, {TargetWarning.calorieFloorApplied});
    expect(manual.manual!.kcal, 1000);
    expect(manual.manual!.manual, isTrue);
    expect(manual.manual!.warnings, {
      TargetWarning.manualBelowFloor,
      TargetWarning.manualLossRateExceeded,
    });
    expect(manual.issues, isEmpty);
  });

  test('PA13 SF-010 TargetCalculator.floor equals calculate().floorKcal', () {
    final date = LocalDate(2026, 10, 28);
    for (final record in [
      _profile,
      _profile.copyWith(sex: FormulaSex.female),
      const ProfileRecord(
        heightInputUnit: HeightInputUnit.centimeter,
        sex: FormulaSex.female,
        birthYear: 1950,
        heightCm: 140,
        activity: ActivityLevel.high,
      ),
    ]) {
      for (final weight in [45.0, 80.0, 140.0]) {
        final profile = record.toProfile(weight);
        final calculated = TargetCalculator.calculate(
          profile: profile,
          goal: ResolvedGoal.resolve(
            type: GoalType.maintain,
            expression: GoalExpression.weekly(0),
            currentKg: weight,
            date: date,
          ),
          date: date,
        );
        expect(TargetCalculator.floor(profile, date), calculated.floorKcal);
      }
    }
  });

  test('D6 DayIntake rejects negative or non-finite values; derived values '
      'print without content (PA14)', () {
    expect(
      () => DayIntake(date: _sat, kcal: -1, entryCount: 1),
      throwsArgumentError,
    );
    expect(
      () => DayIntake(date: _sat, kcal: double.nan, entryCount: 1),
      throwsArgumentError,
    );
    expect(
      () => DayIntake(date: _sat, kcal: 1, entryCount: -1),
      throwsArgumentError,
    );
    final day = _day(_wed, intake: [_ate(_sat, 2345)])!;
    expect('$day', 'DayTargets');
    expect('${day.week}', 'WeekPosition');
    final explanation = TargetsTimeline.explain(
      date: _wed,
      settings: [_version()],
      profile: _profile,
    );
    expect('$explanation', 'TargetExplanation');
  });

  Glados3(
    any.combine5(
      any.doubleInRange(1000, 4000),
      any.doubleInRange(50, 120),
      any.intInRange(0, 2),
      any.intInRange(0, 3),
      any.intInRange(0, 7),
      (base, basis, trend, kind, elapsed) => (
        base: base,
        basis: basis,
        trend: trend == 0 ? null : basis + 15,
        manual: kind > 0,
        acknowledged: kind > 1,
        elapsed: elapsed,
      ),
    ),
    any.listWithLength(
      7,
      any.combine2(
        any.intInRange(0, 3),
        any.doubleInRange(0, 5000),
        (kind, kcal) => (kind, kcal),
      ),
    ),
    any.intInRange(0, 2),
    propertyRuns,
  ).test('D6 SF-010 SF-012 TargetsTimeline.day equals TargetPlan.day on the '
      'same inputs and is '
      'never below the floor unless manual, acknowledged and fixed', (
    input,
    days,
    fixed,
  ) {
    final date = _sat.plusDays(input.elapsed);
    final version = _version(
      base: input.base,
      basis: input.basis,
      manual: input.manual,
      acknowledged: input.acknowledged,
      mode: fixed == 1 ? TargetMode.fixed : TargetMode.weekly,
      dayFactors: {DayOfWeek.friday: 1.3},
    );
    final intake = [
      for (var i = 0; i < input.elapsed; i++)
        DayIntake(
          date: _sat.plusDays(i),
          kcal: days[i].$2,
          entryCount: days[i].$1 == 0 ? 0 : 2,
          incomplete: days[i].$1 == 2,
        ),
    ];
    final result = _day(
      date,
      settings: [version],
      weight: input.trend,
      intake: intake,
    )!;
    final weight = input.trend ?? input.basis;
    final floor = TargetCalculator.floor(_profile.toProfile(weight), date);
    final mayStay = version.mayStayBelowFloor;
    final expected =
        TargetPlan(
          baseKcal: input.base < floor && !mayStay ? floor : input.base,
          floorKcal: floor,
          mode: version.mode,
          manual: input.manual,
          acknowledged: input.acknowledged,
          dayFactors: version.factors,
        ).day(
          date: date,
          weightKg: weight,
          earlierIntake: [
            for (final day in intake)
              if (day.incomplete)
                WeekIntake(date: day.date, kcal: day.kcal, complete: false)
              else if (day.entryCount > 0)
                WeekIntake(date: day.date, kcal: day.kcal),
          ],
        );
    expect(result.day.kcal, expected.kcal);
    expect(result.day.macros.proteinGrams, expected.macros.proteinGrams);
    expect(result.floorKcal, floor);
    if (!mayStay) {
      expect(result.day.kcal, greaterThanOrEqualTo(floor - 1e-9));
    }
  });

  Glados3(
    any.listWithLength(
      7,
      any.combine2(
        any.intInRange(0, 3),
        any.doubleInRange(0, 5000),
        (kind, kcal) => (kind, kcal),
      ),
    ),
    any.intInRange(0, 7),
    any.intInRange(0, 7),
    propertyRuns,
  ).test('HM-002 week position plus the reserved unknown days equals '
      'accountedPastKcal minus the planned past allocation', (
    days,
    elapsed,
    firstDay,
  ) {
    final date = _sat.plusDays(elapsed);
    final first = _sat.plusDays(firstDay < elapsed ? firstDay : 0);
    final result = _day(
      date,
      settings: [
        _version(
          from: first,
          base: 2200,
          dayFactors: {DayOfWeek.friday: 1.3, DayOfWeek.saturday: 1.15},
        ),
      ],
      intake: [
        for (var i = 0; i < elapsed; i++)
          DayIntake(
            date: _sat.plusDays(i),
            kcal: days[i].$2,
            entryCount: days[i].$1 == 0 ? 0 : 1,
            incomplete: days[i].$1 == 2,
          ),
      ],
    )!;
    final week = result.day.week!;
    final unknown = week.unknownDates.toSet();
    var reservedUnknown = 0.0;
    var plannedKnown = 0.0;
    var plannedPast = 0.0;
    for (var i = 0; i < elapsed; i++) {
      final d = _sat.plusDays(i);
      plannedPast += week.planned[d]!;
      if (unknown.contains(d)) {
        reservedUnknown += week.planned[d]!;
      } else {
        plannedKnown += week.planned[d]!;
      }
    }
    expect(
      result.week!.kcal + reservedUnknown,
      closeTo(week.accountedPastKcal - plannedKnown, 1e-6),
    );
    expect(
      result.week!.kcal,
      closeTo(week.accountedPastKcal - plannedPast, 1e-6),
    );
    expect(
      result.week!.uncountedDays,
      unknown.where((d) => !d.isBefore(first)).length,
    );
    if (elapsed == 0) expect(result.week!.kcal, 0);
  });

  group('D-090 per-weekday numbers', () {
    test('a changed weekday follows a new suggestion in proportion; the '
        'plan is exposed for the screen', () {
      final friday = _sat.plusDays(6);
      final before = _day(
        friday,
        settings: [
          _version(dayFactors: {DayOfWeek.friday: 1.25}),
        ],
      )!;
      expect(before.day.kcal, closeTo(2500, 1e-9));
      expect(before.plan.baseKcal, 2000);
      expect(before.plan.plannedKcal(DayOfWeek.monday), 2000);
      // An adaptive update writes a new base; Friday keeps its factor.
      final after = _day(
        friday,
        settings: [
          _version(dayFactors: {DayOfWeek.friday: 1.25}),
          _version(
            id: 2,
            from: _sat,
            base: 2200,
            dayFactors: {DayOfWeek.friday: 1.25},
          ),
        ],
      )!;
      expect(after.day.kcal, closeTo(2750, 1e-9));
      expect(after.issues, isEmpty);
    });

    test('A53 D4 SF-010 a weekday below the floor is raised to it unless the '
        'user confirmed that factor; a confirmed one stays and is flagged', () {
      final settings = [
        _version(dayFactors: {DayOfWeek.saturday: .6}),
      ];
      final raised = _day(_sat, settings: settings)!;
      expect(raised.day.kcal, closeTo(raised.floorKcal, 1e-9));
      expect(raised.issues, isEmpty);
      final kept = TargetsTimeline.day(
        date: _sat,
        settings: settings,
        profile: _profile,
        floorAcknowledged: {DayOfWeek.saturday: .6},
      )!;
      expect(kept.day.kcal, closeTo(1200, 1e-9));
      expect(kept.issues, {TargetIssue.dayBelowFloor});
      // A confirmation of another factor doesn't cover this one.
      final other = TargetsTimeline.day(
        date: _sat,
        settings: settings,
        profile: _profile,
        floorAcknowledged: {DayOfWeek.saturday: .5},
      )!;
      expect(other.day.kcal, closeTo(other.floorKcal, 1e-9));
    });

    test('TG-060 a Ramadan maintain day applies the factor to the maintain '
        'base', () {
      final result = TargetsTimeline.day(
        date: _wed,
        settings: [
          _version(
            mode: TargetMode.fixed,
            dayFactors: {DayOfWeek.wednesday: 1.1},
          ),
        ],
        profile: _profile,
        goals: [_goal(GoalExpression.weekly(-.5))],
        ramadanMaintain: true,
      )!;
      expect(result.day.kcal, closeTo((2000 + .5 * 7700 / 7) * 1.1, .01));
    });
  });

  group('TG-060 maintain during Ramadan', () {
    DayTargets? maintain(
      List<GoalPhaseRecord> goals, {
      TargetSettingsRecord? version,
      bool on = true,
    }) => TargetsTimeline.day(
      date: _wed,
      settings: [version ?? _version(mode: TargetMode.fixed)],
      profile: _profile,
      goals: goals,
      ramadanMaintain: on,
    );

    test("a loss goal's deficit is left out of a generated base", () {
      final goals = [_goal(GoalExpression.weekly(-.5))];
      final normal = maintain(goals, on: false)!;
      final ramadan = maintain(goals)!;
      expect(normal.day.kcal, closeTo(2000, .01));
      expect(ramadan.day.kcal, closeTo(2000 + .5 * 7700 / 7, .01));
      expect(ramadan.ramadanMaintain, isTrue);
      expect(normal.ramadanMaintain, isFalse);
    });

    test('the SF-011 cap limits what is added back', () {
      // 1 % of 80 kg = 0.8 kg/week.
      final ramadan = maintain([_goal(GoalExpression.weekly(-1.2))])!;
      expect(ramadan.day.kcal, closeTo(2000 + .8 * 7700 / 7, .01));
    });

    test("a gain goal's surplus is removed, never below the floor", () {
      final goals = [_goal(GoalExpression.weekly(.1), type: GoalType.gain)];
      expect(maintain(goals)!.day.kcal, closeTo(2000 - .1 * 7700 / 7, .01));
      final low = maintain(
        goals,
        version: _version(mode: TargetMode.fixed, base: 1800),
      )!;
      expect(low.day.kcal, closeTo(1750, .01), reason: 'the floor');
    });

    test('a manual base, a maintain goal or no goal stay unchanged', () {
      final manual = maintain([
        _goal(GoalExpression.weekly(-.5)),
      ], version: _version(mode: TargetMode.fixed, manual: true))!;
      expect(manual.day.kcal, closeTo(2000, .01));
      expect(manual.ramadanMaintain, isFalse);
      expect(maintain(const [])!.ramadanMaintain, isFalse);
      final kept = maintain([
        _goal(GoalExpression.weekly(0), type: GoalType.maintain),
      ])!;
      expect(kept.ramadanMaintain, isFalse);
    });
  });
}
