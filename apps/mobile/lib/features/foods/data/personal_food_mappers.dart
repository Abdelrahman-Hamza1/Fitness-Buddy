import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/app_database.dart';

/// Stored data could be corrupt or from an incompatible client. Never echo it.
final class PersonalFoodMappingError implements Exception {
  /// Fixed, typed failure without the parser exception or source text.
  const new();
  @override
  String toString() => 'PersonalFoodMappingError';
}

/// Wire-only row decoding; unknown future codes do not erase readable foods.
PersonalFood personalFoodOf(PersonalFoodRow row) {
  try {
    Object? decode(String? value) {
      if (value == null) return null;
      if (value.length > PersonalFoodBounds.jsonLength) {
        throw const PersonalFoodMappingError();
      }
      return jsonDecode(value);
    }

    List<String> strings(String? value) {
      final decoded = decode(value);
      if (decoded == null) return [];
      if (decoded is! List || decoded.any((v) => v is! String)) {
        throw const PersonalFoodMappingError();
      }
      return decoded.cast<String>();
    }

    final extras = <NutrientKey, double>{};
    final extraJson = decode(row.per100ExtrasJson);
    if (extraJson != null) {
      if (extraJson is! Map<String, dynamic>) {
        throw const PersonalFoodMappingError();
      }
      for (final e in extraJson.entries) {
        final key = NutrientKey.fromCode(e.key);
        if (e.value is! num ||
            e.key.contains('\u0000') ||
            !PersonalFoodBounds.acceptsNutrient(
              (e.value as num).toDouble(),
              key == null || key.unit == NutrientUnit.milligram
                  ? PersonalFoodBounds.milligrams
                  : PersonalFoodBounds.grams,
            )) {
          throw const PersonalFoodMappingError();
        }
        if (key != null) extras[key] = (e.value as num).toDouble();
      }
    }
    final servings = <PersonalFoodServing>[];
    final servingJson = decode(row.servingsJson);
    if (servingJson != null) {
      if (servingJson is! List) throw const PersonalFoodMappingError();
      for (final s in servingJson) {
        if (s is! Map ||
            s.length != 2 ||
            s['unit'] is! String ||
            s['amount'] is! num) {
          throw const PersonalFoodMappingError();
        }
        servings.add(
          PersonalFoodServing(
            s['unit'] as String,
            (s['amount'] as num).toDouble(),
          ),
        );
      }
    }
    final state = FoodState.fromCode(row.state) ?? FoodState.asSold;
    final basis = switch (row.basis) {
      'g' => NutrientBasis.per100g,
      'ml' => NutrientBasis.per100ml,
      _ => null,
    };
    if (basis == null ||
        (row.entryServingUnit == null) != (row.entryServingAmount == null)) {
      throw const PersonalFoodMappingError();
    }
    final draft = PersonalFoodDraft(
      names: FoodNames(row.nameEn, ar: row.nameAr),
      aliases: strings(row.aliasesJson),
      brand: row.brand,
      barcodes: strings(row.barcodesJson),
      state: state,
      basis: basis,
      per100: Nutrients(
        kcal: row.per100Kcal,
        protein: row.per100ProteinG,
        carbs: row.per100CarbsG,
        fat: row.per100FatG,
        fiber: row.per100FiberG,
        extras: extras,
      ),
      servings: servings,
      entryServing: row.entryServingUnit == null
          ? null
          : PersonalFoodServing(row.entryServingUnit!, row.entryServingAmount!),
      createdFrom: row.createdFrom,
    );
    if (draft.validateWire() != null) throw const PersonalFoodMappingError();
    return PersonalFood(id: row.id, version: row.version, draft: draft);
  } on PersonalFoodMappingError {
    rethrow;
  } on FormatException {
    throw const PersonalFoodMappingError();
    // Domain constructors reject invalid stored values with ArgumentError.
    // ignore: avoid_catching_errors
  } on ArgumentError {
    throw const PersonalFoodMappingError();
  }
}

/// Content only; metadata is exclusively the applier's responsibility.
PersonalFoodsCompanion personalFoodColumns(
  PersonalFoodDraft draft, {
  PersonalFoodRow? previous,
}) => PersonalFoodsCompanion(
  nameEn: Value(draft.names.en),
  nameAr: Value(draft.names.ar),
  aliasesJson: Value(draft.aliases.isEmpty ? null : jsonEncode(draft.aliases)),
  brand: Value(draft.brand),
  barcodesJson: Value(
    draft.barcodes.isEmpty ? null : jsonEncode(draft.barcodes),
  ),
  state: Value(
    previous != null &&
            FoodState.fromCode(previous.state) == null &&
            draft.state == FoodState.asSold
        ? previous.state
        : draft.state.code,
  ),
  basis: Value(draft.basis.unitCode),
  per100Kcal: Value(draft.per100.kcal),
  per100ProteinG: Value(draft.per100.protein),
  per100CarbsG: Value(draft.per100.carbs),
  per100FatG: Value(draft.per100.fat),
  per100FiberG: Value(draft.per100.fiber),
  per100ExtrasJson: Value(_extrasForRewrite(draft, previous)),
  servingsJson: Value(
    draft.servings.isEmpty
        ? null
        : jsonEncode([
            for (final s in draft.servings)
              {'unit': s.unit, 'amount': s.amount},
          ]),
  ),
  entryServingUnit: Value(draft.entryServing?.unit),
  entryServingAmount: Value(draft.entryServing?.amount),
  createdFrom: Value(draft.createdFrom),
);

// Preserve the entire raw column when known values did not change. When they
// did, rewrite known keys only; future keys remain owned by the stored row.
String? _extrasForRewrite(PersonalFoodDraft draft, PersonalFoodRow? previous) {
  final stored = previous == null
      ? null
      : personalFoodOf(previous).per100.extras;
  final known = draft.per100.extras;
  if (stored != null &&
      stored.length == known.length &&
      stored.entries.every((e) => known[e.key] == e.value)) {
    return previous!.per100ExtrasJson;
  }
  final extras = <String, Object?>{
    if (previous?.per100ExtrasJson case final raw?)
      for (final e in (jsonDecode(raw) as Map<String, dynamic>).entries)
        if (NutrientKey.fromCode(e.key) == null) e.key: e.value,
    for (final e in known.entries) e.key.code: e.value,
  };
  final encoded = extras.isEmpty ? null : jsonEncode(extras);
  if (encoded != null && encoded.length > PersonalFoodBounds.jsonLength) {
    throw const PersonalFoodMappingError();
  }
  return encoded;
}
