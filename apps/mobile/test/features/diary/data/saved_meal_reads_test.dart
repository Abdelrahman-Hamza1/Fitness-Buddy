import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/features/diary/data/diary_reads.dart';
import 'package:fb_mobile/features/diary/data/diary_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../foods/data/personal_food_harness.dart';

void main() {
  test('DY-031 watchSavedMeals: live meals with live items in order '
      'and totals; a tombstoned item is excluded', () async {
    final h = PersonalHarness();
    await h.seed(entries: 3, items: 3);
    final items = await h.liveItems();
    await h.write([
      UpdateRow(
        h.db.savedMealItems,
        items.first.id,
        const SavedMealItemsCompanion(
          sortOrder: Value(5),
          editedByUser: Value(true),
          per100ExtrasJson: Value('{"sugar":2}'),
          extrasJson: Value('{"sugar":3}'),
        ),
      ),
      TombstoneRow(h.db.savedMealItems, items[1].id),
    ]);
    final repo = DiaryRepository(h.db);
    final meals = await repo.watchSavedMeals().first;
    final meal = meals.single;
    expect(meal.items.map((i) => i.id), [items.last.id, items.first.id]);
    expect(meal.items.last.food.editedByUser, isTrue);
    expect(meal.items.last.food.per100.extras[NutrientKey.sugar], 2);
    expect(meal.items.last.snapshot.extras[NutrientKey.sugar], 3);
    expect(meal.totals.kcal, items.first.kcal + items.last.kcal);
    expect(meal.versions!.items.map((i) => i.expectedVersion), [1, 2]);
    expect((await repo.watchSavedMeal(fixtureId(3)).first)!.name, 'Saved');
    expect(await repo.watchSavedMeal(fixtureId(999)).first, isNull);
    await h.apply([
      SaveMeal(
        savedMealId: fixtureId(4),
        name: 'Alpha',
        source: MealSource.entries([fixtureId(10)]),
        expected: SourceVersions(entries: [VersionedId(fixtureId(10), 1)]),
      ),
    ]);
    expect((await repo.watchSavedMeals().first).map((m) => m.name), [
      'Alpha',
      'Saved',
    ]);
    await h.apply([DeleteSavedMeal(fixtureId(4), 1)]);
    expect(await repo.watchSavedMeals().first, hasLength(1));
    expect(await repo.watchSavedMeal(fixtureId(4)).first, isNull);
    await h.write([
      for (final item in await h.liveItems())
        TombstoneRow(h.db.savedMealItems, item.id),
    ]);
    final empty = (await repo.watchSavedMeal(fixtureId(3)).first)!;
    expect(empty.items, isEmpty);
    expect(empty.totals, Nutrients.zero);
    expect(empty.versions, isNull);
  });
  test(
    'DY-031 saved-meal streams observe item changes, rename and deletion',
    () async {
      final h = PersonalHarness();
      await h.seed();
      final repo = DiaryRepository(h.db);
      final lists = <List<SavedMeal>>[];
      final singles = <SavedMeal?>[];
      final all = repo.watchSavedMeals().listen(lists.add);
      final one = repo.watchSavedMeal(fixtureId(3)).listen(singles.add);
      addTearDown(all.cancel);
      addTearDown(one.cancel);
      await pumpEventQueue();
      await h.apply([RenameSavedMeal(fixtureId(3), 1, 'Renamed')]);
      await pumpEventQueue();
      final item = (await h.liveItems()).first;
      await h.write([TombstoneRow(h.db.savedMealItems, item.id)]);
      await pumpEventQueue();
      await h.apply([DeleteSavedMeal(fixtureId(3), 2)]);
      await pumpEventQueue();
      expect(lists.map((l) => l.isEmpty ? null : l.single.name), [
        'Saved',
        'Renamed',
        'Renamed',
        null,
      ]);
      expect(singles.map((m) => m?.items.length), [2, 2, 1, null]);
    },
  );
  test(
    'DY-031 unreadable saved snapshots produce a typed redacted failure',
    () async {
      for (final corrupt in [
        const SavedMealItemsCompanion(extrasJson: Value('{private content')),
        const SavedMealItemsCompanion(per100Kcal: Value(-1)),
      ]) {
        final h = PersonalHarness();
        await h.seed();
        final item = (await h.liveItems()).first;
        await h.write([UpdateRow(h.db.savedMealItems, item.id, corrupt)]);
        await expectLater(
          DiaryRepository(h.db).watchSavedMeals().first,
          throwsA(isA<SavedMealReadFailure>()),
        );
        expect(const SavedMealReadFailure().toString(), 'SavedMealReadFailure');
      }
    },
  );
}
