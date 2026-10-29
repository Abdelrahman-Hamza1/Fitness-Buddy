import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'targets_app_harness.dart';

void main() {
  test('PA3 SetupPreview reports goalUnresolvable for a deadline not after '
      'today and a target weight on the wrong side', () {
    for (final goal in [
      GoalInput(
        type: GoalType.lose,
        expression: GoalExpression.targetDate(75, today),
      ),
      GoalInput(
        type: GoalType.lose,
        expression: GoalExpression.targetDate(75, today.plusDays(-3)),
      ),
      GoalInput(
        type: GoalType.lose,
        expression: GoalExpression.targetRate(85, .5),
      ),
      GoalInput(
        type: GoalType.gain,
        expression: GoalExpression.targetDate(70, today.plusDays(60)),
      ),
    ]) {
      final preview = SetupPreview.of(setupInput(goal: goal), today);
      expect(preview.issue, SetupPreviewIssue.goalUnresolvable);
      expect(preview.calculation, isNull);
      expect(preview.dailyKcal, isNull);
      expect(preview.weeklyKcal, isNull);
      expect(preview.monthKg(today), isNull);
    }
  });

  test('TG-011 TG-021 SetupPreview gives the engine calculation, the first '
      'day macros and the month figure', () {
    final preview = SetupPreview.of(setupInput(), today);
    expect(preview.issue, isNull);
    expect(preview.dailyKcal, setupBase);
    expect(preview.weeklyKcal, setupBase * 7);
    expect(preview.calculation!.floorKcal, 1750);
    expect(preview.goal!.requestedKgPerWeek, -.5);
    // November 2026 has 30 days: −0.5 × 30 / 7.
    expect(
      preview.monthKg(LocalDate(2026, 11, 1)),
      closeTo(-.5 * 30 / 7, 1e-12),
    );
    // Default macros: protein 1.8 g/kg of the current weight.
    expect(preview.macros!.proteinGrams, closeTo(144, 1e-9));
    expect(preview.macros!.kcal, setupBase);

    // With a target weight the macros use it and a date is projected.
    final target = SetupPreview.of(
      setupInput(
        goal: GoalInput(
          type: GoalType.lose,
          expression: GoalExpression.targetRate(70, .5),
        ),
      ),
      today,
    );
    expect(target.macros!.proteinGrams, closeTo(126, 1e-9));
    expect(target.calculation!.projectedDate, isNotNull);
  });

  test('D15 SetupPreview reports invalidInput with the rule codes for '
      'out-of-range input', () {
    final profile = SetupPreview.of(
      setupInput(height: Length.centimeters(90), weight: 600),
      today,
    );
    expect(profile.issue, SetupPreviewIssue.invalidInput);
    expect(profile.violations, {
      TargetRuleViolation.height,
      TargetRuleViolation.weight,
    });
    final goal = SetupPreview.of(
      setupInput(
        goal: GoalInput(
          type: GoalType.lose,
          expression: GoalExpression.weekly(-2.5),
        ),
      ),
      today,
    );
    expect(goal.issue, SetupPreviewIssue.invalidInput);
    expect(goal.violations, {TargetRuleViolation.rate});
  });

  test('TG-002 SetupInput keeps typed units and converts lb and ft+in to kg '
      'and cm', () {
    final input = setupInput(
      height: Length.feetAndInches(6, 0),
      heightUnit: HeightInputUnit.feetInches,
      weight: 200,
      weightUnit: MassUnit.pound,
    );
    // Rounded as the first weigh-in stores it (A14, TD-090).
    expect(input.weightKg, 90.72);
    expect(input.profile.heightCm, closeTo(182.88, 1e-9));
    expect(input.profile.heightInputUnit, HeightInputUnit.feetInches);
    final maintain = GoalInput.maintain(weightInputUnit: MassUnit.pound);
    expect(maintain.type, GoalType.maintain);
    expect((maintain.expression as WeeklyGoal).kgPerWeek, 0);
    expect(maintain.weightInputUnit, MassUnit.pound);
  });
}
