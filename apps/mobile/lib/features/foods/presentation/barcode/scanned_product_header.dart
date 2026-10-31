import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/amount_text.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/foods/application/barcode_lookup.dart';
import 'package:fb_mobile/features/foods/application/food_choice.dart';
import 'package:fb_mobile/features/foods/presentation/barcode/halal_note.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The product part of the food sheet for a scan (FD-030, A28a D8): the
/// brand, the values of one serving (per 100 is the sheet's own block), the
/// halal warning when the setting is on (FD-081), the check-the-label note
/// (B22), the fiber note and the
/// Open Food Facts credit (ODbL, `07` §3).
class ScannedProductHeader extends ConsumerWidget {
  /// Creates the header.
  const new({required this.product, required this.food, super.key});

  /// What the scan found.
  final ScannedProduct product;

  /// The food the sheet logs (for the per-serving values).
  final FoodChoice food;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final muted = FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant);
    final halal = ref.watch(halalProvider).value ?? true;
    final warning = halal ? halalMessage(l10n, product.halal) : null;
    final system = ref.watch(unitSystemProvider).value ?? UnitSystem.metric;
    final perServing = _perServing(l10n, system);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: FbSpace.s1,
      children: [
        if (product.brand case final brand?)
          Text(l10n.scannedBrand(brand), style: muted),
        if (perServing != null) Text(perServing, style: muted),
        if (warning != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: FbSpace.s1),
            child: FbInlineBanner(
              kind: FbInlineBannerKind.info,
              message: warning,
            ),
          ),
        if (product.checkLabel) Text(l10n.scannedCheckLabel, style: muted),
        if (product.fiberMissing) Text(l10n.scannedFiberMissing, style: muted),
        if (product.fromOff) Text(l10n.offAttribution, style: muted),
      ],
    );
  }

  /// "1 serving (30 g): 150 kcal · 3 g protein · …", when the food has one.
  String? _perServing(AppLocalizations l10n, UnitSystem system) {
    final serving = food.measures.servingUnits['serving'];
    if (serving == null) return null;
    final factor = serving.amount / 100;
    final n = food.per100;
    String grams(double v) =>
        l10n.foodNutrientGrams(DisplayRounding.nutrientGrams(v * factor));
    return l10n.scannedPerServing(
      l10n.scannedServing(
        servingText(
          l10n,
          input: Quantity(serving.amount, food.basis.unitCode),
          basis: food.basis,
          system: system,
        ),
      ),
      DisplayRounding.kcal(n.kcal * factor),
      grams(n.protein),
      grams(n.carbs),
      grams(n.fat),
    );
  }
}
