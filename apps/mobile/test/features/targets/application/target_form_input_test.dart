import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:flutter_test/flutter_test.dart';

final LocalDate _today = LocalDate(2026, 10, 29);

void main() {
  group('typed numbers', () {
    test('D15 a birth year gives an age of 18–100 on the date; a decimal is '
        'not a year', () {
      expect(readBirthYear('1990', _today).value, 1990);
      expect(readBirthYear('2008', _today).value, 2008);
      expect(readBirthYear('1926', _today).value, 1926);
      expect(readBirthYear('2009', _today).error, TypedFieldError.outOfRange);
      expect(readBirthYear('1925', _today).error, TypedFieldError.outOfRange);
      expect(readBirthYear('1990.5', _today).error, TypedFieldError.notANumber);
      expect(readBirthYear('', _today).error, TypedFieldError.empty);
    });

    test('TG-002 LC-011 a height reads in cm or ft+in within 100–250 cm; '
        'inches under 12; the other unit keeps its own text', () {
      const cm = HeightDraft(cm: '180');
      expect(cm.read().value!.centimeters, 180);
      final ftIn = cm
          .withUnit(HeightInputUnit.feetInches)
          .copyWith(feet: '5', inches: '11');
      expect(ftIn.read().value!.centimeters, closeTo(180.34, 1e-9));
      expect(ftIn.cm, '180');
      expect(ftIn.withUnit(HeightInputUnit.centimeter).read().value, isNotNull);
      expect(
        ftIn.copyWith(inches: '').read().value!.centimeters,
        closeTo(152.4, 1e-9),
      );
      expect(
        ftIn.copyWith(inches: '12').read().error,
        TypedFieldError.outOfRange,
      );
      expect(
        const HeightDraft(cm: '99.9').read().error,
        TypedFieldError.outOfRange,
      );
      expect(const HeightDraft(cm: '250').read().value!.centimeters, 250);
      expect(
        const HeightDraft(unit: HeightInputUnit.feetInches).read().error,
        TypedFieldError.empty,
      );
    });

    test('TG-002 WB-003 a body weight reads by the weigh-in rule (20–500 kg '
        'after conversion); a unit switch relabels the number', () {
      const kg = BodyWeightDraft(text: '90');
      expect(kg.read().value, 90);
      final lb = kg.withUnit(MassUnit.pound);
      expect(lb.text, '90');
      // Rounded as A14 stores the weigh-in (TD-090).
      expect(lb.read().value, 40.82);
      expect(
        const BodyWeightDraft(text: '501').read().error,
        TypedFieldError.outOfRange,
      );
      expect(
        const BodyWeightDraft(unit: MassUnit.pound, text: '44').read().error,
        TypedFieldError.outOfRange,
      );
      for (final (value, unit) in [
        (20.0, MassUnit.kilogram),
        (500.0, MassUnit.kilogram),
        (44.1, MassUnit.pound),
        (75.3, MassUnit.pound),
      ]) {
        final read = BodyWeightDraft(unit: unit, text: '$value').read();
        expect(
          WeighInInput(value, unit).validate(),
          isNull,
          reason: '$value ${unit.code}',
        );
        expect(read.value, WeighInInput(value, unit).kg);
      }
    });
  });

  group('goal draft', () {
    test('D9 choosing lose prefills 0.5 kg a week and gain 0.25 kg, in the '
        'display unit; a typed amount is kept', () {
      final lose = const GoalDraft().withType(GoalType.lose);
      expect(lose.rate, '0.5');
      expect(lose.withType(GoalType.gain).rate, '0.25');
      expect(
        const GoalDraft(unit: MassUnit.pound).withType(GoalType.lose).rate,
        '1.1',
      );
      expect(lose.withUnit(MassUnit.pound).rate, '1.1');
      final typed = lose.copyWith(rate: '0.7');
      expect(typed.withType(GoalType.gain).rate, '0.7');
      expect(typed.withUnit(MassUnit.pound).rate, '0.7');
    });

    test('TG-010 TG-011 each expression reads to a signed GoalInput in '
        'canonical kg; this month is the current calendar month', () {
      final lose = const GoalDraft().withType(GoalType.lose);
      final weekly = lose.read(_today).input!;
      expect(weekly.type, GoalType.lose);
      expect((weekly.expression as WeeklyGoal).kgPerWeek, -.5);

      final monthly =
          lose
                  .withKind(GoalExpressionKind.monthly)
                  .copyWith(month: '2')
                  .read(_today)
                  .input!
                  .expression
              as MonthlyGoal;
      expect(monthly.kg, -2);
      expect(monthly.month, LocalDate(2026, 10, 1));

      final byDate =
          lose
                  .withKind(GoalExpressionKind.targetDate)
                  .copyWith(
                    targetWeight: '80',
                    targetDate: LocalDate(2027, 3, 1),
                  )
                  .read(_today)
                  .input!
                  .expression
              as TargetDateGoal;
      expect(byDate.targetKg, 80);
      expect(byDate.date, LocalDate(2027, 3, 1));

      final paced = const GoalDraft(unit: MassUnit.pound)
          .withType(GoalType.gain)
          .withKind(GoalExpressionKind.targetRate)
          .copyWith(targetWeight: '200', pace: '1')
          .read(_today)
          .input!;
      final rate = paced.expression as TargetRateGoal;
      expect(rate.targetKg, closeTo(90.72, .01));
      expect(rate.kgPerWeek, closeTo(.4536, .0001));
      expect(paced.weightInputUnit, MassUnit.pound);

      final maintain = const GoalDraft()
          .withType(GoalType.maintain)
          .read(_today)
          .input!;
      expect((maintain.expression as WeeklyGoal).kgPerWeek, 0);
    });

    test('D15 goal fields: no type, a zero or too-large amount, a missing '
        'or too-far date are field errors, never a GoalInput', () {
      expect(const GoalDraft().read(_today).errors, {
        GoalField.type: TypedFieldError.empty,
      });
      final lose = const GoalDraft().withType(GoalType.lose);
      for (final (text, error) in [
        ('0', TypedFieldError.outOfRange),
        ('2.1', TypedFieldError.outOfRange),
        ('', TypedFieldError.empty),
      ]) {
        final read = lose.copyWith(rate: text).read(_today);
        expect(read.input, isNull);
        expect(read.errors, {GoalField.rate: error});
      }
      expect(lose.copyWith(rate: '2').read(_today).input, isNotNull);
      expect(
        lose
            .withKind(GoalExpressionKind.monthly)
            .copyWith(month: '8.5')
            .read(_today)
            .errors,
        {GoalField.month: TypedFieldError.outOfRange},
      );
      final byDate = lose.withKind(GoalExpressionKind.targetDate);
      expect(byDate.read(_today).errors, {
        GoalField.targetWeight: TypedFieldError.empty,
        GoalField.targetDate: TypedFieldError.empty,
      });
      expect(
        byDate
            .copyWith(targetWeight: '80', targetDate: LocalDate(2031, 10, 30))
            .read(_today)
            .errors,
        {GoalField.targetDate: TypedFieldError.outOfRange},
      );
      // A date not after today reads; resolving it is GoalProblem's job.
      expect(
        byDate
            .copyWith(targetWeight: '80', targetDate: _today)
            .read(_today)
            .input,
        isNotNull,
      );
    });

    test('PA3 GoalProblem names a deadline not after today and a target on '
        'the wrong side; a resolvable goal has none', () {
      GoalProblem? problem(GoalType type, GoalExpression e) => GoalProblem.of(
        GoalInput(type: type, expression: e),
        currentKg: 90,
        today: _today,
      );
      expect(
        problem(GoalType.lose, GoalExpression.targetDate(80, _today)),
        GoalProblem.deadline,
      );
      expect(
        problem(GoalType.lose, GoalExpression.targetRate(95, .5)),
        GoalProblem.targetNotBelow,
      );
      expect(
        problem(GoalType.gain, GoalExpression.targetRate(85, .5)),
        GoalProblem.targetNotAbove,
      );
      expect(
        problem(GoalType.lose, GoalExpression.targetRate(90, .5)),
        GoalProblem.targetNotBelow,
      );
      expect(problem(GoalType.lose, GoalExpression.weekly(-.5)), isNull);
      expect(problem(GoalType.maintain, GoalExpression.weekly(0)), isNull);
    });

    test('PA14 drafts and reads show no typed values in toString', () {
      final draft = const GoalDraft()
          .withType(GoalType.lose)
          .copyWith(rate: '0.77', targetWeight: '81.5');
      for (final text in [
        '$draft',
        '${draft.read(_today)}',
        '${const HeightDraft(cm: '181')}',
        '${const BodyWeightDraft(text: '93.4')}',
      ]) {
        expect(text, isNot(matches(RegExp(r'\d'))), reason: text);
      }
    });
  });
}
