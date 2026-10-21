import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

TargetProfile profile({
  FormulaSex sex = FormulaSex.male,
  ActivityLevel activity = ActivityLevel.sedentary,
  double weight = 80,
}) => TargetProfile(
  sex: sex,
  birthYear: 1990,
  heightCm: 180,
  weightKg: weight,
  activity: activity,
);
final date = LocalDate(2026, 1, 1);
ResolvedGoal goal(
  GoalExpression expression, {
  GoalType type = GoalType.lose,
  double weight = 80,
  LocalDate? at,
}) => ResolvedGoal.resolve(
  type: type,
  expression: expression,
  currentKg: weight,
  date: at ?? date,
);

void main() {
  test('TG-001 TG-020 formulas and all activity factors are explained', () {
    const defaults = TargetDefaults();
    for (final activity in ActivityLevel.values) {
      final p = profile(activity: activity);
      final result = TargetCalculator.calculate(
        profile: p,
        goal: goal(GoalExpression.weekly(0), type: GoalType.maintain),
        date: date,
      );
      expect(result.restingKcal, 1750);
      expect(result.activityFactor, defaults.activityFactor(activity));
      expect(result.expenditureKcal, 1750 * result.activityFactor);
      expect(result.kcal, result.expenditureKcal);
      expect(result.floorKcal, 1750);
      expect(result.projectedDate, isNull);
      expect(result.manual, isFalse);
      expect(result.acknowledged, isFalse);
      expect(result.warnings, isEmpty);
      expect(result.warnings.clear, throwsUnsupportedError);
    }
    final female = profile(sex: FormulaSex.female);
    expect(TargetCalculator.resting(female, date), 1584);
    expect(female.ageOn(date), 36);
    expect(() => female.ageOn(LocalDate(1989, 1, 1)), throwsArgumentError);
    final small = TargetProfile(
      sex: FormulaSex.female,
      birthYear: 1950,
      heightCm: 140,
      weightKg: 45,
      activity: ActivityLevel.sedentary,
    );
    expect(
      TargetCalculator.calculate(
        profile: small,
        goal: goal(GoalExpression.weekly(0), type: GoalType.maintain),
        date: date,
      ).floorKcal,
      1200,
    );
  });

  test('TG-002 canonical metric and imperial inputs agree', () {
    final imperial = TargetProfile(
      sex: FormulaSex.male,
      birthYear: 1990,
      heightCm: 180 / 2.54 * LengthUnit.inch.centimeters,
      weightKg: 80 / .45359237 * MassUnit.pound.grams / 1000,
      activity: ActivityLevel.sedentary,
    );
    expect(TargetCalculator.resting(imperial, date), closeTo(1750, 1e-9));
  });

  test('TG-011 all expressions convert to signed weekly rates', () {
    final deadline = goal(GoalExpression.targetDate(78, date.plusDays(28)));
    expect(deadline.type, GoalType.lose);
    expect(deadline.requestedKgPerWeek, -.5);
    expect(deadline.targetKg, 78);
    expect(goal(GoalExpression.targetRate(78, .5)).requestedKgPerWeek, -.5);
    expect(goal(GoalExpression.weekly(-.5)).requestedKgPerWeek, -.5);
    expect(
      goal(GoalExpression.monthly(-2, LocalDate(2026, 2, 7)))
          .requestedKgPerWeek,
      -.5,
    );
    expect(
      goal(GoalExpression.monthly(-2, LocalDate(2024, 2, 1)))
          .requestedKgPerWeek,
      closeTo(-14 / 29, 1e-12),
    );
    expect(goal(GoalExpression.monthly(-2, date)).requestedKgPerWeek, -14 / 31);
    expect(
      goal(
        GoalExpression.targetRate(82, .25),
        type: GoalType.gain,
      ).requestedKgPerWeek,
      .25,
    );
    expect(
      goal(
        GoalExpression.targetDate(80, date.plusDays(1)),
        type: GoalType.maintain,
      ).requestedKgPerWeek,
      0,
    );
    expect(
      goal(
        GoalExpression.targetRate(80, 1),
        type: GoalType.maintain,
      ).requestedKgPerWeek,
      0,
    );
  });

  test('SF-010 SF-011 TG-013 floor and rate cap expose achievable rate', () {
    final result = TargetCalculator.calculate(
      profile: profile(),
      date: date,
      goal: goal(GoalExpression.targetRate(70, 2)),
    );
    expect(result.requestedKgPerWeek, -2);
    expect(result.cappedKgPerWeek, -.8);
    expect(result.kcal, 1750);
    expect(result.achievableKgPerWeek, closeTo(-350 * 7 / 7700, 1e-12));
    expect(result.projectedDate, date.plusDays(220));
    expect(result.warnings, {
      TargetWarning.lossRateCapped,
      TargetWarning.calorieFloorApplied,
    });
  });

  test('TG-011 completion rounds up and no deficit means no projection', () {
    final result = TargetCalculator.calculate(
      profile: profile(),
      date: date,
      goal: goal(GoalExpression.targetRate(81, .3), type: GoalType.gain),
    );
    expect(result.projectedDate, date.plusDays(24));
    expect(result.achievableKgPerWeek, closeTo(.3, 1e-12));
    final noDeficit = TargetCalculator.calculate(
      profile: profile(),
      date: date,
      goal: goal(GoalExpression.targetRate(70, .5)),
      manualKcal: 2100,
    );
    expect(noDeficit.projectedDate, isNull);
    final tiny = TargetCalculator.calculate(
      profile: profile(),
      date: date,
      goal: goal(GoalExpression.targetRate(81, 1e-10), type: GoalType.gain),
    );
    expect(tiny.projectedDate, isNull);
  });

  test(
    'SF-012 below-limit manual calories require explicit acknowledgement',
    () {
      for (final kcal in [1000.0, 1200.0]) {
        expect(
          () => TargetCalculator.calculate(
            profile: profile(),
            date: date,
            goal: goal(GoalExpression.weekly(-.5)),
            manualKcal: kcal,
          ),
          throwsArgumentError,
        );
      }
      final manual = TargetCalculator.calculate(
        profile: profile(),
        date: date,
        goal: goal(GoalExpression.weekly(-.5)),
        manualKcal: 1000,
        acknowledged: true,
      );
      expect(manual.kcal, 1000);
      expect(manual.manual, isTrue);
      expect(manual.acknowledged, isTrue);
      expect(
        manual.warnings,
        containsAll([
          TargetWarning.manualBelowFloor,
          TargetWarning.manualLossRateExceeded,
        ]),
      );
    },
  );

  test('TG-021 manual calories do not claim a generated floor adjustment', () {
    final result = TargetCalculator.calculate(
      profile: profile(),
      date: date,
      goal: goal(GoalExpression.weekly(-.5)),
      manualKcal: 2500,
    );
    expect(result.kcal, 2500);
    expect(result.warnings, isEmpty);
    expect(result.achievableKgPerWeek, closeTo(400 * 7 / 7700, 1e-12));
  });

  test(
    'TG-001 TG-011 malformed or contradictory inputs fail without values',
    () {
      for (final value in [double.nan, double.infinity, -1.0, 0.0, 1000001.0]) {
        expect(() => profile(weight: value), throwsArgumentError);
        expect(
          () => GoalExpression.targetDate(value, date),
          throwsArgumentError,
        );
        expect(() => GoalExpression.targetRate(70, value), throwsArgumentError);
      }
      for (final value in [double.nan, double.infinity, 1000001.0]) {
        expect(() => GoalExpression.weekly(value), throwsArgumentError);
        expect(() => GoalExpression.monthly(value, date), throwsArgumentError);
      }
      for (final year in [0, 10000]) {
        expect(
          () => TargetProfile(
            sex: FormulaSex.male,
            birthYear: year,
            heightCm: 180,
            weightKg: 80,
            activity: ActivityLevel.sedentary,
          ),
          throwsArgumentError,
        );
      }
      expect(
        () => goal(GoalExpression.targetDate(70, date)),
        throwsArgumentError,
      );
      expect(() => goal(GoalExpression.weekly(.5)), throwsArgumentError);
      expect(() => goal(GoalExpression.weekly(0)), throwsArgumentError);
      expect(
        () => ResolvedGoal.resolve(
          type: GoalType.lose,
          expression: GoalExpression.weekly(-1),
          currentKg: 0,
          date: date,
        ),
        throwsArgumentError,
      );
      final impossible = TargetProfile(
        sex: FormulaSex.female,
        birthYear: 1,
        heightCm: 1,
        weightKg: 1,
        activity: ActivityLevel.sedentary,
      );
      expect(
        () => TargetCalculator.calculate(
          profile: impossible,
          date: date,
          goal: goal(GoalExpression.weekly(-1)),
        ),
        throwsArgumentError,
      );
    },
  );

  test('TG-012 phases retain history and validate local writes', () {
    GoalPhase phase(String id, LocalDate start, {LocalDate? end}) => GoalPhase(
      id: id.isEmpty
          ? ''
          : '0199e3c2-5b1a-7000-8000-'
                '${id.codeUnitAt(0).toRadixString(16).padLeft(12, '0')}',
      name: 'Cut',
      start: start,
      end: end,
      type: GoalType.lose,
      expression: GoalExpression.weekly(-.5),
    );
    final first = phase('a', date, end: date.plusDays(3));
    final second = phase('b', date.plusDays(5));
    final history = GoalHistory([second, first]);
    expect(history.phases, [first, second]);
    expect(history.at(date), first);
    expect(history.at(date.plusDays(3)), first);
    expect(history.at(date.plusDays(4)), isNull);
    expect(history.at(date.plusDays(5)), second);
    expect(history.at(date.plusDays(-1)), isNull);
    expect(isUuidV7(first.id), isTrue);
    expect(first.name, 'Cut');
    expect(first.type, GoalType.lose);
    expect(first.expression, isA<WeeklyGoal>());
    expect(history.phases.clear, throwsUnsupportedError);
    expect(
      () => GoalHistory.validateForWrite([first, phase('b', date.plusDays(3))]),
      throwsArgumentError,
    );
    expect(
      () =>
          GoalHistory.validateForWrite([second, phase('c', date.plusDays(6))]),
      throwsArgumentError,
    );
    expect(
      () => GoalHistory.validateForWrite([first, phase('a', date.plusDays(5))]),
      throwsArgumentError,
    );
    expect(() => phase('', date), throwsArgumentError);
    expect(() => phase('x', date, end: date.plusDays(-1)), throwsArgumentError);
    expect(
      () => GoalPhase(
        id: 'x',
        name: '',
        start: date,
        type: GoalType.maintain,
        expression: GoalExpression.weekly(0),
      ),
      throwsArgumentError,
    );
  });
}
