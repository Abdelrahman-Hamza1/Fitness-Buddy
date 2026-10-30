import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../today/presentation/support/today_support.dart';
import '../../../today/presentation/today_actions_test.dart'
    show log, pumpRig, settle;
import '../../../today/presentation/today_edit_test.dart'
    show chip, useTallPhone;
import '../../support/diary_harness.dart';

/// Removes the empty meal [id] behind the screen's back.
Future<void> removeEmpty(WidgetTester tester, TodayRig rig, String id) async {
  await tester.runAsync(
    () =>
        rig.diary.apply([RemoveMealSlot(id, 1, expected: SlotContents.empty)]),
  );
  await settle(tester);
}

void main() {
  testWidgets(
    'DY-010 PA3 tapping a meal removed before apply says "That meal was '
    'removed. Choose another." and stays open',
    (tester) async {
      late final TodayRig rig;
      var removeFirst = false;
      rig = TodayRig(
        apply: (changes) async {
          if (removeFirst) {
            removeFirst = false;
            await rig.diary.applier.apply(
              ChangeSet([
                RemoveMealSlot(
                  DefaultSlots.dinnerId,
                  1,
                  expected: SlotContents.empty,
                ),
              ], origin: Origin.direct),
            );
          }
          final result = await rig.diary.applier.apply(changes);
          return result;
        },
      );
      await pumpRig(tester, rig);
      useTallPhone(tester);
      await log(tester, rig, [
        newEntry(
          1,
          when: atDay(testToday, 8),
          slotId: DefaultSlots.breakfastId,
        ),
      ]);
      await tester.tap(find.widgetWithText(FbDisclosureRow, 'Breakfast'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FbListRow, 'Food 1'));
      await tester.pump();
      await tester.tap(chip('Meal'));
      await tester.pumpAndSettle();

      removeFirst = true;
      await tester.tap(find.widgetWithText(FbListRow, 'Dinner').last);
      await settle(tester);
      expect(
        find.text('That meal was removed. Choose another.'),
        findsOneWidget,
      );
      // The sheet is still open, now without Dinner, and nothing moved.
      expect(find.text('Move to'), findsOneWidget);
      expect(find.widgetWithText(FbListRow, 'Lunch'), findsWidgets);
      expect(
        (await tester.runAsync(() => rig.diary.entry(1)))!.slotId,
        DefaultSlots.breakfastId,
      );
      rig.stack.dispose();
    },
  );
}
