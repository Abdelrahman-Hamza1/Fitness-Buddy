import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/targets/presentation/goal_form.dart'
    show capMessage;
import 'package:fb_mobile/features/targets/presentation/targets_text.dart';
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Theme;

/// The plain-language explanation of a generated target (TG-021, D16), from
/// the A12 engine's typed fields only: resting energy, the activity factor,
/// the goal adjustment (dropped with [showGoal] false, e.g. for a goal that
/// can't be resolved, PA3), the cap and floor lines only when they applied
/// (SF-010/011), then the daily and, when known, weekly target.
///
/// Used by setup's last page (WP6) and Me › Targets (A13c), which adds the
/// manual-target lines itself. Weights follow [units] (TG-002).
class TargetExplanationView extends StatelessWidget {
  /// Creates the explanation of [calculation].
  const new({
    required this.calculation,
    required this.activity,
    required this.units,
    this.weeklyKcal,
    this.showGoal = true,
    this.defaults = const TargetDefaults(),
    super.key,
  });

  /// The engine's generated calculation.
  final TargetCalculation calculation;

  /// The profile's activity level (named in the activity line).
  final ActivityLevel activity;

  /// The unit setting: weights in kg or lb.
  final UnitSystem units;

  /// The weekly budget, or null to show the daily target alone.
  final double? weeklyKcal;

  /// Whether the goal line is shown.
  final bool showGoal;

  /// The engine defaults (kcal per kg).
  final TargetDefaults defaults;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final calc = calculation;
    final unit = units.bodyMass;
    final style = FbType.body.copyWith(color: scheme.onSurface);
    const kcal = DisplayRounding.kcal;
    final lines = [
      l10n.targetsExplainResting(kcal(calc.restingKcal)),
      l10n.targetsExplainActivity(
        activityInline(l10n, activity),
        calc.activityFactor,
        kcal(calc.expenditureKcal),
      ),
      if (showGoal) _goalLine(l10n, unit),
      if (calc.warnings.contains(TargetWarning.lossRateCapped))
        capMessage(l10n, calc, unit),
      if (calc.warnings.contains(TargetWarning.calorieFloorApplied))
        l10n.targetsExplainFloor(kcal(calc.floorKcal)),
      if (weeklyKcal case final weekly?)
        l10n.targetsExplainTarget(kcal(calc.kcal), kcal(weekly))
      else
        l10n.targetsExplainTargetDaily(kcal(calc.kcal)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FbSpace.s2,
      children: [for (final line in lines) Text(line, style: style)],
    );
  }

  String _goalLine(AppLocalizations l10n, MassUnit unit) {
    final rate = calculation.cappedKgPerWeek;
    if (rate == 0) return l10n.targetsExplainGoalMaintain;
    final perDay = DisplayRounding.kcal(rate.abs() * defaults.kcalPerKg / 7);
    // About 7,700 kcal per kg, or about 3,490 kcal per lb (nearest 10).
    final perUnit =
        (Mass.of(1, unit).kilograms * defaults.kcalPerKg / 10).round() * 10;
    final rateWords = rateText(l10n, rate.abs(), unit);
    final unitWord = massUnitLabel(l10n, unit);
    return rate < 0
        ? l10n.targetsExplainGoalLose(rateWords, perDay, perUnit, unitWord)
        : l10n.targetsExplainGoalGain(rateWords, perDay, perUnit, unitWord);
  }
}
