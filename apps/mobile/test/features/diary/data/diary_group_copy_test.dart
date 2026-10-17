import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/diary_fixtures.dart';
import '../support/diary_harness.dart';

const String _lunch = DefaultSlots.lunchId;
const String _dinner = DefaultSlots.dinnerId;
const String _breakfast = DefaultSlots.breakfastId;

final LocalDate _past = LocalDate(2026, 10, 10);

CreateDishGroup _group(int n, {LocalDate? date, String slot = _lunch}) =>
    CreateDishGroup(
      id: fixtureId(n),
      name: 'Maqluba',
      date: date ?? today,
      slotId: slot,
    );

/// A group 50 on today's lunch with entries 1 and 2.
Future<DiaryHarness> _grouped() async {
  final h = DiaryHarness();
  await h.apply([
    _group(50),
    LogEntries([
      newEntry(1, group: 50, slotId: _lunch, when: atDay(today, 12)),
      newEntry(2, group: 50, slotId: _lunch, when: atDay(today, 12, 30)),
      newEntry(3, slotId: _lunch),
    ]),
  ]);
  return h;
}

int sourceNumber(String id) =>
    int.parse(id.substring(id.length - 4), radix: 16);

void main() {
  group('dish groups', () {
    test('DY-024 a group is created, with entries, in one change set and '
        'renamed', () async {
      final h = await _grouped();
      final day = await h.reads.day(today);
      expect(day.groups.single.name, 'Maqluba');
      expect(
        day.entries.where((e) => e.dishGroupId == fixtureId(50)),
        hasLength(2),
      );
      await h.apply([RenameDishGroup(fixtureId(50), 1, 'Mansaf')]);
      expect((await h.group(50)).name, 'Mansaf');
      expect(
        await h.reject([RenameDishGroup(fixtureId(50), 1, 'Again')]),
        isA<VersionConflict>(),
      );
    });

    test('DY-024 rename + undo restores the exact state', () async {
      final h = await _grouped();
      final before = await h.state();
      final renamed = await h.apply([
        RenameDishGroup(fixtureId(50), 1, 'Mansaf'),
      ]);
      await h.undo(renamed);
      expect(await h.state(), before);
    });

    test(
      'DY-024 creating a group alone + undo restores the exact state',
      () async {
        final h = DiaryHarness();
        final before = await h.state();
        final created = await h.apply([_group(50)]);
        await h.undo(created);
        expect(await h.state(), before);
      },
    );

    test('DY-024 LogEntries into a group of another slot or day is '
        'InvalidOp(groupMismatch)', () async {
      final h = await _grouped();
      expect(
        await h.reject([
          LogEntries([newEntry(9, group: 50, slotId: _dinner)]),
        ]),
        const InvalidOp('groupMismatch'),
      );
      expect(
        await h.reject([
          LogEntries([newEntry(9, group: 50, when: atDay(_past, 12))]),
        ]),
        const InvalidOp('groupMismatch'),
      );
      // Without a slot the group's slot is used.
      await h.apply([
        LogEntries([newEntry(9, group: 50, when: .onDay(today))]),
      ]);
      expect((await h.entry(9)).slotId, _lunch);
    });

    test('DY-024 D1: moving a grouped entry takes it out of the group; the '
        'last one leaving tombstones the group; undo restores both', () async {
      final h = await _grouped();
      final before = await h.state();
      final first = await h.apply([
        MoveEntries([VersionedId(fixtureId(1), 1)], toSlotId: _dinner),
      ]);
      expect((await h.entry(1)).dishGroupId, isNull);
      expect((await h.entry(2)).dishGroupId, fixtureId(50));
      expect((await h.group(50)).deletedAt, isNull);
      await h.undo(first);
      expect(await h.state(), before);

      final both = await h.apply([
        MoveEntries([
          VersionedId(fixtureId(1), 3),
          VersionedId(fixtureId(2), 1),
        ], toDate: _past),
      ]);
      expect((await h.group(50)).deletedAt, isNotNull);
      expect((await h.reads.day(today)).groups, isEmpty);
      await h.undo(both);
      expect(await h.state(), before);
    });

    test('DY-024 updating the slot of the only grouped entry tombstones the '
        'group; deleting the last entry too; undo restores', () async {
      final h = DiaryHarness();
      await h.apply([
        _group(50),
        LogEntries([newEntry(1, group: 50, slotId: _lunch)]),
      ]);
      final before = await h.state();
      final update = await h.apply([
        UpdateDiaryEntry(fixtureId(1), 1, EntryPatch(slotId: _dinner)),
      ]);
      expect((await h.group(50)).deletedAt, isNotNull);
      expect((await h.entry(1)).dishGroupId, isNull);
      await h.undo(update);
      expect(await h.state(), before);

      final version = (await h.entry(1)).version;
      final delete = await h.apply([
        DeleteEntries([VersionedId(fixtureId(1), version)]),
      ]);
      expect((await h.group(50)).deletedAt, isNotNull);
      await h.undo(delete);
      expect(await h.state(), before);
    });

    test('DY-024 MoveDishGroup moves the group and its live entries, not '
        'others; + undo; EntryChanged', () async {
      final h = await _grouped();
      final before = await h.state();
      final applied = await h.apply([
        MoveDishGroup(fixtureId(50), 1, toDate: _past, toSlotId: _dinner),
      ]);
      final group = await h.group(50);
      expect((group.localDate, group.slotId), ('2026-10-10', _dinner));
      for (final n in [1, 2]) {
        final e = await h.entry(n);
        expect(
          (e.localDate, e.slotId, e.dishGroupId),
          ('2026-10-10', _dinner, fixtureId(50)),
        );
      }
      expect((await h.entry(3)).localDate, '2026-10-17');
      expect(
        applied.events.first,
        EntryChanged([fixtureId(1), fixtureId(2)], [today, _past]),
      );
      await h.undo(applied);
      expect(await h.state(), before);
      expect(
        await h.reject([MoveDishGroup(fixtureId(50), 1, toDate: today)]),
        isA<VersionConflict>(),
      );
    });

    test('DY-003 a group cannot be created or moved to a future day', () async {
      final h = await _grouped();
      final tomorrow = LocalDate(2026, 10, 18);
      expect(
        await h.reject([_group(51, date: tomorrow)]),
        const InvalidOp('futureDate'),
      );
      expect(
        await h.reject([MoveDishGroup(fixtureId(50), 1, toDate: tomorrow)]),
        const InvalidOp('futureDate'),
      );
    });

    test('DY-024 DeleteDishGroup with its entries tombstones all; undo '
        'revives all', () async {
      final h = await _grouped();
      final before = await h.state();
      final applied = await h.apply([
        DeleteDishGroup(fixtureId(50), 1, deleteEntries: true),
      ]);
      expect((await h.entry(1)).deletedAt, isNotNull);
      expect((await h.entry(3)).deletedAt, isNull);
      expect(
        applied.events.first,
        EntryDeleted([fixtureId(1), fixtureId(2)], [today]),
      );
      final undone = await h.undo(applied);
      expect(
        undone.events.first,
        EntriesLogged([fixtureId(1), fixtureId(2)], [today]),
      );
      expect(await h.state(), before);
    });

    test('DY-024 DeleteDishGroup without entries ungroups them; undo '
        'regroups', () async {
      final h = await _grouped();
      final before = await h.state();
      final applied = await h.apply([DeleteDishGroup(fixtureId(50), 1)]);
      expect((await h.entry(1)).deletedAt, isNull);
      expect((await h.entry(1)).dishGroupId, isNull);
      expect((await h.group(50)).deletedAt, isNotNull);
      expect(
        applied.events.first,
        EntryChanged([fixtureId(1), fixtureId(2)], [today]),
      );
      await h.undo(applied);
      expect(await h.state(), before);
    });
  });

  group('CopyMeal', () {
    /// Yesterday's lunch: a group (50) with entries 1 and 2, a loose entry
    /// 3, and a breakfast entry 4 with an estimate.
    Future<DiaryHarness> source() async {
      final h = DiaryHarness(offsetMinutes: 180);
      final date = LocalDate(2026, 10, 16);
      await h.apply([
        _group(50, date: date),
        LogEntries([
          newEntry(
            1,
            group: 50,
            slotId: _lunch,
            when: .onDay(date, time: LocalTime(12, 10)),
          ),
          newEntry(
            2,
            group: 50,
            slotId: _lunch,
            when: .onDay(date, time: LocalTime(12, 40)),
          ),
          newEntry(
            3,
            slotId: _lunch,
            when: .onDay(date, time: LocalTime(13, 5)),
          ),
          newEntry(
            4,
            slotId: _breakfast,
            when: .onDay(date, time: LocalTime(7, 20)),
            ref: FoodRef.estimate(),
            provenance: Provenance(
              source: FoodSource.estimate,
              range: EstimateRange(100, 300),
              assumptions: const ['small'],
            ),
          ),
        ]),
      ]);
      return h;
    }

    final yesterday = LocalDate(2026, 10, 16);

    test('DY-023 DY-032 a slot copied to another day: new IDs, same snapshots, '
        'names, per-100, provenance and local time of day; groups as new '
        'groups', () async {
      final h = await source();
      final before = await h.reads.entriesOn(yesterday);
      final applied = await h.apply([
        CopyMeal(
          MealSource.slot(yesterday, _lunch),
          toDate: today,
          copyIds: {
            fixtureId(50): newId(50),
            fixtureId(1): newId(1),
            fixtureId(2): newId(2),
            fixtureId(3): newId(3),
          },
        ),
      ]);
      final copies = await h.reads.entriesOn(today);
      expect(copies.map((e) => e.id).toSet(), {newId(1), newId(2), newId(3)});
      for (final copy in copies) {
        final from = before.firstWhere(
          (e) => newId(sourceNumber(e.id)) == copy.id,
        );
        expect(copy.id, isNot(from.id));
        expect(copy.snapshot, from.snapshot);
        expect(copy.food, from.food);
        expect(copy.amount, from.amount);
        expect(copy.slotId, from.slotId);
        expect(copy.localDate, today);
        expect(copy.time.tzOffsetMin, from.time.tzOffsetMin);
        expect(copy.time.localDateTime.time, from.time.localDateTime.time);
        expect(copy.editedByUser, isFalse);
        expect(copy.dishGroupId, from.dishGroupId == null ? isNull : newId(50));
      }
      final group = (await h.reads.groupsOn(today)).single;
      expect(
        (group.id, group.name, group.slotId),
        (newId(50), 'Maqluba', _lunch),
      );
      expect(await h.reads.entriesOn(yesterday), before);
      expect(
        applied.events.first,
        EntriesLogged([newId(1), newId(2), newId(3)], [today]),
      );
    });

    test('DY-023 copy + undo tombstones the copies only', () async {
      final h = await source();
      final before = await h.state();
      final applied = await h.apply([
        CopyMeal(
          MealSource.slot(yesterday, _lunch),
          toDate: today,
          toSlotId: _dinner,
          copyIds: {
            fixtureId(50): newId(50),
            fixtureId(1): newId(1),
            fixtureId(2): newId(2),
            fixtureId(3): newId(3),
          },
        ),
      ]);
      expect(
        (await h.reads.entriesOn(today)).every((e) => e.slotId == _dinner),
        isTrue,
      );
      expect((await h.reads.groupsOn(today)).single.slotId, _dinner);
      final undone = await h.undo(applied);
      expect(
        undone.events.first,
        EntryDeleted([newId(1), newId(2), newId(3)], [today]),
      );
      expect(await h.state(), before);
      expect((await h.entry(1)).deletedAt, isNull);
      expect((await h.entry(1000 + 1)).deletedAt, isNotNull);
    });

    test('DY-032 copying a day keeps each entry slot', () async {
      final h = await source();
      await h.apply([
        CopyMeal(
          MealSource.day(yesterday),
          toDate: _past,
          copyIds: {
            fixtureId(50): newId(50),
            for (var n = 1; n <= 4; n++) fixtureId(n): newId(n),
          },
        ),
      ]);
      final copies = await h.reads.entriesOn(_past);
      expect(
        {for (final e in copies) e.id: e.slotId},
        {
          newId(1): _lunch,
          newId(2): _lunch,
          newId(3): _lunch,
          newId(4): _breakfast,
        },
      );
      // The estimate copy keeps its provenance.
      expect(
        copies.firstWhere((e) => e.id == newId(4)).food.provenance.range,
        EstimateRange(100, 300),
      );
    });

    test('DY-023 copying some entries of a group copies them ungrouped; all '
        'of the group needs a group copy ID', () async {
      final h = await source();
      await h.apply([
        CopyMeal(
          MealSource.entries([fixtureId(1), fixtureId(3)]),
          toDate: today,
          copyIds: {fixtureId(1): newId(1), fixtureId(3): newId(3)},
        ),
      ]);
      expect((await h.reads.entriesOn(today)).map((e) => e.dishGroupId), [
        null,
        null,
      ]);
      expect(
        await h.reject([
          CopyMeal(
            MealSource.entries([fixtureId(1), fixtureId(2)]),
            toDate: _past,
            copyIds: {fixtureId(1): newId(11), fixtureId(2): newId(12)},
          ),
        ]),
        const InvalidOp('missingCopyId'),
      );
    });

    test('DY-023 a live source row without a copy ID is InvalidOp '
        '(missingCopyId); an empty source is InvalidOp(emptySource)', () async {
      final h = await source();
      expect(
        await h.reject([
          CopyMeal(
            MealSource.slot(yesterday, _lunch),
            toDate: today,
            copyIds: {fixtureId(1): newId(1), fixtureId(2): newId(2)},
          ),
        ]),
        const InvalidOp('missingCopyId'),
      );
      expect(
        await h.reject([
          CopyMeal(
            MealSource.slot(yesterday, _dinner),
            toDate: today,
            copyIds: {fixtureId(1): newId(1)},
          ),
        ]),
        const InvalidOp('emptySource'),
      );
      expect(await h.reads.entriesOn(today), isEmpty);
    });

    test(
      'DY-011 a copy into an inactive slot is InvalidOp(inactiveSlot)',
      () async {
        final h = await source();
        await h.editSlot(
          _dinner,
          const MealSlotsCompanion(active: Value(false)),
        );
        expect(
          await h.reject([
            CopyMeal(
              MealSource.entries([fixtureId(3)]),
              toDate: today,
              toSlotId: _dinner,
              copyIds: {fixtureId(3): newId(3)},
            ),
          ]),
          const InvalidOp('inactiveSlot'),
        );
      },
    );

    test('DY-003 a copy to a future date is rejected; a missing source '
        'entry is RowNotFound', () async {
      final h = await source();
      expect(
        await h.reject([
          CopyMeal(
            MealSource.entries([fixtureId(3)]),
            toDate: LocalDate(2026, 10, 18),
            copyIds: {fixtureId(3): newId(3)},
          ),
        ]),
        const InvalidOp('futureDate'),
      );
      expect(
        await h.reject([
          CopyMeal(
            MealSource.entries([fixtureId(99)]),
            toDate: today,
            copyIds: {fixtureId(99): newId(99)},
          ),
        ]),
        RowNotFound(entity: 'diaryEntry', id: fixtureId(99)),
      );
    });
  });

  group('SaveMeal', () {
    test('DY-023 SaveMeal writes one item per live source entry with equal '
        'snapshots and IDs from the generator; + undo', () async {
      final h = await _grouped();
      await h.apply([
        DeleteEntries([VersionedId(fixtureId(2), 1)]),
      ]);
      final before = await h.state();
      final applied = await h.apply([
        SaveMeal(
          savedMealId: newId(1),
          name: 'Lunch box',
          source: MealSource.slot(today, _lunch),
        ),
      ]);
      final meal = await h.db.select(h.db.savedMeals).getSingle();
      expect((meal.id, meal.name), (newId(1), 'Lunch box'));
      final items = await (h.db.select(
        h.db.savedMealItems,
      )..orderBy([(t) => OrderingTerm(expression: t.sortOrder)])).get();
      final entries = await h.reads.entriesIn(today, _lunch);
      expect(items, hasLength(2));
      for (final (i, item) in items.indexed) {
        final e = entries[i];
        expect(item.savedMealId, newId(1));
        expect(item.sortOrder, i);
        expect(
          (item.kcal, item.proteinG, item.carbsG, item.fatG, item.fiberG),
          (
            e.snapshot.kcal,
            e.snapshot.protein,
            e.snapshot.carbs,
            e.snapshot.fat,
            e.snapshot.fiber,
          ),
        );
        expect(
          (item.nameEn, item.foodId, item.foodVersion, item.source),
          (
            e.food.names.en,
            e.food.ref.id,
            e.food.ref.version,
            e.food.provenance.source.code,
          ),
        );
        expect(
          (item.amount, item.per100Kcal),
          (e.amount.amount, e.food.per100.kcal),
        );
        expect(isUuidV7(item.id), isTrue);
      }
      await h.undo(applied);
      expect(await h.state(), before);
      expect(
        await h.reject([
          SaveMeal(
            savedMealId: newId(2),
            name: 'Nothing',
            source: MealSource.slot(today, _dinner),
          ),
        ]),
        const InvalidOp('emptySource'),
      );
    });
  });
}
