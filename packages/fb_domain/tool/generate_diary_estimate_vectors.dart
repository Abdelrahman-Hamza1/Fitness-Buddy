import 'dart:convert';
import 'dart:io';

import 'package:fb_domain/fb_domain.dart';

/// Why a case's `serverAccepts` may differ from `appWire` (A62a D5). Closed:
/// `schemaOnly` is a payload the wire rules accept at the declared version
/// but the version's schema rejects (a v2 payload sent as v1).
const Set<String> diaryEstimateAsymmetries = {'schemaOnly'};

/// The slot / saved meal the synthetic rows point at (a UUIDv7).
const String _parentId = '0199e3c2-5b1a-7c3d-8e4f-0123456789ab';

/// The v1 content shared by both entities (an ordinary catalog food), in
/// contract order. Synthetic content only.
Map<String, Object?> _food() => {
  'createdAtMs': 0,
  'origin': 'synthetic',
  'editedByUser': false,
  'inputAmount': 150.0,
  'amount': 150.0,
  'per100Kcal': 130.0,
  'per100ProteinG': 2.7,
  'per100CarbsG': 28.0,
  'per100FatG': 0.3,
  'per100FiberG': 0.4,
  'kcal': 195.0,
  'proteinG': 4.05,
  'carbsG': 42.0,
  'fatG': 0.45,
  'fiberG': 0.6,
  'foodKind': 'catalog',
  'foodId': 'synthetic-food',
  'foodVersion': '1',
  'nameEn': 'synthetic rice',
  'nameAr': null,
  'inputUnit': 'g',
  'amountBasis': 'g',
  'source': 'database',
  'isEstimate': false,
  'per100ExtrasJson': null,
  'extrasJson': null,
  'estimateRangeJson': null,
  'assumptionsJson': null,
};

/// The entity-specific v1 tail, in contract order.
Map<String, Object?> _tail(String entity) => switch (entity) {
  'diaryEntry' => {
    'localDate': '2026-10-18',
    'occurredAtUtc': 1792299600000,
    'tzOffsetMin': 180,
    'slotId': _parentId,
    'dishGroupId': null,
  },
  'savedMealItem' => {'savedMealId': _parentId, 'sortOrder': 0},
  _ => throw ArgumentError.value(entity, 'entity'),
};

/// A v1 payload of [entity] with [content] over the ordinary food.
Map<String, Object?> _v1(
  String entity, [
  Map<String, Object?> content = const {},
]) => {..._food(), ...content, ..._tail(entity)};

/// A v2 payload: [v1] plus the five flags (all known, not an estimate,
/// unless [flags] says otherwise).
Map<String, Object?> _v2(
  Map<String, Object?> v1, [
  Map<String, Object?> flags = const {},
]) => {
  ...v1,
  'userEstimate': false,
  'proteinKnown': true,
  'carbsKnown': true,
  'fatKnown': true,
  'fiberKnown': true,
  ...flags,
};

/// A user estimate of [kcal] with the given macros known (others unknown,
/// stored 0). Per-100 = the typed totals at 100 g, one serving (A62 D2).
Map<String, Object?> _estimate(
  String entity, {
  required double kcal,
  double? protein,
  double? carbs,
  double? fat,
  double? fiber,
  String name = 'Estimate',
}) {
  final content = <String, Object?>{
    'editedByUser': true,
    'inputAmount': 1.0,
    'amount': 100.0,
    'per100Kcal': kcal,
    'per100ProteinG': protein ?? 0.0,
    'per100CarbsG': carbs ?? 0.0,
    'per100FatG': fat ?? 0.0,
    'per100FiberG': fiber ?? 0.0,
    'kcal': kcal,
    'proteinG': protein ?? 0.0,
    'carbsG': carbs ?? 0.0,
    'fatG': fat ?? 0.0,
    'fiberG': fiber ?? 0.0,
    'foodKind': 'estimate',
    'foodId': null,
    'foodVersion': null,
    'nameEn': name,
    'inputUnit': 'serving',
    'source': 'yours',
    'isEstimate': true,
  };
  return _v2(_v1(entity, content), {
    'userEstimate': true,
    'proteinKnown': protein != null,
    'carbsKnown': carbs != null,
    'fatKnown': fat != null,
    'fiberKnown': fiber != null,
  });
}

final class _Corpus {
  final List<Map<String, Object?>> payloads = [];

  void add(
    String id,
    String entity,
    int schemaVersion,
    Map<String, Object?> payload, {
    required bool server,
    DiaryEstimateWireRule? rule,
    bool schema = false,
  }) {
    final wire = DiaryEstimateWireRules.holds(entity, schemaVersion, payload);
    // Only a schema or version case may be wire-valid and still rejected.
    final asymmetry = schema && wire && !server ? 'schemaOnly' : null;
    if (asymmetry == null && wire != server) {
      throw StateError('$id: serverAccepts $server but appWire $wire');
    }
    if (rule != null &&
        DiaryEstimateWireRules.violation(entity, schemaVersion, payload) !=
            rule &&
        !server) {
      throw StateError('$id: breaks another rule than $rule');
    }
    payloads.add({
      'id': '$entity-$id',
      'entity': entity,
      'schemaVersion': schemaVersion,
      'rawPayload': jsonEncode(payload),
      'rule': ?rule?.readme,
      'asymmetry': ?asymmetry,
      'serverAccepts': server,
      'appWire': wire,
    });
  }
}

void _cases(_Corpus c, String entity) {
  final add = c.add;
  final ordinary = _v2(_v1(entity));
  final kcalOnly = _estimate(entity, kcal: 700);
  final partial = _estimate(entity, kcal: 700, protein: 35);
  final full = _estimate(entity, kcal: 450, protein: 30, carbs: 40, fat: 0);
  final allKnown = _estimate(
    entity,
    kcal: 450,
    protein: 30,
    carbs: 40,
    fat: 10,
    fiber: 5,
  );
  final buddy = _v2(
    _v1(entity, {
      'foodKind': 'estimate',
      'foodId': null,
      'foodVersion': null,
      'source': 'estimate',
      'isEstimate': true,
      'estimateRangeJson': '{"low":150,"high":250}',
    }),
  );

  // Accepted bases.
  add('v1-base', entity, 1, _v1(entity), server: true);
  add(
    'v1-legacy-estimate',
    entity,
    1,
    _v1(entity, {
      'foodKind': 'estimate',
      'foodId': null,
      'source': 'yours',
      'isEstimate': true,
    }),
    server: true,
  );
  add('v2-ordinary', entity, 2, ordinary, server: true);
  add('v2-buddy-estimate', entity, 2, buddy, server: true);
  add('v2-estimate-kcal-only', entity, 2, kcalOnly, server: true);
  add('v2-estimate-protein-only', entity, 2, partial, server: true);
  add('v2-estimate-known-zero-fat', entity, 2, full, server: true);
  add('v2-estimate-all-known', entity, 2, allKnown, server: true);
  add(
    'v2-estimate-max',
    entity,
    2,
    _estimate(entity, kcal: 10000, protein: 1000, carbs: 1000, fat: 1000),
    server: true,
  );
  // FD-012 doesn't apply: kcal far from 4P + 4C + 9F is admitted.
  add(
    'v2-estimate-no-sanity-check',
    entity,
    2,
    _estimate(entity, kcal: 10000, protein: 0, carbs: 0, fat: 0),
    server: true,
  );
  add('v2-estimate-integer-zero', entity, 2, {
    ...kcalOnly,
    'proteinG': 0,
    'per100ProteinG': 0,
  }, server: true);

  // Versions: each payload only under its own schemaVersion.
  add('v1-sent-as-v2', entity, 2, _v1(entity), server: false, schema: true);
  add(
    'v2-ordinary-sent-as-v1',
    entity,
    1,
    ordinary,
    server: false,
    schema: true,
  );
  add(
    'v2-estimate-sent-as-v1',
    entity,
    1,
    partial,
    server: false,
    schema: true,
  );

  // W1 user estimate shape.
  const w1 = DiaryEstimateWireRule.userEstimateShape;
  for (final kind in ['catalog', 'personal', 'batch']) {
    add(
      'W1-food-kind-$kind',
      entity,
      2,
      {...partial, 'foodKind': kind},
      server: false,
      rule: w1,
    );
  }
  for (final source in ['database', 'reference', 'estimate']) {
    add(
      'W1-source-$source',
      entity,
      2,
      {...partial, 'source': source},
      server: false,
      rule: w1,
    );
  }
  add(
    'W1-not-is-estimate',
    entity,
    2,
    {...partial, 'isEstimate': false},
    server: false,
    rule: w1,
  );
  add(
    'W1-food-id',
    entity,
    2,
    {...partial, 'foodId': 'synthetic-food'},
    server: false,
    rule: w1,
  );
  add(
    'W1-all-known-catalog',
    entity,
    2,
    {...allKnown, 'foodKind': 'catalog'},
    server: false,
    rule: w1,
  );

  // W2 unknowns only on user estimates.
  const w2 = DiaryEstimateWireRule.unknownsOnlyOnUserEstimates;
  for (final (known, snapshot, per100) in DiaryEstimateWireRules.nutrients) {
    add(
      'W2-ordinary-$known-false',
      entity,
      2,
      {...ordinary, known: false, snapshot: 0.0, per100: 0.0},
      server: false,
      rule: w2,
    );
  }
  add(
    'W2-buddy-proteinKnown-false',
    entity,
    2,
    {...buddy, 'proteinKnown': false, 'proteinG': 0.0, 'per100ProteinG': 0.0},
    server: false,
    rule: w2,
  );
  add(
    'W2-estimate-flag-cleared',
    entity,
    2,
    {...kcalOnly, 'userEstimate': false},
    server: false,
    rule: w2,
  );

  // W3 unknown is stored zero.
  const w3 = DiaryEstimateWireRule.unknownIsStoredZero;
  for (final (known, snapshot, per100) in DiaryEstimateWireRules.nutrients) {
    add(
      'W3-$known-false-snapshot',
      entity,
      2,
      {...kcalOnly, snapshot: 1.0},
      server: false,
      rule: w3,
    );
    add(
      'W3-$known-false-per100',
      entity,
      2,
      {...kcalOnly, per100: 1.0},
      server: false,
      rule: w3,
    );
  }
  add(
    'W3-tiny-nonzero',
    entity,
    2,
    {...kcalOnly, 'fiberG': 1e-9},
    server: false,
    rule: w3,
  );

  // Schema of the new fields (the rules see a missing flag as unknown).
  for (final field in DiaryEstimateWireRules.v2Fields) {
    add(
      'schema-missing-$field',
      entity,
      2,
      {...ordinary}..remove(field),
      server: false,
      schema: true,
    );
    add(
      'schema-null-$field',
      entity,
      2,
      {...ordinary, field: null},
      server: false,
      schema: true,
    );
    add(
      'schema-string-$field',
      entity,
      2,
      {...ordinary, field: 'true'},
      server: false,
      schema: true,
    );
  }
}

/// The corpus as a JSON value.
Map<String, Object?> diaryEstimateVectors() {
  final c = _Corpus();
  for (final entity in DiaryEstimateWireRules.entities) {
    _cases(c, entity);
  }
  return {
    'version': 1,
    'constants': {
      'entities': DiaryEstimateWireRules.entities,
      'versions': DiaryEstimateWireRules.versions,
      'foodKind': DiaryEstimateWireRules.foodKind,
      'source': DiaryEstimateWireRules.source,
      'v2Fields': DiaryEstimateWireRules.v2Fields,
      'nutrients': [
        for (final (known, snapshot, per100)
            in DiaryEstimateWireRules.nutrients)
          {'known': known, 'snapshot': snapshot, 'per100': per100},
      ],
    },
    'rules': [
      for (final rule in DiaryEstimateWireRule.values)
        {'id': rule.id, 'readme': rule.readme},
    ],
    'payloads': c.payloads,
  };
}

/// Stable JSON bytes shared by the Dart and C# tests.
String generateDiaryEstimateVectors() =>
    '${const JsonEncoder.withIndent('  ').convert(diaryEstimateVectors())}\n';

/// Writes the corpus.
void main() {
  File.fromUri(
    Platform.script.resolve(
      '../../../contracts/testdata/sync/diary-estimate-validation-vectors.json',
    ),
  ).writeAsStringSync(generateDiaryEstimateVectors());
}
