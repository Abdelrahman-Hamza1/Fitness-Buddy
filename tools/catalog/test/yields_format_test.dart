import 'dart:io';

import 'package:fb_catalog/fb_catalog.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

final String fixtures = p.join('test', 'fixtures');
final String schemaDir = p.join('..', '..', 'data', 'schema');

const _goodYields = '''
rows:
  - group: rice
    from: dry
    to: cooked
    factor: 2.8
    source: "USDA test"
''';

const _goodWords = '''
rows:
  - food: usda:rice_raw
    unit: piece
    g: 10
    range: [8, 12]
    source: "fixture"
''';

/// Writes the given YAML texts to a temp dir, loads the good fixtures plus
/// them, and returns every error as `file: path: message` text.
List<String> run({
  String? yields,
  String? words,
  String? selection,
  bool useGoodFiles = false,
}) {
  final dir = Directory.systemTemp.createTempSync('yield_fixture');
  addTearDown(() => dir.deleteSync(recursive: true));
  File? write(String name, String? text) {
    if (text == null) return null;
    return File(p.join(dir.path, name))..writeAsStringSync(text);
  }

  var sel = File(p.join(fixtures, 'selection.yaml'));
  if (selection != null) sel = write('selection.yaml', selection)!;
  final data = loadCatalog(
    schemaDir: schemaDir,
    selection: sel,
    extract: File(p.join(fixtures, 'extract.jsonl')),
    dishesDir: Directory(p.join(fixtures, 'good')),
    yields: write('yields.yaml', yields),
    portionWords: write('portion_words.yaml', words),
  );
  final report = validateCatalog(
    basics: data.basics,
    dishes: data.dishes,
    yields: data.yields,
    portionWords: data.portionWords,
  );
  return [
    for (final i in [...data.issues, ...report.errors])
      i.toString().replaceAll(dir.path, '<tmp>'),
  ];
}

String _yieldRow(String body) => 'rows:\n  - group: rice\n$body';

void expectError(List<String> errors, String contains) => expect(
  errors.any((e) => e.contains(contains)),
  isTrue,
  reason: 'wanted "$contains" in $errors',
);

void main() {
  test('good yields and portion words validate', () {
    expect(run(yields: _goodYields, words: _goodWords), isEmpty);
  });

  test('absent files are fine (not curated yet)', () {
    expect(run(), isEmpty);
  });

  group('yields', () {
    test('FD-060 yields schema rejects factor <= 0 and unknown states', () {
      for (final factor in ['0', '-2.5']) {
        final errors = run(
          yields: _yieldRow(
            '    from: dry\n    to: cooked\n    factor: $factor\n'
            '    source: x\n',
          ),
        );
        expectError(errors, '/rows/0/factor');
      }
      final state = run(
        yields: _yieldRow(
          '    from: boiled\n    to: cooked\n    factor: 2\n    source: x\n',
        ),
      );
      expectError(state, '/rows/0/from');
      final missing = run(
        yields: _yieldRow('    from: dry\n    to: cooked\n    factor: 2\n'),
      );
      expectError(missing, 'required property `source` is missing');
      final extra = run(
        yields: _yieldRow(
          '    from: dry\n    to: cooked\n    factor: 2\n    source: x\n'
          '    colour: red\n',
        ),
      );
      expectError(extra, 'unknown property `colour`');
    });

    test('from must differ from to', () {
      final errors = run(
        yields: _yieldRow(
          '    from: dry\n    to: dry\n    factor: 2\n    source: x\n',
        ),
      );
      expectError(errors, 'must differ from `from`');
    });

    test('duplicate and inverse rows are errors', () {
      const row =
          '  - group: rice\n    from: dry\n    to: cooked\n'
          '    factor: 2.8\n    source: x\n';
      expectError(run(yields: 'rows:\n$row$row'), 'duplicate yield row');
      const inverse =
          '  - group: rice\n    from: cooked\n    to: dry\n'
          '    factor: 0.35\n    source: x\n';
      expectError(
        run(yields: 'rows:\n$row$inverse'),
        'already given by the inverse row',
      );
    });

    test('Open Food Facts is rejected as a source', () {
      final errors = run(
        yields: _yieldRow(
          '    from: dry\n    to: cooked\n    factor: 2\n'
          '    source: https://world.openfoodfacts.org/x\n',
        ),
      );
      expectError(errors, 'Open Food Facts');
    });

    test('a basicʼs yield_group must have a row', () {
      final selection = File(p.join(fixtures, 'selection.yaml'))
          .readAsStringSync()
          .replaceFirst('state: dry\n', 'state: dry\n    yield_group: rice\n');

      expect(run(selection: selection, yields: _goodYields), isEmpty);
      final errors = run(
        selection: selection.replaceFirst(
          'yield_group: rice',
          'yield_group: rce',
        ),
        yields: _goodYields,
      );
      expectError(errors, 'yield_group `rce` has no row');
      // No yields file yet: the group check waits for the curator.
      expect(run(selection: selection), isEmpty);
    });

    test('FD-060 a basicʼs state must be a from/to state of its group', () {
      final selection = File(p.join(fixtures, 'selection.yaml'))
          .readAsStringSync()
          .replaceFirst('state: dry\n', 'state: raw\n    yield_group: rice\n');
      expectError(
        run(selection: selection, yields: _goodYields),
        'state `raw` is not a from/to state of yield group `rice`',
      );
    });

    test('a from == to row gives one error, not a false inverse error', () {
      final errors = run(
        yields: _yieldRow(
          '    from: dry\n    to: dry\n    factor: 2\n    source: x\n',
        ),
      );
      expect(errors, hasLength(1));
    });
  });

  group('portion words', () {
    String row(String body) => 'rows:\n  - food: usda:rice_raw\n$body';

    test('LC-051 portion word rows need g or ml, not both', () {
      final none = run(words: row('    unit: loaf\n    source: x\n'));
      expectError(none, 'needs `g` or `ml`, and not both');
      final both = run(
        words: row('    unit: loaf\n    g: 70\n    ml: 70\n    source: x\n'),
      );
      expectError(both, 'needs `g` or `ml`, and not both');
      expect(
        run(words: row('    unit: loaf\n    g: 70\n    source: x\n')),
        isEmpty,
      );
      expect(
        run(words: row('    unit: glass\n    ml: 250\n    source: x\n')),
        isEmpty,
      );
    });

    test('amounts must be positive', () {
      final errors = run(
        words: row('    unit: loaf\n    g: 0\n    source: x\n'),
      );
      expectError(errors, '/rows/0');
    });

    test('food must resolve to a basic or a dish', () {
      final errors = run(
        words:
            'rows:\n  - food: usda:nope\n    unit: piece\n    g: 5\n'
            '    source: x\n',
      );
      expectError(errors, '`usda:nope` does not resolve');
      expect(
        run(
          words:
              'rows:\n  - food: ref:test_pilaf/chicken\n    unit: plate\n'
              '    g: 300\n    source: x\n',
        ),
        isEmpty,
      );
      expectError(
        run(
          words:
              'rows:\n  - food: ref:test_pilaf/none\n    unit: plate\n'
              '    g: 300\n    source: x\n',
        ),
        'does not resolve',
      );
    });

    test('unit must be known (can is allowed ahead of A05)', () {
      expectError(
        run(words: row('    unit: bucket\n    g: 5\n    source: x\n')),
        'unknown unit `bucket`',
      );
      expect(
        run(words: row('    unit: can\n    ml: 330\n    source: x\n')),
        isEmpty,
      );
    });

    test('mass and volume codes are not portion-word units', () {
      for (final unit in ['g', 'kg', 'ml', 'l', 'oz', 'fl_oz']) {
        expectError(
          run(words: row('    unit: $unit\n    g: 5\n    source: x\n')),
          'is a mass or volume unit',
        );
      }
    });

    test('D5 a selection serving must agree with the portion word', () {
      String selection(String serving) =>
          File(p.join(fixtures, 'selection.yaml'))
              .readAsStringSync()
              .replaceFirst(
                'state: dry\n',
                'state: dry\n    servings: [{unit: piece, g: $serving}]\n',
              );
      expect(
        run(
          selection: selection('10'),
          words: row('    unit: piece\n    g: 10\n    source: x\n'),
        ),
        isEmpty,
      );
      expectError(
        run(
          selection: selection('12'),
          words: row('    unit: piece\n    g: 10\n    source: x\n'),
        ),
        'servings says 12.0 g but the portion word says 10.0 g',
      );
      expectError(
        run(
          selection: selection('12'),
          words: row('    unit: piece\n    ml: 12\n    source: x\n'),
        ),
        'portion word says 12.0 ml',
      );
      // Different units never conflict.
      expect(
        run(
          selection: selection('12'),
          words: row('    unit: loaf\n    g: 70\n    source: x\n'),
        ),
        isEmpty,
      );
    });

    test('range must contain the value and be ordered', () {
      expectError(
        run(
          words: row(
            '    unit: loaf\n    g: 70\n    range: [80, 90]\n    source: x\n',
          ),
        ),
        'outside its range',
      );
      expectError(
        run(
          words: row(
            '    unit: loaf\n    g: 70\n    range: [90, 60]\n    source: x\n',
          ),
        ),
        'low is above high',
      );
    });

    test('duplicate food + unit and OFF sources are errors', () {
      const r =
          '  - food: usda:rice_raw\n    unit: loaf\n    g: 70\n'
          '    source: x\n';
      expectError(run(words: 'rows:\n$r$r'), 'duplicate portion word');
      expectError(
        run(
          words: row(
            '    unit: loaf\n    g: 70\n'
            '    source: https://de.openfoodfacts.org/p\n',
          ),
        ),
        'Open Food Facts',
      );
    });
  });
}
