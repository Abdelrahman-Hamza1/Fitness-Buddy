import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/features/diary/data/diary_mappers.dart';

/// The food columns an entry and a saved-meal item share (A06 D3-D5), as one
/// value: built from what an op logs ([FoodColumns.of]) or copied from a
/// stored entry ([FoodColumns.fromEntry]), and written as either row. Holds
/// user content: no `toString`.
final class FoodColumns {
  const new _({
    required this.foodKind,
    required this.editedByUser,
    required this.foodId,
    required this.foodVersion,
    required this.nameEn,
    required this.nameAr,
    required this.inputAmount,
    required this.inputUnit,
    required this.amount,
    required this.amountBasis,
    required this.per100,
    required this.snapshot,
    required this.source,
    required this.isEstimate,
    required this.estimateRangeJson,
    required this.assumptionsJson,
    required this.userEstimate,
    required this.known,
    this.rawPer100ExtrasJson,
    this.rawExtrasJson,
  });

  /// [food] logged as [amount]: the snapshot is computed from the per-100
  /// values and the amount at storage precision (A06 D4, FD-073).
  factory of(EntryFood food, EntryAmount amount) {
    final computed = const NutritionCalculator().forAmount(
      per100: food.per100,
      amount: amount.amount,
      basis: amount.basis,
    );
    final provenance = food.provenance;
    // W3 (A62 D27): an unknown nutrient is 0 in the snapshot too. EntryFood
    // already holds it for per-100, so this only guards a future change.
    for (final field in EntryFood.allKnown) {
      if (!food.known.contains(field) &&
          computed.nutrients.valueOf(field) != 0) {
        throw ArgumentError('an unknown nutrient is stored as 0 (W3)');
      }
    }
    return FoodColumns._(
      userEstimate: food.userEstimate,
      known: food.known,
      editedByUser: food.editedByUser,
      foodKind: food.ref.kind.code,
      foodId: food.ref.id,
      foodVersion: food.ref.version,
      nameEn: food.names.en,
      nameAr: food.names.ar,
      inputAmount: amount.input.amount,
      inputUnit: amount.input.unitCode,
      amount: computed.amount,
      amountBasis: amount.basis.unitCode,
      per100: food.per100,
      snapshot: computed.nutrients,
      source: provenance.source.code,
      isEstimate: provenance.isEstimate,
      estimateRangeJson: provenance.range == null
          ? null
          : jsonEncode({
              'lowKcal': provenance.range!.lowKcal,
              'highKcal': provenance.range!.highKcal,
            }),
      assumptionsJson: provenance.assumptions.isEmpty
          ? null
          : jsonEncode(provenance.assumptions),
    );
  }

  /// The columns of the stored [row], unchanged.
  factory fromEntry(DiaryEntryRow row) => FoodColumns._(
    userEstimate: row.userEstimate,
    known: knownOf(
      protein: row.proteinKnown,
      carbs: row.carbsKnown,
      fat: row.fatKnown,
      fiber: row.fiberKnown,
    ),
    editedByUser: row.editedByUser,
    foodKind: row.foodKind,
    foodId: row.foodId,
    foodVersion: row.foodVersion,
    nameEn: row.nameEn,
    nameAr: row.nameAr,
    inputAmount: row.inputAmount,
    inputUnit: row.inputUnit,
    amount: row.amount,
    amountBasis: row.amountBasis,
    per100: nutrientsOf(
      kcal: row.per100Kcal,
      proteinG: row.per100ProteinG,
      carbsG: row.per100CarbsG,
      fatG: row.per100FatG,
      fiberG: row.per100FiberG,
      extrasJson: row.per100ExtrasJson,
    ),
    snapshot: nutrientsOf(
      kcal: row.kcal,
      proteinG: row.proteinG,
      carbsG: row.carbsG,
      fatG: row.fatG,
      fiberG: row.fiberG,
      extrasJson: row.extrasJson,
    ),
    source: row.source,
    isEstimate: row.isEstimate,
    estimateRangeJson: row.estimateRangeJson,
    assumptionsJson: row.assumptionsJson,
  );

  /// Copies saved snapshots without recalculation or JSON rewriting (DY-031).
  factory fromSavedItem(SavedMealItemRow row) => FoodColumns._(
    rawPer100ExtrasJson: row.per100ExtrasJson,
    rawExtrasJson: row.extrasJson,
    userEstimate: row.userEstimate,
    known: knownOf(
      protein: row.proteinKnown,
      carbs: row.carbsKnown,
      fat: row.fatKnown,
      fiber: row.fiberKnown,
    ),
    editedByUser: row.editedByUser,
    foodKind: row.foodKind,
    foodId: row.foodId,
    foodVersion: row.foodVersion,
    nameEn: row.nameEn,
    nameAr: row.nameAr,
    inputAmount: row.inputAmount,
    inputUnit: row.inputUnit,
    amount: row.amount,
    amountBasis: row.amountBasis,
    per100: nutrientsOf(
      kcal: row.per100Kcal,
      proteinG: row.per100ProteinG,
      carbsG: row.per100CarbsG,
      fatG: row.per100FatG,
      fiberG: row.per100FiberG,
      extrasJson: row.per100ExtrasJson,
    ),
    snapshot: nutrientsOf(
      kcal: row.kcal,
      proteinG: row.proteinG,
      carbsG: row.carbsG,
      fatG: row.fatG,
      fiberG: row.fiberG,
      extrasJson: row.extrasJson,
    ),
    source: row.source,
    isEstimate: row.isEstimate,
    estimateRangeJson: row.estimateRangeJson,
    assumptionsJson: row.assumptionsJson,
  );

  /// An update of an entry row to a new [amount] of the food with [per100]
  /// values: the input, the canonical amount and the snapshot, recomputed
  /// from the per-100 values, never by rescaling the old snapshot (A06 D4).
  static DiaryEntriesCompanion amountChanges(
    Nutrients per100,
    EntryAmount amount,
  ) {
    final computed = const NutritionCalculator().forAmount(
      per100: per100,
      amount: amount.amount,
      basis: amount.basis,
    );
    final snapshot = computed.nutrients;
    return DiaryEntriesCompanion(
      inputAmount: Value(amount.input.amount),
      inputUnit: Value(amount.input.unitCode),
      amount: Value(computed.amount),
      amountBasis: Value(amount.basis.unitCode),
      kcal: Value(snapshot.kcal),
      proteinG: Value(snapshot.protein),
      carbsG: Value(snapshot.carbs),
      fatG: Value(snapshot.fat),
      fiberG: Value(snapshot.fiber),
      extrasJson: Value(extrasToJson(snapshot.extras)),
    );
  }

  /// Whether the snapshot was edited (AI-072); copies retain it.
  final bool editedByUser;

  /// Per-100 equivalent and recomputed snapshot for a nutrient override.
  /// Each field in [overridden] becomes known (A62 D24: the user gave it,
  /// an explicit 0 included); the others keep their state.
  static DiaryEntriesCompanion per100Changes(
    Nutrients per100,
    EntryAmount amount, {
    Set<NutrientField> overridden = const {},
  }) {
    final snapshot = amountChanges(per100, amount);
    return snapshot.copyWith(
      proteinKnown: overridden.contains(NutrientField.protein)
          ? const Value(true)
          : const Value.absent(),
      carbsKnown: overridden.contains(NutrientField.carbs)
          ? const Value(true)
          : const Value.absent(),
      fatKnown: overridden.contains(NutrientField.fat)
          ? const Value(true)
          : const Value.absent(),
      fiberKnown: overridden.contains(NutrientField.fiber)
          ? const Value(true)
          : const Value.absent(),
      // Nutrient edits retain the exact stored canonical amount.
      amount: const Value.absent(),
      per100Kcal: Value(per100.kcal),
      per100ProteinG: Value(per100.protein),
      per100CarbsG: Value(per100.carbs),
      per100FatG: Value(per100.fat),
      per100FiberG: Value(per100.fiber),
      per100ExtrasJson: Value(extrasToJson(per100.extras)),
      editedByUser: const Value(true),
    );
  }

  /// Original JSON spelling when copying a saved snapshot.
  final String? rawPer100ExtrasJson;

  /// Original snapshot extras JSON when copying a saved item.
  final String? rawExtrasJson;

  /// The foodKind column(s).
  final String foodKind;

  /// The foodId column(s).
  final String? foodId;

  /// The foodVersion column(s).
  final String? foodVersion;

  /// The nameEn column(s).
  final String nameEn;

  /// The nameAr column(s).
  final String? nameAr;

  /// The inputAmount column(s).
  final double inputAmount;

  /// The inputUnit column(s).
  final String inputUnit;

  /// The amount column(s).
  final double amount;

  /// The amountBasis column(s).
  final String amountBasis;

  /// The per100 column(s).
  final Nutrients per100;

  /// The snapshot column(s).
  final Nutrients snapshot;

  /// The source column(s).
  final String source;

  /// The isEstimate column(s).
  final bool isEstimate;

  /// The estimateRangeJson column(s).
  final String? estimateRangeJson;

  /// The assumptionsJson column(s).
  final String? assumptionsJson;

  /// The userEstimate column(s) (A62 D3).
  final bool userEstimate;

  /// The `*_known` columns: the known nutrients of protein, carbs, fat and
  /// fiber (A62 D3).
  final Set<NutrientField> known;

  /// The known set of four stored `*_known` flags.
  static Set<NutrientField> knownOf({
    required bool protein,
    required bool carbs,
    required bool fat,
    required bool fiber,
  }) => {
    if (protein) NutrientField.protein,
    if (carbs) NutrientField.carbs,
    if (fat) NutrientField.fat,
    if (fiber) NutrientField.fiber,
  };

  /// A new entry row.
  DiaryEntriesCompanion entry({
    required String id,
    required String localDate,
    required EntryTime time,
    required String slotId,
    required String? dishGroupId,
  }) => DiaryEntriesCompanion(
    id: Value(id),
    editedByUser: Value(editedByUser),
    foodKind: Value(foodKind),
    foodId: Value(foodId),
    foodVersion: Value(foodVersion),
    nameEn: Value(nameEn),
    nameAr: Value(nameAr),
    inputAmount: Value(inputAmount),
    inputUnit: Value(inputUnit),
    amount: Value(amount),
    amountBasis: Value(amountBasis),
    per100Kcal: Value(per100.kcal),
    per100ProteinG: Value(per100.protein),
    per100CarbsG: Value(per100.carbs),
    per100FatG: Value(per100.fat),
    per100FiberG: Value(per100.fiber),
    per100ExtrasJson: Value(rawPer100ExtrasJson ?? extrasToJson(per100.extras)),
    kcal: Value(snapshot.kcal),
    proteinG: Value(snapshot.protein),
    carbsG: Value(snapshot.carbs),
    fatG: Value(snapshot.fat),
    fiberG: Value(snapshot.fiber),
    extrasJson: Value(rawExtrasJson ?? extrasToJson(snapshot.extras)),
    source: Value(source),
    isEstimate: Value(isEstimate),
    estimateRangeJson: Value(estimateRangeJson),
    assumptionsJson: Value(assumptionsJson),
    userEstimate: Value(userEstimate),
    proteinKnown: Value(known.contains(NutrientField.protein)),
    carbsKnown: Value(known.contains(NutrientField.carbs)),
    fatKnown: Value(known.contains(NutrientField.fat)),
    fiberKnown: Value(known.contains(NutrientField.fiber)),
    localDate: Value(localDate),
    occurredAtUtc: Value(time.occurredAtUtc.millisecondsSinceEpoch),
    tzOffsetMin: Value(time.tzOffsetMin),
    slotId: Value(slotId),
    dishGroupId: Value(dishGroupId),
  );

  /// An update of an entry row to these food columns (name, ref, input,
  /// amount, per-100, snapshot and provenance together).
  DiaryEntriesCompanion entryChanges() => DiaryEntriesCompanion(
    editedByUser: Value(editedByUser),
    foodKind: Value(foodKind),
    foodId: Value(foodId),
    foodVersion: Value(foodVersion),
    nameEn: Value(nameEn),
    nameAr: Value(nameAr),
    inputAmount: Value(inputAmount),
    inputUnit: Value(inputUnit),
    amount: Value(amount),
    amountBasis: Value(amountBasis),
    per100Kcal: Value(per100.kcal),
    per100ProteinG: Value(per100.protein),
    per100CarbsG: Value(per100.carbs),
    per100FatG: Value(per100.fat),
    per100FiberG: Value(per100.fiber),
    per100ExtrasJson: Value(rawPer100ExtrasJson ?? extrasToJson(per100.extras)),
    kcal: Value(snapshot.kcal),
    proteinG: Value(snapshot.protein),
    carbsG: Value(snapshot.carbs),
    fatG: Value(snapshot.fat),
    fiberG: Value(snapshot.fiber),
    extrasJson: Value(rawExtrasJson ?? extrasToJson(snapshot.extras)),
    source: Value(source),
    isEstimate: Value(isEstimate),
    estimateRangeJson: Value(estimateRangeJson),
    assumptionsJson: Value(assumptionsJson),
    userEstimate: Value(userEstimate),
    proteinKnown: Value(known.contains(NutrientField.protein)),
    carbsKnown: Value(known.contains(NutrientField.carbs)),
    fatKnown: Value(known.contains(NutrientField.fat)),
    fiberKnown: Value(known.contains(NutrientField.fiber)),
  );

  /// A new saved-meal item row.
  SavedMealItemsCompanion savedItem({
    required String id,
    required String savedMealId,
    required int sortOrder,
  }) => SavedMealItemsCompanion(
    id: Value(id),
    savedMealId: Value(savedMealId),
    sortOrder: Value(sortOrder),
    editedByUser: Value(editedByUser),
    foodKind: Value(foodKind),
    foodId: Value(foodId),
    foodVersion: Value(foodVersion),
    nameEn: Value(nameEn),
    nameAr: Value(nameAr),
    inputAmount: Value(inputAmount),
    inputUnit: Value(inputUnit),
    amount: Value(amount),
    amountBasis: Value(amountBasis),
    per100Kcal: Value(per100.kcal),
    per100ProteinG: Value(per100.protein),
    per100CarbsG: Value(per100.carbs),
    per100FatG: Value(per100.fat),
    per100FiberG: Value(per100.fiber),
    per100ExtrasJson: Value(rawPer100ExtrasJson ?? extrasToJson(per100.extras)),
    kcal: Value(snapshot.kcal),
    proteinG: Value(snapshot.protein),
    carbsG: Value(snapshot.carbs),
    fatG: Value(snapshot.fat),
    fiberG: Value(snapshot.fiber),
    extrasJson: Value(rawExtrasJson ?? extrasToJson(snapshot.extras)),
    source: Value(source),
    isEstimate: Value(isEstimate),
    estimateRangeJson: Value(estimateRangeJson),
    assumptionsJson: Value(assumptionsJson),
    userEstimate: Value(userEstimate),
    proteinKnown: Value(known.contains(NutrientField.protein)),
    carbsKnown: Value(known.contains(NutrientField.carbs)),
    fatKnown: Value(known.contains(NutrientField.fat)),
    fiberKnown: Value(known.contains(NutrientField.fiber)),
  );
}
