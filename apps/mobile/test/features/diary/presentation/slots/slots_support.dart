import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../today/presentation/support/today_support.dart';
import '../../../today/presentation/today_actions_test.dart' show settle;
import '../../support/diary_harness.dart';

/// The Meal times screen on a real in-memory diary (360 x 800 by default).
Future<void> pumpMealTimes(
  WidgetTester tester,
  TodayRig rig, {
  double textScale = 1,
  Size size = const Size(360, 800),
  Brightness brightness = Brightness.light,
  List<Override> extra = const [],
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [...rig.overrides, ...extra],
      child: phoneApp(
        const MealSlotsScreen(),
        textScale: textScale,
        brightness: brightness,
      ),
    ),
  );
  await settle(tester);
}

/// Takes the app down so database streams close (a widget test must not
/// leave their timers pending).
Future<void> unmount(WidgetTester tester, TodayRig rig) async {
  rig.stack.dispose();
  // Undo entries and snackbars expire one after the other (5 s each).
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(seconds: 6));
  }
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
}

Finder button(String label) => find.widgetWithText(FbButton, label);

bool isEnabled(WidgetTester tester, Finder finder) =>
    tester.widget<FbButton>(finder).onPressed != null;

/// The meal row titled [label].
Finder mealRow(String label) => find.widgetWithText(FbListRow, label);

/// The row's text lines, title first.
List<String> rowTexts(WidgetTester tester, String label) => [
  for (final t in tester.widgetList<Text>(
    find.descendant(of: mealRow(label), matching: find.byType(Text)),
  ))
    t.data ?? '',
];

/// A meal's stored record, by ID.
Future<SlotRecord> recordOf(
  WidgetTester tester,
  TodayRig rig,
  String id,
) async => (await tester.runAsync(
  () => DiaryRepository(rig.diary.db).watchSlotRecords().first,
))!.firstWhere((r) => r.slot.id == id);

/// Runs a screen-reader custom action [label] on the meal row [meal].
Future<void> moveBy(WidgetTester tester, String meal, String label) async {
  SemanticsNode? node = tester.getSemantics(find.text(meal));
  while (node != null &&
      (node.getSemanticsData().customSemanticsActionIds ?? []).isEmpty) {
    node = node.parent;
  }
  node!.owner!.performAction(
    node.id,
    SemanticsAction.customAction,
    CustomSemanticsAction.getIdentifier(CustomSemanticsAction(label: label)),
  );
  await settle(tester);
}

/// Picks a time in the open time picker by its text input mode.
Future<void> pickTime(
  WidgetTester tester,
  int hour12,
  int minute, {
  required bool pm,
}) async {
  await tester.tap(find.byTooltip('Switch to text input mode'));
  await tester.pumpAndSettle();
  final fields = find.descendant(
    of: find.byType(Dialog),
    matching: find.byType(TextField),
  );
  await tester.enterText(fields.at(0), '$hour12');
  await tester.enterText(fields.at(1), minute.toString().padLeft(2, '0'));
  await tester.tap(find.text(pm ? 'PM' : 'AM'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

/// An entry of any date in [slotId] for the diary harness.
NewDiaryEntry logIn(int n, String slotId, {LocalDate? date}) =>
    newEntry(n, slotId: slotId, when: date == null ? null : atDay(date));
