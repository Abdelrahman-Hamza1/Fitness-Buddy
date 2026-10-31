import 'dart:io';

import 'package:fb_catalog/fb_catalog.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

final String fixtures = p.join('test', 'fixtures');
final String schemaDir = p.join('..', '..', 'data', 'schema');

/// Loads and validates the good fixtures plus, optionally, one bad file.
/// Returns every error as `file: path: message` text, plus the report.
({List<String> errors, ValidationReport report, CatalogData data}) run({
  String? bad,
  String? selection,
}) {
  final dir = Directory.systemTemp.createTempSync('dish_fixture');
  addTearDown(() => dir.deleteSync(recursive: true));
  for (final f in Directory(p.join(fixtures, 'good')).listSync()) {
    if (f is File) f.copySync(p.join(dir.path, p.basename(f.path)));
  }
  if (bad != null) {
    File(p.join(fixtures, 'bad', '$bad.yaml'))
        .copySync(p.join(dir.path, '$bad.yaml'));
  }
  final data = loadCatalog(
    schemaDir: schemaDir,
    selection: File(selection ?? p.join(fixtures, 'selection.yaml')),
    extract: File(p.join(fixtures, 'extract.jsonl')),
    dishesDir: dir,
  );
  final report = validateCatalog(
    basics: data.basics,
    dishes: data.dishes,
    basicsLoaded: data.basicsLoaded,
  );
  return (
    errors: [
      for (final i in [...data.issues, ...report.errors])
        i.toString().replaceAll(dir.path, '<dishes>'),
    ],
    report: report,
    data: data,
  );
}

void expectFails(String bad, String contains, {String? at}) {
  final errors = run(bad: bad).errors;
  expect(errors, isNotEmpty, reason: '$bad should fail');
  expect(
    errors.every((e) => e.startsWith('<dishes>/$bad.yaml')),
    isTrue,
    reason: 'only the bad file may fail, got $errors',
  );
  expect(
    errors.any((e) => e.contains(contains) && (at == null || e.contains(at))),
    isTrue,
    reason: 'wanted "$contains"${at == null ? '' : ' at $at'} in $errors',
  );
}

void main() {
  group('good fixtures', () {
    test('FD-050 the full example dishes and the basics validate', () {
      final r = run();
      expect(r.errors, isEmpty);
      expect(r.data.dishes.map((d) => d.id), [
        'ref:test_bowl',
        'ref:test_pilaf',
      ]);
      expect(r.report.computed.keys, [
        'ref:test_bowl/standard',
        'ref:test_pilaf/chicken',
        'ref:test_pilaf/plain',
      ]);
    });

    test('FD-050 per-100 g of a fixture dish equals the hand calculation', () {
      // Whole pot: rice 300 g, chicken 400 g, oil 40 g; cooked weight 1000 g.
      //   kcal    = 300*3.6  + 400*2.0 + 40*8.84     = 1080 + 800 + 353.6
      //           = 2233.6      -> 223.36 per 100 g
      //   protein = 300*.07  + 400*.20               = 21 + 80   = 101 -> 10.1
      //   carbs   = 300*.80                          = 240       -> 24
      //   fat     = 300*.006 + 400*.13 + 40*1        = 1.8+52+40 = 93.8 -> 9.38
      //   fiber   = 300*.013                         = 3.9       -> 0.39
      //   sodium  = 300*.05 + 400*.8 + 40*.02        = 335.8 mg  -> 33.58
      final t = run().report.computed['ref:test_pilaf/chicken']!.typical;
      expect(t.kcal, 223.36);
      expect(t.protein, 10.1);
      expect(t.carbs, 24);
      expect(t.fat, 9.38);
      expect(t.fiber, 0.39);
      expect(t.extra(NutrientKey.sodium), 33.58);
    });

    test('FD-050 range: ingredient lows and highs bound the per-100 g', () {
      // Low: rice 280, chicken 350, oil 20 over the largest cooked weight
      // 1100 g: kcal = (1008 + 700 + 176.8) / 1100 * 100 = 171.35.
      // High: 320, 450, 60 over 950 g: (1152 + 900 + 530.4) / 950 * 100
      // = 271.83.
      final v = run().report.computed['ref:test_pilaf/chicken']!;
      expect(v.low.kcal, 171.35);
      expect(v.high.kcal, 271.83);
      expect(v.low.protein, 8.15);
      expect(v.low.kcal, lessThanOrEqualTo(v.typical.kcal));
      expect(v.typical.kcal, lessThanOrEqualTo(v.high.kcal));
      for (final id in ['ref:test_pilaf/chicken', 'ref:test_bowl/standard']) {
        final x = run().report.computed[id]!;
        expect(x.low.kcal, lessThanOrEqualTo(x.typical.kcal));
        expect(x.typical.kcal, lessThanOrEqualTo(x.high.kcal));
      }
    });

    test('FD-050 per_100g variant passes through unchanged', () {
      final v = run().report.computed['ref:test_pilaf/plain']!;
      expect(v.typical.kcal, 130);
      expect(v.typical.protein, 2.7);
      expect(v.typical.carbs, 28);
      expect(v.typical.fat, 0.3);
      expect(v.typical.fiber, 0.4);
      expect(v.typical.extra(NutrientKey.sodium), 1);
      expect(v.low, v.typical);
      expect(v.high, v.typical);
    });

    test('FD-050 a dish can be an ingredient of another dish', () {
      // 250 g of pilaf (223.36 kcal/100 g) + 5 g oil over 255 g:
      // (558.4 + 44.2) / 255 * 100 = 236.31.
      expect(
        run().report.computed['ref:test_bowl/standard']!.typical.kcal,
        236.31,
      );
    });
  });

  group('FD-050 bad dishes fail with their message', () {
    test(
      'no names.ar',
      () => expectFails(
        'no_names_ar',
        'required property `ar` is missing',
        at: '/names/ar',
      ),
    );
    test(
      'two default variants',
      () => expectFails(
        'two_defaults',
        'exactly one variant must be default, found 2',
        at: '/variants',
      ),
    );
    test(
      'recipe and per_100g together',
      () =>
          expectFails('recipe_and_per_100g', 'and not both', at: '/variants/0'),
    );
    test(
      'range lo > hi',
      () => expectFails(
        'range_low_above_high',
        'low is above high',
        at: '/variants/0/recipe/0/range',
      ),
    );
    test(
      'grams outside their range',
      () => expectFails(
        'grams_outside_range',
        'grams 300 is outside its range [100, 200]',
      ),
    );
    test(
      'empty sources',
      () => expectFails(
        'empty_sources',
        'needs at least 1 item',
        at: '/review/sources',
      ),
    );
    test(
      'ID grammar rejects uppercase',
      () => expectFails(
        'uppercase_id',
        'does not match the required format',
        at: '/id',
      ),
    );
    test(
      'ID grammar rejects a raw FDC number',
      () => expectFails(
        'fdc_number_ref',
        'does not match the required format',
        at: '/variants/0/recipe/0/food',
      ),
    );
    test(
      'recipe references must resolve',
      () => expectFails(
        'unresolved_ref',
        '`usda:no_such_food` does not resolve',
        at: '/variants/0/recipe/0/food',
      ),
    );
    test(
      'an unknown field is rejected (typos)',
      () => expectFails(
        'unknown_field',
        'unknown property `serving_size`',
        at: '/serving_size',
      ),
    );
    test(
      'an unknown state is rejected',
      () => expectFails('bad_state', 'enum violated boiled', at: '/state'),
    );
    test(
      'negative grams are rejected',
      () => expectFails(
        'negative_grams',
        'exclusiveMinimum',
        at: '/variants/0/recipe/0/grams',
      ),
    );
    test(
      'file name must match the id',
      () => expectFails(
        'file_name_mismatch',
        'file name must be some_other_slug.yaml',
      ),
    );
    test(
      'a dish that contains itself fails',
      () => expectFails('circular', 'circular recipe'),
    );
    test('an A -> B -> A recipe cycle fails', () {
      final dir = Directory.systemTemp.createTempSync('cycle');
      addTearDown(() => dir.deleteSync(recursive: true));
      String dish(String id, String other) =>
          File(p.join(fixtures, 'bad', 'circular.yaml'))
              .readAsStringSync()
              .replaceAll('ref:circular', id)
              .replaceFirst('food: $id,', 'food: $other,');
      File(p.join(dir.path, 'cycle_a.yaml'))
          .writeAsStringSync(dish('ref:cycle_a', 'ref:cycle_b'));
      File(p.join(dir.path, 'cycle_b.yaml'))
          .writeAsStringSync(dish('ref:cycle_b', 'ref:cycle_a'));
      final data = loadCatalog(
        schemaDir: schemaDir,
        selection: File(p.join(fixtures, 'selection.yaml')),
        extract: File(p.join(fixtures, 'extract.jsonl')),
        dishesDir: dir,
      );
      final report = validateCatalog(basics: data.basics, dishes: data.dishes);
      final errors = [...data.issues, ...report.errors].join('\n');
      expect(errors, contains('circular recipe'));
    });
    test(
      'broken YAML names the file',
      () => expectFails('invalid_yaml', 'not valid YAML'),
    );
  });

  group('rules from the plan', () {
    test('C-5 a dish citing an openfoodfacts URL fails validate', () {
      expectFails(
        'off_source',
        'Open Food Facts is not allowed',
        at: '/review/sources/0',
      );
      expectFails(
        'off_nutrient_source',
        'Open Food Facts is not allowed',
        at: '/variants/0/nutrient_source',
      );
    });

    test('FD-012 a dish whose numbers fail sanity fails validate', () {
      expectFails('sanity_fail', 'sanity fail: ref:sanity_fail/only');
    });

    test('FD-012 sanity_override with a reason passes and is reported', () {
      final r = run(bad: 'sanity_override');
      expect(r.errors, isEmpty);
      expect(r.report.overrides.single.toString(), contains('waived'));
      expect(
        r.report.overrides.single.toString(),
        contains('a made-up value on purpose'),
      );
    });

    test('FD-004 duplicate normalized name in one language fails', () {
      // "duplicate_name" uses مقلوبه, the test pilaf مقلوبة (same key).
      final errors = run(bad: 'duplicate_name').errors;
      expect(errors, hasLength(1));
      expect(errors.single, contains('duplicate ar name "مقلوبة"'));
      expect(errors.single, contains('"مقلوبه" of ref:duplicate_name'));
      expect(errors.single, contains('/names/ar/0'));
    });
  });

  group('selection', () {
    test('a selection entry without an extract line fails validate', () {
      final dir = Directory.systemTemp.createTempSync('selection');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File(p.join(dir.path, 'selection.yaml'))
        ..writeAsStringSync(
          '${File(p.join(fixtures, 'selection.yaml')).readAsStringSync()}'
          '  - id: usda:lentils_dry\n'
          '    fdc_id: 1004\n'
          '    state: dry\n'
          '    names: {en: [Lentils]}\n',
        );
      final errors = run(selection: file.path).errors;
      expect(
        errors.single,
        contains('usda:lentils_dry has no line in the extract'),
      );
    });

    test('FD-050 the selection schema rejects a bad id with its path', () {
      final dir = Directory.systemTemp.createTempSync('selection');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File(p.join(dir.path, 'selection.yaml'))
        ..writeAsStringSync(
          'foods:\n'
          '  - id: usda:Rice Raw\n'
          '    fdc_id: 1\n'
          '    state: dry\n'
          '    names: {en: [Rice]}\n',
        );
      final errors = run(selection: file.path).errors;
      expect(errors.first, contains('selection.yaml: /foods/0/id'));
      expect(errors.first, contains('usda:Rice Raw'));
    });

    test('#66 a selection that fails its schema is the only error', () {
      final dir = Directory.systemTemp.createTempSync('selection');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File(p.join(dir.path, 'selection.yaml'))
        ..writeAsStringSync(
          File(p.join(fixtures, 'selection.yaml'))
              .readAsStringSync()
              .replaceFirst('fdc_id: 1001', 'fdc_id: "not a number"'),
        );
      final result = run(selection: file.path);
      expect(result.data.basicsLoaded, isFalse);
      expect(result.errors, isNotEmpty);
      expect(
        result.errors.where((e) => e.contains('does not resolve')),
        isEmpty,
        reason: "the dishes' usda: lines must not repeat the root cause",
      );
      expect(result.errors.first, contains('selection.yaml'));
    });

    test('#66 a valid selection counts as loaded', () {
      expect(run().data.basicsLoaded, isTrue);
    });

    test('FD-004 a basic and a dish may not share a name', () {
      final dir = Directory.systemTemp.createTempSync('selection');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File(p.join(dir.path, 'selection.yaml'))
        ..writeAsStringSync(
          File(p.join(fixtures, 'selection.yaml'))
              .readAsStringSync()
              .replaceFirst('ar: ["رز"]', 'ar: ["مقلوبه"]'),
        );
      expect(
        run(selection: file.path).errors.single,
        contains('duplicate ar name "مقلوبة"'),
      );
    });
  });

  group('cli', () {
    test('validate prints per-100 g and exits 0 for good data', () async {
      final out = StringBuffer();
      final err = StringBuffer();
      final code = await runCatalog(
        [
          'validate',
          '--schema-dir',
          schemaDir,
          '--selection',
          p.join(fixtures, 'selection.yaml'),
          '--extract',
          p.join(fixtures, 'extract.jsonl'),
          '--dishes',
          p.join(fixtures, 'good'),
        ],
        out: out,
        err: err,
      );
      expect(code, 0, reason: '$err');
      expect(out.toString(), contains('ref:test_pilaf/chicken  223.36 kcal'));
    });

    test('validate exits 1 and names file and path for bad data', () async {
      final out = StringBuffer();
      final err = StringBuffer();
      final dir = Directory.systemTemp.createTempSync('cli');
      addTearDown(() => dir.deleteSync(recursive: true));
      File(p.join(fixtures, 'bad', 'no_names_ar.yaml'))
          .copySync(p.join(dir.path, 'no_names_ar.yaml'));
      final code = await runCatalog(
        [
          'validate',
          '--schema-dir',
          schemaDir,
          '--selection',
          p.join(fixtures, 'selection.yaml'),
          '--extract',
          p.join(fixtures, 'extract.jsonl'),
          '--dishes',
          dir.path,
        ],
        out: out,
        err: err,
      );
      expect(code, 1);
      expect(err.toString(), contains('no_names_ar.yaml: /names/ar:'));
    });
  });
}
