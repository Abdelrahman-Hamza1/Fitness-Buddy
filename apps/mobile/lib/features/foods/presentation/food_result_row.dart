import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart'
    show FoodNameLines, HalalCheck, UnitSystem;
import 'package:fb_mobile/core/l10n/amount_text.dart';
import 'package:fb_mobile/core/l10n/domain_labels.dart' show fbSourceOf;
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/foods/application/food_search_row.dart';
import 'package:fb_mobile/features/foods/presentation/barcode/halal_note.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_text/fb_text.dart' show normalizeKey;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// One search result (FD-020, FD-023, D-091): the source badge first, the
/// name in the "Food names" language, then under it "Matched …" when the
/// query hit an alias, the Arabic name in "Both" and the serving the
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
    final names = watchFoodNames(ref, row.choice.names);
    final matched = matchedName(row, names);
    final parts = [
      if (matched != null) l10n.foodMatched(isolateName(matched)),
      if (names.secondary case final second?) isolateName(second),
    ];
    final base = parts.fold(
      serving,
      (rest, part) => l10n.foodResultSubtitle(part, rest),
    );
    // FD-081: names only (catalog and personal foods carry no ingredients).
    final halal = (ref.watch(halalProvider).value ?? true)
        ? halalMessage(l10n, HalalCheck.check(name: row.nameEn, nameAr: ar))
        : null;
    return FbListRow(
      title: names.primary,
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

/// What "Matched …" names for [row] shown as [names] (D-091, sketch
/// `FnSearch`), or null: an alias or spelling the query hit, or the other
/// language's name when only one language is shown.
String? matchedName(FoodSearchRow row, FoodNameLines names) {
  final shown = {
    normalizeKey(names.primary),
    if (names.secondary case final second?) normalizeKey(second),
  };
  final key = row.matchedKey;
  if (key == null || shown.contains(key)) return null;
  final food = row.choice.names;
  // The other language's name, as written.
  if (key == normalizeKey(food.en)) return food.en;
  if (food.ar case final ar? when key == normalizeKey(ar)) return ar;
  // Another display name (a dish's own name) isn't worth a line.
  if (row.matchedDisplay) return null;
  // A personal food's alias as the user typed it.
  for (final typed in row.choice.personalFood?.aliases ?? const <String>[]) {
    if (normalizeKey(typed) == key) return typed;
  }
  return key;
}
