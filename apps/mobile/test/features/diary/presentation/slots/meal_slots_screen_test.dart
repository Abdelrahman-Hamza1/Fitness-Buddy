import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../today/presentation/support/today_support.dart';
import '../../../today/presentation/today_actions_test.dart' show settle;
import '../../support/diary_fixtures.dart' show fixtureId;
import '../../support/diary_harness.dart';
import 'slots_support.dart';

void main() {
  testWidgets('DY-010 the Meal times screen lists the meals in order with '
      'their windows and item counts, and the footnote', (tester) async {
    final rig = TodayRig();
    await tester.runAsync(
      () => rig.diary.apply([
        LogEntries([
          logIn(1, DefaultSlots.breakfastId),
          logIn(2, DefaultSlots.breakfastId),
          logIn(3, DefaultSlots.lunchId),
        ]),
      ]),
    );
    await pumpMealTimes(tester, rig);

    final titles = [
      for (final row in tester.widgetList<FbListRow>(find.byType(FbListRow)))
        row.title,
    ];
    expect(titles, ['Breakfast', 'Lunch', 'Dinner', 'Snacks']);
    expect(rowTexts(tester, 'Breakfast'), [
      'Breakfast',
      '4:00 AM – 11:00 AM · 2 items',
    ]);
    expect(rowTexts(tester, 'Lunch').last, '11:00 AM – 4:00 PM · 1 item');
    expect(rowTexts(tester, 'Snacks').last, 'Any time · no items');
    expect(
      find.text(
        "Times decide which meal new food goes into. Food you've already "
        'logged stays where it is.',
      ),
      findsOneWidget,
    );
    expect(isEnabled(tester, button('Add meal')), isTrue);
    await unmount(tester, rig);
  });

  testWidgets('DY-010 UX-030 add a meal with a window: it is placed by its '
      'start, shows Undo, and Undo removes it again', (tester) async {
    final rig = TodayRig();
    await pumpMealTimes(tester, rig);

    await tester.tap(button('Add meal'));
    await tester.pumpAndSettle();
    expect(find.text('Add meal'), findsNWidgets(2)); // button + sheet title
    // Save waits for a name.
    expect(isEnabled(tester, button('Add')), isFalse);
    await tester.enterText(find.byType(TextField), 'Pre workout');
    await tester.pump();
    expect(isEnabled(tester, button('Add')), isTrue);

    // Times: on at the current hour (12:00 on the test clock) for two hours.
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('12:00 PM'), findsOneWidget);
    expect(find.text('2:00 PM'), findsOneWidget);
    // Pick 5:00 PM to 6:00 PM.
    await tester.tap(find.widgetWithText(FbChoiceChip, 'From'));
    await tester.pumpAndSettle();
    await pickTime(tester, 5, 0, pm: true);
    await tester.tap(find.widgetWithText(FbChoiceChip, 'To'));
    await tester.pumpAndSettle();
    await pickTime(tester, 6, 0, pm: true);

    await tester.tap(button('Add'));
    await settle(tester);
    expect(find.text('Added Pre workout'), findsOneWidget);
    final titles = [
      for (final row in tester.widgetList<FbListRow>(find.byType(FbListRow)))
        row.title,
    ];
    // Before Dinner (16:00) it would start earlier; 17:00 is after it.
    expect(titles, ['Breakfast', 'Lunch', 'Dinner', 'Pre workout', 'Snacks']);
    expect(
      rowTexts(tester, 'Pre workout').last,
      startsWith('5:00 PM – 6:00 PM'),
    );

    await tester.tap(find.text('Undo'));
    await settle(tester);
    expect(mealRow('Pre workout'), findsNothing);
    await unmount(tester, rig);
  });

  testWidgets('DY-010 DY-011 time windows reject equal endpoints and accept '
      'a window across midnight', (tester) async {
    final rig = TodayRig();
    await pumpMealTimes(tester, rig);
    await tester.tap(button('Add meal'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Night');
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FbChoiceChip, 'From'));
    await tester.pumpAndSettle();
    await pickTime(tester, 11, 0, pm: true);
    await tester.tap(find.widgetWithText(FbChoiceChip, 'To'));
    await tester.pumpAndSettle();
    await pickTime(tester, 11, 0, pm: true);
    expect(find.text("From and To can't be the same time."), findsOneWidget);
    expect(isEnabled(tester, button('Add')), isFalse);
    await tester.tap(find.widgetWithText(FbChoiceChip, 'To'));
    await tester.pumpAndSettle();
    await pickTime(tester, 1, 0, pm: false);
    expect(isEnabled(tester, button('Add')), isTrue);
    await tester.tap(button('Add'));
    await settle(tester);
    expect(
      rowTexts(tester, 'Night').last,
      startsWith('11:00 PM – 1:00 AM, overnight'),
    );
    await unmount(tester, rig);
  });

  testWidgets('UX-030 DY-010 a rename shows Undo; Undo restores the name; '
      'Undo after a conflicting change says it changed since', (tester) async {
    final rig = TodayRig();
    await pumpMealTimes(tester, rig);

    await tester.tap(mealRow('Snacks'));
    await tester.pumpAndSettle();
    // The built-in meal opens on its label, with its own hint when emptied.
    final field = find.byType(TextField);
    expect(tester.widget<TextField>(field).controller!.text, 'Snacks');
    await tester.enterText(field, '');
    await tester.pump();
    expect(find.text('Leave empty to use Snacks'), findsOneWidget);
    await tester.enterText(field, 'Evening snack');
    await tester.pump();
    await tester.tap(button('Save'));
    await settle(tester);

    expect(find.text('Evening snack updated'), findsOneWidget);
    expect(mealRow('Evening snack'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await settle(tester);
    expect(mealRow('Snacks'), findsOneWidget);

    // Rename again, then change the meal elsewhere: Undo must refuse.
    await tester.tap(mealRow('Snacks'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Late bite');
    await tester.pump();
    await tester.tap(button('Save'));
    await settle(tester);
    await tester.runAsync(
      () => rig.diary.editSlot(
        DefaultSlots.snacksId,
        const MealSlotsCompanion(name: Value('Elsewhere')),
      ),
    );
    await settle(tester);
    await tester.tap(find.text('Undo'));
    await settle(tester);
    expect(find.text("Couldn't undo, it was changed since."), findsOneWidget);
    expect(mealRow('Elsewhere'), findsOneWidget);
    await unmount(tester, rig);
  });

  testWidgets('UX-052 D12 an edit sheet whose meal was removed says so and '
      'disables Save and Remove', (tester) async {
    final rig = TodayRig();
    await pumpMealTimes(tester, rig);
    await tester.tap(mealRow('Lunch'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Noon');
    await tester.pump();
    expect(isEnabled(tester, button('Save')), isTrue);

    await tester.runAsync(
      () => rig.diary.apply([
        RemoveMealSlot(DefaultSlots.lunchId, 1, expected: SlotContents.empty),
      ]),
    );
    await settle(tester);
    expect(find.text('This meal was removed.'), findsOneWidget);
    expect(isEnabled(tester, button('Save')), isFalse);
    expect(isEnabled(tester, button('Remove meal')), isFalse);
    await unmount(tester, rig);
  });

  testWidgets('UX-052 D12 a changed meal offers Reload, which keeps the typed '
      'name and takes the new window; a stale Save is refused', (tester) async {
    final rig = TodayRig();
    await pumpMealTimes(tester, rig);
    await tester.tap(mealRow('Lunch'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Noon');
    await tester.pump();

    // Another change: the window moves to 12:00-15:00.
    await tester.runAsync(
      () => rig.diary.editSlot(
        DefaultSlots.lunchId,
        const MealSlotsCompanion(
          windowStartMin: Value(12 * 60),
          windowEndMin: Value(15 * 60),
        ),
      ),
    );
    await settle(tester);
    expect(find.text('This meal changed.'), findsOneWidget);
    // Saving the old base is refused, nothing is written.
    await tester.tap(button('Save'));
    await settle(tester);
    expect(find.text('That meal changed. Nothing was saved.'), findsOneWidget);
    expect(mealRow('Lunch'), findsOneWidget);

    await tester.tap(find.text('Reload'));
    await tester.pumpAndSettle();
    expect(find.text('This meal changed.'), findsNothing);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Noon',
    );
    expect(find.text('12:00 PM'), findsOneWidget);
    expect(find.text('3:00 PM'), findsOneWidget);
    await tester.tap(button('Save'));
    await settle(tester);
    expect(mealRow('Noon'), findsOneWidget);
    expect(rowTexts(tester, 'Noon').last, startsWith('12:00 PM – 3:00 PM'));
    await unmount(tester, rig);
  });

  testWidgets(
    "DY-010 D10 a name equal to another meal's label is refused inline",
    (tester) async {
      final rig = TodayRig();
      await pumpMealTimes(tester, rig);
      await tester.tap(mealRow('Snacks'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'lunch');
      await tester.pump();
      expect(find.text('Another meal already has this name.'), findsOneWidget);
      expect(isEnabled(tester, button('Save')), isFalse);
      await tester.enterText(find.byType(TextField), 'Lunchbox');
      await tester.pump();
      expect(find.text('Another meal already has this name.'), findsNothing);
      expect(isEnabled(tester, button('Save')), isTrue);
      await unmount(tester, rig);
    },
  );

  testWidgets(
    'DY-010 D13 the 8th meal disables Add with its hint; the last meal '
    "can't be removed",
    (tester) async {
      final rig = TodayRig();
      await tester.runAsync(() async {
        for (var i = 0; i < 4; i++) {
          await rig.diary.apply([AddMealSlot(newId(i), 'Extra $i')]);
        }
      });
      await pumpMealTimes(tester, rig);
      expect(find.text('You can have up to 8 meals.'), findsOneWidget);
      expect(isEnabled(tester, button('Add meal')), isFalse);
      await unmount(tester, rig);

      final single = TodayRig();
      await tester.runAsync(() async {
        for (final id in [
          DefaultSlots.breakfastId,
          DefaultSlots.lunchId,
          DefaultSlots.dinnerId,
        ]) {
          await single.diary.apply([
            RemoveMealSlot(id, 1, expected: SlotContents.empty),
          ]);
        }
      });
      await pumpMealTimes(tester, single);
      await tester.tap(mealRow('Snacks'));
      await tester.pumpAndSettle();
      expect(find.text('Keep at least one meal.'), findsOneWidget);
      expect(isEnabled(tester, button('Remove meal')), isFalse);
      await unmount(tester, single);
    },
  );

  testWidgets('DY-010 the Move up and Move down actions reorder with Undo; '
      "the list doesn't jump while the write is pending", (tester) async {
    final handle = tester.ensureSemantics();
    final gate = Completer<void>();
    late final TodayRig rig;
    rig = TodayRig(
      apply: (changes) async {
        await gate.future;
        final result = await rig.diary.applier.apply(changes);
        return result;
      },
    );
    await pumpMealTimes(tester, rig);
    List<String> titles() => [
      for (final row in tester.widgetList<FbListRow>(find.byType(FbListRow)))
        row.title,
    ];

    await moveBy(tester, 'Snacks', 'Move up');
    // The write hasn't happened, but the list already shows the new order,
    // and stays there.
    expect(titles(), ['Breakfast', 'Lunch', 'Snacks', 'Dinner']);
    await tester.pump(const Duration(milliseconds: 200));
    expect(titles(), ['Breakfast', 'Lunch', 'Snacks', 'Dinner']);
    // Controls are off while the write is in flight.
    expect(isEnabled(tester, button('Add meal')), isFalse);

    gate.complete();
    await settle(tester);
    expect(titles(), ['Breakfast', 'Lunch', 'Snacks', 'Dinner']);
    expect(find.text('Meals reordered'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await settle(tester);
    expect(titles(), ['Breakfast', 'Lunch', 'Dinner', 'Snacks']);

    await moveBy(tester, 'Breakfast', 'Move down');
    expect(titles(), ['Lunch', 'Breakfast', 'Dinner', 'Snacks']);
    handle.dispose();
    await unmount(tester, rig);
  });

  for (final adding in [true, false]) {
    testWidgets(
      'DY-010 UX-030 queued ${adding ? 'Add' : 'Save'} callbacks submit once '
      'before rebuild',
      (tester) async {
        final gate = Completer<void>();
        var commands = 0;
        late final TodayRig rig;
        rig = TodayRig(
          apply: (changes) async {
            commands++;
            await gate.future;
            return await rig.diary.applier.apply(changes);
          },
        );
        await pumpMealTimes(tester, rig);
        await tester.tap(adding ? button('Add meal') : mealRow('Lunch'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'Noon');
        await tester.pump();
        final submit = tester
            .widget<FbButton>(button(adding ? 'Add' : 'Save'))
            .onPressed!;
        submit();
        submit();
        await tester.pump();
        expect(find.byType(SlotEditSheet), findsOneWidget);
        expect(commands, 1);
        gate.complete();
        await settle(tester);
        expect(commands, 1);
        expect(mealRow('Noon'), findsOneWidget);
        final records = (await tester.runAsync(
          () => DiaryRepository(rig.diary.db).watchSlotRecords().first,
        ))!;
        expect(records.where((r) => r.slot.name == 'Noon'), hasLength(1));
        expect(
          find.text(adding ? 'Added Noon' : 'Noon updated'),
          findsOneWidget,
        );
        // A queued second feedback would appear after the first expires.
        await tester.pump(const Duration(seconds: 6));
        await tester.pumpAndSettle();
        expect(find.text(adding ? 'Added Noon' : 'Noon updated'), findsNothing);
        await unmount(tester, rig);
      },
    );
  }

  for (final dismissal in ['back', 'barrier', 'drag']) {
    testWidgets(
      'DY-010 UX-030 pending save dismissed by $dismissal keeps feedback '
      'and Undo',
      (tester) async {
        final gate = Completer<void>();
        late final TodayRig rig;
        rig = TodayRig(
          apply: (changes) async {
            await gate.future;
            return await rig.diary.applier.apply(changes);
          },
        );
        await pumpMealTimes(tester, rig);
        await tester.tap(mealRow('Lunch'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'Noon');
        await tester.pump();
        await tester.tap(button('Save'));
        await tester.pump();
        await dismissPending(tester, dismissal);
        expect(find.byType(SlotEditSheet), findsNothing);
        gate.complete();
        await settle(tester);
        expect(find.text('Noon updated'), findsOneWidget);
        expect(mealRow('Noon'), findsOneWidget);
        await tester.tap(find.text('Undo'));
        await settle(tester);
        expect(mealRow('Lunch'), findsOneWidget);
        await unmount(tester, rig);
      },
    );

    testWidgets(
      'DY-010 UX-030 pending historical removal dismissed by $dismissal '
      'keeps feedback and Undo',
      (tester) async {
        final gate = Completer<void>();
        late final TodayRig rig;
        rig = TodayRig(
          apply: (changes) async {
            await gate.future;
            return await rig.diary.applier.apply(changes);
          },
        );
        await tester.runAsync(
          () => rig.diary.apply([
            LogEntries([
              logIn(1, DefaultSlots.lunchId),
              logIn(2, DefaultSlots.lunchId, date: testToday.plusDays(-1)),
            ]),
          ]),
        );
        await pumpMealTimes(tester, rig);
        await tester.tap(mealRow('Lunch'));
        await tester.pumpAndSettle();
        await tester.tap(button('Remove meal'));
        await tester.pumpAndSettle();
        await tester.tap(button('Remove and move'));
        await tester.pump();
        await dismissPending(tester, dismissal);
        expect(find.byType(SlotRemoveSheet), findsNothing);
        // The edit sheet below remains open; completion must not pop it.
        expect(find.byType(SlotEditSheet), findsOneWidget);
        gate.complete();
        await settle(tester);
        expect(find.byType(SlotEditSheet), findsOneWidget);
        Navigator.of(tester.element(find.byType(SlotEditSheet))).pop();
        await tester.pumpAndSettle();
        expect(
          find.text('Removed Lunch, moved 2 items to Snacks'),
          findsOneWidget,
        );
        for (final n in [1, 2]) {
          expect(
            (await tester.runAsync(() => rig.diary.entry(n)))!.slotId,
            DefaultSlots.snacksId,
          );
        }
        await tester.tap(find.text('Undo'));
        await settle(tester);
        expect(mealRow('Lunch'), findsOneWidget);
        for (final n in [1, 2]) {
          expect(
            (await tester.runAsync(() => rig.diary.entry(n)))!.slotId,
            DefaultSlots.lunchId,
          );
        }
        await unmount(tester, rig);
      },
    );
  }

  testWidgets('DY-010 D12 editing controls disable while Save is pending', (
    tester,
  ) async {
    final gate = Completer<void>();
    late final TodayRig rig;
    rig = TodayRig(
      apply: (changes) async {
        await gate.future;
        return await rig.diary.applier.apply(changes);
      },
    );
    await pumpMealTimes(tester, rig);
    await tester.tap(mealRow('Lunch'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Noon');
    await tester.pump();
    await tester.tap(button('Save'));
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
    for (final chip in tester.widgetList<FbChoiceChip>(
      find.byType(FbChoiceChip),
    )) {
      expect(chip.onTap, isNull);
    }
    expect(isEnabled(tester, button('Save')), isFalse);
    expect(isEnabled(tester, button('Remove meal')), isFalse);
    gate.complete();
    await settle(tester);
    expect(mealRow('Noon'), findsOneWidget);
    await unmount(tester, rig);
  });

  testWidgets('DY-010 a refused reorder snaps the list back and says so', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final rig = TodayRig(
      apply: (_) async => const Rejected(InvalidOp('sourceChanged')),
    );
    await pumpMealTimes(tester, rig);
    await moveBy(tester, 'Snacks', 'Move up');
    final titles = [
      for (final row in tester.widgetList<FbListRow>(find.byType(FbListRow)))
        row.title,
    ];
    expect(titles, ['Breakfast', 'Lunch', 'Dinner', 'Snacks']);
    expect(
      find.text("Couldn't change the order. It was left as it was."),
      findsOneWidget,
    );
    handle.dispose();
    await unmount(tester, rig);
  });

  group('remove sheet', () {
    /// Lunch with three entries on two days, opened on its remove sheet.
    Future<TodayRig> openRemove(
      WidgetTester tester, {
      List<Override> extra = const [],
    }) async {
      final rig = TodayRig();
      await tester.runAsync(
        () => rig.diary.apply([
          LogEntries([
            logIn(1, DefaultSlots.lunchId),
            logIn(2, DefaultSlots.lunchId),
            logIn(3, DefaultSlots.lunchId, date: testToday.plusDays(-1)),
          ]),
        ]),
      );
      await pumpMealTimes(tester, rig, extra: extra);
      await tester.tap(mealRow('Lunch'));
      await tester.pumpAndSettle();
      await tester.tap(button('Remove meal'));
      await tester.pumpAndSettle();
      return rig;
    }

    testWidgets(
      'DY-010 D11 PA1 the sheet shows the live count and days, defaults to '
      'the meal without a window, and removes and moves with Undo',
      (tester) async {
        final rig = await openRemove(tester);
        expect(
          find.text('Lunch has 3 items on 2 days. Move them to:'),
          findsOneWidget,
        );
        expect(
          tester
              .widget<FbOptionList<String>>(find.byType(FbOptionList<String>))
              .selected,
          DefaultSlots.snacksId,
        );
        expect(button('Remove and move'), findsOneWidget);

        // A new item arrives under the open sheet: the count follows.
        await tester.runAsync(
          () => rig.diary.apply([
            LogEntries([logIn(4, DefaultSlots.lunchId)]),
          ]),
        );
        await settle(tester);
        expect(
          find.text('Lunch has 4 items on 2 days. Move them to:'),
          findsOneWidget,
        );

        await tester.tap(
          find.descendant(
            of: find.byType(FbOptionList<String>),
            matching: find.text('Dinner'),
          ),
        );
        await tester.pump();
        await tester.tap(button('Remove and move'));
        await settle(tester);
        expect(
          find.text('Removed Lunch, moved 4 items to Dinner'),
          findsOneWidget,
        );
        // Both sheets closed; the list no longer has Lunch.
        expect(find.text('Remove Lunch'), findsNothing);
        expect(mealRow('Lunch'), findsNothing);
        expect(rowTexts(tester, 'Dinner').last, endsWith('4 items'));
        final moved = await tester.runAsync(() => rig.diary.entry(1));
        expect(moved!.slotId, DefaultSlots.dinnerId);

        await tester.tap(find.text('Undo'));
        await settle(tester);
        expect(mealRow('Lunch'), findsOneWidget);
        expect(rowTexts(tester, 'Lunch').last, endsWith('4 items'));
        await unmount(tester, rig);
      },
    );

    testWidgets('DY-010 PA1 a destination renamed after the pick refuses with '
        '"That meal changed. Nothing was removed."', (tester) async {
      final rig = await openRemove(tester);
      // Snacks is the picked (default) destination; it is renamed.
      await tester.runAsync(
        () => rig.diary.editSlot(
          DefaultSlots.snacksId,
          const MealSlotsCompanion(name: Value('Bites')),
        ),
      );
      await settle(tester);
      await tester.tap(button('Remove and move'));
      await settle(tester);
      expect(
        find.text('That meal changed. Nothing was removed.'),
        findsOneWidget,
      );
      expect(find.text('Remove Lunch'), findsOneWidget);
      final entry = await tester.runAsync(() => rig.diary.entry(1));
      expect(entry!.slotId, DefaultSlots.lunchId);

      // The user has now seen the new name: the next try goes through.
      await tester.tap(button('Remove and move'));
      await settle(tester);
      expect(
        find.text('Removed Lunch, moved 3 items to Bites'),
        findsOneWidget,
      );
      await unmount(tester, rig);
    });

    testWidgets(
      'DY-010 D11 the sheet refuses with "That meal changed. Nothing was '
      'removed." when its contents changed after they were shown',
      (tester) async {
        // The sheet is shown a snapshot that goes stale: its stream never
        // re-emits.
        final stale = SlotContents(
          entries: [
            VersionedId(fixtureId(1), 1),
            VersionedId(fixtureId(2), 1),
            VersionedId(fixtureId(3), 1),
          ],
          dates: [testToday.toString(), testToday.plusDays(-1).toString()],
        );
        final rig = await openRemove(
          tester,
          extra: [
            slotContentsProvider(DefaultSlots.lunchId)
                .overrideWith((ref) => Stream.value(stale)),
          ],
        );
        await tester.runAsync(
          () => rig.diary.apply([
            LogEntries([logIn(4, DefaultSlots.lunchId)]),
          ]),
        );
        await settle(tester);
        await tester.tap(button('Remove and move'));
        await settle(tester);
        expect(
          find.text('That meal changed. Nothing was removed.'),
          findsOneWidget,
        );
        final entry = await tester.runAsync(() => rig.diary.entry(4));
        expect(entry!.slotId, DefaultSlots.lunchId);
        await unmount(tester, rig);
      },
    );

    testWidgets('DY-010 UX-052 the remove sheet offers Reload when its source '
        'changes and preserves the chosen destination', (tester) async {
      final rig = await openRemove(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(FbOptionList<String>),
          matching: find.text('Dinner'),
        ),
      );
      await tester.pump();
      await tester.runAsync(
        () => rig.diary.editSlot(
          DefaultSlots.lunchId,
          const MealSlotsCompanion(name: Value('Noon')),
        ),
      );
      await settle(tester);
      Finder inRemove(String text) => find.descendant(
        of: find.byType(SlotRemoveSheet),
        matching: find.text(text),
      );
      expect(inRemove('This meal changed.'), findsOneWidget);
      await tester.tap(inRemove('Reload'));
      await tester.pump();
      expect(inRemove('This meal changed.'), findsNothing);
      expect(
        tester
            .widget<FbOptionList<String>>(find.byType(FbOptionList<String>))
            .selected,
        DefaultSlots.dinnerId,
      );
      await tester.tap(button('Remove and move'));
      await settle(tester);
      expect(
        find.text('Removed Noon, moved 3 items to Dinner'),
        findsOneWidget,
      );
      await unmount(tester, rig);
    });

    testWidgets('DY-010 D11 an empty meal just goes, with Undo', (
      tester,
    ) async {
      final rig = TodayRig();
      await pumpMealTimes(tester, rig);
      await tester.tap(mealRow('Dinner'));
      await tester.pumpAndSettle();
      await tester.tap(button('Remove meal'));
      await tester.pumpAndSettle();
      expect(
        find.text('Dinner has nothing logged. It will leave your day.'),
        findsOneWidget,
      );
      await tester.tap(button('Remove'));
      await settle(tester);
      expect(find.text('Removed Dinner'), findsOneWidget);
      expect(mealRow('Dinner'), findsNothing);
      await tester.tap(find.text('Undo'));
      await settle(tester);
      expect(mealRow('Dinner'), findsOneWidget);
      await unmount(tester, rig);
    });
  });

  testWidgets('UX-070 the Meal times screen and its sheets at text scale 2.0 '
      'on a small phone: no overflow, and Save and Remove stay on screen', (
    tester,
  ) async {
    final rig = TodayRig();
    await tester.runAsync(
      () => rig.diary.apply([
        LogEntries([logIn(1, DefaultSlots.lunchId)]),
      ]),
    );
    await pumpMealTimes(tester, rig, textScale: 2, size: const Size(320, 640));
    expect(tester.takeException(), isNull);
    // Add stays reachable under the list.
    expect(tester.getRect(button('Add meal')).bottom, lessThanOrEqualTo(640));

    await tester.tap(mealRow('Lunch'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    for (final label in ['Save', 'Remove meal']) {
      final rect = tester.getRect(button(label));
      expect(rect.bottom, lessThanOrEqualTo(640), reason: label);
      expect(rect.top, greaterThan(0), reason: label);
    }
    await tester.tap(button('Remove meal'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final rect = tester.getRect(button('Remove and move'));
    expect(rect.bottom, lessThanOrEqualTo(640));
    expect(rect.top, greaterThan(0));
    await unmount(tester, rig);
  });
}

Future<void> dismissPending(WidgetTester tester, String dismissal) async {
  switch (dismissal) {
    case 'back':
      await tester.binding.handlePopRoute();
    case 'barrier':
      await tester.tapAt(const Offset(10, 10));
    case 'drag':
      await tester.drag(find.byType(FbSheet).last, const Offset(0, 900));
  }
  await tester.pumpAndSettle();
}
