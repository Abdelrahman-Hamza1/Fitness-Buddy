import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/approx_text.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

/// Calories (large) and the four macros of an amount (UX-045, A57 D13),
/// shared by the food sheet and the entry amount sheet.
///
/// Both lines are always there: while the amount is incomplete ([nutrients]
/// is null) they show dashes ("— kcal", "Protein — · …"), and a real zero
/// shows "0 kcal". Each line keeps the height of its widest value (an
/// invisible sample under it), so typing 248 → 2,475 or clearing the amount
/// never moves what sits below, at any text scale.
class NutritionSummary extends StatelessWidget {
  /// Creates the summary. [known] names the known macros (A62 D26): an
  /// unknown one shows "—", never 0.
  const new({
    required this.nutrients,
    this.known = EntryFood.allKnown,
    super.key,
  });

  /// The amount's nutrients, or null while the amount is incomplete.
  final Nutrients? nutrients;

  /// Which of protein, carbs, fat and fiber are known.
  final Set<NutrientField> known;

  /// Key of the calories line while the amount is incomplete.
  static const Key pendingKey = ValueKey('nutrition-pending');

  /// Key of the calories line with a number.
  static const Key kcalKey = ValueKey('nutrition-kcal');

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final n = nutrients;
    final kcalStyle = FbType.numeric(FbType.headline)
        .copyWith(color: scheme.onSurface);
    final macroStyle = FbType.numeric(FbType.bodySmall)
        .copyWith(color: scheme.onSurfaceVariant);
    String grams(NutrientField field, double value) =>
        known.contains(field) ? gramsText(l10n, value) : l10n.unknownValue;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Reserved(
          sample: l10n.foodSheetKcal(8888),
          style: kcalStyle,
          child: Text(
            n == null
                ? l10n.foodSheetKcalPending
                : l10n.foodSheetKcal(DisplayRounding.kcal(n.kcal)),
            key: n == null ? pendingKey : kcalKey,
            style: kcalStyle,
          ),
        ),
        _Reserved(
          // Up to about a kilogram of any macro; a larger amount may wrap
          // once more.
          sample: l10n.foodSheetMacros('888', '888', '888', '88'),
          style: macroStyle,
          child: Text(
            n == null
                ? l10n.foodSheetMacrosPending
                : l10n.foodSheetMacros(
                    grams(NutrientField.protein, n.protein),
                    grams(NutrientField.carbs, n.carbs),
                    grams(NutrientField.fat, n.fat),
                    grams(NutrientField.fiber, n.fiber),
                  ),
            style: macroStyle,
          ),
        ),
      ],
    );
  }
}

/// [child] over an invisible [sample] in the same [style]: the box is as
/// tall as the taller of the two, so a shorter value never shrinks it.
class _Reserved extends StatelessWidget {
  const new({required this.sample, required this.style, required this.child});

  final String sample;
  final TextStyle style;
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      ExcludeSemantics(
        child: Opacity(opacity: 0, child: Text(sample, style: style)),
      ),
      child,
    ],
  );
}
