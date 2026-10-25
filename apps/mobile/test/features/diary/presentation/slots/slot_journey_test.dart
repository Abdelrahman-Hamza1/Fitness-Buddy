import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../today/presentation/support/today_support.dart';
import '../../../today/presentation/today_actions_test.dart' show settle;
import '../../support/diary_harness.dart';
import 'slots_support.dart' show unmount;

void main() {
  testWidgets('DY-010 DY-011 exit 2 Today follows the host slot journey and '
      'shows storage totals after every change', (tester) async {
    final rig = TodayRig();
    final container = ProviderContainer(overrides: rig.overrides);
    addTearDown(container.dispose);
    final repo = container.read(diaryRepositoryProvider);
    final actions = container.read(slotActionsProvider.notifier);
    tester.view
      ..physicalSize = const Size(360, 1400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: phoneApp(const TodayScreen()),
      ),
    );

    Future<SlotRecord> record(String id) async =>
        (await repo.watchSlotRecords().first).singleWhere(
          (r) => r.slot.id == id,
        );

    Future<void> check() async {
      await settle(tester);
      final stored = (await tester.runAsync(
        () => rig.diary.reads.entriesOn(testToday),
      ))!;
      final view = container.read(dayViewProvider(testToday)).requireValue;
      expect(
        view.raw.entries.map((e) => (e.id, e.slotId, e.version)),
        stored.map((e) => (e.id, e.slotId, e.version)),
      );
      final page = find.byKey(ValueKey<LocalDate>(testToday));
      expect(
        tester
            .widget<FbBigNumber>(
              find.descendant(of: page, matching: find.byType(FbBigNumber)),
            )
            .value,
        DisplayRounding.kcal(DiaryTotals.day(stored).kcal).toString(),
      );
      for (final section in view.layout.sections) {
        final label =
            section.slot!.name ??
            switch (section.slot!.defaultKey) {
              'breakfast' => 'Breakfast',
              'lunch' => 'Lunch',
              'dinner' => 'Dinner',
              _ => 'Snacks',
            };
        expect(
          find.descendant(
            of: page,
            matching: find.widgetWithText(FbDisclosureRow, label),
          ),
          findsOneWidget,
        );
      }
    }

    await check();
    late String pre;
    await tester.runAsync(() async {
      expect(
        await actions.addSlot(
          'Pre-workout',
          window: TimeWindow(17 * 60, 18 * 60),
        ),
        isA<SlotDone>(),
      );
      pre = (await repo.watchSlotRecords().first)
          .singleWhere((r) => r.slot.name == 'Pre-workout')
          .slot
          .id;
    });
    await check();
    await tester.runAsync(() async {
      expect(
        await actions.updateSlot(
          await record(DefaultSlots.snacksId),
          MealSlotPatch(setName: true, name: 'Evening snack'),
        ),
        isA<SlotDone>(),
      );
      expect(
        await actions.updateSlot(
          await record(DefaultSlots.breakfastId),
          MealSlotPatch(setWindow: true, window: TimeWindow(300, 600)),
        ),
        isA<SlotDone>(),
      );
    });
    await check();
    await tester.runAsync(() async {
      final records = await repo.watchSlotRecords().first;
      expect(
        await actions.reorder([
          records.last,
          ...records.take(records.length - 1),
        ]),
        isA<SlotDone>(),
      );
    });
    await check();
    await tester.runAsync(() async {
      rig.diary.clock.utc = DateTime.utc(2026, 10, 17, 17, 30);
      await rig.diary.apply([
        LogEntries([
          newEntry(1, when: EntryWhen.at(EntryTime.now(rig.diary.clock))),
        ]),
      ]);
      rig.diary.clock.utc = DateTime.utc(2026, 10, 17, 10, 30);
      await rig.diary.apply([
        LogEntries([
          newEntry(2, when: EntryWhen.at(EntryTime.now(rig.diary.clock))),
        ]),
      ]);
      expect((await rig.diary.entry(1)).slotId, pre);
      expect((await rig.diary.entry(2)).slotId, DefaultSlots.snacksId);
    });
    await check();
    await tester.runAsync(() async {
      expect(
        await actions.removeSlot(
          await record(pre),
          shown: await repo.watchSlotContents(pre).first,
          moveTo: await record(DefaultSlots.dinnerId),
        ),
        isA<SlotDone>(),
      );
      expect((await rig.diary.entry(1)).slotId, DefaultSlots.dinnerId);
    });
    await check();
    expect(find.widgetWithText(FbDisclosureRow, 'Pre-workout'), findsNothing);
    await unmount(tester, rig);
  });
}
