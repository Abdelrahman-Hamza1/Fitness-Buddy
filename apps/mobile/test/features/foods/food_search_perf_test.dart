import 'dart:async';
import 'dart:io';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:fb_mobile/core/catalog/catalog.dart';
import 'package:fb_mobile/core/changes/change_set_applier.dart';
import 'package:fb_mobile/core/events/domain_event_bus.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/foods/data/food_catalog_repository.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/catalog/support/catalog_support.dart';
import '../../core/db/support/db_support.dart';
import 'support/search_benchmark.dart';

void main() {
  test('FD-020 dense long typo plus common token p95 <50 ms', () async {
    final sql = StringBuffer();
    for (var i = 0; i < 600; i++) {
      final a = String.fromCharCode(97 + i % 26);
      final b = String.fromCharCode(97 + (i ~/ 26) % 26);
      final word = 'abcdefghijkl$a$b';
      sql.writeln(
        'INSERT INTO names VALUES '
        "('usda:rice_white_long_grain_cooked','en',"
        "'rice $word','rice $word',0);",
      );
    }
    final (_, catalog) = fixtureCatalog(extraSql: sql.toString());
    final service = FoodSearchService(FoodCatalogRepository(catalog));
    addTearDown(service.dispose);
    await service.updateHistory([]);
    await service.indexReady;
    final times = <int>[];
    for (var i = 0; i < 35; i++) {
      final timer = Stopwatch()..start();
      final result = await service.search('rice abcdefghijxlzz');
      expect(result.rows, isNotEmpty);
      if (i >= 5) times.add(timer.elapsedMicroseconds);
    }
    final ms = p95(times);
    // ignore: avoid_print, content-free benchmark timing.
    print('A07 dense long typo: p95 ${ms.toStringAsFixed(2)} ms');
    expect(ms, lessThan(50));
  }, tags: ['perf']);

  final real = File('assets/catalog/catalog.db');
  for (final scaled in [false, true]) {
    for (final size in [(5500, 300), (16500, 600)]) {
      test(
        'FD-020 A07 perf search ${scaled ? 'x8' : 'real'} '
        '${size.$1}/${size.$2}',
        () async {
          final root = tempDir().path;
          final pack = scaled ? '$root/scaled.db' : real.absolute.path;
          if (scaled) scalePack(real.absolute.path, pack);
          final db = backgroundDatabase(root, catalog: FixedPack(pack));
          final catalog = OfflineCatalog(db);
          final service = FoodSearchService(FoodCatalogRepository(catalog));
          addTearDown(service.dispose);
          final ids = await db
              .customSelect('SELECT id FROM catalog.foods ORDER BY id')
              .get();
          await seedHistory(
            db,
            size.$1,
            size.$2,
            ids.map((r) => r.read<String>('id')).take(size.$2).toList(),
          );
          final diary = DiaryRepository(db);
          await service.updateHistory(await diary.watchFoodHistory().first);
          await service.indexReady;
          final result = await searchBenchmark(service);
          // ignore: avoid_print, benchmark output is content-free timing data.
          print(
            'A07 search ${scaled ? 'x8' : 'real'} ${size.$1}/${size.$2}: '
            'p95 ${result.toStringAsFixed(2)} ms',
          );
          expect(result, lessThan(50));
          if (size.$1 == 16500) {
            final refresh = await historyBenchmark(diary, service);
            // ignore: avoid_print, content-free timing data.
            print(
              'A07 history ${scaled ? 'x8' : 'real'} 16500/600: '
              'p95 ${refresh.toStringAsFixed(2)} ms',
            );
            expect(refresh, lessThan(50));
          }
        },
        tags: ['perf'],
        skip: !real.existsSync() ? 'Build catalog-pack first' : false,
      );
    }
  }
  test(
    'FD-020 PA11 A07 perf cold fuzzy index real and x8 distinct vocabulary',
    () async {
      final db = backgroundDatabase(
        tempDir().path,
        catalog: FixedPack(real.absolute.path),
      );
      final keys = await OfflineCatalog(db).vocabularyKeys();
      for (final scale in [1, 8]) {
        final words = {
          for (var i = 0; i < scale; i++)
            for (final key in keys) ...mutateVocabulary(key, i).split(' '),
        }.toList();
        final result = await measureIndex(words);
        // ignore: avoid_print, benchmark output is content-free counts/timing.
        print(
          'A07 fuzzy x$scale: ${words.length} words, ${result.keys} '
          'keys, d2=${result.two}, ${result.ms.toStringAsFixed(2)} '
          'ms, ${(result.bytes / 1048576).toStringAsFixed(2)} '
          'MiB retained',
        );
        expect(result.ms, lessThan(1500));
        expect(result.bytes, greaterThan(0));
        expect(result.bytes, lessThan(32 * 1048576));
      }
    },
    tags: ['perf'],
    skip: !real.existsSync() ? 'Build catalog-pack first' : false,
  );

  test(
    'AI-048 PA7 A07 perf 30 keystrokes during 5 logs <150 ms',
    () async {
      final db = backgroundDatabase(
        tempDir().path,
        catalog: FixedPack(real.absolute.path),
      );
      final service = FoodSearchService(
        FoodCatalogRepository(OfflineCatalog(db)),
      );
      addTearDown(service.dispose);
      await seedHistory(db, 16500, 600, ['usda:pita_white']);
      final diary = DiaryRepository(db);
      await service.updateHistory(await diary.watchFoodHistory().first);
      await service.indexReady;
      final clock = ManualClock(DateTime.utc(2026, 10, 22, 12));
      final events = DomainEventBus();
      addTearDown(events.close);
      final ids = SequenceIdGenerator();
      final applier = ChangeSetApplier(
        db: db,
        tables: db.syncedTables,
        handlers: (db) => [DiaryOpHandler(db)],
        clock: clock,
        ids: ids,
        deviceId: () async => testDevice,
        events: events,
      );
      final undo = UndoStack(revert: applier.revert, clock: clock);
      addTearDown(undo.dispose);
      final log = LogFood(
        apply: applier.apply,
        undoStack: undo,
        clock: clock,
        ids: ids,
      );
      final choice = (await FoodChoiceLoader(
        service.repository,
        () => service.history,
      ).load(FoodChoiceRef(FoodRef.catalog('usda:pita_white', version: '6'))))!;
      final container = ProviderContainer(
        overrides: [foodSearchServiceProvider.overrideWith((ref) => service)],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        foodSearchControllerProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);
      final controller = container.read(foodSearchControllerProvider.notifier);
      // Warm the existing write path before measuring interactive use.
      final warm = await log(
        choice: choice,
        input: Quantity(1, 'loaf'),
        date: LocalDate(2026, 10, 22),
      );
      await undo.undo((warm as FoodLogged).undoEntryId);
      final initialHistory = Completer<void>();
      final latest = Completer<void>();
      final historySub = diary.watchFoodHistory().listen((h) async {
        await service.updateHistory(h);
        if (!initialHistory.isCompleted) initialHistory.complete();
      });
      addTearDown(historySub.cancel);
      await initialHistory.future;
      final resultSub = container.listen(foodSearchControllerProvider, (
        _,
        next,
      ) {
        if (!latest.isCompleted &&
            next.query == 'pita' &&
            next.results?.rows.firstOrNull?.choice.lastUsed?.uses == 32) {
          latest.complete();
        }
      });
      addTearDown(resultSub.close);
      final timer = Stopwatch()..start();
      final writes = [
        for (var i = 0; i < 5; i++)
          log(
            choice: choice,
            input: Quantity(1, 'loaf'),
            date: LocalDate(2026, 10, 22),
          ),
      ];
      for (var i = 0; i < 30; i++) {
        controller.setQuery(i == 29 ? 'pita' : 'pi${'t' * (i % 3)}');
      }
      await Future.wait(writes);
      await latest.future;
      await controller.settle();
      final ms = timer.elapsedMicroseconds / 1000;
      // ignore: avoid_print, benchmark output is content-free timing data.
      print('A07 typing burst: ${ms.toStringAsFixed(2)} ms');
      expect(
        container
            .read(foodSearchControllerProvider)
            .results!
            .rows
            .first
            .choice
            .lastUsed!
            .uses,
        32,
      );
      expect(ms, lessThan(150));
    },
    tags: ['perf'],
    skip: !real.existsSync() ? 'Build catalog-pack first' : false,
  );
}
