import 'dart:io';

import 'package:fb_catalog/fb_catalog.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Builds a tiny FDC dataset on disk. [foods] is fdc_id -> description,
/// [nutrients] is fdc_id -> {nutrient id -> amount}.
Directory dataset(
  Directory root,
  String name, {
  Map<int, String> foods = const {},
  Map<int, Map<int, double>> nutrients = const {},
  List<String> portions = const [],
  List<String> extraNutrientRows = const [],
}) {
  final dir = Directory(p.join(root.path, name))..createSync();
  void write(String file, String content) =>
      File(p.join(dir.path, file)).writeAsStringSync(content);
  write(
    'nutrient.csv',
    '"id","name","unit_name","nutrient_nbr","rank"\n'
        '"1008","Energy","KCAL","208","300"\n'
        '"2047","Energy (Atwater General)","KCAL","957","280"\n'
        '"2048","Energy (Atwater Specific)","KCAL","958","290"\n'
        '"1003","Protein","G","203","600"\n'
        '"1004","Total lipid (fat)","G","204","800"\n'
        '"1005","Carbohydrate, by difference","G","205","1110"\n'
        '"1050","Carbohydrate, by summation","G","205.2","1120"\n'
        '"1079","Fiber, total dietary","G","291","1200"\n'
        '"2000","Sugars, Total","G","269","1510"\n'
        '"1063","Sugars, Total NLEA","G","269.3","1500"\n'
        '"1258","Fatty acids, total saturated","G","606","9700"\n'
        '"1257","Fatty acids, total trans","G","605","15400"\n'
        '"1093","Sodium, Na","MG","307","5800"\n'
        '"1253","Cholesterol","MG","601","15700"\n'
        '"1018","Alcohol, ethyl","G","221","18200"\n'
        '"1051","Water","G","255","100"\n',
  );
  write(
    'food.csv',
    '"fdc_id","data_type","description","food_category_id","publication_date"\n'
        '${foods.entries.map(_foodRow).join('\n')}\n',
  );
  final rows = [
    for (final f in nutrients.entries)
      for (final n in f.value.entries)
        '"${f.key}${n.key}","${f.key}","${n.key}","${n.value}"',
    ...extraNutrientRows,
  ];
  write(
    'food_nutrient.csv',
    '"id","fdc_id","nutrient_id","amount"\n${rows.join('\n')}\n',
  );
  write(
    'measure_unit.csv',
    '"id","name"\n"1000","cup"\n"9999","undetermined"\n',
  );
  write(
    'food_portion.csv',
    '"id","fdc_id","seq_num","amount","measure_unit_id","portion_description",'
        '"modifier","gram_weight"\n${portions.join('\n')}\n',
  );
  return dir;
}

String _foodRow(MapEntry<int, String> e) =>
    '"${e.key}","x","${e.value}","1","2019-04-01"';

const core = {1003: 10.0, 1004: 5.0, 1005: 20.0, 1079: 3.0};

void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('fb_catalog_test'));
  tearDown(() => tmp.deleteSync(recursive: true));

  Future<List<UsdaFood>> run(
    Map<int, Map<int, double>> nutrients, {
    bool fiberZero = false,
    Map<int, String>? foods,
    List<String> extra = const [],
    List<String> portions = const [],
  }) {
    final sr = dataset(
      tmp,
      'sr_legacy',
      foods: foods ?? {for (final id in nutrients.keys) id: 'Food $id'},
      nutrients: nutrients,
      extraNutrientRows: extra,
      portions: portions,
    );
    final fd = dataset(tmp, 'foundation');
    return importUsda(
      datasetDirs: {'sr_legacy': sr, 'foundation': fd},
      selection: [
        for (final id in nutrients.keys)
          SelectionEntry(id: 'usda:f$id', fdcId: id, fiberZero: fiberZero),
      ],
    );
  }

  test(
    'FD-002 importer maps FDC nutrient ids to the core five and extras',
    () async {
      final foods = await run({
        1: {
          ...core,
          1008: 180.0,
          2000: 4.0,
          1258: 1.5,
          1257: 0.1,
          1093: 300.0,
          1253: 20.0,
          1018: 0.5,
          1051: 70.0, // known but unmapped: ignored
        },
      });
      expect(foods.single.nutrients, {
        'kcal': 180.0,
        'protein_g': 10.0,
        'fat_g': 5.0,
        'carbs_g': 20.0,
        'fiber_g': 3.0,
        'sugar_g': 4.0,
        'saturated_fat_g': 1.5,
        'trans_fat_g': 0.1,
        'sodium_mg': 300.0,
        'cholesterol_mg': 20.0,
        'alcohol_g': 0.5,
      });
      expect(foods.single.dataset, 'sr_legacy');
    },
  );

  test('energy falls back 1008 -> 2048 -> 2047', () async {
    final foods = await run({
      1: {...core, 1008: 100.0, 2048: 110.0, 2047: 120.0},
      2: {...core, 2048: 110.0, 2047: 120.0},
      3: {...core, 2047: 120.0},
    });
    expect([for (final f in foods) f.nutrients['kcal']], [100.0, 110.0, 120.0]);
    expect([for (final f in foods) f.energyNutrientId], [1008, 2048, 2047]);
  });

  test('carbs fall back 1005 -> 1050', () async {
    final foods = await run({
      1: {...core, 1008: 1.0, 1050: 99.0},
      2: {1003: 1.0, 1004: 1.0, 1079: 1.0, 1008: 1.0, 1050: 17.0},
    });
    expect(foods[0].nutrients['carbs_g'], 20.0);
    expect(foods[1].nutrients['carbs_g'], 17.0);
    expect(foods[1].carbsNutrientId, 1050);
  });

  test('sugar falls back 2000 -> 1063', () async {
    final foods = await run({
      1: {...core, 1008: 1.0, 1063: 2.5},
    });
    expect(foods.single.nutrients['sugar_g'], 2.5);
  });

  test('missing fiber fails unless fiber_zero', () async {
    final noFiber = {1003: 1.0, 1004: 1.0, 1005: 1.0, 1008: 1.0};
    await expectLater(
      run({1: noFiber}),
      throwsA(
        isA<ImportException>().having(
          (e) => e.message,
          'message',
          allOf(
            contains('fiber_g'),
            contains('usda:f1'),
            contains('fiber_zero'),
          ),
        ),
      ),
    );
    final foods = await run({1: noFiber}, fiberZero: true);
    expect(foods.single.nutrients['fiber_g'], 0);
    expect(foods.single.fiberZero, isTrue);
  });

  test(
    'a missing core nutrient other than fiber fails even with fiber_zero',
    () async {
      await expectLater(
        run({
          1: {1003: 1.0, 1005: 1.0, 1008: 1.0},
        }, fiberZero: true),
        throwsA(isA<ImportException>()),
      );
    },
  );

  test('unknown nutrient id fails with its id', () async {
    await expectLater(
      run(
        {
          1: {...core, 1008: 1.0},
        },
        extra: ['"x","1","7777","3"'],
      ),
      throwsA(
        isA<ImportException>().having(
          (e) => e.message,
          'message',
          contains('7777'),
        ),
      ),
    );
  });

  test('a mapped nutrient missing from nutrient.csv fails', () async {
    final sr = dataset(tmp, 'sr_legacy');
    File(p.join(sr.path, 'nutrient.csv'))
        .writeAsStringSync('"id","name","unit_name"\n"1008","Energy","KCAL"\n');
    final fd = dataset(tmp, 'foundation');
    await expectLater(
      importUsda(
        datasetDirs: {'sr_legacy': sr, 'foundation': fd},
        selection: const [],
      ),
      throwsA(isA<ImportException>()),
    );
  });

  test('a nutrient with a different unit than expected fails', () async {
    final sr = dataset(tmp, 'sr_legacy');
    final f = File(p.join(sr.path, 'nutrient.csv'));
    f.writeAsStringSync(
      f.readAsStringSync().replaceFirst(
        '"1003","Protein","G"',
        '"1003","Protein","MG"',
      ),
    );
    final fd = dataset(tmp, 'foundation');
    await expectLater(
      importUsda(
        datasetDirs: {'sr_legacy': sr, 'foundation': fd},
        selection: const [],
      ),
      throwsA(
        isA<ImportException>().having(
          (e) => e.message,
          'message',
          allOf(contains('1003'), contains('unit MG'), contains('expected G')),
        ),
      ),
    );
  });

  test('an FDC id in both datasets fails', () async {
    final sr = dataset(
      tmp,
      'sr_legacy',
      foods: {7: 'Rice'},
      nutrients: {
        7: {...core, 1008: 1.0},
      },
    );
    final fd = dataset(
      tmp,
      'foundation',
      foods: {7: 'Rice'},
      nutrients: {
        7: {...core, 1008: 1.0},
      },
    );
    await expectLater(
      importUsda(
        datasetDirs: {'sr_legacy': sr, 'foundation': fd},
        selection: const [SelectionEntry(id: 'usda:rice', fdcId: 7)],
      ),
      throwsA(
        isA<ImportException>().having(
          (e) => e.message,
          'message',
          allOf(contains('FDC 7'), contains('both sr_legacy and foundation')),
        ),
      ),
    );
  });

  test('a food that is in no dataset fails', () async {
    final sr = dataset(tmp, 'sr_legacy');
    await expectLater(
      importUsda(
        datasetDirs: {'sr_legacy': sr},
        selection: const [SelectionEntry(id: 'usda:x', fdcId: 5)],
      ),
      throwsA(
        isA<ImportException>().having(
          (e) => e.message,
          'message',
          contains('5'),
        ),
      ),
    );
  });

  test('portions are read with their unit and sorted', () async {
    final foods = await run(
      {
        1: {...core, 1008: 1.0},
      },
      portions: [
        '"1","1","1","1","1000","","chopped","120"',
        '"2","1","2","1","9999","","slice","30"',
        '"3","1","3","1","1000","","","0"', // zero grams: dropped
      ],
    );
    expect(
      foods.single.portions.map((e) => '${e.amount} ${e.label} ${e.grams}'),
      ['1.0 cup chopped 120.0', '1.0 slice 30.0'],
    );
  });

  test('extract is sorted and deterministic (two runs, same bytes)', () async {
    final nutrients = {
      2: {...core, 1008: 2.0},
      1: {...core, 1008: 1.0},
    };
    final a = encodeExtract(await run(nutrients));
    tmp
      ..deleteSync(recursive: true)
      ..createSync();
    final b = encodeExtract((await run(nutrients)).reversed.toList());
    expect(a, b);
    expect(a.split('\n').first, contains('"usda:f1"'));
    expect(a.endsWith('}\n'), isTrue);
  });

  group('selection', () {
    File write(String yaml) =>
        File(p.join(tmp.path, 'sel.yaml'))..writeAsStringSync(yaml);

    test('reads entries', () {
      final entries = loadSelection(
        write(
          'foods:\n  - {id: usda:a_b, fdc_id: 1}\n'
          '  - {id: usda:c, fdc_id: 2, fiber_zero: true}\n',
        ),
      );
      expect(entries.map((e) => e.id), ['usda:a_b', 'usda:c']);
      expect(entries[1].fiberZero, isTrue);
    });

    test('rejects a bad id, duplicates and a missing list', () {
      for (final yaml in [
        'foods:\n  - {id: ref:a, fdc_id: 1}\n',
        'foods:\n  - {id: usda:A, fdc_id: 1}\n',
        'foods:\n  - {id: usda:a, fdc_id: 1}\n  - {id: usda:a, fdc_id: 2}\n',
        'foods:\n  - {id: usda:a, fdc_id: 1}\n  - {id: usda:b, fdc_id: 1}\n',
        'foods:\n  - {id: usda:a, fdc_id: x}\n',
        'nope: 1\n',
      ]) {
        expect(
          () => loadSelection(write(yaml)),
          throwsA(isA<SelectionException>()),
          reason: yaml,
        );
      }
    });
  });

  test('cli: import-usda writes the extract; bad usage exits 64', () async {
    final sr = dataset(
      tmp,
      'sr_legacy',
      foods: {1: 'Rice'},
      nutrients: {
        1: {...core, 1008: 130.0},
      },
    );
    dataset(tmp, 'foundation');
    File(p.join(tmp.path, 'sel.yaml'))
        .writeAsStringSync('foods:\n  - {id: usda:rice, fdc_id: 1}\n');
    final out = StringBuffer();
    final err = StringBuffer();
    final target = p.join(tmp.path, 'out', 'extract.jsonl');
    final code = await runCatalog(
      [
        'import-usda',
        '--selection',
        p.join(tmp.path, 'sel.yaml'),
        '--usda-dir',
        p.dirname(sr.path),
        '--out',
        target,
      ],
      out: out,
      err: err,
    );
    expect(code, 0, reason: err.toString());
    expect(File(target).readAsStringSync(), contains('"usda:rice"'));
    expect(await runCatalog(['bogus'], out: out, err: err), 64);
  });
}
