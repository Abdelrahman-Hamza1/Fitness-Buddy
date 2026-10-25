import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/diary_fixtures.dart';
import '../support/diary_harness.dart';
import 'diary_edit_commands_test.dart' show setup;

/// Every column of every diary entry and dish group, tombstones included:
/// what "byte-identical" means for rows the slot editor must not touch.
Future<String> diaryRows(DiaryHarness h) async {
  final rows = <Object?>[];
  for (final table in ['diary_entries', 'dish_groups']) {
    final result = await h.db
        .customSelect('SELECT * FROM $table ORDER BY id')
        .get();
    rows.add([for (final row in result) row.data]);
  }
  return rows.toString();
}

/// An entry logged by the clock time [hour]:[minute] with no meal given.
NewDiaryEntry autoAt(int n, int hour, int minute) => newEntry(
  n,
  when: .at(EntryTime(DateTime.utc(2026, 10, 17, hour, minute), 0)),
);

Future<String> slotOf(DiaryHarness h, int n) async => (await h.entry(n)).slotId;

Future<SlotRecord> record(ProviderContainer c, String id) async =>
    (await c.read(diaryRepositoryProvider).watchSlotRecords().first).firstWhere(
      (r) => r.slot.id == id,
    );

Future<String> add(ProviderContainer c, String name, TimeWindow? window) async {
  final done =
      await c.read(slotActionsProvider.notifier).addSlot(name, window: window)
          as SlotDone;
  expect(done.kind, SlotKind.slotAdded);
  final records = await c
      .read(diaryRepositoryProvider)
      .watchSlotRecords()
      .first;
  return records.firstWhere((r) => r.slot.name == name).slot.id;
}

void main() {
  test('DY-011 PA4 window edits and reordering leave existing entries and '
      'groups untouched (every column and version identical) while new '
      'automatic logs follow shortest-window-wins', () async {
    final h = DiaryHarness();
    final c = setup(h);
    // Existing items in several meals, one of them a dish group.
    await h.apply([
      CreateDishGroup(
        id: fixtureId(50),
        name: 'Dish',
        date: today,
        slotId: DefaultSlots.dinnerId,
      ),
      LogEntries([
        newEntry(1, slotId: DefaultSlots.breakfastId),
        newEntry(2, slotId: DefaultSlots.dinnerId, group: 50),
        newEntry(3, slotId: DefaultSlots.snacksId),
      ]),
    ]);
    final before = await diaryRows(h);

    // Add Pre-workout 17:00-18:00, move Breakfast's window, reorder.
    final pre = await add(c, 'Pre-workout', TimeWindow(17 * 60, 18 * 60));
    final actions = c.read(slotActionsProvider.notifier);
    final breakfast = await record(c, DefaultSlots.breakfastId);
    expect(
      await actions.updateSlot(
        breakfast,
        MealSlotPatch(window: TimeWindow(5 * 60, 10 * 60), setWindow: true),
      ),
      isA<SlotDone>(),
    );
    final records = await c
        .read(diaryRepositoryProvider)
        .watchSlotRecords()
        .first;
    expect(await actions.reorder(records.reversed.toList()), isA<SlotDone>());
    expect(await diaryRows(h), before);

    // Shortest window wins: 17:30 is in Dinner 16-22 and Pre-workout 17-18.
    await h.apply([
      LogEntries([autoAt(4, 17, 30), autoAt(5, 10, 30), autoAt(6, 7, 0)]),
    ]);
    expect(await slotOf(h, 4), pre);
    // 10:30 is after Breakfast's new end (10:00) and before Lunch.
    expect(await slotOf(h, 5), DefaultSlots.snacksId);
    expect(await slotOf(h, 6), DefaultSlots.breakfastId);
    // The older rows are still exactly what they were.
    expect((await h.entry(2)).dishGroupId, fixtureId(50));
  });

  test('DY-011 overnight overlap: Late 23:00-01:00 inside Night 22:00-02:00 '
      'catches 00:30; 01:00 goes to Night (exclusive end), 02:00 to the '
      'next rule', () async {
    final h = DiaryHarness();
    final c = setup(h);
    final night = await add(c, 'Night', TimeWindow(22 * 60, 2 * 60));
    final late = await add(c, 'Late', TimeWindow(23 * 60, 60));
    await h.apply([
      LogEntries([
        autoAt(1, 0, 30),
        autoAt(2, 1, 0),
        autoAt(3, 2, 0),
        autoAt(4, 22, 30),
      ]),
    ]);
    expect(await slotOf(h, 1), late);
    expect(await slotOf(h, 2), night);
    // 02:00 is in no window: the catch-all (Snacks) is the next rule.
    expect(await slotOf(h, 3), DefaultSlots.snacksId);
    // 22:30 is in Night 22-02 and Dinner 16-22? No: Dinner ends at 22:00.
    expect(await slotOf(h, 4), night);
  });

  test('DY-011 exclusive end: with Pre-workout 17:00-18:00, a log at 18:00 '
      'goes to Dinner', () async {
    final h = DiaryHarness();
    final c = setup(h);
    final pre = await add(c, 'Pre-workout', TimeWindow(17 * 60, 18 * 60));
    await h.apply([
      LogEntries([autoAt(1, 17, 59), autoAt(2, 18, 0), autoAt(3, 17, 0)]),
    ]);
    expect(await slotOf(h, 1), pre);
    expect(await slotOf(h, 2), DefaultSlots.dinnerId);
    expect(await slotOf(h, 3), pre);
  });

  test('DY-010 exit 2 host journey: add Pre-workout 17:00-18:00, rename '
      'Snacks to Evening snack, move Breakfast to 05:00-10:00, reorder; food '
      'with no meal lands in Pre-workout at 17:30 and in Evening snack at '
      '10:30; remove Pre-workout moving its items to Dinner; totals match '
      'storage after each step', () async {
    final h = DiaryHarness();
    final c = setup(h);
    final actions = c.read(slotActionsProvider.notifier);
    final repo = c.read(diaryRepositoryProvider);

    Future<void> totalsMatchStorage(String step) async {
      final day = await repo.watchDay(today).first;
      final entries = await h.reads.entriesOn(today);
      expect(day.totals.kcal, DiaryTotals.day(entries).kcal, reason: step);
      for (final slot in day.slots.where((s) => s.active)) {
        expect(
          day.entries.where((e) => e.slotId == slot.id).length,
          entries.where((e) => e.slotId == slot.id).length,
          reason: '$step: ${slot.id}',
        );
      }
    }

    await h.apply([
      LogEntries([newEntry(1, slotId: DefaultSlots.breakfastId)]),
    ]);
    await totalsMatchStorage('start');

    final pre = await add(c, 'Pre-workout', TimeWindow(17 * 60, 18 * 60));
    await totalsMatchStorage('added');
    final snacks = await record(c, DefaultSlots.snacksId);
    expect(
      await actions.updateSlot(
        snacks,
        MealSlotPatch(name: 'Evening snack', setName: true),
      ),
      isA<SlotDone>(),
    );
    final breakfast = await record(c, DefaultSlots.breakfastId);
    expect(
      await actions.updateSlot(
        breakfast,
        MealSlotPatch(window: TimeWindow(5 * 60, 10 * 60), setWindow: true),
      ),
      isA<SlotDone>(),
    );
    await totalsMatchStorage('edited');
    final order = await repo.watchSlotRecords().first;
    expect(
      await actions.reorder([order.last, ...order.take(order.length - 1)]),
      isA<SlotDone>(),
    );
    await totalsMatchStorage('reordered');

    await h.apply([
      LogEntries([autoAt(2, 17, 30), autoAt(3, 10, 30)]),
    ]);
    expect(await slotOf(h, 2), pre);
    expect(await slotOf(h, 3), DefaultSlots.snacksId);
    await totalsMatchStorage('logged');

    final removed = await actions.removeSlot(
      await record(c, pre),
      shown: await repo.watchSlotContents(pre).first,
      moveTo: await record(c, DefaultSlots.dinnerId),
    );
    expect(removed, isA<SlotDone>());
    expect(await slotOf(h, 2), DefaultSlots.dinnerId);
    await totalsMatchStorage('removed');
  });
}
