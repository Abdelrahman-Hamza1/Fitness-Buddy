import 'package:drift/drift.dart';
import 'package:fb_mobile/core/db/app_database.steps.dart';
import 'package:fb_mobile/core/db/seed_rows.dart';

/// Schema v2 → v3 (A06 WP2): the diary tables, their indexes and outbox
/// triggers, and the four default meal slots.
///
/// Shipped migrations are frozen: never edit this file once it is on `main`
/// (`tools/scripts/check-frozen-migrations.sh`).
Future<void> from2To3(Migrator m, Schema3 schema) async {
  await m.createTable(schema.mealSlots);
  await m.createTable(schema.dishGroups);
  await m.createTable(schema.diaryEntries);
  await m.createTable(schema.dayMarks);
  await m.createTable(schema.savedMeals);
  await m.createTable(schema.savedMealItems);
  await m.createIndex(schema.ixDiaryEntriesLive);
  await m.createIndex(schema.ixDiaryEntriesGroup);
  await m.createIndex(schema.ixDishGroupsLive);
  await m.createIndex(schema.ixSavedMealItemsMeal);
  await m.createIndex(schema.ixDayMarksDate);
  for (final trigger in [
    schema.mealSlotsOutboxAi,
    schema.mealSlotsOutboxAu,
    schema.mealSlotsNoDelete,
    schema.dishGroupsOutboxAi,
    schema.dishGroupsOutboxAu,
    schema.dishGroupsNoDelete,
    schema.diaryEntriesOutboxAi,
    schema.diaryEntriesOutboxAu,
    schema.diaryEntriesNoDelete,
    schema.dayMarksOutboxAi,
    schema.dayMarksOutboxAu,
    schema.dayMarksNoDelete,
    schema.savedMealsOutboxAi,
    schema.savedMealsOutboxAu,
    schema.savedMealsNoDelete,
    schema.savedMealItemsOutboxAi,
    schema.savedMealItemsOutboxAu,
    schema.savedMealItemsNoDelete,
  ]) {
    await m.createTrigger(trigger);
  }
  await seedRows(m.database, schema.mealSlots, [
    for (final slot in v3SeedSlots)
      RawValuesInsertable<Never>({
        'id': Variable<String>(slot.id),
        'default_key': Variable<String>(slot.key),
        'name': const Variable<String>(null),
        'sort_order': Variable<int>(slot.sortOrder),
        'window_start_min': Variable<int>(slot.startMin),
        'window_end_min': Variable<int>(slot.endMin),
        'mode': const Variable<String>('normal'),
        'active': const Variable<bool>(true),
      }),
  ]);
}

/// The four default slots as v3 seeded them: the values are copied here, so
/// a later change to `DefaultSlots` can't alter this frozen step. A test
/// checks them against today's `DefaultSlots.all`.
const List<({String id, String key, int sortOrder, int? startMin, int? endMin})>
v3SeedSlots = [
  (
    id: '4c5aed24-f404-506e-a925-f0ff33099753',
    key: 'breakfast',
    sortOrder: 0,
    startMin: 240,
    endMin: 660,
  ),
  (
    id: 'ca0daf21-3d15-53c5-b4ec-ee09a5e0c674',
    key: 'lunch',
    sortOrder: 1,
    startMin: 660,
    endMin: 960,
  ),
  (
    id: '260cb3fe-def5-53e5-9f5c-d64f61a4ec3e',
    key: 'dinner',
    sortOrder: 2,
    startMin: 960,
    endMin: 1320,
  ),
  (
    id: '9c906ed8-064d-52d3-b116-803e12ee5630',
    key: 'snacks',
    sortOrder: 3,
    startMin: null,
    endMin: null,
  ),
];
