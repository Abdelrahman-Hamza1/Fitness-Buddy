import 'package:fb_domain/src/diary/diary_entry.dart';
import 'package:fb_domain/src/food/personal_food.dart';

/// A bounded merge cannot discard excess user data silently.
final class MergeTooMany implements PersonalFoodMergeResult {
  /// No private content.
  const new();
}

/// Pure union rules for FD-073; the app injects fb_text.normalizeKey.
abstract final class PersonalFoodMerge {
  /// The survivor's values win; the duplicate contributes missing metadata.
  /// Returns [PersonalFoodDraft] or [MergeTooMany].
  static PersonalFoodMergeResult combine(
    PersonalFood survivor,
    PersonalFood merged, {
    required String Function(String) keyOf,
  }) {
    final a = survivor.draft;
    final b = merged.draft;
    final ar = a.names.ar ?? b.names.ar;
    final seen = {
      keyOf(a.names.en),
      if (ar != null) keyOf(ar),
      ...a.aliases.map(keyOf),
    };
    // Existing aliases are user-owned spelling/order, even when redundant.
    final aliases = [...a.aliases];
    for (final name in [b.names.en, ?b.names.ar, ...b.aliases]) {
      if (seen.add(keyOf(name))) aliases.add(name);
    }
    final barcodes = {...a.barcodes, ...b.barcodes}.toList();
    final units = {for (final s in a.servings) s.unit};
    final servings = [
      ...a.servings,
      for (final s in b.servings)
        if (units.add(s.unit)) s,
    ];
    if (aliases.length > PersonalFoodBounds.aliases ||
        barcodes.length > PersonalFoodBounds.barcodes ||
        servings.length > PersonalFoodBounds.servings) {
      return const MergeTooMany();
    }
    return PersonalFoodDraft(
      names: FoodNames(a.names.en, ar: ar),
      aliases: aliases,
      brand: a.brand ?? b.brand,
      barcodes: barcodes,
      state: a.state,
      basis: a.basis,
      per100: a.per100,
      servings: servings,
      entryServing: a.entryServing,
      createdFrom: a.createdFrom,
    );
  }
}
