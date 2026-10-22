import 'dart:convert';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/app_database.dart';

/// Row to `fb_domain` mapping for the diary (A06 §3.3). Read side only:
/// writes go through the applier's op handler (WP3).
///
/// Values written by a newer app are mapped to the nearest known value
/// instead of failing a whole day: an unknown food kind reads as an estimate
/// reference (its id kept), an unknown source as an estimate (always
/// marked), an unknown basis as grams.

/// The domain slot of [row].
MealSlot mealSlotOf(MealSlotRow row) => MealSlot(
  id: row.id,
  sortOrder: row.sortOrder,
  defaultKey: row.defaultKey,
  name: row.name,
  window: TimeWindow.fromBounds(row.windowStartMin, row.windowEndMin),
  mode: SlotMode.fromCode(row.mode) ?? SlotMode.normal,
  active: row.active,
);

/// The domain dish group of [row].
DishGroup dishGroupOf(DishGroupRow row) => DishGroup(
  id: row.id,
  version: row.version,
  name: row.name,
  localDate: LocalDate.parse(row.localDate),
  slotId: row.slotId,
);

/// The domain day mark of [row].
DayMark dayMarkOf(DayMarkRow row) => DayMark(
  localDate: LocalDate.parse(row.localDate),
  incomplete: row.incomplete,
  notFasting: row.notFasting,
);

/// The domain entry of [row].
DiaryEntry diaryEntryOf(DiaryEntryRow row) => DiaryEntry(
  id: row.id,
  version: row.version,
  time: EntryTime(
    DateTime.fromMillisecondsSinceEpoch(row.occurredAtUtc, isUtc: true),
    row.tzOffsetMin,
  ),
  localDate: LocalDate.parse(row.localDate),
  slotId: row.slotId,
  dishGroupId: row.dishGroupId,
  food: EntryFood(
    ref: foodRefOf(row.foodKind, row.foodId, row.foodVersion),
    names: FoodNames(row.nameEn, ar: row.nameAr),
    per100: nutrientsOf(
      kcal: row.per100Kcal,
      proteinG: row.per100ProteinG,
      carbsG: row.per100CarbsG,
      fatG: row.per100FatG,
      fiberG: row.per100FiberG,
      extrasJson: row.per100ExtrasJson,
    ),
    provenance: provenanceOf(
      row.source,
      row.estimateRangeJson,
      row.assumptionsJson,
      isEstimate: row.isEstimate,
    ),
  ),
  amount: EntryAmount(
    input: Quantity(row.inputAmount, row.inputUnit),
    amount: row.amount,
    basis: basisOf(row.amountBasis),
  ),
  snapshot: nutrientsOf(
    kcal: row.kcal,
    proteinG: row.proteinG,
    carbsG: row.carbsG,
    fatG: row.fatG,
    fiberG: row.fiberG,
    extrasJson: row.extrasJson,
  ),
  editedByUser: row.editedByUser,
);

/// The basis of a stored `g` / `ml`.
NutrientBasis basisOf(String code) => code == NutrientBasis.per100ml.unitCode
    ? NutrientBasis.per100ml
    : NutrientBasis.per100g;

/// Nutrients from the five stored columns and the extras JSON.
Nutrients nutrientsOf({
  required double kcal,
  required double proteinG,
  required double carbsG,
  required double fatG,
  required double fiberG,
  String? extrasJson,
}) => Nutrients(
  kcal: kcal,
  protein: proteinG,
  carbs: carbsG,
  fat: fatG,
  fiber: fiberG,
  extras: extrasFromJson(extrasJson),
);

/// The extras stored as `{"sugar": 1.2}`; unknown keys and non-numbers are
/// skipped.
Map<NutrientKey, double> extrasFromJson(String? json) {
  if (json == null) return const {};
  final decoded = jsonDecode(json);
  if (decoded is! Map<String, Object?>) return const {};
  return {
    for (final MapEntry(:key, :value) in decoded.entries)
      if (NutrientKey.fromCode(key) case final k?)
        if (value is num) k: value.toDouble(),
  };
}

/// [extras] as stored JSON, or `null` when there are none.
String? extrasToJson(Map<NutrientKey, double> extras) => extras.isEmpty
    ? null
    : jsonEncode({
        for (final MapEntry(:key, :value) in extras.entries) key.code: value,
      });

/// Stored food identity, shared by diary and history snapshots.
FoodRef foodRefOf(String kind, String? id, String? version) {
  final known = FoodRefKind.fromCode(kind);
  if (known == null) {
    return FoodRef(FoodRefKind.estimate, id: id, version: version);
  }
  return FoodRef(known, id: id, version: version);
}

/// Full stored provenance, shared by diary and history snapshots.
Provenance provenanceOf(
  String source,
  String? rangeJson,
  String? assumptionsJson, {
  required bool isEstimate,
}) {
  final known = FoodSource.fromCode(source);
  final estimate = known == null || known == FoodSource.estimate || isEstimate;
  EstimateRange? range;
  if (rangeJson != null && estimate) {
    final decoded = jsonDecode(rangeJson);
    if (decoded is Map<String, Object?> &&
        decoded['lowKcal'] is num &&
        decoded['highKcal'] is num) {
      range = EstimateRange(
        (decoded['lowKcal']! as num).toDouble(),
        (decoded['highKcal']! as num).toDouble(),
      );
    }
  }
  final decodedAssumptions = assumptionsJson == null
      ? null
      : jsonDecode(assumptionsJson);
  return Provenance(
    source: known ?? FoodSource.estimate,
    isEstimate: estimate,
    range: range,
    assumptions: [
      if (decodedAssumptions is List<Object?>)
        for (final a in decodedAssumptions)
          if (a is String) a,
    ],
  );
}
