import 'package:drift/drift.dart' show Value;
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/natural_id.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/diary_fixtures.dart';
import '../support/diary_harness.dart';

const String _breakfast = DefaultSlots.breakfastId;
const String _lunch = DefaultSlots.lunchId;
const String _dinner = DefaultSlots.dinnerId;
const String _snacks = DefaultSlots.snacksId;

final LocalDate _past = LocalDate(2026, 10, 10);

void main() {
  group('LogEntries', () {
    test('DY-003 a past day with a time stores that local_date and assigns '
        'the slot from the time', () async {
      final h = DiaryHarness();
      await h.apply([
        LogEntries([newEntry(1, when: .onDay(_past, time: LocalTime(8, 15)))]),
      ]);
      final e = await h.entry(1);
      expect(e.localDate, '2026-10-10');
      expect(e.slotId, _breakfast);
      expect(
        e.occurredAtUtc,
        DateTime.utc(2026, 10, 10, 8, 15).millisecondsSinceEpoch,
      );
      expect(e.origin, 'direct');
      expect(e.editedByUser, isFalse);
    });

    test('DY-003 neither time nor slot on a past day takes the current local '
        'time of day, then DY-011 picks the slot', () async {
      final h = DiaryHarness(offsetMinutes: 180);
      // 12:00 UTC is 15:00 at +03:00: lunch.
      await h.apply([
        LogEntries([newEntry(1, when: .onDay(_past))]),
      ]);
      final e = await h.entry(1);
      expect(e.tzOffsetMin, 180);
      expect(e.localDate, '2026-10-10');
      expect(
        e.occurredAtUtc,
        DateTime.utc(2026, 10, 10, 12).millisecondsSinceEpoch,
      );
      expect(e.slotId, _lunch);
    });

    test('DY-003 a past day with a slot but no time gets the slot window '
        'start, or 12:00 for a slot without a window', () async {
      final h = DiaryHarness();
      await h.apply([
        LogEntries([
          newEntry(1, when: .onDay(_past), slotId: _dinner),
          newEntry(2, when: .onDay(_past), slotId: _snacks),
        ]),
      ]);
      expect(
        (await h.entry(1)).occurredAtUtc,
        DateTime.utc(2026, 10, 10, 16).millisecondsSinceEpoch,
      );
      expect(
        (await h.entry(2)).occurredAtUtc,
        DateTime.utc(2026, 10, 10, 12).millisecondsSinceEpoch,
      );
    });

    test(
      'DY-003 a future local_date is rejected as InvalidOp(futureDate)',
      () async {
        final h = DiaryHarness();
        final tomorrow = LocalDate(2026, 10, 18);
        expect(
          await h.reject([
            LogEntries([newEntry(1, when: .onDay(tomorrow))]),
          ]),
          const InvalidOp('futureDate'),
        );
        expect(
          await h.reject([
            LogEntries([newEntry(1, when: atDay(tomorrow))]),
          ]),
          const InvalidOp('futureDate'),
        );
        expect(await h.db.select(h.db.diaryEntries).get(), isEmpty);
      },
    );

    test('DY-002 an entry keeps the stored offset and the local date it was '
        'logged on (00:30 belongs to the new day)', () async {
      final h = DiaryHarness(offsetMinutes: 180);
      await h.apply([
        LogEntries([
          newEntry(
            1,
            when: .at(EntryTime(DateTime.utc(2026, 10, 16, 21, 30), 180)),
          ),
        ]),
      ]);
      final e = await h.entry(1);
      expect(e.localDate, '2026-10-17');
      expect(e.tzOffsetMin, 180);
      expect(e.slotId, _snacks);
    });

    test('DY-011 without slotId the SlotAssigner picks the slot; an explicit '
        'slotId wins', () async {
      final h = DiaryHarness();
      await h.apply([
        LogEntries([
          newEntry(1, when: atDay(today, 10, 59)),
          newEntry(2, when: atDay(today, 11, 0)),
          newEntry(3, when: atDay(today, 16, 0)),
          newEntry(4, when: atDay(today, 3, 59)),
          newEntry(5, when: atDay(today, 8, 0), slotId: _snacks),
        ]),
      ]);
      expect(
        [for (var n = 1; n <= 5; n++) (await h.entry(n)).slotId],
        [_breakfast, _lunch, _dinner, _snacks, _snacks],
      );
    });

    test('an unknown slot is InvalidOp(unknownSlot)', () async {
      final h = DiaryHarness();
      expect(
        await h.reject([
          LogEntries([newEntry(1, slotId: fixtureId(77))]),
        ]),
        const InvalidOp('unknownSlot'),
      );
    });

    // An active slot of the other mode is accepted (A41a D6:
    // ramadan_diary_ops_test).
    test('DY-011 an inactive slot is InvalidOp(inactiveSlot) in '
        'log, update, move', () async {
      final h = DiaryHarness();
      await h.apply([
        LogEntries([newEntry(1)]),
      ]);
      await h.editSlot(_dinner, const MealSlotsCompanion(active: Value(false)));
      const inactive = InvalidOp('inactiveSlot');
      for (final slot in [_dinner]) {
        expect(
          await h.reject([
            LogEntries([newEntry(2, slotId: slot)]),
          ]),
          inactive,
        );
        expect(
          await h.reject([
            UpdateDiaryEntry(fixtureId(1), 1, EntryPatch(slotId: slot)),
          ]),
          inactive,
        );
        expect(
          await h.reject([
            MoveEntries([VersionedId(fixtureId(1), 1)], toSlotId: slot),
          ]),
          inactive,
        );
        expect(
          await h.reject([
            CreateDishGroup(
              id: fixtureId(50),
              name: 'x',
              date: today,
              slotId: slot,
            ),
          ]),
          inactive,
        );
      }
    });

    test('DY-003 today with a slot but no time never gets a future time: a '
        'window starting after now takes the current time', () async {
      final h = DiaryHarness();
      // 12:00 now; dinner starts at 16:00.
      await h.apply([
        LogEntries([
          newEntry(1, when: .onDay(today), slotId: _dinner),
          newEntry(2, when: .onDay(today), slotId: _breakfast),
        ]),
      ]);
      expect(
        (await h.entry(1)).occurredAtUtc,
        DateTime.utc(2026, 10, 17, 12).millisecondsSinceEpoch,
      );
      expect(
        (await h.entry(2)).occurredAtUtc,
        DateTime.utc(2026, 10, 17, 4).millisecondsSinceEpoch,
      );
      expect((await h.entry(1)).slotId, _dinner);
    });

    test('FD-010 SC-4 the catalog version, source badge, estimate range and '
        'assumptions are stored and read back', () async {
      final h = DiaryHarness();
      final estimate = Provenance(
        source: FoodSource.estimate,
        range: EstimateRange(300, 500),
        assumptions: const ['one cup', 'olive oil'],
      );
      await h.apply([
        LogEntries([
          newEntry(1),
          newEntry(2, ref: FoodRef.estimate(), provenance: estimate),
        ]),
      ]);
      final catalog = await h.entry(1);
      expect(catalog.foodKind, 'catalog');
      expect(catalog.foodVersion, '2026.10.1');
      expect(catalog.source, 'database');
      final entries = await h.reads.entriesOn(today);
      expect(
        entries.first.food.provenance,
        Provenance(source: FoodSource.database),
      );
      expect(entries.last.food.provenance, estimate);
      expect(entries.last.food.ref, FoodRef.estimate());
      expect((await h.entry(2)).isEstimate, isTrue);
    });

    test('DY-001 the snapshot is the per-100 values for the amount, rounded '
        'once, and the per-100 values are kept (FD-073)', () async {
      final h = DiaryHarness();
      await h.apply([
        LogEntries([newEntry(1)]),
      ]);
      final e = (await h.reads.entriesOn(today)).single;
      final expected = const NutritionCalculator().forAmount(
        per100: foodOf(1).per100,
        amount: 150,
        basis: NutrientBasis.per100g,
      );
      expect(e.snapshot, expected.nutrients);
      expect(e.food.per100, foodOf(1).per100);
      expect(e.amount.amount, 150);
    });

    test('LogEntries + undo: the rows end tombstoned and the state is the '
        'one before; events are EntriesLogged then EntryDeleted', () async {
      final h = DiaryHarness();
      final before = await h.state();
      final applied = await h.apply([
        LogEntries([newEntry(1), newEntry(2)]),
      ]);
      expect(
        applied.events.first,
        EntriesLogged([fixtureId(1), fixtureId(2)], [today]),
      );
      final undone = await h.undo(applied);
      expect(
        undone.events.first,
        EntryDeleted([fixtureId(1), fixtureId(2)], [today]),
      );
      expect((await h.entry(1)).deletedAt, isNotNull);
      expect(await h.state(), before);
    });

    test('a second apply of the same op fails as a duplicate ID', () async {
      final h = DiaryHarness();
      await h.apply([
        LogEntries([newEntry(1)]),
      ]);
      expect(
        await h.reject([
          LogEntries([newEntry(1)]),
        ]),
        const ConstraintViolation('duplicateId'),
      );
    });
  });

  group('UpdateDiaryEntry', () {
    Future<DiaryHarness> logged() async {
      final h = DiaryHarness();
      await h.apply([
        LogEntries([newEntry(1, when: atDay(today))]),
      ]);
      return h;
    }

    EntryAmount grams(double g) => EntryAmount(
      input: Quantity(g, 'g'),
      amount: g,
      basis: NutrientBasis.per100g,
    );

    test('DY-021 FD-073 an amount edit recomputes from the stored per-100 '
        'values: no drift after 10 edits', () async {
      final h = await logged();
      final amounts = [
        133.3,
        71.9,
        250.5,
        99.1,
        10.0,
        187.7,
        64.3,
        301.0,
        42.2,
        123.4,
      ];
      for (final (i, g) in amounts.indexed) {
        await h.apply([
          UpdateDiaryEntry(fixtureId(1), i + 1, EntryPatch(amount: grams(g))),
        ]);
      }
      final e = (await h.reads.entriesOn(today)).single;
      final expected = const NutritionCalculator().forAmount(
        per100: foodOf(1).per100,
        amount: amounts.last,
        basis: NutrientBasis.per100g,
      );
      expect(e.snapshot, expected.nutrients);
      expect(e.food.per100, foodOf(1).per100);
      expect(e.version, 11);
      expect(e.editedByUser, isFalse);
    });

    test('DY-021 an amount edit + undo restores the exact state', () async {
      final h = await logged();
      final before = await h.state();
      final applied = await h.apply([
        UpdateDiaryEntry(fixtureId(1), 1, EntryPatch(amount: grams(80))),
      ]);
      expect(await h.state(), isNot(before));
      expect(applied.events.first, EntryChanged([fixtureId(1)], [today]));
      await h.undo(applied);
      expect(await h.state(), before);
    });

    test('DY-021 a food change replaces ref, names, per-100 and provenance '
        'together, keeping the amount; + undo', () async {
      final h = await logged();
      final before = await h.state();
      final food = EntryFood(
        ref: FoodRef.personal('mine'),
        names: FoodNames('My dish'),
        per100: Nutrients(kcal: 100, protein: 1, carbs: 2, fat: 3, fiber: 4),
        provenance: Provenance(source: FoodSource.yours),
      );
      final applied = await h.apply([
        UpdateDiaryEntry(fixtureId(1), 1, EntryPatch(food: food)),
      ]);
      final e = (await h.reads.entriesOn(today)).single;
      expect(e.food, food);
      expect(e.amount.amount, 150);
      expect(e.snapshot.kcal, 150);
      expect((await h.entry(1)).nameAr, isNull);
      await h.undo(applied);
      expect(await h.state(), before);
    });

    test('DY-021 a slot change; a time change keeps local_date; a date change '
        'keeps the local time of day; each + undo', () async {
      final h = await logged();
      Future<Applied> edit(EntryPatch patch) async {
        final version = (await h.entry(1)).version;
        return await h.apply([UpdateDiaryEntry(fixtureId(1), version, patch)]);
      }

      Future<void> editAndUndo(EntryPatch patch) async {
        final before = await h.state();
        final applied = await edit(patch);
        expect(await h.state(), isNot(before));
        await h.undo(applied);
        expect(await h.state(), before);
      }

      await editAndUndo(EntryPatch(slotId: _dinner));
      await editAndUndo(EntryPatch(localTime: LocalTime(9, 30)));
      await editAndUndo(EntryPatch(localDate: _past));

      await edit(EntryPatch(localTime: LocalTime(9, 30)));
      var e = await h.entry(1);
      expect(e.localDate, '2026-10-17');
      expect(
        e.occurredAtUtc,
        DateTime.utc(2026, 10, 17, 9, 30).millisecondsSinceEpoch,
      );
      final date = await edit(EntryPatch(localDate: _past));
      e = await h.entry(1);
      expect(e.localDate, '2026-10-10');
      expect(
        e.occurredAtUtc,
        DateTime.utc(2026, 10, 10, 9, 30).millisecondsSinceEpoch,
      );
      expect(date.events.first, EntryChanged([fixtureId(1)], [today, _past]));
    });

    test('DY-022 a day move keeps the stored entry tz_offset_min and '
        'recomputes occurred_at_utc', () async {
      final h = DiaryHarness();
      await h.apply([
        LogEntries([
          newEntry(
            1,
            when: .at(EntryTime(DateTime.utc(2026, 10, 16, 22, 30), 180)),
          ),
        ]),
      ]);
      // Local 2026-10-17 01:30 at +03:00.
      await h.apply([
        UpdateDiaryEntry(fixtureId(1), 1, EntryPatch(localDate: _past)),
      ]);
      final e = await h.entry(1);
      expect(e.tzOffsetMin, 180);
      expect(e.localDate, '2026-10-10');
      expect(
        e.occurredAtUtc,
        DateTime.utc(2026, 10, 9, 22, 30).millisecondsSinceEpoch,
      );
    });

    test('DY-003 moving an entry to a future date is rejected', () async {
      final h = await logged();
      expect(
        await h.reject([
          UpdateDiaryEntry(
            fixtureId(1),
            1,
            EntryPatch(localDate: LocalDate(2026, 10, 18)),
          ),
        ]),
        const InvalidOp('futureDate'),
      );
    });

    test('a stale expectedVersion is a VersionConflict; a missing entry is '
        'RowNotFound', () async {
      final h = await logged();
      expect(
        await h.reject([
          UpdateDiaryEntry(fixtureId(1), 5, EntryPatch(slotId: _dinner)),
        ]),
        VersionConflict(
          entity: 'diaryEntry',
          id: fixtureId(1),
          expected: 5,
          actual: 1,
        ),
      );
      expect(
        await h.reject([
          UpdateDiaryEntry(fixtureId(9), 1, EntryPatch(slotId: _dinner)),
        ]),
        RowNotFound(entity: 'diaryEntry', id: fixtureId(9)),
      );
    });

    test('FD-073 editing an entry never changes another entry of the same '
        'food', () async {
      final h = DiaryHarness();
      final same = FoodRef.catalog('shared', version: '1');
      await h.apply([
        LogEntries([newEntry(1, ref: same), newEntry(2, ref: same)]),
      ]);
      final other = (await h.reads.entriesOn(today)).last;
      await h.apply([
        UpdateDiaryEntry(
          fixtureId(1),
          1,
          EntryPatch(
            amount: grams(10),
            food: foodOf(5, kcal: 999, ref: same),
          ),
        ),
      ]);
      expect((await h.reads.entriesOn(today)).last, other);
    });
  });

  group('MoveEntries and DeleteEntries', () {
    test('DY-022 MoveEntries to another slot and day + undo', () async {
      final h = DiaryHarness();
      await h.apply([
        LogEntries([newEntry(1), newEntry(2)]),
      ]);
      final before = await h.state();
      final applied = await h.apply([
        MoveEntries(
          [VersionedId(fixtureId(1), 1), VersionedId(fixtureId(2), 1)],
          toDate: _past,
          toSlotId: _dinner,
        ),
      ]);
      expect((await h.entry(2)).localDate, '2026-10-10');
      expect((await h.entry(2)).slotId, _dinner);
      expect(
        applied.events.first,
        EntryChanged([fixtureId(1), fixtureId(2)], [today, _past]),
      );
      await h.undo(applied);
      expect(await h.state(), before);
    });

    test('moving an entry to where it already is writes nothing', () async {
      final h = DiaryHarness();
      await h.apply([
        LogEntries([newEntry(1)]),
      ]);
      final applied = await h.apply([
        MoveEntries([VersionedId(fixtureId(1), 1)], toDate: today),
      ]);
      expect((await h.entry(1)).version, 1);
      expect(applied.events.whereType<EntryChanged>(), isEmpty);
    });

    test('DY-022 DeleteEntries tombstones, undo revives; EntryDeleted then '
        'EntriesLogged', () async {
      final h = DiaryHarness();
      await h.apply([
        LogEntries([newEntry(1), newEntry(2)]),
      ]);
      final before = await h.state();
      final applied = await h.apply([
        DeleteEntries([VersionedId(fixtureId(1), 1)]),
      ]);
      expect((await h.entry(1)).deletedAt, isNotNull);
      expect(applied.events.first, EntryDeleted([fixtureId(1)], [today]));
      final undone = await h.undo(applied);
      expect(undone.events.first, EntriesLogged([fixtureId(1)], [today]));
      expect(await h.state(), before);
      expect(
        await h.reject([
          DeleteEntries([VersionedId(fixtureId(1), 1)]),
        ]),
        isA<VersionConflict>(),
      );
    });
  });

  group('MarkDay', () {
    test('DY-004 mark, unmark: one row with the derived dayMark ID, DayMarked '
        'each time, + undo', () async {
      final h = DiaryHarness();
      final before = await h.state();
      final marked = await h.apply([MarkDay(today, incomplete: true)]);
      await h.undo(marked);
      expect(await h.state(), before);
      await h.apply([MarkDay(today, incomplete: true)]);
      final rows = await h.db.select(h.db.dayMarks).get();
      expect(rows.single.id, naturalId('dayMark', '2026-10-17'));
      expect(rows.single.incomplete, isTrue);
      expect((await h.reads.markOn(today))?.incomplete, isTrue);

      final unmarked = await h.apply([MarkDay(today, incomplete: false)]);
      expect(unmarked.events.first, DayMarked(today, incomplete: false));
      expect(
        (await h.db.select(h.db.dayMarks).get()).single.incomplete,
        isFalse,
      );

      final undone = await h.undo(unmarked);
      expect(undone.events.first, DayMarked(today, incomplete: true));
      expect((await h.reads.markOn(today))?.incomplete, isTrue);

      final markedAgain = await h.apply([MarkDay(today, incomplete: true)]);
      expect(markedAgain.events.whereType<DayMarked>(), isEmpty);
    });

    test('DY-004 undoing a mark emits the restored (unmarked) state', () async {
      final h = DiaryHarness();
      final marked = await h.apply([MarkDay(today, incomplete: true)]);
      final undone = await h.undo(marked);
      expect(undone.events.first, DayMarked(today, incomplete: false));
    });

    test('DY-004 unmark + undo restores the exact state', () async {
      final h = DiaryHarness();
      await h.apply([MarkDay(today, incomplete: true)]);
      final before = await h.state();
      final unmarked = await h.apply([MarkDay(today, incomplete: false)]);
      await h.undo(unmarked);
      expect(await h.state(), before);
    });

    test('DY-003 a future day cannot be marked', () async {
      final h = DiaryHarness();
      expect(
        await h.reject([MarkDay(LocalDate(2026, 10, 18), incomplete: true)]),
        const InvalidOp('futureDate'),
      );
      expect(await h.db.select(h.db.dayMarks).get(), isEmpty);
    });

    test('DY-004 marking a day as it already is writes nothing', () async {
      final h = DiaryHarness();
      final applied = await h.apply([MarkDay(today, incomplete: false)]);
      expect(await h.db.select(h.db.dayMarks).get(), isEmpty);
      expect(applied.events.whereType<DayMarked>(), isEmpty);
    });
  });
}
