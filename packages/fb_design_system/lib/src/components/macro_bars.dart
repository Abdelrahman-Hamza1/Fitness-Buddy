import 'package:fb_design_system/src/components/progress_bar.dart';
import 'package:fb_design_system/src/tokens/colors.dart';
import 'package:fb_design_system/src/tokens/spacing.dart';
import 'package:fb_design_system/src/tokens/typography.dart';
import 'package:material_ui/material_ui.dart';

/// The macro nutrients with a colour of their own (UX-042).
enum FbMacroKind {
  /// Protein.
  protein,

  /// Carbs.
  carbs,

  /// Fat.
  fat,

  /// Fibre: shown smaller than the other three.
  fiber,
}

/// One macro row: its amounts and the texts that go with them.
@immutable
class FbMacroValue {
  /// Creates a macro value. Without a [target] the row shows its text only,
  /// with no track (TG-054: carbs and fat in "calories and protein only").
  const new({
    required this.kind,
    required this.value,
    required this.label,
    required this.valueText,
    this.target,
  });

  /// Which macro (decides the colour).
  final FbMacroKind kind;

  /// The amount so far (geometry only).
  final double value;

  /// The target, or null for a macro with no target: then no track is drawn
  /// and [valueText] carries the amount alone ("96 g").
  final double? target;

  /// The macro's name, e.g. "Protein". Always shown next to the colour
  /// (UX-071).
  final String label;

  /// The formatted amounts, e.g. "82 / 140 g" or "12 g over".
  final String valueText;
}

/// Macro bars, one per [FbMacroValue] (HM-003). Each bar has its text label
/// right above it, so colour is never the only cue (UX-071). Past the target
/// a bar is full in the neutral over-target tone (SF-021). A macro without a
/// target is its label and text only.
class FbMacroBars extends StatelessWidget {
  /// Creates the bars.
  const new({required this.macros, super.key});

  /// The macros, in display order.
  final List<FbMacroValue> macros;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < macros.length; i++) ...[
        if (i > 0) const SizedBox(height: FbSpace.s3),
        _MacroBar(macro: macros[i]),
      ],
    ],
  );
}

class _MacroBar extends StatelessWidget {
  const new({required this.macro});

  final FbMacroValue macro;

  @override
  Widget build(BuildContext context) {
    final colors = context.fbColors;
    final scheme = Theme.of(context).colorScheme;
    final small = macro.kind == FbMacroKind.fiber;
    final color = switch (macro.kind) {
      FbMacroKind.protein => colors.protein,
      FbMacroKind.carbs => colors.carbs,
      FbMacroKind.fat => colors.fat,
      FbMacroKind.fiber => colors.fiber,
    };
    final labelStyle = (small ? FbType.caption : FbType.label).copyWith(
      color: scheme.onSurface,
    );
    final valueStyle = FbType.numeric(small ? FbType.caption : FbType.bodySmall)
        .copyWith(color: scheme.onSurfaceVariant);
    return Semantics(
      container: true,
      label: '${macro.label}, ${macro.valueText}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The amounts keep one line at the end ("82 / 140 g" never wraps);
          // at large text sizes they go under the label instead.
          if (MediaQuery.textScalerOf(context).scale(14) >= 14 * 1.4)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(macro.label, style: labelStyle),
                Text(
                  macro.valueText,
                  style: valueStyle,
                  textAlign: TextAlign.end,
                ),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(child: Text(macro.label, style: labelStyle)),
                const SizedBox(width: FbSpace.s2),
                Text(macro.valueText, style: valueStyle),
              ],
            ),
          if (macro.target case final target?) ...[
            const SizedBox(height: FbSpace.s1),
            FbBarTrack(
              value: macro.value,
              target: target,
              color: color,
              height: small ? 4 : 8,
            ),
          ],
        ],
      ),
    );
  }
}
