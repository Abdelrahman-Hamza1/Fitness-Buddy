import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show QueryExecutor, QueryInterceptor, Value;
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/catalog/catalog.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/foods/data/food_catalog_repository.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/catalog/support/catalog_support.dart';
import '../../core/db/support/db_support.dart';
import '../diary/support/diary_fixtures.dart';
import '../diary/support/diary_harness.dart';

const riceId = 'usda:rice_white_long_grain_cooked';
const rawId = 'usda:rice_white_long_grain_raw';

FoodSearchService fixtureService({String extraSql = ''}) {
  final (_, catalog) = fixtureCatalog(extraSql: extraSql);
  final service = FoodSearchService(FoodCatalogRepository(catalog));
  addTearDown(service.dispose);
  return service;
}

Future<void> ready(
  FoodSearchService service, [
  List<FoodHistoryItem> history = const [],
]) async {
  await service.updateHistory(history);
  await service.indexReady;
}

FoodHistoryItem historyOf(
  String id, {
  String name = 'Snapshot rice',
  int uses = 1,
  double amount = 100,
  double input = 100,
  String unit = 'g',
  NutrientBasis basis = NutrientBasis.per100g,
  FoodRefKind kind = FoodRefKind.catalog,
}) => FoodHistoryItem(
  food: EntryFood(
    ref: FoodRef(kind, id: id, version: 'old-pack'),
    names: FoodNames(name),
    per100: Nutrients(kcal: 100, protein: 2, carbs: 10, fat: 1, fiber: 0),
    provenance: Provenance(
      source: FoodSource.reference,
      assumptions: ['old log'],
    ),
  ),
  amount: EntryAmount(
    input: Quantity(input, unit),
    amount: amount,
    basis: basis,
  ),
  uses: uses,
  lastUsedHlc: Hlc.parse(hlcAt(uses)),
);

void main() {
  test(
    'FD-020 controller keeps stale rows on failure and recovers on retry',
    () async {
      final (_, catalog) = fixtureCatalog();
      final repository = RecoverableRepository(catalog);
      final service = FoodSearchService(repository);
      addTearDown(service.dispose);
      await ready(service);
      final container = ProviderContainer(
        overrides: [foodSearchServiceProvider.overrideWithValue(service)],
      );
      addTearDown(container.dispose);
      final sub = container.listen(foodSearchControllerProvider, (_, _) {});
      addTearDown(sub.close);
      final controller = container.read(foodSearchControllerProvider.notifier)
        ..setQuery('rice');
      await controller.settle();
      final original = container.read(foodSearchControllerProvider).results;
      repository.fail = true;
      controller.setQuery('rice white');
      await controller.settle();
      final failed = container.read(foodSearchControllerProvider);
      expect(failed.error, isNotNull);
      expect(failed.results, same(original));
      expect(failed.resultsFor, 'rice');
      expect(failed.query, 'rice white');
      repository.fail = false;
      controller.setQuery(failed.query);
      await controller.settle();
      final retried = container.read(foodSearchControllerProvider);
      expect(retried.error, isNull);
      expect(retried.resultsFor, 'rice white');
      expect(retried.results!.rows, isNotEmpty);
    },
  );

  test('FD-020 FD-023 pack refresh overlapping same-food history '
      'is atomic', () async {
    final (db, catalog) = fixtureCatalog();
    final repository = MetadataBlockingRepository(catalog);
    final service = FoodSearchService(repository);
    addTearDown(service.dispose);
    await ready(service, [historyOf(riceId)]);
    final root = tempDir().path;
    final replacement = writeFixturePack(
      '$root/replacement.db',
      extraSql:
          "UPDATE meta SET value='2' WHERE key='catalog_version'; "
          "UPDATE foods SET name_en='Replacement rice', kcal=777 "
          "WHERE id='$riceId'; "
          'INSERT INTO names VALUES '
          "('$riceId','en','Novelalias','novelalias',0);",
    );
    repository.block = true;
    await db.reattachCatalog(replacement);
    await repository.started.future;
    final refresh = service.updateHistory([historyOf(riceId, uses: 9)]);
    repository.release.complete();
    await refresh;
    await service.indexReady;
    final row = (await service.recent()).rows.single;
    expect(row.nameEn, 'Replacement rice');
    expect(row.choice.per100.kcal, 777);
    expect(row.choice.lastUsed!.uses, 9);
    expect(service.fuzzyIndex!.isWordPrefix('novelalias'), isTrue);
    repository.historyOnly = true;
    expect(
      (await service.search('novelalias')).rows.single.choice.ref.id,
      riceId,
    );
    await db.reattachCatalog(null);
    await service.updateHistory([historyOf(riceId, uses: 10)]);
    expect(service.packReady, isFalse);
  });

  test('FD-022 LC-010 imperial search rows open on the sheet default '
      'portion', () async {
    final service = fixtureService();
    await ready(service, [historyOf(riceId)]);
    final metric = (await service.search('rice')).rows.first;
    final imperial = (await service.search(
      'rice',
      system: UnitSystem.imperial,
    )).rows.first;
    expect(
      imperial.defaultPortion,
      imperial.choice.defaultPortion(system: UnitSystem.imperial),
    );
    expect(metric.defaultPortion, metric.choice.defaultPortion());
  });

  test('FD-023 recent merges dish variants and sorts by latest use', () async {
    final service = fixtureService();
    final variants = (await service.repository.foodsByIds([
      'ref:mloukhiyeh_rice',
    ]))['ref:mloukhiyeh_rice']!;
    await ready(service, [
      historyOf(variants.first.id, uses: 10),
      historyOf(variants.last.id, uses: 30),
      historyOf(riceId, uses: 20),
    ]);
    final rows = (await service.recent()).rows;
    expect(rows.length, 2);
    expect(rows.first.choice.ref.id, variants.last.id);
    expect(rows.last.choice.ref.id, riceId);
  });

  test('FD-020 PA11 index rebuilds on history vocabulary '
      'and pack detach off search path', () async {
    final (db, catalog) = fixtureCatalog();
    final service = FoodSearchService(FoodCatalogRepository(catalog));
    addTearDown(service.dispose);
    await ready(service);
    final first = service.fuzzyIndex;
    await service.updateHistory([
      historyOf('retired', name: 'Uniquevocabulary'),
    ]);
    await service.indexReady;
    expect(identical(first, service.fuzzyIndex), isFalse);
    expect(service.fuzzyIndex!.isWordPrefix('uniquevocab'), isTrue);
    final changed = service.changes.first;
    await db.reattachCatalog(null);
    await changed;
    await service.indexReady;
    expect(service.packReady, isFalse);
    expect(service.fuzzyIndex!.isWordPrefix('uniquevocab'), isTrue);
    expect(
      (await service.search('uniquevocabulary')).rows.single.choice.ref.id,
      'retired',
    );
  });

  test(
    'FD-021 snapshot exact strength wins over the same food partial pack match',
    () async {
      final service = fixtureService();
      await ready(service, [historyOf(riceId, name: 'Secret rice')]);
      final row = (await service.search('secret rice')).rows.first;
      expect(row.choice.ref.id, riceId);
      expect(row.tier, SourceTier.history);
    },
  );

  test(
    'FD-020 fuzzy retrieves rcie without a shared trigram and chiken breast',
    () async {
      final service = fixtureService();
      // Before the isolate completes, ordinary search is still usable.
      await service.updateHistory([]);
      expect((await service.search('rice')).rows, isNotEmpty);
      await service.indexReady;
      expect(
        (await service.search('rcie')).rows.first.nameEn,
        contains('Rice'),
      );
      expect(
        (await service.search('rcie white')).rows.first.nameEn,
        contains('Rice'),
      );
      expect(
        (await service.search('chiken breast')).rows.first.nameEn,
        contains('Chicken'),
      );
    },
  );

  test('#224 FD-021 "finjan qahwa" and "قهوة عربية" rank Arabic coffee above '
      'the coffee basics (rows copied from the real pack)', () async {
    final service = fixtureService(
      extraSql: File('test/fixtures/catalog_coffee.sql').readAsStringSync(),
    );
    await ready(service);
    for (final query in [
      'finjan qahwa',
      'قهوة عربية',
      'arabic coffee',
      'qahwa arabiyeh',
    ]) {
      final rows = (await service.search(query)).rows;
      expect(rows, isNotEmpty, reason: query);
      expect(
        rows.first.choice.ref.id,
        startsWith('ref:arabic_coffee'),
        reason: '$query: got ${rows.map((r) => r.choice.ref.id).toList()}',
      );
    }
    // The generic word still finds the generic basic first.
    expect(
      (await service.search('qahwa')).rows.first.choice.ref.id,
      'usda:coffee_brewed',
    );
  });

  test('FD-021 PA10 uncapped exact behind 600 prefixes '
      'and 400 substring rows', () async {
    final sql = StringBuffer();
    for (var i = 0; i < 650; i++) {
      sql.writeln(
        "INSERT INTO names VALUES ('$rawId','en','rice $i','rice $i',0);",
      );
    }
    for (var i = 0; i < 400; i++) {
      sql.writeln(
        "INSERT INTO names VALUES ('$rawId','en','priceless "
        "$i','priceles $i',0);",
      );
    }
    sql
      ..writeln("INSERT INTO names VALUES ('$riceId','en','rice','rice',0);")
      ..writeln("INSERT INTO names_fts(names_fts) VALUES ('rebuild');");
    final (_, catalog) = fixtureCatalog(extraSql: sql.toString());
    final rows = await catalog.candidateNames(const CandidateQuery('rice'));
    expect(rows.where((r) => r.pass == CandidatePass.prefix).length, 500);
    expect(
      rows.any((r) => r.targetId == riceId && r.pass == CandidatePass.exact),
      isTrue,
    );
    final service = FoodSearchService(FoodCatalogRepository(catalog));
    addTearDown(service.dispose);
    await ready(service);
    expect((await service.search('rice')).rows.first.choice.ref.id, riceId);
  });

  test('FD-020 PA1 prefix survives 300 token rows and '
      'token cap orders word hits', () async {
    final sql = StringBuffer();
    for (var i = 0; i < 350; i++) {
      sql.writeln(
        "INSERT INTO names VALUES ('$rawId','en','white "
        "rice $i','white rice $i',0);",
      );
    }
    sql
      ..writeln(
        "INSERT INTO names VALUES ('$riceId','en', "
        "'rice white special','rice white special',0);",
      )
      ..writeln("INSERT INTO names_fts(names_fts) VALUES ('rebuild');");
    final (_, catalog) = fixtureCatalog(extraSql: sql.toString());
    final rows = await catalog.candidateNames(
      const CandidateQuery('rice white'),
    );
    expect(
      rows.any((r) => r.targetId == riceId && r.pass == CandidatePass.prefix),
      isTrue,
    );
    expect(
      rows
          .where((r) => r.pass == CandidatePass.token)
          .every((r) => r.wordHits == 2),
      isTrue,
    );
    expect(
      (await catalog.candidateNames(const CandidateQuery('rice')))
          .any((r) => r.targetId == riceId && r.pass == CandidatePass.prefix),
      isTrue,
    );
  });

  test('FD-021 PA1 history beyond target 60 and snapshot-only '
      'names survive', () async {
    final sql = StringBuffer();
    // Distinct actual foods, not just duplicate names on one target.
    for (var i = 0; i < 85; i++) {
      sql
        ..writeln(
          "INSERT INTO foods SELECT 'test:$i',kind,source,source_ref, "
          "dish_id,'White rice "
          "number $i',name_ar,state,basis,kcal,protein_g,carbs_g, "
          'fat_g,fiber_g,kcal_low,kcal_high,protein_low, '
          'protein_high,carbs_low,carbs_high,fat_low,fat_high, '
          'fiber_low,fiber_high,extras_json,density_g_per_ml, '
          'yield_group,verified,review_status,sanity, '
          'catalog_version '
          "FROM foods WHERE id='$riceId';",
        )
        ..writeln(
          "INSERT INTO names VALUES ('test:$i','en','White rice "
          "number $i','rice number $i',1);",
        );
    }
    final service = fixtureService(extraSql: sql.toString());
    await ready(service, [historyOf('test:84', name: 'Rice secret snapshot')]);
    expect(
      (await service.search('rice')).rows
          .any((r) => r.choice.ref.id == 'test:84'),
      isTrue,
    );
    final secret = (await service.search('secret snapshot')).rows.single;
    expect(secret.choice.ref.id, 'test:84');
    expect(secret.tier, SourceTier.history);
    expect(secret.choice.per100.kcal, 130);
  });

  test('FD-021 PA5 dish aliases expand all variants and '
      'used variant represents dish', () async {
    final service = fixtureService();
    final foods = (await service.repository.foodsByIds([
      'ref:mloukhiyeh_rice',
    ]))['ref:mloukhiyeh_rice']!;
    expect(foods.length, greaterThan(1));
    expect(foods.where((f) => f.isDefaultVariant).length, 1);
    final used = foods.firstWhere((f) => !f.isDefaultVariant);
    await ready(service, [historyOf(used.id)]);
    for (final q in ['mloukhiyeh', 'ملوخية', 'molokhia']) {
      final rows = (await service.search(q)).rows;
      expect(rows.length, 1, reason: q);
      expect(rows.single.choice.ref.id, used.id);
      expect(rows.single.choice.measures.servingUnits, contains('plate'));
    }
  });

  test('FD-023 PA4 MAX row keeps latest full snapshot, '
      'version, provenance; excludes tombstones/estimates', () async {
    final db = memoryDatabase();
    final slot = DefaultSlots.all.first.id;
    await insertEntries(db, [
      entryRow(1, date: '$today', slotId: slot, wall: 50).copyWith(
        foodId: const Value('same'),
        nameEn: const Value('Latest'),
        foodVersion: const Value('retired-version'),
        isEstimate: const Value(true),
        estimateRangeJson: const Value('{"lowKcal":80,"highKcal":120}'),
        inputAmount: const Value(2),
        inputUnit: const Value('glass'),
        amount: const Value(500),
        amountBasis: const Value('ml'),
        per100ExtrasJson: const Value('{"sugar":4}'),
        source: const Value('reference'),
        assumptionsJson: const Value('["historic"]'),
        editedByUser: const Value(true),
      ),
      entryRow(
        2,
        date: '$today',
        slotId: slot,
      ).copyWith(foodId: const Value('same')),
      entryRow(3, date: '$today', slotId: slot, deletedAt: 1),
      entryRow(4, date: '$today', slotId: slot, foodKind: 'estimate'),
    ]);
    final h = (await DiaryRepository(db).watchFoodHistory().first).single;
    expect(h.food.names.en, 'Latest');
    expect(h.food.ref.version, 'retired-version');
    expect(h.food.provenance.source, FoodSource.reference);
    expect(h.food.provenance.assumptions, ['historic']);
    expect(h.food.provenance.range!.lowKcal, 80);
    expect(h.food.provenance.range!.highKcal, 120);
    expect(h.food.per100.extras[NutrientKey.sugar], 4);
    expect(h.editedByUser, isTrue);
    expect(h.uses, 2);
    expect(h.derivedServing!.amount, 250);
    expect(h.derivedServing!.basis, NutrientBasis.per100ml);
  });

  test(
    'FD-023 retired ID without pack has snapshot metadata only and ml serving',
    () async {
      final service = FoodSearchService(
        FoodCatalogRepository(OfflineCatalog(memoryDatabase())),
      );
      addTearDown(service.dispose);
      final h = historyOf(
        'retired',
        name: 'Milk snapshot',
        unit: 'glass',
        input: 1,
        amount: 250,
        basis: NutrientBasis.per100ml,
      );
      await ready(service, [h]);
      final result = await service.search('milk');
      expect(result.packReady, isFalse);
      final choice = (await FoodChoiceLoader(
        service.repository,
        () => service.history,
      ).load(result.rows.single.choiceRef))!;
      expect(choice.ref.version, 'old-pack');
      expect(choice.state, isNull);
      expect(choice.siblings, isEmpty);
      expect(choice.sanity, isNull);
      expect(choice.badge, FoodSource.reference);
      expect(
        choice.measures.resolve(Quantity(1, 'glass')),
        isA<Resolved>().having((r) => r.amount, 'ml', 250),
      );
    },
  );

  test('AI-048 FD-010 DY-003 LogFood direct write, history '
      'emission, undo; ml snapshot preserved', () async {
    final harness = DiaryHarness();
    final stack = UndoStack(
      revert: harness.applier.revert,
      clock: harness.clock,
    );
    addTearDown(stack.dispose);
    final command = LogFood(
      apply: harness.applier.apply,
      undoStack: stack,
      clock: harness.clock,
      ids: harness.ids,
    );
    final diary = DiaryRepository(harness.db);
    final emissions = <List<FoodHistoryItem>>[];
    final sub = diary.watchFoodHistory().listen(emissions.add);
    addTearDown(sub.cancel);
    final h = historyOf(
      'retired',
      name: 'Milk',
      unit: 'glass',
      input: 1,
      amount: 250,
      basis: NutrientBasis.per100ml,
    );
    final result = await command(
      choice: historyChoice(h),
      input: Quantity(1, 'glass'),
      date: LocalDate(2026, 10, 1),
      slotId: DefaultSlots.all.last.id,
    );
    expect(result, isA<FoodLogged>());
    expect((result as FoodLogged).slotId, DefaultSlots.all.last.id);
    final row = (await harness.db.select(harness.db.diaryEntries).get()).single;
    expect(row.localDate, '2026-10-01');
    expect(row.amount, 250);
    expect(row.amountBasis, 'ml');
    expect(row.foodVersion, 'old-pack');
    expect(row.origin, 'direct');
    expect(row.source, 'reference');
    expect(row.assumptionsJson, '["old log"]');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(emissions.last.single.food.ref.id, 'retired');
    expect(await stack.undo(result.undoEntryId), UndoOutcome.undone);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(emissions.last, isEmpty);
  });

  test('FD-060 FD-062 PA12 compatible rice switch keeps '
      'typed amount, no assumptions', () async {
    final service = fixtureService();
    await ready(service);
    final choice = (await FoodChoiceLoader(
      service.repository,
      () => [],
    ).load(FoodChoiceRef(FoodRef.catalog(riceId, version: '1'))))!;
    expect(choice.siblings.map((f) => f.id), contains(rawId));
    final harness = DiaryHarness();
    final stack = UndoStack(
      revert: harness.applier.revert,
      clock: harness.clock,
    );
    addTearDown(stack.dispose);
    final choiceRef = FoodChoiceRef(choice.ref);
    final container = ProviderContainer(
      overrides: [
        foodChoiceProvider(choiceRef).overrideWith((ref) async => choice),
        unitSystemProvider.overrideWith(
          (ref) => Stream.value(UnitSystem.metric),
        ),
        foodSlotsProvider.overrideWith(
          (ref, _) => Stream.value(DefaultSlots.all),
        ),
        clockProvider.overrideWithValue(harness.clock),
        logFoodProvider.overrideWith(
          (ref) => LogFood(
            apply: harness.applier.apply,
            undoStack: stack,
            clock: harness.clock,
            ids: harness.ids,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final provider = foodAmountControllerProvider(choiceRef, today);
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);
    await container.read(provider.future);
    final controller = container.read(provider.notifier);
    final explicitSlot = DefaultSlots.all.last.id;
    final routeProvider = foodAmountControllerProvider(
      choiceRef,
      today,
      slotId: explicitSlot,
    );
    final routeSub = container.listen(routeProvider, (_, _) {});
    addTearDown(routeSub.close);
    expect((await container.read(routeProvider.future)).slotId, explicitSlot);
    controller.setAmount('0');
    expect(container.read(provider).requireValue.canAdd, isFalse);
    expect(await controller.submit(), isA<FoodLogFailed>());
    controller.setAmount('incomplete');
    expect(container.read(provider).requireValue.canAdd, isFalse);
    controller
      ..setAmount('100')
      ..setUnit('unknown');
    expect(container.read(provider).requireValue.canAdd, isFalse);
    controller.setUnit('g');
    expect(container.read(provider).requireValue.canAdd, isTrue);
    expect(controller.switchState('unrelated'), isFalse);
    expect(controller.switchState(rawId), isTrue);
    expect(container.read(provider).requireValue.input, Quantity(100, 'g'));
    expect(
      container.read(provider).requireValue.yieldNote!.toAmount.grams,
      closeTo(280, 0.01),
    );
    expect(await controller.submit(), isA<FoodLogged>());
    final row = (await harness.db.select(harness.db.diaryEntries).get()).single;
    expect(row.foodId, rawId);
    expect(row.amount, 100);
    expect(row.inputAmount, 100);
    expect(row.inputUnit, 'g');
    expect(row.assumptionsJson, anyOf(isNull, '[]'));
    expect(row.slotId, container.read(provider).requireValue.slotId);
    final history = await DiaryRepository(harness.db).watchFoodHistory().first;
    final reopened = (await FoodChoiceLoader(
      service.repository,
      () => history,
    ).load(FoodChoiceRef(FoodRef.catalog(rawId, version: '1'))))!;
    expect(
      DefaultPortion.choose(
        reopened.measures,
        lastUsed: reopened.lastUsed!.amount.input,
      ),
      Quantity(100, 'g'),
    );
    await harness.apply([
      UpdateDiaryEntry(
        row.id,
        row.version,
        EntryPatch(
          amount: EntryAmount(
            input: Quantity(125, 'g'),
            amount: 125,
            basis: NutrientBasis.per100g,
          ),
        ),
      ),
    ]);
    final edited =
        (await harness.db.select(harness.db.diaryEntries).get()).single;
    expect(edited.inputAmount, 125);
    expect(edited.amount, 125);
  });

  test('FD-020 D7 original-first preserves numeric names, '
      'carries quantity otherwise', () async {
    final service = fixtureService(
      extraSql: "INSERT INTO names VALUES ('$riceId','en','7 Up','7 up',0);",
    );
    await ready(service);
    expect((await service.search('7 Up')).carried, isNull);
    final result = await service.search('2 rice');
    expect(result.carried!.amount, 2);
    expect(result.rows.first.defaultPortion.amount, 2);
  });

  test(
    'FD-020 PA7 typing has one running and one pending, last query wins',
    () async {
      final service = fixtureService();
      await ready(service);
      final repository = BlockingRepository(service.repository.catalog);
      final blocking = FoodSearchService(repository);
      addTearDown(blocking.dispose);
      await ready(blocking);
      final container = ProviderContainer(
        overrides: [foodSearchServiceProvider.overrideWith((ref) => blocking)],
      );
      addTearDown(container.dispose);
      final sub = container.listen(foodSearchControllerProvider, (_, _) {});
      addTearDown(sub.close);
      final controller = container.read(foodSearchControllerProvider.notifier);
      container.read(foodSearchControllerProvider.notifier).setQuery('r');
      await repository.started.future;
      for (var i = 0; i < 30; i++) {
        controller.setQuery(i == 29 ? 'rice' : 'query$i');
      }
      repository.release.complete();
      await controller.settle();
      expect(repository.maximum, 1);
      expect(repository.calls, 2);
      expect(container.read(foodSearchControllerProvider).query, 'rice');
      expect(
        container.read(foodSearchControllerProvider).results!.rows,
        isNotEmpty,
      );
    },
  );

  test(
    'FD-060 PA12 real pack pins every compatible pair; '
    '90/10 beef switches only to matching 90/10',
    () async {
      final db = backgroundDatabase(
        tempDir().path,
        catalog: FixedPack(File('assets/catalog/catalog.db').absolute.path),
      );
      final repository = FoodCatalogRepository(OfflineCatalog(db));
      final loader = FoodChoiceLoader(repository, () => []);
      final targets = await db
          .customSelect(
            'SELECT id FROM catalog.foods WHERE yield_group '
            'IS NOT NULL ORDER BY id',
          )
          .get();
      final actual = <String>[];
      for (final row in targets) {
        final id = row.read<String>('id');
        final choice = (await loader.load(
          FoodChoiceRef(FoodRef.catalog(id, version: '6')),
        ))!;
        if (id == 'usda:beef_ground_90_raw') {
          expect(choice.siblings.map((s) => s.id), [
            'usda:beef_ground_90_cooked',
          ]);
        }
        actual.addAll(choice.siblings.map((s) => '$id -> ${s.id}'));
      }
      expect(
        actual..sort(),
        <(String, String)>[
          ('usda:beef_chuck_braised', 'usda:beef_chuck_raw'),
          ('usda:beef_chuck_raw', 'usda:beef_chuck_braised'),
          ('usda:beef_ground_80_cooked', 'usda:beef_ground_80_raw'),
          ('usda:beef_ground_80_raw', 'usda:beef_ground_80_cooked'),
          ('usda:beef_ground_85_cooked', 'usda:beef_ground_85_raw'),
          ('usda:beef_ground_85_raw', 'usda:beef_ground_85_cooked'),
          ('usda:beef_ground_90_cooked', 'usda:beef_ground_90_raw'),
          ('usda:beef_ground_90_raw', 'usda:beef_ground_90_cooked'),
          ('usda:beef_ground_95_cooked', 'usda:beef_ground_95_raw'),
          ('usda:beef_ground_95_raw', 'usda:beef_ground_95_cooked'),
          ('usda:beef_lean_round_raw', 'usda:beef_lean_round_roasted'),
          ('usda:beef_lean_round_roasted', 'usda:beef_lean_round_raw'),
          ('usda:beef_ribeye_grilled', 'usda:beef_ribeye_raw'),
          ('usda:beef_ribeye_raw', 'usda:beef_ribeye_grilled'),
          ('usda:beef_sirloin_broiled', 'usda:beef_sirloin_raw'),
          ('usda:beef_sirloin_raw', 'usda:beef_sirloin_broiled'),
          ('usda:beef_tenderloin_broiled', 'usda:beef_tenderloin_raw'),
          ('usda:beef_tenderloin_raw', 'usda:beef_tenderloin_broiled'),
          ('usda:black_eyed_peas_cooked', 'usda:black_eyed_peas_dry'),
          ('usda:black_eyed_peas_dry', 'usda:black_eyed_peas_cooked'),
          ('usda:bulgur_cooked', 'usda:bulgur_dry'),
          ('usda:bulgur_dry', 'usda:bulgur_cooked'),
          ('usda:chicken_meat_raw', 'usda:chicken_meat_roasted'),
          ('usda:chicken_meat_roasted', 'usda:chicken_meat_raw'),
          ('usda:chickpeas_cooked', 'usda:chickpeas_dry'),
          ('usda:chickpeas_dry', 'usda:chickpeas_cooked'),
          ('usda:cod_cooked', 'usda:cod_raw'),
          ('usda:cod_raw', 'usda:cod_cooked'),
          ('usda:fava_beans_cooked', 'usda:fava_beans_dry'),
          ('usda:fava_beans_dry', 'usda:fava_beans_cooked'),
          ('usda:grouper_cooked', 'usda:grouper_raw'),
          ('usda:grouper_raw', 'usda:grouper_cooked'),
          ('usda:kidney_beans_cooked', 'usda:kidney_beans_dry'),
          ('usda:kidney_beans_dry', 'usda:kidney_beans_cooked'),
          ('usda:lamb_chops_grilled', 'usda:lamb_chops_raw'),
          ('usda:lamb_chops_raw', 'usda:lamb_chops_grilled'),
          ('usda:lamb_ground_cooked', 'usda:lamb_ground_raw'),
          ('usda:lamb_ground_raw', 'usda:lamb_ground_cooked'),
          ('usda:lamb_leg_raw', 'usda:lamb_leg_roasted'),
          ('usda:lamb_leg_roasted', 'usda:lamb_leg_raw'),
          ('usda:lamb_mixed_cuts_cooked', 'usda:lamb_mixed_cuts_raw'),
          ('usda:lamb_mixed_cuts_raw', 'usda:lamb_mixed_cuts_cooked'),
          ('usda:lamb_shank_braised', 'usda:lamb_shank_raw'),
          ('usda:lamb_shank_raw', 'usda:lamb_shank_braised'),
          ('usda:lamb_shoulder_braised', 'usda:lamb_shoulder_raw'),
          ('usda:lamb_shoulder_raw', 'usda:lamb_shoulder_braised'),
          ('usda:lentils_cooked', 'usda:lentils_dry'),
          ('usda:lentils_dry', 'usda:lentils_cooked'),
          ('usda:mackerel_cooked', 'usda:mackerel_raw'),
          ('usda:mackerel_raw', 'usda:mackerel_cooked'),
          ('usda:mullet_cooked', 'usda:mullet_raw'),
          ('usda:mullet_raw', 'usda:mullet_cooked'),
          ('usda:pasta_cooked', 'usda:pasta_dry'),
          ('usda:pasta_dry', 'usda:pasta_cooked'),
          ('usda:pasta_whole_wheat_cooked', 'usda:pasta_whole_wheat_dry'),
          ('usda:pasta_whole_wheat_dry', 'usda:pasta_whole_wheat_cooked'),
          ('usda:potato_boiled', 'usda:potato_raw'),
          ('usda:potato_raw', 'usda:potato_boiled'),
          (
            'usda:rice_brown_long_grain_cooked',
            'usda:rice_brown_long_grain_raw',
          ),
          (
            'usda:rice_brown_long_grain_raw',
            'usda:rice_brown_long_grain_cooked',
          ),
          ('usda:rice_parboiled_cooked', 'usda:rice_parboiled_raw'),
          ('usda:rice_parboiled_raw', 'usda:rice_parboiled_cooked'),
          ('usda:rice_short_grain_cooked', 'usda:rice_short_grain_raw'),
          ('usda:rice_short_grain_raw', 'usda:rice_short_grain_cooked'),
          (
            'usda:rice_white_long_grain_cooked',
            'usda:rice_white_long_grain_raw',
          ),
          (
            'usda:rice_white_long_grain_raw',
            'usda:rice_white_long_grain_cooked',
          ),
          (
            'usda:rice_white_medium_grain_cooked',
            'usda:rice_white_medium_grain_raw',
          ),
          (
            'usda:rice_white_medium_grain_raw',
            'usda:rice_white_medium_grain_cooked',
          ),
          ('usda:salmon_farmed_cooked', 'usda:salmon_farmed_raw'),
          ('usda:salmon_farmed_raw', 'usda:salmon_farmed_cooked'),
          ('usda:sea_bass_cooked', 'usda:sea_bass_raw'),
          ('usda:sea_bass_raw', 'usda:sea_bass_cooked'),
          ('usda:shrimp_cooked', 'usda:shrimp_raw'),
          ('usda:shrimp_raw', 'usda:shrimp_cooked'),
          ('usda:sole_cooked', 'usda:sole_raw'),
          ('usda:sole_raw', 'usda:sole_cooked'),
          ('usda:tilapia_cooked', 'usda:tilapia_raw'),
          ('usda:tilapia_raw', 'usda:tilapia_cooked'),
          ('usda:trout_cooked', 'usda:trout_raw'),
          ('usda:trout_raw', 'usda:trout_cooked'),
          ('usda:veal_stew_braised', 'usda:veal_stew_raw'),
          ('usda:veal_stew_raw', 'usda:veal_stew_braised'),
          ('usda:white_beans_cooked', 'usda:white_beans_dry'),
          ('usda:white_beans_dry', 'usda:white_beans_cooked'),
        ].map((pair) => '${pair.$1} -> ${pair.$2}').toList(),
      );
    },
    skip: !File('assets/catalog/catalog.db').existsSync()
        ? 'Build catalog-pack first'
        : false,
  );

  test('FD-060 fixture group with only one state offers no switch', () async {
    final service = fixtureService(
      extraSql: "UPDATE foods SET yield_group='isolated' WHERE id='$riceId';",
    );
    await ready(service);
    final choice = (await FoodChoiceLoader(
      service.repository,
      () => [],
    ).load(FoodChoiceRef(FoodRef.catalog(riceId, version: '1'))))!;
    expect(choice.siblings, isEmpty);
  });
}

class BlockingRepository extends FoodCatalogRepository {
  new(super.catalog);
  final started = Completer<void>();
  final release = Completer<void>();
  int running = 0;
  int maximum = 0;
  int calls = 0;
  @override
  Future<List<CatalogNameRow>> candidateNames(CandidateQuery query) async {
    calls++;
    running++;
    if (running > maximum) maximum = running;
    if (!started.isCompleted) {
      started.complete();
      await release.future;
    }
    try {
      return await super.candidateNames(query);
    } finally {
      running--;
    }
  }
}

class ReadCounter extends QueryInterceptor {
  final statements = <String>[];
  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    statements.add(statement);
    return executor.runSelect(statement, args);
  }
}

class MetadataBlockingRepository extends FoodCatalogRepository {
  new(super.catalog);
  bool block = false;
  bool historyOnly = false;
  @override
  Future<List<CatalogNameRow>> candidateNames(CandidateQuery query) =>
      historyOnly ? Future.value([]) : super.candidateNames(query);
  final started = Completer<void>();
  final release = Completer<void>();
  @override
  Future<List<CatalogNameRow>> namesForTargets(Iterable<String> ids) async {
    final rows = await super.namesForTargets(ids);
    if (block && !started.isCompleted) {
      started.complete();
      await release.future;
    }
    return rows;
  }
}

class RecoverableRepository extends FoodCatalogRepository {
  new(super.catalog);
  bool fail = false;
  @override
  Future<List<CatalogNameRow>> candidateNames(CandidateQuery query) {
    if (fail) throw StateError('read');
    return super.candidateNames(query);
  }
}
