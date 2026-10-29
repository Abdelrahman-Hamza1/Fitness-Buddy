import 'package:alchemist/alchemist.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../today/presentation/support/today_support.dart' show phoneApp;
import 'target_forms_support.dart';

/// One golden per component: light and dark at text scale 1.0 and 2.0, on a
/// 360 dp phone (UX-070).
Future<void> _golden(
  String description,
  String file,
  Widget Function() screen, {
  double height = 800,
}) => goldenTest(
  description,
  fileName: file,
  builder: () => GoldenTestGroup(
    columns: 4,
    children: [
      for (final scale in const [1.0, 2.0])
        for (final (label, brightness) in const [
          ('light', Brightness.light),
          ('dark', Brightness.dark),
        ])
          GoldenTestScenario(
            name: '$label, x$scale',
            child: SizedBox(
              width: 360,
              height: height,
              child: phoneApp(
                formScreen(screen()),
                brightness: brightness,
                textScale: scale,
              ),
            ),
          ),
    ],
  ),
);

Future<void> main() async {
  await _golden(
    'TG-001 TG-002 UX-070 profile fields: sex, birth year, ft+in height with '
        'its unit choice, lb weight, and cm/kg range messages',
    'targets_profile_fields',
    () => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        SexField(selected: FormulaSex.male, onSelected: (_) {}),
        BirthYearField(text: '1990', today: formToday, onChanged: (_) {}),
        HeightField(
          draft: const HeightDraft(
            unit: HeightInputUnit.feetInches,
            feet: '5',
            inches: '11',
          ),
          showUnitChoice: true,
          onChanged: (_) {},
        ),
        BodyWeightField(
          draft: const BodyWeightDraft(unit: MassUnit.pound, text: '200'),
          onChanged: (_) {},
        ),
        HeightField(
          draft: const HeightDraft(cm: '300'),
          showError: true,
          onChanged: (_) {},
        ),
        BodyWeightField(
          draft: const BodyWeightDraft(text: '600'),
          showError: true,
          onChanged: (_) {},
        ),
      ],
    ),
    height: 1400,
  );

  await _golden(
    'TG-001 UX-070 activity options with plain descriptions, one chosen',
    'targets_activity_options',
    () => ActivityOptions(selected: ActivityLevel.moderate, onSelected: (_) {}),
    height: 900,
  );

  await _golden(
    'TG-011 TG-013 UX-070 goal form: lose per week above 1% with the '
        'projection and the cap message',
    'targets_goal_form',
    () {
      final draft = loseDraft().copyWith(rate: '1.2');
      return GoalForm(
        draft: draft,
        onChanged: (_) {},
        today: formToday,
        calculation: calculationFor(draft),
      );
    },
    height: 1400,
  );

  await _golden(
    'TG-011 PA3 UX-070 goal form: target weight by a date that has passed '
        'shows the goal message instead of numbers',
    'targets_goal_form_problem',
    () => GoalForm(
      draft: loseDraft()
          .withKind(GoalExpressionKind.targetDate)
          .copyWith(targetWeight: '80', targetDate: formToday),
      onChanged: (_) {},
      today: formToday,
      problem: GoalProblem.deadline,
    ),
    height: 1400,
  );

  await _golden(
    'TG-021 SF-010 UX-070 target explanation with the floor line and the '
        'macro summary',
    'targets_explanation',
    () {
      final calc = calculationFor(loseDraft());
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 24,
        children: [
          TargetExplanationView(
            calculation: calc,
            activity: ActivityLevel.moderate,
            units: UnitSystem.metric,
            weeklyKcal: calc.kcal * 7,
          ),
          TargetExplanationView(
            calculation: floorCalculation(),
            activity: ActivityLevel.sedentary,
            units: UnitSystem.metric,
          ),
          MacroSummary(
            macros: MacroPlan.calculate(
              baseKcal: calc.kcal,
              weightKg: 90,
              settings: MacroSettings(caloriesProteinOnly: true),
            ).forDay(calc.kcal),
          ),
        ],
      );
    },
    height: 2300,
  );
}
