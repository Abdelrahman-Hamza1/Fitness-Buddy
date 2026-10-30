import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../today/presentation/support/today_support.dart';
import '../../../today/presentation/today_actions_test.dart' show settle;
import 'slots_support.dart';

void main() {
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
