import 'dart:io';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/foods/presentation/unit_labels.dart';
import 'package:fb_mobile/l10n/gen/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../../core/catalog/support/catalog_support.dart';
import '../../../core/db/support/db_support.dart';

/// Every distinct serving unit code of the pack at [path].
Set<String> packUnitCodes(String path) {
  final db = sqlite3.open(path, mode: OpenMode.readOnly);
  try {
    return {
      for (final row in db.select('SELECT DISTINCT unit_code FROM servings'))
        row['unit_code'] as String,
    };
  } finally {
    db.close();
  }
}

void main() {
  final l10n = AppLocalizationsEn();

  void expectWords(Iterable<String> codes) {
    for (final code in codes) {
      expect(
        knownUnitLabel(l10n, code, 2),
        isNotNull,
        reason: 'unit "$code" has no ARB label',
      );
    }
  }

  test('LC-011 D8 every unit code of the fixture pack has its own label', () {
    final codes = packUnitCodes(writeFixturePack('${tempDir().path}/pack.db'));
    expect(codes, isNotEmpty);
    expectWords(codes);
  });

  test('LC-011 D8 every unit code of the bundled pack has its own label', () {
    final pack = File('assets/catalog/catalog.db');
    if (!pack.existsSync()) {
      markTestSkipped('no bundled pack: run `make catalog-pack`');
      return;
    }
    final codes = packUnitCodes(pack.absolute.path);
    expect(codes, isNotEmpty);
    expectWords(codes);
  });

  test('LC-011 D8 every unit the sheet can offer has a label', () {
    expectWords([
      ...UnitOptions.servingPriority,
      for (final u in MassUnit.values) u.code,
      for (final u in VolumeUnit.values) u.code,
      for (final u in PortionUnit.values) u.code,
    ]);
  });

  test('LC-011 D8 an unknown code falls back to "portion"', () {
    expect(knownUnitLabel(l10n, 'handful', 1), isNull);
    expect(unitLabel(l10n, 'handful', 1), 'portion');
  });
}
