import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart' show HalalCheck, UnitSystem;
import 'package:fb_mobile/core/l10n/amount_text.dart';
import 'package:fb_mobile/core/l10n/domain_labels.dart' show fbSourceOf;
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/foods/application/food_search_row.dart';
import 'package:fb_mobile/features/foods/presentation/barcode/halal_note.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// One search result (FD-020, FD-023): the source badge first, the English
/// name, then under it the Arabic one when there is one and the serving the
/// calories are for ("خبز عربي · 1 loaf"), and the calories of that serving
/// at the end. The tile keeps one line for the calories at every text size,
/// so the serving sits with the names. With the Halal setting on, a name
/// that suggests pork, alcohol or gelatin adds the halal note (FD-081).
class FoodResultRow extends ConsumerWidget {
  /// Creates the row.
  const new({required this.row, required this.onTap, super.key});

  /// The result to show.
  final FoodSearchRow row;

  /// Called when the row is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final portion = row.defaultPortion;
    final serving = servingText(
      l10n,
      input: portion,
      basis: row.choice.basis,
      system: ref.watch(unitSystemProvider).value ?? UnitSystem.metric,
      serving: row.choice.measures.servingUnits[portion.unitCode],
    );
    final ar = row.nameAr;
    final base = ar == null ? serving : l10n.foodResultSubtitle(ar, serving);
    // FD-081: names only (catalog and personal foods carry no ingredients).
    final halal = (ref.watch(halalProvider).value ?? true)
        ? halalMessage(l10n, HalalCheck.check(name: row.nameEn, nameAr: ar))
        : null;
    return FbListRow(
      title: row.nameEn,
      subtitle: halal == null
          ? base
          : l10n.foodResultHalalSubtitle(base, halal),
      leading: FbSourceBadge(source: fbSourceOf(row.source)),
      trailing: Text(
        l10n.foodResultKcal(row.kcalForDefault.round()),
        style: FbType.numeric(FbType.body),
      ),
      onTap: onTap,
    );
  }
}
