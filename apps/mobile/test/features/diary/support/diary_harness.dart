import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/change_set_applier.dart';
import 'package:fb_mobile/core/changes/row_ops.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/events/domain_event_bus.dart';
import 'package:fb_mobile/features/diary/data/diary_op_handler.dart';
import 'package:fb_mobile/features/diary/data/diary_reads.dart';
import 'package:fb_mobile/features/diary/data/meal_slot_op_handler.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../core/changes/support/test_db.dart'
    show ScriptHandler, ScriptOp;
import '../../../core/db/support/db_support.dart';
import 'diary_fixtures.dart';

/// The fixed "today" of the handler tests: 2026-10-17, 12:00 UTC.
final LocalDate today = LocalDate(2026, 10, 17);

/// The diary tables the exact-state comparison covers.
const _tables = [
  'meal_slots',
  'dish_groups',
  'diary_entries',
  'day_marks',
  'saved_meals',
  'saved_meal_items',
];

/// A profile database with the real applier and diary/slot handlers, a
/// manual clock (2026-10-17 12:00 UTC) and a sequence ID generator.
final class DiaryHarness {
  new({int offsetMinutes = 0})
    : clock = ManualClock(
        DateTime.utc(2026, 10, 17, 12),
        offsetMinutes: offsetMinutes,
      ) {
    addTearDown(bus.close);
    applier = ChangeSetApplier(
      db: db,
      tables: db.syncedTables,
      handlers: (db) => [
        DiaryOpHandler(db),
        MealSlotOpHandler(db),
        const ScriptHandler(),
      ],
      clock: clock,
      ids: ids,
      deviceId: () async => testDevice,
      events: bus,
    );
  }

  final AppDatabase db = memoryDatabase();
  final DomainEventBus bus = DomainEventBus();
  final ManualClock clock;
  final SequenceIdGenerator ids = SequenceIdGenerator();
  late final ChangeSetApplier<AppDatabase> applier;
  late final DiaryReads reads = DiaryReads(db);

  /// Applies [ops] as one direct change set; fails the test unless applied.
  Future<Applied> apply(List<ChangeOp> ops) async {
    final result = await applier.apply(ChangeSet(ops, origin: Origin.direct));
    if (result is! Applied) fail('expected Applied, got $result');
    return result;
  }

  /// Simulates an external slot edit through the applier for race tests.
  Future<void> editSlot(String id, MealSlotsCompanion changes) async {
    final result = await applier.apply(
      ChangeSet([
        ScriptOp.rows([UpdateRow(db.mealSlots, id, changes)]),
      ], origin: Origin.direct),
    );
    if (result is! Applied) fail('expected Applied, got $result');
  }

  /// Adds an active slot of [mode] with [id] through the applier.
  Future<void> addSlot(String id, {required String mode}) async {
    final result = await applier.apply(
      ChangeSet([
        ScriptOp.rows([
          InsertRow(
            db.mealSlots,
            MealSlotsCompanion(
              id: Value(id),
              name: const Value('Iftar'),
              sortOrder: const Value(9),
              mode: Value(mode),
              active: const Value(true),
            ),
          ),
        ]),
      ], origin: Origin.direct),
    );
    if (result is! Applied) fail('expected Applied, got $result');
  }

  /// Applies [ops] and returns why they were rejected.
  Future<ChangeFailure> reject(List<ChangeOp> ops) async {
    final result = await applier.apply(ChangeSet(ops, origin: Origin.direct));
    if (result is! Rejected) fail('expected Rejected, got $result');
    return result.failure;
  }

  /// Undoes [applied]; fails the test unless it works.
  Future<Applied> undo(Applied applied) async {
    final result = await applier.revert(applied.inverse);
    if (result is! Applied) fail('expected Applied, got $result');
    return result;
  }

  /// The row of entry [n], tombstone or not.
  Future<DiaryEntryRow> entry(int n) => (db.select(
    db.diaryEntries,
  )..where((t) => t.id.equals(fixtureId(n)))).getSingle();

  /// The row of the dish group [n], tombstone or not.
  Future<DishGroupRow> group(int n) => (db.select(
    db.dishGroups,
  )..where((t) => t.id.equals(fixtureId(n)))).getSingle();

  /// Every live row of the diary tables, content columns, `edited_by_user`
  /// only (A01 D3's comparison), as text.
  Future<String> state() async {
    final dump = <String, Object?>{};
    for (final table in _tables) {
      final rows = await db
          .customSelect(
            'SELECT * FROM $table WHERE deleted_at IS NULL ORDER BY id',
          )
          .get();
      dump[table] = [
        for (final row in rows)
          {
            for (final MapEntry(:key, :value) in row.data.entries)
              if (!_meta.contains(key)) key: value,
          },
      ];
    }
    return jsonEncode(dump);
  }
}

const _meta = {
  'created_at',
  'updated_hlc',
  'version',
  'deleted_at',
  'device_id',
  'origin',
};

/// An entry to log with ID [n] ([fixtureId]), of 150 g of a food with
/// [kcal] per 100 g.
NewDiaryEntry newEntry(
  int n, {
  EntryWhen? when,
  String? slotId,
  int? group,
  double kcal = 200,
  double grams = 150,
  FoodRef? ref,
  Provenance? provenance,
}) => NewDiaryEntry(
  id: fixtureId(n),
  when: when ?? .at(EntryTime(DateTime.utc(2026, 10, 17, 13, 5), 0)),
  slotId: slotId,
  dishGroupId: group == null ? null : fixtureId(group),
  food: foodOf(n, kcal: kcal, ref: ref, provenance: provenance),
  amount: EntryAmount(
    input: Quantity(grams, 'g'),
    amount: grams,
    basis: NutrientBasis.per100g,
  ),
);

/// A catalog food named "Food [n]" with [kcal] per 100 g.
EntryFood foodOf(
  int n, {
  double kcal = 200,
  FoodRef? ref,
  Provenance? provenance,
}) => EntryFood(
  ref: ref ?? FoodRef.catalog('food-$n', version: '2026.10.1'),
  names: FoodNames('Food $n', ar: 'طعام $n'),
  per100: Nutrients(
    kcal: kcal,
    protein: 7.3,
    carbs: 21.7,
    fat: 3.1,
    fiber: 2.2,
    extras: {NutrientKey.sugar: 1.3},
  ),
  provenance: provenance ?? Provenance(source: FoodSource.database),
);

/// 13:05 UTC on [date].
EntryWhen atDay(LocalDate date, [int hour = 13, int minute = 5]) => .at(
  EntryTime(DateTime.utc(date.year, date.month, date.day, hour, minute), 0),
);

/// An ID for new rows, apart from the entries' fixture IDs.
String newId(int n) => fixtureId(1000 + n);
