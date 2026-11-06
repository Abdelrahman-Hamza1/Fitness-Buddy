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
  estimateKcal: row.estimateKcal,
  estimateOnly: row.estimateOnly,
  version: row.version,
);

/// The domain entry of [row].
DiaryEntry diaryEntryOf(DiaryEntryRow row) {
  final (food, snapshot) = storedFoodOf(
    kind: row.foodKind,
    id: row.foodId,
    version: row.foodVersion,
    nameEn: row.nameEn,
    nameAr: row.nameAr,
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
    rangeJson: row.estimateRangeJson,
    assumptionsJson: row.assumptionsJson,
    isEstimate: row.isEstimate,
    userEstimate: row.userEstimate,
    known: (
      protein: row.proteinKnown,
      carbs: row.carbsKnown,
      fat: row.fatKnown,
      fiber: row.fiberKnown,
    ),
  );
  return DiaryEntry(
    id: row.id,
    version: row.version,
    time: EntryTime(
      DateTime.fromMillisecondsSinceEpoch(row.occurredAtUtc, isUtc: true),
      row.tzOffsetMin,
    ),
    localDate: LocalDate.parse(row.localDate),
    slotId: row.slotId,
    dishGroupId: row.dishGroupId,
    food: food,
    amount: EntryAmount(
      input: Quantity(row.inputAmount, row.inputUnit),
      amount: row.amount,
      basis: basisOf(row.amountBasis),
    ),
    snapshot: snapshot,
    editedByUser: row.editedByUser,
  );
}

/// The stored `*_known` flags of a row.
typedef KnownFlags = ({bool protein, bool carbs, bool fat, bool fiber});

/// A stored food and its snapshot (entries and saved items, A62 D3, D27).
///
/// Never throws for the A62 flags: a row is a user estimate only when it
/// has the user-estimate shape (W1); only a user estimate keeps unknowns
/// (W2); an unknown nutrient reads as 0 in both values (W3). The server
/// refuses rows that break these, so this only absorbs a local bug.
(EntryFood, Nutrients) storedFoodOf({
  required String kind,
  required String? id,
  required String? version,
  required String nameEn,
  required String? nameAr,
  required Nutrients per100,
  required Nutrients snapshot,
  required String source,
  required String? rangeJson,
  required String? assumptionsJson,
  required bool isEstimate,
  required bool userEstimate,
  required KnownFlags known,
  bool editedByUser = false,
}) {
  final ref = foodRefOf(kind, id, version);
  final provenance = provenanceOf(
    source,
    rangeJson,
    assumptionsJson,
    isEstimate: isEstimate,
  );
  final estimate =
      userEstimate &&
      ref.kind == FoodRefKind.estimate &&
      ref.id == null &&
      provenance.source == FoodSource.yours &&
      provenance.isEstimate;
  final knownSet = estimate
      ? {
          if (known.protein) NutrientField.protein,
          if (known.carbs) NutrientField.carbs,
          if (known.fat) NutrientField.fat,
          if (known.fiber) NutrientField.fiber,
        }
      : EntryFood.allKnown;
  Nutrients zeroUnknown(Nutrients n) => knownSet.length == 4
      ? n
      : Nutrients(
          kcal: n.kcal,
          protein: knownSet.contains(NutrientField.protein) ? n.protein : 0,
          carbs: knownSet.contains(NutrientField.carbs) ? n.carbs : 0,
          fat: knownSet.contains(NutrientField.fat) ? n.fat : 0,
          fiber: knownSet.contains(NutrientField.fiber) ? n.fiber : 0,
          extras: n.extras,
        );
  return (
    EntryFood(
      ref: ref,
      names: FoodNames(nameEn, ar: nameAr),
      per100: zeroUnknown(per100),
      provenance: provenance,
      editedByUser: editedByUser,
      userEstimate: estimate,
      known: knownSet,
    ),
    zeroUnknown(snapshot),
  );
}

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
