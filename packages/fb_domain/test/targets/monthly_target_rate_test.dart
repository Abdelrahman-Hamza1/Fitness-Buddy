import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

String _id(int value) =>
    '0199e3c2-5b1a-7000-8000-${value.toRadixString(16).padLeft(12, '0')}';

final LocalDate _day = LocalDate(2026, 10, 28);

const _profile = ProfileRecord(
  heightInputUnit: HeightInputUnit.centimeter,
  sex: FormulaSex.male,
  birthYear: 1990,
  heightCm: 180,
  activity: ActivityLevel.sedentary,
);

TargetSettingsRecord _version({
  double base = 2000,
  bool manual = false,
  bool acknowledged = false,
}) => TargetSettingsRecord(
  id: _id(1),
  revision: 1,
  effectiveFrom: _day,
  baseKcal: base,
  basisWeightKg: 80,
  manual: manual,
  acknowledged: acknowledged,
);

GoalPhaseRecord _goal(GoalExpression expression) => GoalPhaseRecord(
  weightInputUnit: MassUnit.kilogram,
  id: _id(50),
  revision: 1,
  start: _day.plusDays(-30),
  type: GoalType.lose,
  expression: expression,
);

TargetExplanation? _explain(
  TargetSettingsRecord version, {
  List<GoalPhaseRecord> goals = const [],
  ProfileRecord profile = _profile,
}) => TargetsTimeline.explain(
  date: _day,
  settings: [version],
  profile: profile,
  goals: goals,
);

void main() {
  final lose = [_goal(GoalExpression.weekly(-.5))];

  test('WB-023 TG-011 a generated target gives its achievable rate', () {
    final explanation = _explain(_version(), goals: lose)!;
    final rate = MonthlyTargetRate.of(explanation);
    expect(rate, isA<GeneratedMonthlyRate>());
    expect(rate.kgPerWeek, explanation.calculated.achievableKgPerWeek);
    expect(rate.toString(), 'GeneratedMonthlyRate');
  });

  test('WB-023 a computable manual target gives its own rate', () {
    final explanation = _explain(
      _version(base: 1900, manual: true, acknowledged: true),
      goals: lose,
    )!;
    final rate = MonthlyTargetRate.of(explanation);
    expect(rate, isA<ManualMonthlyRate>());
    expect(rate.kgPerWeek, explanation.manual!.achievableKgPerWeek);
    expect(rate.toString(), 'ManualMonthlyRate');
  });

  test('SF-012 a manual target that needs review gives no monthly target, '
      'never the generated one', () {
    // 1,760 kcal against a floor risen to 1,812.5 (taller profile).
    final explanation = _explain(
      _version(base: 1760, manual: true),
      goals: lose,
      profile: _profile.copyWith(heightCm: 190),
    )!;
    expect(explanation.issues, {TargetIssue.manualNeedsReview});
    final rate = MonthlyTargetRate.of(explanation);
    expect(rate.kgPerWeek, isNull);
    expect(
      (rate as MonthlyRateUnavailable).gap,
      MonthlyRateGap.manualNeedsReview,
    );
  });

  test('WB-023 no targets, no goal or an unresolvable goal give no monthly '
      'target and a reason', () {
    MonthlyRateGap gap(TargetExplanation? e) =>
        (MonthlyTargetRate.of(e) as MonthlyRateUnavailable).gap;
    expect(gap(null), MonthlyRateGap.noTargets);
    expect(gap(_explain(_version())), MonthlyRateGap.noGoal);
    expect(
      gap(
        _explain(
          _version(),
          goals: [_goal(GoalExpression.targetDate(70, _day.plusDays(-1)))],
        ),
      ),
      MonthlyRateGap.goalNeedsUpdate,
    );
    expect(
      const MonthlyRateUnavailable(MonthlyRateGap.noGoal).toString(),
      'MonthlyRateUnavailable(noGoal)',
    );
  });
}
