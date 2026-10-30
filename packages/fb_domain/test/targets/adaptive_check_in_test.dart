import 'package:fb_domain/fb_domain.dart';
import 'package:glados/glados.dart';

import '../helpers/property.dart';

final LocalDate _today = LocalDate(2026, 11, 7);

String _id(int n) =>
    '0199e3c2-5b1a-7000-8000-${n.toRadixString(16).padLeft(12, '0')}';

/// Male, 180 cm, born 1990, sedentary: resting 1,780 kcal at 80 kg in
/// 2026 (so the floor is 1,780).
ProfileRecord _profile({FormulaSex sex = FormulaSex.male}) => ProfileRecord(
  sex: sex,
  birthYear: 1990,
  heightCm: 180,
  heightInputUnit: HeightInputUnit.centimeter,
  activity: ActivityLevel.sedentary,
);

TargetSettingsRecord _version(
  double base, {
  bool manual = false,
  bool acknowledged = false,
  TargetMode mode = TargetMode.weekly,
}) => TargetSettingsRecord(
  id: _id(1),
  revision: 1,
  effectiveFrom: LocalDate(2026, 10, 1),
  baseKcal: base,
  basisWeightKg: 80,
  manual: manual,
  acknowledged: acknowledged,
  mode: mode,
);

GoalPhaseRecord _phase(GoalType type, GoalExpression expression) =>
    GoalPhaseRecord(
      id: _id(2),
      revision: 1,
      start: LocalDate(2026, 10, 1),
      type: type,
      expression: expression,
      weightInputUnit: MassUnit.kilogram,
    );

CheckInDecision _decide({
  required double base,
  required double? expenditure,
  List<GoalPhaseRecord> goals = const [],
  bool manual = false,
  bool acknowledged = false,
  TargetMode mode = TargetMode.weekly,
  ProfileRecord? profile,
  bool noProfile = false,
}) => AdaptiveCheckIn.decide(
  today: _today,
  expenditureKcal: expenditure,
  settings: [
    _version(base, manual: manual, acknowledged: acknowledged, mode: mode),
  ],
  profile: noProfile ? null : profile ?? _profile(),
  goals: goals,
  weightKg: 80,
);

void main() {
  final floor = TargetCalculator.floor(_profile().toProfile(80), _today);

  group('TG-034 TG-035 SF-010 the weekly check-in', () {
    test('maintain: recommends the estimate; a big gap is capped at 150', () {
      final d = _decide(base: 2600, expenditure: 2300);
      expect(d.proposes, isTrue);
      expect(d.recommendedKcal, 2300);
      expect(d.currentKcal, 2600);
      expect(d.proposedKcal, 2450);
      expect(d.floorKcal, floor);
      final up = _decide(base: 2200, expenditure: 2900);
      expect(up.proposedKcal, 2350);
    });

    test('within 50 kcal: nothing; just over: a step rounded to 10', () {
      expect(
        _decide(base: 2350, expenditure: 2300).skip,
        CheckInSkip.withinThreshold,
      );
      expect(
        _decide(base: 2300, expenditure: 2250).skip,
        CheckInSkip.withinThreshold,
        reason: 'exactly 50 is not more than 50',
      );
      expect(_decide(base: 2300, expenditure: 2243).proposedKcal, 2250);
      // From an uneven base, a round number toward it.
      expect(_decide(base: 2304.6, expenditure: 2000).proposedKcal, 2160);
    });

    test('a goal rate applies on top of the estimate (TG-036: never '
        'exercise)', () {
      final lose = _decide(
        base: 2500,
        expenditure: 2600,
        goals: [_phase(GoalType.lose, GoalExpression.weekly(-.5))],
      );
      // 2,600 − 0.5 × 7,700 / 7 = 2,050; capped at −150 from 2,500.
      expect(lose.recommendedKcal, closeTo(2050, 1e-9));
      expect(lose.proposedKcal, 2350);
    });

    test('the floor wins over the step', () {
      expect(
        AdaptiveCheckIn.propose(current: 1800, recommended: 1500, floor: 1750),
        1750,
      );
      // Already at the floor: nothing left to change.
      expect(
        AdaptiveCheckIn.propose(current: 1750, recommended: 1500, floor: 1750),
        isNull,
      );
      // The engine's recommendation is floored already.
      final d = _decide(base: floor + 100, expenditure: 1500);
      expect(d.recommendedKcal, floor);
      expect(d.proposedKcal, floor);
    });

    test('a base below the floor is read at the floor (D6)', () {
      final d = _decide(base: 1000, expenditure: 2300);
      expect(d.currentKcal, floor);
      expect(d.proposedKcal, floor + 150);
    });

    test('an acknowledged fixed manual target below the floor is never '
        'touched', () {
      final d = _decide(
        base: 1400,
        expenditure: 2300,
        manual: true,
        acknowledged: true,
        mode: TargetMode.fixed,
      );
      expect(d.skip, CheckInSkip.belowFloor);
    });

    test('a manual target above the floor still gets a proposal', () {
      expect(
        _decide(base: 2600, expenditure: 2300, manual: true).proposes,
        isTrue,
      );
    });

    test('skips: not ready, no targets, a goal that needs updating', () {
      expect(_decide(base: 2300, expenditure: null).skip, CheckInSkip.notReady);
      expect(
        _decide(base: 2300, expenditure: 2000, noProfile: true).skip,
        CheckInSkip.noTargets,
      );
      final reached = _decide(
        base: 2300,
        expenditure: 2000,
        goals: [_phase(GoalType.lose, GoalExpression.targetRate(85, .5))],
      );
      expect(reached.skip, CheckInSkip.goalNeedsUpdate);
    });
  });

  Glados3(
    any.doubleInRange(1000, 5000),
    any.doubleInRange(800, 6000),
    any.doubleInRange(1200, 2500),
    propertyRuns,
  ).test('TG-035 SF-010 property: propose never moves more than 150 kcal '
      'and never goes below the floor', (current, recommended, floorKcal) {
    final proposed = AdaptiveCheckIn.propose(
      current: current,
      recommended: recommended,
      floor: floorKcal,
    );
    if (proposed == null) return;
    expect(current, greaterThanOrEqualTo(floorKcal));
    expect((proposed - current).abs(), lessThanOrEqualTo(150));
    expect(proposed, greaterThanOrEqualTo(floorKcal));
    expect((recommended - current).abs(), greaterThan(50));
    // Always toward the recommendation.
    expect((proposed - current).sign, (recommended - current).sign);
  });

  Glados3(
    any.doubleInRange(900, 5000),
    any.doubleInRange(900, 6000),
    any.intInRange(0, 5),
    propertyRuns,
  ).test('TG-035 SF-010 property: a check-in never proposes beyond ±150 '
      "kcal/day of today's target or below the floor", (base, expenditure, g) {
    final goals = switch (g) {
      0 => <GoalPhaseRecord>[],
      1 => [_phase(GoalType.lose, GoalExpression.weekly(-1))],
      2 => [_phase(GoalType.gain, GoalExpression.weekly(.5))],
      3 => [_phase(GoalType.lose, GoalExpression.targetRate(70, .75))],
      _ => [_phase(GoalType.maintain, GoalExpression.weekly(0))],
    };
    for (final sex in FormulaSex.values) {
      final d = _decide(
        base: base,
        expenditure: expenditure,
        goals: goals,
        profile: _profile(sex: sex),
      );
      if (!d.proposes) continue;
      expect((d.proposedKcal! - d.currentKcal!).abs(), lessThanOrEqualTo(150));
      expect(d.proposedKcal, greaterThanOrEqualTo(d.floorKcal!));
      expect(d.currentKcal, greaterThanOrEqualTo(d.floorKcal!));
    }
  });

  group('drafts', () {
    test('a check-in draft round-trips and rejects broken JSON', () {
      final draft = TargetChangeDraft(
        weekStart: _today,
        versionId: _id(1),
        versionRevision: 2,
        fromKcal: 2400,
        toKcal: 2250,
        recommendedKcal: 2100.5,
        expenditureKcal: 2600,
        confidence: ExpenditureConfidence.medium,
        fromManual: true,
      );
      expect(TargetChangeDraft.tryParse(draft.toJson()), draft);
      final applied = draft.copyWith(
        toKcal: 2300,
        automatic: true,
        seen: true,
        appliedVersionId: _id(9),
        appliedRevision: 1,
      );
      expect(applied.toKcal, 2300);
      expect(TargetChangeDraft.tryParse(applied.toJson()), applied);
      expect(applied.automatic && applied.seen, isTrue);
      expect(applied.appliedVersionId, _id(9));
      expect(
        TargetChangeDraft.tryParse(
          applied.toJson().replaceFirst(
            '"appliedRevision":1',
            '"appliedRevision":0',
          ),
        ),
        isNull,
      );
      // Older drafts without the flags read them as false.
      final legacy = draft.toJson().replaceFirst(
        ',"automatic":false,"seen":false',
        '',
      );
      expect(legacy, isNot(contains('automatic')));
      expect(TargetChangeDraft.tryParse(legacy), draft);
      final held = TargetChangeDraft(
        weekStart: _today,
        versionId: _id(1),
        versionRevision: 1,
        fromKcal: 2400,
        toKcal: 2250,
        recommendedKcal: 2100,
        expenditureKcal: 2600,
        confidence: ExpenditureConfidence.low,
        hold: CheckInHold.anomaly,
        anomalyDates: [LocalDate(2026, 11, 3)],
      );
      final back = TargetChangeDraft.tryParse(held.toJson())!;
      expect(back.hold, CheckInHold.anomaly);
      expect(back.anomalyDates, [LocalDate(2026, 11, 3)]);
      expect(
        TargetChangeDraft.tryParse(
          held.toJson().replaceFirst('"anomaly"', '"later"'),
        ),
        isNull,
      );
      expect(draft.toString(), isNot(contains('2400')));
      for (final bad in [
        '',
        '[]',
        '{}',
        draft.toJson().replaceFirst('"medium"', '"sure"'),
        draft.toJson().replaceFirst('2400.0', '-1'),
        draft.toJson().replaceFirst(_id(1), 'not-a-uuid'),
      ]) {
        expect(TargetChangeDraft.tryParse(bad), isNull, reason: bad);
      }
    });

    test('an incomplete-day draft holds its date', () {
      expect(
        DayIncompleteDraft.dateOf(DayIncompleteDraft.toJson(_today)),
        _today,
      );
      expect(DayIncompleteDraft.dateOf('{"date": 3}'), isNull);
      expect(DayIncompleteDraft.dateOf('nope'), isNull);
    });
  });
}
