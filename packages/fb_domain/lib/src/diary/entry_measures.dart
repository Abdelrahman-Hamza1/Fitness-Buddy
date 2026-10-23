import 'package:fb_domain/src/diary/diary_entry.dart';
import 'package:fb_domain/src/units/food_measures.dart';

/// Measures retained by a logged snapshot, independent of the catalog (PA3).
abstract final class EntryMeasures {
  /// Restores food-specific units even when they shadow a generic cup.
  static FoodMeasures of(DiaryEntry entry) => FoodMeasures(
    basis: entry.amount.basis,
    servingUnits: [?reconstructedServingOf(entry.amount)],
  );
}

/// Resolves edits using the entry's original portion size.
abstract final class EntryAmounts {
  /// A positive canonical amount, or null for zero/unresolvable input.
  static EntryAmount? resolve(DiaryEntry entry, Quantity input) {
    if (input.amount <= 0) return null;
    final resolved = EntryMeasures.of(entry).resolve(input);
    if (resolved is! Resolved || resolved.amount <= 0) return null;
    return EntryAmount(
      input: input,
      amount: resolved.amount,
      basis: resolved.basis,
    );
  }
}

/// Reconstructs a serving when generic resolution loses the logged size.
ServingUnit? reconstructedServingOf(EntryAmount amount) {
  final input = amount.input;
  if (input.amount <= 0 || amount.amount <= 0) return null;
  final generic = FoodMeasures(basis: amount.basis).resolve(input);
  if (generic is Resolved && (generic.amount - amount.amount).abs() <= 0.005) {
    return null;
  }
  final size = amount.amount / input.amount;
  if (!size.isFinite || size <= 0) return null;
  return amount.basis == NutrientBasis.per100g
      ? ServingUnit.grams(input.unitCode, size)
      : ServingUnit.milliliters(input.unitCode, size);
}
