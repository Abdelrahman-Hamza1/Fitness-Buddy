import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../diary/support/diary_harness.dart';
import 'support/today_support.dart';

/// Lets the database and the undo stack finish what a tap started.
Future<void> settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 60)),
  );
  await tester.pumpAndSettle();
}

Future<void> pumpRig(
  WidgetTester tester,
  TodayRig rig, {
  bool disableAnimations = true,
}) async {
  usePhone(tester);
  await tester.pumpWidget(
    ProviderScope(
      overrides: rig.overrides,
      child: phoneApp(
        const TodayScreen(),
        disableAnimations: disableAnimations,
      ),
    ),
  );
  await settle(tester);
}

Future<void> log(
  WidgetTester tester,
  TodayRig rig,
  List<NewDiaryEntry> e,
) async {
  await tester.runAsync(() => rig.diary.apply([LogEntries(e)]));
  await settle(tester);
}

Finder row(String name) => find.widgetWithText(FbListRow, name);

/// Food 1 and Food 2 for breakfast (300 kcal each) on today.
Future<TodayRig> rigWithBreakfast(
  WidgetTester tester, {
  TodayRig? rig,
  bool disableAnimations = true,
}) async {
  rig ??= TodayRig();
  await pumpRig(tester, rig, disableAnimations: disableAnimations);
  await log(tester, rig, [
    newEntry(1, when: atDay(testToday, 8), slotId: DefaultSlots.breakfastId),
    newEntry(2, when: atDay(testToday, 9), slotId: DefaultSlots.breakfastId),
  ]);
  await tester.tap(find.widgetWithText(FbDisclosureRow, 'Breakfast'));
  await tester.pump();
  return rig;
}

Future<void> swipe(WidgetTester tester, Finder finder, double dx) async {
  await tester.drag(finder, Offset(dx, 0));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('DY-022 UX-030 swipe delete hides the row at once, shows Undo; '
      'Undo brings it back', (tester) async {
    final rig = await rigWithBreakfast(tester);
    expect(find.text('600'), findsOneWidget);

    // A drag that starts on an item row swipes the item, not the day.
    await swipe(tester, row('Food 1'), -400);

    expect(find.text('Today'), findsOneWidget);
    expect(row('Food 1'), findsNothing);
    expect(row('Food 2'), findsOneWidget);
    // Totals match what is shown, before the write has even finished.
    expect(find.text('300'), findsOneWidget);
    await settle(tester);
    expect(find.text('Deleted Food 1'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
    expect(find.text('300'), findsOneWidget);
    expect(
      (await tester.runAsync(() => rig.diary.entry(1)))!.deletedAt,
      isNotNull,
    );

    await tester.tap(find.text('Undo'));
    await settle(tester);

    expect(row('Food 1'), findsOneWidget);
    expect(find.text('600'), findsOneWidget);
  });

  testWidgets('UX-052 a rejected delete says "That item changed" and the row '
      'returns', (tester) async {
    final rig = TodayRig(
      apply: (change) async => const Rejected(
        VersionConflict(entity: 'diary_entry', id: 'x', expected: 1, actual: 2),
      ),
    );
    await rigWithBreakfast(tester, rig: rig);

    await swipe(tester, row('Food 1'), -400);
    await settle(tester);

    expect(
      find.text('That item was changed, so nothing was saved.'),
      findsOneWidget,
    );
    expect(find.text('Undo'), findsNothing);
    expect(row('Food 1'), findsOneWidget);
    expect(find.text('600'), findsOneWidget);
  });
}
