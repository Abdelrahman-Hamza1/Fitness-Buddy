import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:fb_mobile/core/catalog/catalog.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/connection.dart';
import 'package:fb_mobile/core/db/database_location.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/foods/data/food_catalog_repository.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:patrol/patrol.dart';

import '../test/features/foods/support/search_benchmark.dart'
    show benchmarkQueries, historyBenchmark, p95, seedHistory;

/// Median in milliseconds (nearest rank).
double _median(List<int> micros) {
  final sorted = List.of(micros)..sort();
  return sorted[(sorted.length * .5).ceil() - 1] / 1000;
}

/// The A07 D14 search benchmark on the device (A07 §5, exit criterion "search
/// p95 < 50 ms on the A55"), run by `make test-it`. The host benchmark
/// (`test/features/foods/food_search_perf_test.dart`) is the asserted gate;
/// this prints the device numbers (median and p95, numbers only), which the
/// owner records from the A55 (backlog item). The same 22 queries and the
/// same bodies as the host test, on the pack bundled in the APK and history of
/// 5,500 entries / 300 foods and 16,500 / 600. The x8 scaled pack of the host
/// test is left out: it needs the build-time pack file next to the test.
///
/// The only assertions are generous sanity bounds so an emulator or a slow
/// CI runner doesn't flake.
void main() {
  patrolTest(
    'A07 perf: search over the bundled pack on the device: median and p95 of '
    '22 queries x 10 runs after a warm-up, 5,500 and 16,500 history entries',
    ($) async {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      // createTemp: a nested path that doesn't exist fails on Android.
      final cache = await getTemporaryDirectory();

      for (final (entries, distinct) in [(5500, 300), (16500, 600)]) {
        final root = await cache.createTemp('fb_food_perf');
        addTearDown(() => root.deleteSync(recursive: true));
        final installer = CatalogPackInstaller(
          root: () async => root.path,
          loadAsset: (key) async =>
              (await rootBundle.load(key)).buffer.asUint8List(),
        );
        final db = AppDatabase(
          openUserDatabase(
            DatabaseLocation(
              profileKey: 'perf',
              root: () async => root.path,
              temporary: () async => root.path,
            ),
          ),
          catalog: installer,
        );
        addTearDown(db.close);
        await installAndAttachCatalog(installer, db);
        expect(await db.isCatalogAttached(), isTrue);

        final catalog = OfflineCatalog(db);
        addTearDown(catalog.dispose);
        final service = FoodSearchService(FoodCatalogRepository(catalog));
        addTearDown(service.dispose);
        final ids = await db
            .customSelect('SELECT id FROM catalog.foods ORDER BY id')
            .get();
        await seedHistory(
          db,
          entries,
          distinct,
          ids.map((r) => r.read<String>('id')).take(distinct).toList(),
        );
        final diary = DiaryRepository(db);

        final index = Stopwatch()..start();
        await service.updateHistory(await diary.watchFoodHistory().first);
        await service.indexReady;
        final firstBuild = index.elapsedMilliseconds;

        // Warm-up, then 10 runs of every query, as the host benchmark.
        for (final query in benchmarkQueries) {
          await service.search(query);
        }
        final micros = <int>[];
        for (var i = 0; i < 10; i++) {
          for (final query in benchmarkQueries) {
            final timer = Stopwatch()..start();
            await service.search(query);
            micros.add(timer.elapsedMicroseconds);
          }
        }
        debugPrint(
          'A07 search device real $entries/$distinct: '
          '${micros.length} runs, median ${_median(micros).toStringAsFixed(2)}'
          ' ms, p95 ${p95(micros).toStringAsFixed(2)} ms '
          '(first index build and history load $firstBuild ms)',
        );
        // Sanity only; the budget (p95 < 50 ms) is checked by reading the
        // number on the A55.
        expect(p95(micros), lessThan(1000));

        if (entries == 16500) {
          final refresh = await historyBenchmark(diary, service);
          debugPrint(
            'A07 history refresh device 16500/600: '
            'p95 ${refresh.toStringAsFixed(2)} ms',
          );
          expect(refresh, lessThan(2000));
        }
      }
    },
  );
}
