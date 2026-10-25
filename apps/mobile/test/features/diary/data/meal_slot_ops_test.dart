import 'package:drift/drift.dart' show Value;
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/diary/data/diary_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/diary_fixtures.dart';
import '../support/diary_harness.dart';

const String lunch = DefaultSlots.lunchId;
const String snacks = DefaultSlots.snacksId;
Future<List<Map<String, Object?>>> dump(DiaryHarness h, String table) async => [
  for (final r
      in await h.db.customSelect('SELECT * FROM $table ORDER BY rowid').get())
    r.data,
];
Future<void> refuses(DiaryHarness h, ChangeOp op, Matcher matcher) async {
  final before = [
    for (final t in [
      'meal_slots',
      'diary_entries',
      'dish_groups',
      'sync_outbox',
    ])
      await dump(h, t),
  ];
  expect(await h.reject([op]), matcher);
  expect([
    for (final t in [
      'meal_slots',
      'diary_entries',
      'dish_groups',
      'sync_outbox',
    ])
      await dump(h, t),
  ], before);
}

Future<List<Object>> undoState(DiaryHarness h) async => [
  for (final t in [
    'meal_slots',
    'diary_entries',
    'dish_groups',
    'sync_outbox',
    'sync_state',
  ])
    await dump(h, t),
];

Future<void> refusesUndo(DiaryHarness h, Applied applied, String code) async {
  final before = await undoState(h);
  final result = await h.applier.revert(applied.inverse);
  expect(
    result,
    isA<Rejected>().having((r) => r.failure, 'failure', InvalidOp(code)),
  );
  expect(await undoState(h), before);
  final stack = UndoStack(revert: h.applier.revert, clock: h.clock);
  addTearDown(stack.dispose);
  final entry = stack.record(applied, UndoLabel('mealSlotsChanged'));
  expect(await stack.undo(entry.id), UndoOutcome.conflict);
  expect(await stack.undo(entry.id), UndoOutcome.unknown);
  expect(await undoState(h), before);
}

Future<void> undoWithOutbox(DiaryHarness h, Applied applied) async {
  final before = await dump(h, 'sync_outbox');
  final versions = <String, int>{};
  for (final row in applied.inverse.rows) {
    final current = (await dump(
      h,
      row.table.actualTableName,
    )).singleWhere((r) => r['id'] == row.id);
    versions[row.id] = current['version']! as int;
  }
  await h.undo(applied);
  final after = await dump(h, 'sync_outbox');
  expect(after.take(before.length).toList(), before);
  final appended = after.skip(before.length).toList();
  expect(appended.length, applied.inverse.rows.length);
  expect(
    appended.map((r) => r['row_id']).toSet(),
    applied.inverse.rows.map((r) => r.id).toSet(),
  );
  for (final row in applied.inverse.rows) {
    final current = (await dump(
      h,
      row.table.actualTableName,
    )).singleWhere((r) => r['id'] == row.id);
    final event = appended.singleWhere((r) => r['row_id'] == row.id);
    expect(current['version'], versions[row.id]! + 1);
    expect(current['origin'], 'undo:${applied.changeSetId}');
    expect(event['hlc'], current['updated_hlc']);
    expect(event['deleted'], current['deleted_at'] == null ? 0 : 1);
  }
}

Future<SlotRecord> record(DiaryHarness h, [String id = lunch]) async =>
    (await DiaryRepository(
      h.db,
    ).watchSlotRecords().first).singleWhere((r) => r.slot.id == id);
Future<RemoveMealSlot> remove(
  DiaryHarness h, {
  String id = lunch,
  String? target = snacks,
}) async => RemoveMealSlot(
  id,
  (await record(h, id)).version,
  expected: await DiaryRepository(h.db).watchSlotContents(id).first,
  moveTo: target == null ? null : (await record(h, target)).versionedId,
);
Future<DiaryHarness> source() async {
  final h = DiaryHarness(offsetMinutes: 180);
  await h.apply([
    CreateDishGroup(
      id: fixtureId(50),
      name: 'Private group',
      date: today,
      slotId: lunch,
    ),
    LogEntries([
      newEntry(1, slotId: lunch, group: 50),
      newEntry(2, slotId: lunch, group: 50),
      newEntry(3, slotId: lunch, when: atDay(today.plusDays(-1))),
    ]),
  ]);
  return h;
}

void main() {
  test(
    'DY-010 UX-030 undo removal rejects new group member atomically',
    () async {
      final h = await source();
      final applied = await h.apply([await remove(h)]);
      await h.apply([
        LogEntries([newEntry(4, slotId: snacks, group: 50)]),
      ]);
      expect((await h.group(50)).version, 2);
      await refusesUndo(h, applied, 'sourceChanged');
    },
  );
  test(
    'DY-010 UX-030 undo addition rejects entry arrival atomically',
    () async {
      final h = DiaryHarness();
      final applied = await h.apply([AddMealSlot(newId(1), 'Custom')]);
      await h.apply([
        LogEntries([newEntry(4, slotId: newId(1))]),
      ]);
      expect((await record(h, newId(1))).version, 1);
      await refusesUndo(h, applied, 'slotInUse');
    },
  );
  test(
    'DY-010 UX-030 undo addition rejects empty group arrival atomically',
    () async {
      final h = DiaryHarness();
      final applied = await h.apply([AddMealSlot(newId(1), 'Custom')]);
      await h.apply([
        CreateDishGroup(
          id: fixtureId(50),
          name: 'Empty',
          date: today,
          slotId: newId(1),
        ),
      ]);
      expect((await record(h, newId(1))).version, 1);
      await refusesUndo(h, applied, 'slotInUse');
    },
  );
  test(
    'DY-010 UX-030 undo removal rejects ninth active slot atomically',
    () async {
      final h = DiaryHarness();
      for (var i = 1; i <= 4; i++) {
        await h.apply([AddMealSlot(newId(i), 'Custom $i')]);
      }
      final applied = await h.apply([await remove(h, target: null)]);
      await h.apply([AddMealSlot(newId(5), 'Replacement')]);
      expect((await record(h)).version, 2);
      await refusesUndo(h, applied, 'tooManySlots');
    },
  );
  test('DY-010 UX-030 undo multiple removals checks combined active '
      'count atomically', () async {
    final h = DiaryHarness();
    for (var i = 1; i <= 4; i++) {
      await h.apply([AddMealSlot(newId(i), 'Custom $i')]);
    }
    final applied = await h.apply([
      await remove(h, target: null),
      await remove(h, id: DefaultSlots.breakfastId, target: null),
    ]);
    await h.apply([AddMealSlot(newId(5), 'Replacement')]);
    await refusesUndo(h, applied, 'tooManySlots');
  });
  test('DY-010 AddMealSlot: inserted before the first slot starting '
      'later, the rest renumbered; no window → last; a 9th active '
      'slot → tooManySlots; blank or 31-char name → nameInvalid', () async {
    final h = DiaryHarness();
    await h.apply([
      AddMealSlot(
        newId(1),
        '  Pre   workout ',
        window: TimeWindow(17 * 60, 18 * 60),
      ),
    ]);
    final slots = await DiaryRepository(h.db).watchSlotRecords().first;
    expect(slots.map((r) => r.slot.id), [
      DefaultSlots.breakfastId,
      lunch,
      DefaultSlots.dinnerId,
      newId(1),
      snacks,
    ]);
    expect(slots.map((r) => r.slot.sortOrder), [0, 1, 2, 3, 4]);
    expect(slots[3].slot.name, 'Pre workout');
    for (var i = 2; i <= 4; i++) {
      await h.apply([AddMealSlot(newId(i), 'Meal $i')]);
    }
    expect(
      (await DiaryRepository(h.db).watchSlotRecords().first).last.slot.id,
      newId(4),
    );
    await refuses(
      h,
      AddMealSlot(newId(5), 'Ninth'),
      equals(const InvalidOp('tooManySlots')),
    );
    expect(() => AddMealSlot(newId(9), ''), throwsArgumentError);
    expect(() => AddMealSlot(newId(9), 'a' * 31), throwsArgumentError);
  });
  test("DY-010 UpdateMealSlot: rename; clearing a default slot's "
      "name stores NULL; clearing a custom slot's name → "
      'nameInvalid; window set and cleared; start = end refused; '
      'same values → no write; stale version → VersionConflict', () async {
    final h = DiaryHarness();
    await h.apply([
      UpdateMealSlot(lunch, 1, MealSlotPatch(name: 'Noon', setName: true)),
    ]);
    await h.apply([
      UpdateMealSlot(
        lunch,
        2,
        MealSlotPatch(name: 'Lunch', setName: true, setWindow: true),
      ),
    ]);
    expect((await record(h)).slot.name, isNull);
    expect((await record(h)).slot.window, isNull);
    final before = await dump(h, 'sync_outbox');
    final unchanged = await h.apply([
      UpdateMealSlot(lunch, 3, MealSlotPatch(setName: true)),
    ]);
    expect(unchanged.inverse.isEmpty, isTrue);
    expect(await dump(h, 'sync_outbox'), before);
    await h.apply([
      UpdateMealSlot(
        lunch,
        3,
        MealSlotPatch(window: TimeWindow(5, 10), setWindow: true),
      ),
    ]);
    await refuses(
      h,
      UpdateMealSlot(lunch, 3, MealSlotPatch(setWindow: true)),
      isA<VersionConflict>(),
    );
    await h.apply([AddMealSlot(newId(1), 'Custom')]);
    await refuses(
      h,
      UpdateMealSlot(newId(1), 1, MealSlotPatch(setName: true)),
      equals(const InvalidOp('nameInvalid')),
    );
    expect(() => TimeWindow(5, 5), throwsArgumentError);
  });
  test('DY-010 ReorderMealSlots: writes only changed sortOrders; a '
      'missing or extra active slot → sourceChanged; a stale version '
      '→ VersionConflict', () async {
    final h = DiaryHarness();
    final slots = await DiaryRepository(h.db).watchSlotRecords().first;
    final order = slots.map((r) => r.versionedId).toList();
    final before = await dump(h, 'sync_outbox');
    expect((await h.apply([ReorderMealSlots(order)])).inverse.isEmpty, isTrue);
    expect(await dump(h, 'sync_outbox'), before);
    await refuses(
      h,
      ReorderMealSlots(order.take(3)),
      equals(const InvalidOp('sourceChanged')),
    );
    await refuses(
      h,
      ReorderMealSlots([...order, VersionedId(newId(1), 1)]),
      equals(const InvalidOp('sourceChanged')),
    );
    await h.apply([
      ReorderMealSlots([order[1], order[0], ...order.skip(2)]),
    ]);
    expect((await record(h, DefaultSlots.dinnerId)).version, 1);
    await refuses(h, ReorderMealSlots(order), isA<VersionConflict>());
  });
  test('DY-010 an empty slot is deactivated, not tombstoned', () async {
    final h = DiaryHarness();
    await h.apply([await remove(h, target: null)]);
    final row = await (h.db.select(
      h.db.mealSlots,
    )..where((t) => t.id.equals(lunch))).getSingle();
    expect(row.active, isFalse);
    expect(row.deletedAt, isNull);
  });
  test('DY-010 a slot with 3 entries on 2 days and a dish group moves '
      'exactly the observed rows to Snacks keeping date, time, offset '
      'and group membership; the slot is inactive', () async {
    final h = await source();
    final before = await dump(h, 'diary_entries');
    await h.apply([await remove(h)]);
    final after = await dump(h, 'diary_entries');
    for (var i = 0; i < before.length; i++) {
      for (final key in [
        'local_date',
        'occurred_at_utc',
        'tz_offset_min',
        'dish_group_id',
        'amount',
        'kcal',
      ]) {
        expect(after[i][key], before[i][key]);
      }
      expect(after[i]['slot_id'], snacks);
    }
    expect((await h.group(50)).slotId, snacks);
    expect((await record(h)).slot.active, isFalse);
  });
  test('DY-010 an entry logged into the slot after the sheet opened → '
      'sourceChanged', () async {
    final h = await source();
    final op = await remove(h);
    await h.apply([
      LogEntries([newEntry(4, slotId: lunch)]),
    ]);
    await refuses(h, op, equals(const InvalidOp('sourceChanged')));
  });
  test('DY-010 PA1 same-count replacement (one observed entry moved '
      'out, another moved in) → sourceChanged', () async {
    final h = await source();
    final op = await remove(h);
    await h.apply([
      MoveEntries([VersionedId(fixtureId(3), 1)], toSlotId: snacks),
      LogEntries([newEntry(4, slotId: lunch)]),
    ]);
    await refuses(h, op, equals(const InvalidOp('sourceChanged')));
  });
  test('DY-010 PA1 group-only change (a group of the slot renamed → '
      'VersionConflict; a group moved in or out with no entry change '
      '→ sourceChanged)', () async {
    final h = await source();
    final op = await remove(h);
    await h.apply([RenameDishGroup(fixtureId(50), 1, 'Changed')]);
    await refuses(h, op, isA<VersionConflict>());
    final fresh = await remove(h);
    await h.apply([
      CreateDishGroup(
        id: fixtureId(51),
        name: 'Empty',
        date: today,
        slotId: lunch,
      ),
    ]);
    await refuses(h, fresh, equals(const InvalidOp('sourceChanged')));
    final shown = await remove(h);
    await h.apply([MoveDishGroup(fixtureId(51), 1, toSlotId: snacks)]);
    await refuses(h, shown, equals(const InvalidOp('sourceChanged')));
  });
  test('DY-010 PA1 an observed entry edited → VersionConflict; deleted '
      '→ sourceChanged', () async {
    final h = await source();
    final op = await remove(h);
    await h.apply([
      UpdateDiaryEntry(
        fixtureId(3),
        1,
        EntryPatch(
          amount: EntryAmount(
            input: Quantity(100, 'g'),
            amount: 100,
            basis: NutrientBasis.per100g,
          ),
        ),
      ),
    ]);
    await refuses(h, op, isA<VersionConflict>());
    final fresh = await remove(h);
    await h.apply([
      DeleteEntries([VersionedId(fixtureId(3), 2)]),
    ]);
    await refuses(h, fresh, equals(const InvalidOp('sourceChanged')));
  });
  test(
    'DY-010 PA1 destination changed after the pick (renamed, window '
    'changed, reordered → VersionConflict; deactivated → badTarget)',
    () async {
      for (final patch in [
        const MealSlotsCompanion(name: Value('Other')),
        const MealSlotsCompanion(
          windowStartMin: Value(5),
          windowEndMin: Value(10),
        ),
        const MealSlotsCompanion(sortOrder: Value(9)),
        const MealSlotsCompanion(active: Value(false)),
      ]) {
        final h = await source();
        final op = await remove(h);
        await h.editSlot(snacks, patch);
        await refuses(
          h,
          op,
          patch.active.present
              ? equals(const InvalidOp('badTarget'))
              : isA<VersionConflict>(),
        );
      }
    },
  );
  test('DY-010 entries present and no moveTo → slotNotEmpty', () async {
    final h = await source();
    await refuses(
      h,
      await remove(h, target: null),
      equals(const InvalidOp('slotNotEmpty')),
    );
  });
  test('DY-010 moveTo the slot itself, an inactive slot or a Ramadan '
      'slot → badTarget', () async {
    final h = await source();
    await refuses(
      h,
      await remove(h, target: lunch),
      equals(const InvalidOp('badTarget')),
    );
    for (final patch in [
      const MealSlotsCompanion(active: Value(false)),
      const MealSlotsCompanion(active: Value(true), mode: Value('ramadan')),
    ]) {
      await h.editSlot(snacks, patch);
      await refuses(
        h,
        RemoveMealSlot(
          lunch,
          1,
          expected: await DiaryRepository(h.db).watchSlotContents(lunch).first,
          moveTo: VersionedId(snacks, 1),
        ),
        equals(const InvalidOp('badTarget')),
      );
    }
  });
  test('DY-010 the last active slot → lastSlot', () async {
    final h = DiaryHarness();
    for (final id in [
      DefaultSlots.breakfastId,
      DefaultSlots.dinnerId,
      snacks,
    ]) {
      await h.apply([await remove(h, id: id, target: null)]);
    }
    await refuses(
      h,
      await remove(h, target: null),
      equals(const InvalidOp('lastSlot')),
    );
  });
  test('DY-010 stale slot version → VersionConflict', () async {
    final h = DiaryHarness();
    final op = await remove(h);
    await h.editSlot(lunch, const MealSlotsCompanion(name: Value('New')));
    await refuses(h, op, isA<VersionConflict>());
  });
  test('UX-030 undo of a removal restores the slot and every moved '
      'entry and group exactly', () async {
    final h = await source();
    final before = await h.state();
    final applied = await h.apply([await remove(h)]);
    await undoWithOutbox(h, applied);
    expect(await h.state(), before);
    // Undo is another synced write: the outbox contains every affected row.
    final outbox = await dump(h, 'sync_outbox');
    expect(outbox, isNotEmpty);
  });
  test('UX-030 remove, edit one moved entry, Undo → conflict and '
      'nothing is reverted (atomic)', () async {
    final h = await source();
    final applied = await h.apply([await remove(h)]);
    await h.apply([
      OverrideNutrients(fixtureId(1), 2, {NutrientField.kcal: 100}),
    ]);
    final before = await undoState(h);
    expect(await h.applier.revert(applied.inverse), isA<Rejected>());
    expect(await undoState(h), before);
  });
  test('UX-030 every slot op + undo restores the exact state', () async {
    for (final op in <MealSlotOp>[
      AddMealSlot(newId(1), 'Private', window: TimeWindow(60, 120)),
      UpdateMealSlot(lunch, 1, MealSlotPatch(name: 'Noon', setName: true)),
    ]) {
      final h = DiaryHarness();
      final before = await h.state();
      final applied = await h.apply([op]);
      await undoWithOutbox(h, applied);
      expect(await h.state(), before);
    }
    final h = DiaryHarness();
    final order = (await DiaryRepository(
      h.db,
    ).watchSlotRecords().first).reversed.map((r) => r.versionedId);
    final before = await h.state();
    final applied = await h.apply([ReorderMealSlots(order)]);
    await undoWithOutbox(h, applied);
    expect(await h.state(), before);
  });
  test('DY-011 after removal, LogEntries with no slot never picks the '
      'inactive slot', () async {
    final h = DiaryHarness();
    await h.apply([await remove(h)]);
    await h.apply([
      LogEntries([newEntry(1)]),
    ]);
    expect((await h.entry(1)).slotId, isNot(lunch));
  });
  test('DY-010 watchSlotRecords carries versions and re-emits on a '
      'slot write; watchSlotEntryCounts counts live entries only', () async {
    final h = await source();
    final repo = DiaryRepository(h.db);
    final emissions = <List<SlotRecord>>[];
    final sub = repo.watchSlotRecords().listen(emissions.add);
    addTearDown(sub.cancel);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await h.editSlot(lunch, const MealSlotsCompanion(name: Value('Live')));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(emissions.last.singleWhere((r) => r.slot.id == lunch).version, 2);
    expect(await repo.watchSlotEntryCounts().first, {lunch: 3});
    await h.apply([
      DeleteEntries([VersionedId(fixtureId(3), 1)]),
    ]);
    expect(await repo.watchSlotEntryCounts().first, {lunch: 2});
  });
  test(
    'DY-010 watchSlotContents follows adds, moves and deletes across days',
    () async {
      final h = await source();
      final repo = DiaryRepository(h.db);
      final emissions = <SlotContents>[];
      final sub = repo.watchSlotContents(lunch).listen(emissions.add);
      addTearDown(sub.cancel);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(emissions.last.dates.length, 2);
      await h.apply([
        MoveEntries([VersionedId(fixtureId(3), 1)], toSlotId: snacks),
      ]);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(emissions.last.entries.length, 2);
      await h.apply([
        DeleteEntries([VersionedId(fixtureId(1), 1)]),
      ]);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(emissions.last.entries.length, 1);
      await h.apply([
        LogEntries([
          newEntry(4, slotId: lunch, when: atDay(today.plusDays(-2))),
        ]),
      ]);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(emissions.last.entries.length, 2);
      expect(emissions.last.dates.length, 2);
    },
  );
  test(
    'DY-011 PA3 a meal removed between the pick and submit: '
    'LogEntries, MoveEntries, UpdateDiaryEntry(slot) and CopyMeal '
    'reject inactiveSlot with nothing written, mapped to slotRemoved',
    () async {
      final h = DiaryHarness();
      await h.apply([
        LogEntries([newEntry(1, slotId: snacks)]),
      ]);
      await h.apply([await remove(h)]);
      for (final op in <DiaryOp>[
        LogEntries([newEntry(2, slotId: lunch)]),
        MoveEntries([VersionedId(fixtureId(1), 1)], toSlotId: lunch),
        UpdateDiaryEntry(fixtureId(1), 1, EntryPatch(slotId: lunch)),
        CopyMeal(
          MealSource.entries([fixtureId(1)]),
          toDate: today.plusDays(-1),
          toSlotId: lunch,
          expected: SourceVersions(entries: [VersionedId(fixtureId(1), 1)]),
          copyIds: {fixtureId(1): newId(1)},
        ),
      ]) {
        await refuses(h, op, equals(const InvalidOp('inactiveSlot')));
      }
    },
  );
  test('DY-010 inactive, wrong-mode, absent and duplicate source slots '
      'refuse without writes', () async {
    final h = DiaryHarness();
    await refuses(
      h,
      UpdateMealSlot(newId(99), 1, MealSlotPatch(setName: true)),
      isA<RowNotFound>(),
    );
    await refuses(
      h,
      AddMealSlot(lunch, 'Duplicate'),
      equals(const InvalidOp('duplicateId')),
    );
    await h.editSlot(lunch, const MealSlotsCompanion(mode: Value('ramadan')));
    await refuses(
      h,
      UpdateMealSlot(lunch, 2, MealSlotPatch(setName: true)),
      equals(const InvalidOp('wrongMode')),
    );
    await h.editSlot(lunch, const MealSlotsCompanion(active: Value(false)));
    await refuses(
      h,
      UpdateMealSlot(lunch, 3, MealSlotPatch(setName: true)),
      equals(const InvalidOp('inactiveSlot')),
    );
  });
  test(
    'DY-010 slot and entry events carry identities and undo publishes them',
    () async {
      final h = await source();
      final events = <DomainEvent>[];
      final sub = h.bus.events.listen(events.add);
      addTearDown(sub.cancel);
      final applied = await h.apply([await remove(h)]);
      await undoWithOutbox(h, applied);
      await Future<void>.delayed(Duration.zero);
      expect(events.whereType<MealSlotsChanged>().length, 2);
      expect(events.whereType<EntryChanged>().length, 2);
      expect(events.whereType<EntryChanged>().first.dates.length, 2);
    },
  );
}
