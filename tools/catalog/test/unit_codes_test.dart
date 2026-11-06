import 'dart:io';

import 'package:fb_catalog/fb_catalog.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('FD-003 LC-011 every catalog unit code has its own word in the app '
      '(knownUnitLabel), so none falls back to "portion" (#88)', () {
    final labels = File(
      p.join(
        '..',
        '..',
        'apps',
        'mobile',
        'lib',
        'core',
        'l10n',
        'domain_labels.dart',
      ),
    ).readAsStringSync();
    final start = labels.indexOf('String? knownUnitLabel(');
    expect(start, isNonNegative);
    final body = labels.substring(start, labels.indexOf('_ => null', start));
    final appCodes = {
      for (final m in RegExp("'([a-z_]+)' =>").allMatches(body)) m[1]!,
    };
    expect(catalogUnitCodes.difference(appCodes), isEmpty);
  });

  test('FD-003 the vocabulary covers every unit the domain knows and the '
      'catalog portion extras (#88)', () {
    expect(catalogUnitCodes, containsAll(extraPortionUnits));
    for (final u in PortionUnit.values) {
      expect(catalogUnitCodes, contains(u.code), reason: u.code);
    }
    for (final code in ['g', 'kg', 'ml', 'l', 'cup', 'tbsp', 'tsp']) {
      expect(catalogUnitCodes, contains(code), reason: code);
    }
  });

  test('FD-003 a basic serving with an unknown unit fails validation '
      '(#88)', () {
    final nutrients = Nutrients(
      kcal: 100,
      protein: 5,
      carbs: 15,
      fat: 2.2,
      fiber: 1,
    );
    BasicFood basic(String unit) => BasicFood(
      file: 'usda_selection.yaml',
      index: 0,
      id: 'usda:test_food',
      names: const {
        'en': ['Test food'],
      },
      state: FoodState.raw,
      nutrients: nutrients,
      servings: {unit: 30},
    );
    final bad = validateCatalog(basics: [basic('handful')], dishes: const []);
    expect(
      bad.errors.map((e) => e.toString()),
      contains(contains('unknown unit `handful`')),
    );
    final good = validateCatalog(basics: [basic('slice')], dishes: const []);
    expect(
      good.errors.where((e) => e.toString().contains('unknown unit')),
      isEmpty,
    );
  });
}
