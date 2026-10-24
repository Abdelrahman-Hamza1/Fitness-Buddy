import 'dart:convert';
import 'dart:io';

import 'package:fb_domain/fb_domain.dart';

/// B17 synthetic parity corpus. Mapper outcomes are declarations checked by the
/// app's real decoder/writer tests, never a replacement implementation here.
Map<String, Object?> personalFoodVectors() {
  final trim = <int>[
    for (var c = 0; c <= 0xffff; c++)
      if ((c < 0xd800 || c > 0xdfff) && String.fromCharCode(c).trim().isEmpty)
        c,
  ];
  final payloads = <Map<String, Object?>>[];
  final asymmetric = <String>[];
  void add(
    String id,
    Map<String, Object?> changes, {
    bool server = true,
    bool app = true,
    bool deleted = false,
    String? raw,
  }) {
    payloads.add({
      'id': id,
      'rawPayload': raw ?? jsonEncode({..._base(), ...changes}),
      'serverAccepts': server,
      'appReads': app,
      'deleted': deleted,
    });
    if (!server && app) asymmetric.add(id);
  }

  add('minimal', {});
  add('tombstone-full', {}, deleted: true);
  add(
    'tombstone-empty',
    {},
    raw: '{}',
    server: false,
    app: false,
    deleted: true,
  );
  for (final state in FoodState.values) {
    add('state-${state.code}', {'state': state.code});
  }
  add('basis-ml', {'basis': 'ml'});
  add('unknown-state', {'state': 'future'}, server: false);
  add('unknown-basis', {'basis': 'future'}, server: false, app: false);
  for (final field in ['nameEn', 'nameAr', 'brand']) {
    final max = field == 'brand'
        ? PersonalFoodBounds.brand
        : PersonalFoodBounds.name;
    for (final size in [1, max - 1, max, max + 1]) {
      add(
        '$field-ascii-$size',
        {field: 'x' * size},
        server: size <= max,
        app: size <= max,
      );
    }
    for (final size in [max - 1, max, max + 1]) {
      final text = '${'x' * (size - 2)}\u{1f34e}';
      add(
        '$field-supplementary-$size',
        {field: text},
        server: size <= max,
        app: size <= max,
      );
    }
    add('$field-empty', {field: ''}, server: false, app: false);
    add('$field-nul', {field: 'x\u0000'}, server: false, app: false);
    // The row decoder trims, while the wire schema caps the raw field.
    add('$field-raw-over-trimmed-limit', {
      field: ' ${'x' * max}',
    }, server: false);
  }
  for (final c in [...trim, 0x1c, 0x1d, 0x1e, 0x1f, 0x180e, 0x200b]) {
    final space = String.fromCharCode(c);
    add(
      'trim-$c-only',
      {'nameEn': space},
      server: !trim.contains(c),
      app: !trim.contains(c),
    );
    add('trim-$c-edges', {'nameEn': '${space}x$space'});
    add('trim-$c-embedded', {'nameEn': 'x${space}x'});
  }
  for (final field in ['aliasesJson', 'barcodesJson', 'servingsJson']) {
    add('$field-empty-list', {field: '[]'});
    add('$field-json-null', {field: 'null'}, server: false);
    for (final value in ['{}', '"text"', '42', '[null]', '[true]', '[1]']) {
      add(
        '$field-wrong-${jsonEncode(value)}',
        {field: value},
        server: false,
        app: false,
      );
    }
  }
  add('extras-empty', {'per100ExtrasJson': '{}'});
  add('extras-json-null', {'per100ExtrasJson': 'null'}, server: false);
  for (final value in ['[]', '"text"', '42', '{bad', '{"sodium":null}']) {
    add(
      'extras-wrong-${jsonEncode(value)}',
      {'per100ExtrasJson': value},
      server: false,
      app: false,
    );
  }
  add('unknown-extra', {'per100ExtrasJson': '{"future":1}'}, server: false);
  add('duplicate-extra', {
    'per100ExtrasJson': '{"sodium":1,"sodium":2}',
  }, server: false);
  add('escaped-duplicate-extra', {
    'per100ExtrasJson': r'{"sodium":1,"\u0073odium":2}',
  }, server: false);
  final baseRaw = jsonEncode(_base());
  add(
    'duplicate-payload-name',
    {},
    raw: baseRaw.replaceFirst('"nameEn":', '"nameEn":"old","nameEn":'),
    server: false,
  );
  for (final escape in [r'\ud800', r'\udc00']) {
    add(
      'name-lone-$escape',
      {},
      raw: baseRaw.replaceFirst('"Synthetic food"', '"$escape"'),
      server: false,
    );
    add('alias-lone-$escape', {'aliasesJson': '["$escape"]'}, server: false);
  }
  for (final size in [
    PersonalFoodBounds.aliases,
    PersonalFoodBounds.aliases + 1,
  ]) {
    add(
      'aliases-count-$size',
      {
        'aliasesJson': jsonEncode([for (var i = 0; i < size; i++) 'alias$i']),
      },
      server: size <= PersonalFoodBounds.aliases,
      app: size <= PersonalFoodBounds.aliases,
    );
  }
  for (final size in [1, 79, 80, 81]) {
    add(
      'alias-supplementary-$size',
      {
        'aliasesJson': jsonEncode([
          if (size == 1) 'x' else '${'x' * (size - 2)}\u{1f34e}',
        ]),
      },
      server: size <= PersonalFoodBounds.name,
      app: size <= PersonalFoodBounds.name,
    );
  }
  add(
    'aliases-trim-duplicate',
    {'aliasesJson': '["alias"," alias "]'},
    server: false,
    app: false,
  );
  add('aliases-case-distinct', {'aliasesJson': '["alias","Alias"]'});
  final gtins = ['96385074', '036000291452', '4006381333931', '00012345600012'];
  for (final barcode in [...gtins, '96385075', '１２３４５６７８', ' 96385074']) {
    add(
      'gtin-$barcode',
      {
        'barcodesJson': jsonEncode([barcode]),
      },
      server: Gtin.isValid(barcode),
      app: Gtin.isValid(barcode),
    );
  }
  add(
    'duplicate-gtin',
    {'barcodesJson': '["96385074","96385074"]'},
    server: false,
    app: false,
  );
  // Synthetic check digits come from the real reference, not a second checksum.
  final manyGtins = <String>[
    for (var n = 0; n < 11; n++)
      for (var digit = 0; digit < 10; digit++)
        if (Gtin.isValid('${n.toString().padLeft(7, '0')}$digit'))
          '${n.toString().padLeft(7, '0')}$digit',
  ];
  for (final size in [10, 11]) {
    add(
      'gtin-count-$size',
      {'barcodesJson': jsonEncode(manyGtins.take(size).toList())},
      server: size <= PersonalFoodBounds.barcodes,
      app: size <= PersonalFoodBounds.barcodes,
    );
  }
  for (final entry in {
    'per100Kcal': PersonalFoodBounds.kcal,
    'per100ProteinG': PersonalFoodBounds.grams,
    'per100CarbsG': PersonalFoodBounds.grams,
    'per100FatG': PersonalFoodBounds.grams,
    'per100FiberG': PersonalFoodBounds.grams,
  }.entries) {
    for (final number in [
      0.0,
      entry.value,
      entry.value + 1,
      -0.1,
      1e-28,
      1e-29,
    ]) {
      final accepted = PersonalFoodBounds.acceptsNutrient(number, entry.value);
      add(
        '${entry.key}-$number',
        {entry.key: number},
        server: accepted,
        app: accepted,
      );
    }
  }
  for (final key in NutrientKey.values) {
    final max = key.unit == NutrientUnit.milligram
        ? PersonalFoodBounds.milligrams
        : PersonalFoodBounds.grams;
    for (final number in [0.0, max, max + 1, -0.1, 1e-28, 1e-29]) {
      final accepted = PersonalFoodBounds.acceptsNutrient(number, max);
      add(
        'extra-${key.code}-$number',
        {
          'per100ExtrasJson': jsonEncode({key.code: number}),
        },
        server: accepted,
        app: accepted,
      );
    }
  }
  for (final unit in PersonalFoodBounds.units) {
    add('unit-$unit', {
      'servingsJson': jsonEncode([
        {'unit': unit, 'amount': 1},
      ]),
      'entryServingUnit': unit,
      'entryServingAmount': 1,
    });
  }
  for (final amount in [0.0, 0.09, 0.1, 5000.0, 5000.1]) {
    final accepted =
        amount >= PersonalFoodBounds.minServing &&
        amount <= PersonalFoodBounds.maxServing;
    add(
      'serving-amount-$amount',
      {
        'servingsJson': jsonEncode([
          {'unit': 'piece', 'amount': amount},
        ]),
      },
      server: accepted,
      app: accepted,
    );
    add(
      'entry-amount-$amount',
      {'entryServingUnit': 'piece', 'entryServingAmount': amount},
      server: accepted,
      app: accepted,
    );
  }
  for (final value in [
    '[{"unit":"future","amount":1}]',
    '[{"unit":"piece"}]',
    '[{"unit":"piece","amount":1,"other":1}]',
    '[{"unit":"piece","amount":1},{"unit":"piece","amount":2}]',
  ]) {
    add(
      'servings-invalid-$value',
      {'servingsJson': value},
      server: false,
      app: false,
    );
  }
  add('duplicate-serving-key', {
    'servingsJson': '[{"unit":"piece","amount":1,"amount":2}]',
  }, server: false);
  for (final size in [10, 11]) {
    add(
      'servings-count-$size',
      {
        'servingsJson': jsonEncode([
          for (final unit in PersonalFoodBounds.units.take(size))
            {'unit': unit, 'amount': 1},
        ]),
      },
      server: size <= PersonalFoodBounds.servings,
      app: size <= PersonalFoodBounds.servings,
    );
  }
  add(
    'entry-unit-only',
    {'entryServingUnit': 'piece'},
    server: false,
    app: false,
  );
  add(
    'entry-amount-only',
    {'entryServingAmount': 1},
    server: false,
    app: false,
  );
  add(
    'entry-unknown-unit',
    {'entryServingUnit': 'future', 'entryServingAmount': 1},
    server: false,
    app: false,
  );
  for (final value in ['f', 'x' * 32, '', 'x' * 33, 'form1', 'form\n', 'ع']) {
    final accepted =
        value.isNotEmpty &&
        value.length <= PersonalFoodBounds.createdFrom &&
        RegExp(r'^[a-zA-Z]+$').hasMatch(value);
    add(
      'createdFrom-${jsonEncode(value)}',
      {'createdFrom': value},
      server: accepted,
      app: accepted,
    );
  }
  add('sanity-macrosTooHeavy', {'per100ProteinG': 106.0});
  add('sanity-kcalMismatch', {'per100Kcal': 900.0});

  final writers = <Map<String, Object?>>[];
  for (final fields in [
    <String, Object?>{},
    <String, Object?>{
      'nameEn': '  Synthetic food  ',
      'nameAr': ' طعام تجريبي ',
      'brand': ' Brand ',
      'aliasesJson': '[" Alias "]',
      'barcodesJson': jsonEncode(gtins),
      'per100ExtrasJson': jsonEncode({
        for (final k in NutrientKey.values) k.code: 1.0,
      }),
      'servingsJson': '[{"unit":"piece","amount":30.0}]',
      'entryServingUnit': 'cup',
      'entryServingAmount': 0.1,
      'basis': 'ml',
    },
  ]) {
    final input = {..._base(), ...fields};
    final draft = _draft(input);
    if (draft.validateWire() != null) {
      throw StateError('invalid writer fixture');
    }
    final id = 'writer-${writers.length}';
    final expected = {
      ...input,
      'nameEn': draft.names.en,
      'nameAr': draft.names.ar,
      'brand': draft.brand,
      'aliasesJson': draft.aliases.isEmpty ? null : jsonEncode(draft.aliases),
    };
    // The input declares a draft; the app test, not this generator, exercises
    // personalFoodColumns (including the previous-row preservation branch).
    add(id, expected);
    writers.add({'payloadId': id, 'draft': input});
  }
  return {
    'formatVersion': 1,
    'dartSdkVersion': Platform.version.split(' ').first,
    'provenance':
        'Synthetic only; generated with the repository-pinned Dart SDK. '
        'Run make gen-personal-food-vectors. App outcomes are declared, '
        'verified by personal_food_sync_vectors_test.dart.',
    'constants': {
      'name': PersonalFoodBounds.name,
      'brand': PersonalFoodBounds.brand,
      'aliases': PersonalFoodBounds.aliases,
      'barcodes': PersonalFoodBounds.barcodes,
      'servings': PersonalFoodBounds.servings,
      'kcal': PersonalFoodBounds.kcal,
      'grams': PersonalFoodBounds.grams,
      'milligrams': PersonalFoodBounds.milligrams,
      'minServing': PersonalFoodBounds.minServing,
      'maxServing': PersonalFoodBounds.maxServing,
      'createdFrom': PersonalFoodBounds.createdFrom,
      'jsonLength': PersonalFoodBounds.jsonLength,
    },
    'vocabularies': {
      'nutrients': {for (final k in NutrientKey.values) k.code: k.unit.code},
      'units': PersonalFoodBounds.units.toList(),
      'states': [for (final state in FoodState.values) state.code],
      'bases': [for (final basis in NutrientBasis.values) basis.unitCode],
    },
    'trimCodeUnits': trim,
    'strings': [
      for (final text in [
        '\ufeff x \u0085',
        'x\u200bx',
        'x' * 78 + '\u{1f34e}',
      ])
        {'input': text, 'length': text.length, 'trimmed': text.trim()},
    ],
    'payloads': payloads,
    'serverRejectsAppTolerates': asymmetric,
    'writers': writers,
    'domain': [
      for (final fields in [
        <String, Object?>{},
        <String, Object?>{'per100ProteinG': 106.0},
        <String, Object?>{'per100Kcal': 900.0},
      ])
        {
          'input': {..._base(), ...fields},
          'wireFailure': _draft({..._base(), ...fields}).validateWire()?.name,
          'formFailure': _draft({..._base(), ...fields}).validate()?.name,
        },
    ],
  };
}

Map<String, Object?> _base() => {
  'createdAtMs': 0,
  'origin': 'direct',
  'editedByUser': true,
  'nameEn': 'Synthetic food',
  'nameAr': null,
  'aliasesJson': null,
  'brand': null,
  'barcodesJson': null,
  'state': 'as_sold',
  'basis': 'g',
  'per100Kcal': 0.0,
  'per100ProteinG': 0.0,
  'per100CarbsG': 0.0,
  'per100FatG': 0.0,
  'per100FiberG': 0.0,
  'per100ExtrasJson': null,
  'servingsJson': null,
  'entryServingUnit': null,
  'entryServingAmount': null,
  'createdFrom': 'form',
};

PersonalFoodDraft _draft(Map<String, Object?> p) {
  Object? nested(String field) =>
      p[field] == null ? null : jsonDecode(p[field]! as String);
  final extras = nested('per100ExtrasJson') as Map<String, dynamic>? ?? {};
  return PersonalFoodDraft(
    names: FoodNames(p['nameEn']! as String, ar: p['nameAr'] as String?),
    brand: p['brand'] as String?,
    aliases: (nested('aliasesJson') as List<dynamic>? ?? []).cast<String>(),
    barcodes: (nested('barcodesJson') as List<dynamic>? ?? []).cast<String>(),
    state: FoodState.fromCode(p['state']! as String)!,
    basis: p['basis'] == 'ml' ? NutrientBasis.per100ml : NutrientBasis.per100g,
    per100: Nutrients(
      kcal: (p['per100Kcal']! as num).toDouble(),
      protein: (p['per100ProteinG']! as num).toDouble(),
      carbs: (p['per100CarbsG']! as num).toDouble(),
      fat: (p['per100FatG']! as num).toDouble(),
      fiber: (p['per100FiberG']! as num).toDouble(),
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
            p['entryServingUnit']! as String,
            (p['entryServingAmount']! as num).toDouble(),
          ),
    createdFrom: p['createdFrom']! as String,
  );
}

/// Stable JSON bytes shared by Dart and C# tests, independent of local paths.
String generatePersonalFoodVectors() =>
    '${const JsonEncoder.withIndent('  ').convert(personalFoodVectors())}\n';

/// Writes only the corpus; drift checking calls the in-memory function instead.
void main() {
  File.fromUri(
    Platform.script.resolve(
      '../../../contracts/testdata/sync/personal-food-validation-vectors.json',
    ),
  ).writeAsStringSync(generatePersonalFoodVectors());
}
