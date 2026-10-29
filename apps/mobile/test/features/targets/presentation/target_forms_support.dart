import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:material_ui/material_ui.dart';

/// The date the form tests run on (a Thursday in October).
final LocalDate formToday = LocalDate(2026, 10, 29);

/// The profile of the form tests: male, born 1990, 180 cm, 90 kg, moderate.
/// Resting energy 1,850 kcal, expenditure 2,867.5 kcal, floor 1,850 kcal.
TargetProfile formProfile() => TargetProfile(
  sex: FormulaSex.male,
  birthYear: 1990,
  heightCm: 180,
  weightKg: 90,
  activity: ActivityLevel.moderate,
);

/// A lose goal at the default 0.5 kg a week.
GoalDraft loseDraft() => const GoalDraft().withType(GoalType.lose);

/// The engine's calculation for [draft] at [formProfile] on [formToday].
TargetCalculation calculationFor(GoalDraft draft) {
  final input = draft.read(formToday).input!;
  return TargetCalculator.calculate(
    profile: formProfile(),
    goal: ResolvedGoal.resolve(
      type: input.type,
      expression: input.expression,
      currentKg: 90,
      date: formToday,
    ),
    date: formToday,
  );
}

/// A generated target raised to the floor: female, born 1960, 155 cm, 50 kg,
/// sedentary, losing 0.5 kg a week (floor 1,200 kcal).
TargetCalculation floorCalculation() => TargetCalculator.calculate(
  profile: TargetProfile(
    sex: FormulaSex.female,
    birthYear: 1960,
    heightCm: 155,
    weightKg: 50,
    activity: ActivityLevel.sedentary,
  ),
  goal: ResolvedGoal.resolve(
    type: GoalType.lose,
    expression: GoalExpression.weekly(-.5),
    currentKg: 50,
    date: formToday,
  ),
  date: formToday,
);

/// [child] as a scrolling form screen with the page padding.
Widget formScreen(Widget child) => Scaffold(
  body: SingleChildScrollView(
    padding: const EdgeInsetsDirectional.all(FbSpace.s4),
    child: child,
  ),
);
