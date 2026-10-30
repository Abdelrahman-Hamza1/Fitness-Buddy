import 'dart:io';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/catalog/catalog.dart';
import 'package:flutter_test/flutter_test.dart';

import '../db/support/db_support.dart';
import 'support/catalog_support.dart';

void main() {
  test('FD-023 search finds a fixture basic by EN, AR and Arabizi', () async {
    final (_, catalog) = fixtureCatalog();
    for (final q in ['white rice cooked', 'رز مطبوخ']) {
      final ids = [for (final f in await catalog.search(q)) f.id];
      expect(ids, contains('usda:rice_white_long_grain_cooked'), reason: q);
    }
    final ar = await catalog.search('رز');
    expect(ar, isNotEmpty, reason: 'short Arabic query uses the exact key');
    final ruz = await catalog.search('ruz');
    expect(ruz, isNotEmpty, reason: 'short Arabizi query uses the exact key');
  });

  test('WO-001 exercise aliases never become food search results', () async {
    final (_, catalog) = fixtureCatalog(
      extraSql: '''
      INSERT INTO exercises VALUES
        ('ex:barbell_bench_press', 'Barbell bench press', 'weight_reps',
         'barbell', 'chest', 'triceps', 2);
      INSERT INTO names (target_id, lang, name, key, is_display) VALUES
        ('ex:barbell_bench_press', 'en', 'BB bench', 'b bench', 1);
      INSERT INTO names_fts (rowid, key)
        SELECT rowid, key FROM names WHERE target_id = 'ex:barbell_bench_press';
    ''',
    );
    expect(await catalog.search('BB bench'), isEmpty);
    expect(await catalog.byId('ex:barbell_bench_press'), isNull);
    expect(await catalog.search('rice'), isNotEmpty);
  });

  test('FD-023 search finds a fixture dish by EN, AR and Arabizi', () async {
    final (_, catalog) = fixtureCatalog();
    for (final q in ['mloukhiyeh', 'ملوخية', 'molokhia']) {
      final ids = [for (final f in await catalog.search(q)) f.id];
      expect(
        ids.any((id) => id.startsWith('ref:mloukhiyeh_rice/')),
        isTrue,
        reason: q,
      );
    }
  });

  test(
    'search: nothing for an empty query, and no pack means no hits',
    () async {
      final (_, catalog) = fixtureCatalog();
      expect(await catalog.search('   '), isEmpty);
      expect(await catalog.search('zzzzqq'), isEmpty);

      final db = memoryDatabase();
      final none = OfflineCatalog(db);
      expect(await none.search('rice'), isEmpty);
      expect(await none.byId('usda:rice_white_long_grain_cooked'), isNull);
      expect(await none.yieldFactors(), isEmpty);
      expect(await none.packVersion(), isNull);
    },
  );

  test(
    'byId returns a basic with Nutrients, FoodState, servings and badge',
    () async {
      final (_, catalog) = fixtureCatalog();
      final rice = (await catalog.byId('usda:rice_white_long_grain_cooked'))!;
      expect(rice.kind, CatalogFoodKind.basic);
      expect(rice.state, FoodState.cooked);
      expect(rice.basis, NutrientBasis.per100g);
      expect(rice.nutrients.kcal, 130);
      expect(rice.nutrients.extras[NutrientKey.sodium], 1);
      expect(rice.badge, CatalogBadge.database);
      expect(rice.packVersion, 1);
      expect(rice.yieldGroup, 'rice');
      expect(rice.servingUnits.map((s) => s.code), contains('cup'));
      expect(rice.measures.servingUnits['cup']!.amount, 158);
    },
  );

  test('byId returns a variant with the reference badge; a dish gives its '
      'default variant', () async {
    final (_, catalog) = fixtureCatalog();
    final variant = (await catalog.byId('ref:mloukhiyeh_rice/chicken'))!;
    expect(variant.kind, CatalogFoodKind.variant);
    expect(variant.dishId, 'ref:mloukhiyeh_rice');
    expect(variant.badge, CatalogBadge.reference);
    expect(variant.isDraft, isFalse); // released as ai-verified (A17/A18)
    final viaDish = await catalog.byId('ref:mloukhiyeh_rice');
    expect(viaDish, isNotNull);
    expect(viaDish!.dishId, 'ref:mloukhiyeh_rice');
    expect(await catalog.byId('usda:nope'), isNull);
  });

  test('byBarcode returns null on an empty barcode table and the food when '
      'present', () async {
    final (_, empty) = fixtureCatalog();
    expect(await empty.byBarcode('6281000000000'), isNull);
    expect(await empty.byBarcode(''), isNull);

    final (_, withCode) = fixtureCatalog(
      extraSql:
          'INSERT INTO barcodes VALUES '
          "('6281000000000', 'usda:rice_white_long_grain_raw')",
    );
    final food = await withCode.byBarcode('6281000000000');
    expect(food?.id, 'usda:rice_white_long_grain_raw');
    expect(await withCode.byBarcode('1'), isNull);
  });

  test('FD-060 yields from the pack feed YieldConverter', () async {
    final (_, catalog) = fixtureCatalog();
    final factors = await catalog.yieldFactors();
    expect(factors.any((f) => f.group == 'rice'), isTrue);
    final note = YieldConverter(factors).convert(
      amount: Mass.grams(200),
      group: 'rice',
      from: FoodState.dry,
      to: FoodState.cooked,
    );
    expect(note, isNotNull);
    expect(note!.toAmount.grams, greaterThan(400));
  });

  test('info gives the pack version and the attribution entries', () async {
    final (_, catalog) = fixtureCatalog(
      extraSql: '''
UPDATE meta SET value = '[{"id":"usda_fdc","name":"USDA","licence":"CC0",
"url":"https://fdc.nal.usda.gov/","credit":"USDA credit","used_for":"Basics"}]'
WHERE key = 'attribution'
''',
    );
    final info = (await catalog.info())!;
    expect(info.packVersion, 1);
    expect(info.attribution.single.id, 'usda_fdc');
    expect(info.attribution.single.credit, 'USDA credit');
    expect(await OfflineCatalog(memoryDatabase()).info(), isNull);
  });

  test('a corrupt pack reads as absent and is reported once', () async {
    final dir = tempDir().path;
    final pack = '$dir/catalog-1.db';
    File(pack).writeAsBytesSync(List.filled(4096, 7));
    final errors = <Object>[];
    final db = fileDatabase(
      '$dir/user.db',
      catalog: FixedPack(pack),
      onCatalogError: (error, _) => errors.add(error),
    );
    final catalog = OfflineCatalog(db, onError: errors.add);
    expect(await catalog.search('rice'), isEmpty);
    expect(await catalog.byId('usda:rice_white_long_grain_cooked'), isNull);
    expect(await catalog.byBarcode('123'), isNull);
    expect(await catalog.info(), isNull);
    // Garbage bytes fail at attach (reported there) or at the first read
    // (reported by the catalog): once either way.
    expect(errors, hasLength(1));
  });
}
