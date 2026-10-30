import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/today_support.dart';

Future<void> pumpToday(
  WidgetTester tester,
  List<Override> overrides, {
  double scale = 1,
  bool tall = false,
}) async {
  usePhone(tester);
  // Tall: the opened rows stay on screen under the header (numbers and the
  // weight card, A14).
  if (tall) tester.view.physicalSize = const Size(360, 1200);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: phoneApp(const TodayScreen(), textScale: scale),
    ),
  );
  await tester.pump();
}

Finder slotRow(String name) => find.widgetWithText(FbDisclosureRow, name);

void main() {
  group('layout', () {
    testWidgets('HM-007 DY-020 a full day shows four slot rows with '
        'summaries and kcal; tapping one shows its macro line and items', (
      tester,
    ) async {
      await pumpToday(tester, fakeToday(days: {testToday: fullDay(testToday)}));

      for (final (name, summary, kcal) in [
        ('Breakfast', 'Pita bread, white · Labaneh', '255 kcal'),
        ('Lunch', 'Mloukhiyeh · Rice, white, cooked', '625 kcal'),
        ('Snacks', 'Nothing yet', '—'),
        ('Dinner', 'Hummus', '310 kcal'),
      ]) {
        final row = slotRow(name);
        expect(row, findsOneWidget, reason: name);
        expect(
          find.descendant(of: row, matching: find.text(summary)),
          findsOneWidget,
          reason: name,
        );
        expect(
          find.descendant(of: row, matching: find.text(kcal)),
          findsOneWidget,
          reason: name,
        );
        // A "+" per meal.
        expect(find.byTooltip('Add food to $name'), findsOneWidget);
      }
      // Closed by default: no items, no macro line.
      expect(find.byType(DiaryEntryTile), findsNothing);
      expect(find.textContaining('P 5'), findsNothing);

      await tester.tap(slotRow('Breakfast'));
      await tester.pump();

      expect(find.text('P 17 · C 32 · F 8.5 · Fiber 4.3'), findsOneWidget);
      expect(find.widgetWithText(FbListRow, 'Pita bread, white'), findsOne);
      expect(find.widgetWithText(FbListRow, 'Labaneh'), findsOne);
      expect(find.text('1 loaf'), findsOneWidget);
      // Only that meal opened.
      expect(find.widgetWithText(FbListRow, 'Hummus'), findsNothing);
    });
  });

  group('add', () {
    testWidgets('UX-013 + on a slot opens search with that slot and the '
        'viewed date (1 tap)', (tester) async {
      final nav = RecordingNavigator();
      await pumpToday(tester, fakeToday(navigator: nav));
      await tester.tap(find.byTooltip('Previous day'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Add food to Lunch'));

      final route = nav.pushed.single as FoodSearchRoute;
      expect(route.date, testYesterday);
      expect(route.slotId, DefaultSlots.lunchId);
      // The meal row did not toggle.
      expect(find.byType(DiaryEntryTile), findsNothing);
    });

    // rule: A22 input-bar-sheet
    testWidgets('AI-001 HM-008 input bar opens the chat sheet', (tester) async {
      final nav = RecordingNavigator();
      await pumpToday(tester, fakeToday(navigator: nav));
      await tester.tap(find.byTooltip('Previous day'));
      await tester.pumpAndSettle();

      final bar = find.byType(FbInputBar);
      expect(bar, findsOneWidget);
      expect(
        tester.getBottomLeft(bar).dy,
        greaterThan(tester.getBottomLeft(find.byType(PageView)).dy),
      );
      expect(find.text('Tell Buddy what you ate…'), findsOneWidget);
      // No suggestions, so no chip row (A09 D14).
      expect(find.byType(FbQuickAddChip), findsNothing);

      await tester.tap(bar);
      await tester.pumpAndSettle();
      expect(find.byType(FbComposer), findsOneWidget);
      // The manual path stays two taps: the sheet's magnifier opens search
      // for the viewed day, without a slot (auto-slot).
      await tester.tap(find.byTooltip('Search foods'));
      await tester.pumpAndSettle();
      final route = nav.pushed.single as FoodSearchRoute;
      expect(route.date, testYesterday);
      expect(route.slotId, isNull);
    });

    testWidgets('HM-008 the camera is not in staging or prod; the barcode '
        'scanner is (A28a)', (tester) async {
      await pumpToday(tester, fakeToday());

      expect(find.byTooltip('Take a photo'), findsNothing);
      expect(find.byTooltip('Scan a barcode'), findsOneWidget);
    });
  });

  group('details', () {});

  group('dish groups', () {
    testWidgets('DY-024 in an opened slot a dish shows its name, kcal and '
        'members; tapping the dish row collapses it and the choice survives '
        'a day change', (tester) async {
      await pumpToday(
        tester,
        fakeToday(
          days: {
            testToday: fullDay(testToday),
            testYesterday: fullDay(testYesterday, seed: 1),
          },
        ),
        tall: true,
      );
      await tester.tap(slotRow('Lunch'));
      await tester.pump();

      final dish = find.widgetWithText(FbDisclosureRow, 'Mloukhiyeh');
      expect(dish, findsOneWidget);
      expect(
        find.descendant(of: dish, matching: find.text('2 items')),
        findsOne,
      );
      expect(
        find.descendant(of: dish, matching: find.text('420 kcal')),
        findsOne,
      );
      expect(find.widgetWithText(FbListRow, 'Mloukhiyeh leaves'), findsOne);
      expect(find.widgetWithText(FbListRow, 'Chicken thigh'), findsOne);
      expect(find.widgetWithText(FbListRow, 'Rice, white, cooked'), findsOne);

      await tester.tap(dish);
      await tester.pump();
      expect(find.widgetWithText(FbListRow, 'Chicken thigh'), findsNothing);
      expect(find.widgetWithText(FbListRow, 'Rice, white, cooked'), findsOne);

      // The choice is per dish, not per day page: another day's dish
      // keeps its own state, and coming back keeps this one folded.
      await tester.tap(find.byTooltip('Previous day'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(FbListRow, 'Chicken thigh'), findsOne);
      await tester.tap(find.byTooltip('Next day'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(FbListRow, 'Chicken thigh'), findsNothing);
    });
  });

  group('semantics', () {
    testWidgets('DY-022 each item row offers Delete and Move to another '
        'meal as screen-reader actions', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpToday(tester, fakeToday(days: {testToday: fullDay(testToday)}));
      await tester.tap(slotRow('Breakfast'));
      await tester.pump();

      final node = tester.getSemantics(
        find.widgetWithText(FbListRow, 'Labaneh'),
      );
      // The custom actions sit on an ancestor of the row's own node.
      var found = <String>{};
      SemanticsNode? walk = node;
      while (walk != null && found.isEmpty) {
        found = {
          for (final id
              in walk.getSemanticsData().customSemanticsActionIds ?? <int>[])
            ?CustomSemanticsAction.getAction(id)?.label,
        };
        walk = walk.parent;
      }
      expect(found, containsAll(['Delete', 'Move to another meal']));
      handle.dispose();
    });
  });
}
