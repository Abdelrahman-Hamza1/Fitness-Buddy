import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Theme;

/// A day's macro targets as label / amount rows (TG-050–055): protein,
/// carbs, fat, then fiber smaller. In "calories and protein only" carbs and
/// fat read "No target" (TG-054). Setup's last page and Me › Targets.
class MacroSummary extends StatelessWidget {
  /// Creates the rows for [macros].
  const new({required this.macros, super.key});

  /// The engine's targets for the day.
  final DailyMacros macros;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    String grams(double? g) => g == null
        ? l10n.targetsMacroNoTarget
        : l10n.targetsMacroGrams(DisplayRounding.macroTargetGrams(g));
    final colors = context.fbColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FbSpace.s2,
      children: [
        _Row(
          l10n.todayMacroProtein,
          grams(macros.proteinGrams),
          colors.protein,
        ),
        _Row(l10n.todayMacroCarbs, grams(macros.carbsGrams), colors.carbs),
        _Row(l10n.todayMacroFat, grams(macros.fatGrams), colors.fat),
        _Row(
          l10n.todayMacroFiber,
          grams(macros.fiberGrams),
          colors.fiber,
          small: true,
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const new(this.label, this.value, this.color, {this.small = false});

  final String label;
  final String value;

  /// The macro's own colour (UX-042), as a dot next to its name.
  final Color color;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = small ? FbType.bodySmall : FbType.body;
    final name = Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: const SizedBox.square(dimension: FbSpace.s2),
        ),
        const SizedBox(width: FbSpace.s2),
        Expanded(
          child: Text(label, style: base.copyWith(color: scheme.onSurface)),
        ),
      ],
    );
    final amount = Text(
      value,
      textAlign: TextAlign.end,
      style: FbType.numeric(base).copyWith(color: scheme.onSurfaceVariant),
    );
    // The amount keeps one line at the end; at large text sizes it goes
    // under the name instead.
    final large = MediaQuery.textScalerOf(context).scale(14) >= 14 * 1.4;
    return MergeSemantics(
      child: large
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [name, amount],
            )
          : Row(
              children: [
                Expanded(child: name),
                const SizedBox(width: FbSpace.s2),
                amount,
              ],
            ),
    );
  }
}
