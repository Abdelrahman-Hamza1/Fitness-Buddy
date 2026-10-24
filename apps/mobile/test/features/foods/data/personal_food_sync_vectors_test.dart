import 'dart:convert';
import 'dart:io';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/features/foods/data/personal_food_mappers.dart';
import 'package:flutter_test/flutter_test.dart';

const _id = '0199e3c2-5b1a-7c3d-8e4f-0123456789ab';
const _hlc = '1760351234567-00000-0199e3c2-5b1a-7c3d-8e4f-0123456789ab';

void main() {
  final corpus = jsonDecode(
    File('../../contracts/testdata/sync/personal-food-validation-vectors.json')
        .readAsStringSync(),
  ) as Map<String, dynamic>;
  final payloads = (corpus['payloads'] as List<dynamic>)
      .cast<Map<String, dynamic>>();
  final byId = {for (final p in payloads) p['id']! as String: p};
  for (final p in payloads) {
    test('FD-071 AC-010 mapper outcome: ${p['id']}', () {
      final payload =
          jsonDecode(p['rawPayload']! as String) as Map<String, dynamic>;
      PersonalFood read() =>
          personalFoodOf(_row(payload, deleted: p['deleted']! as bool));
      if (p['appReads']! as bool) {
        expect(read, returnsNormally);
      } else {
        // A schema-invalid document may not even be constructible as a typed
        // drift row; other failures must come from the actual decoder.
        expect(
          read,
          throwsA(anyOf(isA<PersonalFoodMappingError>(), isA<TypeError>())),
        );
      }
      if (p['serverAccepts']! as bool) expect(p['appReads'], isTrue);
    });
  }
  test('B17 asymmetric list is exactly server-rejected readable rows', () {
    expect(corpus['serverRejectsAppTolerates'], [
      for (final p in payloads)
        if (p['serverAccepts'] == false && p['appReads'] == true) p['id'],
    ]);
  });
  for (final writer
      in (corpus['writers'] as List<dynamic>).cast<Map<String, dynamic>>()) {
    for (final withPrevious in [false, true]) {
      test(
        'FD-071 AC-010 columns: ${writer['payloadId']} previous=$withPrevious',
        () {
          final expected = byId[writer['payloadId']]!;
          expect(expected['serverAccepts'], isTrue);
          final payload = jsonDecode(
            expected['rawPayload']! as String,
          ) as Map<String, dynamic>;
          final draft = _draft(writer['draft'] as Map<String, dynamic>);
          expect(draft.validateWire(), isNull);
          final columns = personalFoodColumns(
            draft,
            previous: withPrevious ? _row(payload) : null,
          );
          expect(_content(columns, payload), payload);
          expect(personalFoodOf(_row(payload)).draft, draft);
        },
      );
    }
  }
}

PersonalFoodRow _row(Map<String, dynamic> p, {bool deleted = false}) =>
    PersonalFoodRow(
      id: _id,
      createdAt: p['createdAtMs'] as int,
      updatedHlc: _hlc,
      version: 1,
      deviceId: _id,
      deletedAt: deleted ? 1760351234567 : null,
      origin: p['origin'] as String,
      editedByUser: p['editedByUser'] as bool,
      nameEn: p['nameEn'] as String,
      nameAr: p['nameAr'] as String?,
      brand: p['brand'] as String?,
      aliasesJson: p['aliasesJson'] as String?,
      barcodesJson: p['barcodesJson'] as String?,
      state: p['state'] as String,
      basis: p['basis'] as String,
      per100Kcal: (p['per100Kcal'] as num).toDouble(),
      per100ProteinG: (p['per100ProteinG'] as num).toDouble(),
      per100CarbsG: (p['per100CarbsG'] as num).toDouble(),
      per100FatG: (p['per100FatG'] as num).toDouble(),
      per100FiberG: (p['per100FiberG'] as num).toDouble(),
      per100ExtrasJson: p['per100ExtrasJson'] as String?,
      servingsJson: p['servingsJson'] as String?,
      entryServingUnit: p['entryServingUnit'] as String?,
      entryServingAmount: (p['entryServingAmount'] as num?)?.toDouble(),
      createdFrom: p['createdFrom'] as String,
    );

// Build a typed draft from declared inputs, independently of personalFoodOf.
PersonalFoodDraft _draft(Map<String, dynamic> p) {
  Object? nested(String key) =>
      p[key] == null ? null : jsonDecode(p[key] as String);
  final extras = nested('per100ExtrasJson') as Map<String, dynamic>? ?? {};
  return PersonalFoodDraft(
    names: FoodNames(p['nameEn'] as String, ar: p['nameAr'] as String?),
    brand: p['brand'] as String?,
    aliases: (nested('aliasesJson') as List<dynamic>? ?? []).cast<String>(),
    barcodes: (nested('barcodesJson') as List<dynamic>? ?? []).cast<String>(),
    state: FoodState.fromCode(p['state'] as String)!,
    basis: p['basis'] == 'g' ? NutrientBasis.per100g : NutrientBasis.per100ml,
    per100: Nutrients(
      kcal: (p['per100Kcal'] as num).toDouble(),
      protein: (p['per100ProteinG'] as num).toDouble(),
      carbs: (p['per100CarbsG'] as num).toDouble(),
      fat: (p['per100FatG'] as num).toDouble(),
      fiber: (p['per100FiberG'] as num).toDouble(),
      extras: {
        for (final e in extras.entries)
          NutrientKey.fromCode(e.key)!: (e.value as num).toDouble(),
      },
    ),
    servings: [
      for (final s in nested('servingsJson') as List<dynamic>? ?? [])
        PersonalFoodServing(
          (s as Map<String, dynamic>)['unit'] as String,
          (s['amount'] as num).toDouble(),
        ),
    ],
    entryServing: p['entryServingUnit'] == null
        ? null
        : PersonalFoodServing(
            p['entryServingUnit'] as String,
            (p['entryServingAmount'] as num).toDouble(),
          ),
    createdFrom: p['createdFrom'] as String,
  );
}

Map<String, Object?> _content(
  PersonalFoodsCompanion c,
  Map<String, dynamic> metadata,
) => {
  'createdAtMs': metadata['createdAtMs'],
  'origin': metadata['origin'],
  'editedByUser': metadata['editedByUser'],
  'nameEn': c.nameEn.value,
  'nameAr': c.nameAr.value,
  'aliasesJson': c.aliasesJson.value,
  'brand': c.brand.value,
  'barcodesJson': c.barcodesJson.value,
  'state': c.state.value,
  'basis': c.basis.value,
  'per100Kcal': c.per100Kcal.value,
  'per100ProteinG': c.per100ProteinG.value,
  'per100CarbsG': c.per100CarbsG.value,
  'per100FatG': c.per100FatG.value,
  'per100FiberG': c.per100FiberG.value,
  'per100ExtrasJson': c.per100ExtrasJson.value,
  'servingsJson': c.servingsJson.value,
  'entryServingUnit': c.entryServingUnit.value,
  'entryServingAmount': c.entryServingAmount.value,
  'createdFrom': c.createdFrom.value,
};
