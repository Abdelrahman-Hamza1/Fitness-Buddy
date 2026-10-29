import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/targets/targets.dart';
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

    testWidgets('HM-001 the numbers show eaten kcal and the macro line '
        '(no target yet)', (tester) async {
      await pumpToday(tester, fakeToday(days: {testToday: fullDay(testToday)}));

      expect(find.text('1,190'), findsOneWidget);
      expect(find.text('kcal eaten'), findsOneWidget);
      for (final macro in [
        'Protein 79 g',
        'Carbs 149 g',
        'Fat 40 g',
        'Fiber 20 g',
      ]) {
        expect(find.text(macro), findsOneWidget, reason: macro);
      }
      expect(find.textContaining('left'), findsNothing);
    });

    for (final scale in [1.4, 2.0]) {
      testWidgets(
        'UX-070 at text scale $scale a row keeps its kcal in the subtitle, '
        'so names keep their room',
        (tester) async {
          await pumpToday(
            tester,
            fakeToday(days: {testToday: fullDay(testToday)}),
            scale: scale,
            tall: true,
          );

          final breakfast = slotRow('Breakfast');
          expect(
            find.descendant(of: breakfast, matching: find.text('255 kcal')),
            findsOneWidget,
          );
          await tester.tap(breakfast);
          await tester.pump();
          expect(find.text('165 kcal'), findsOneWidget);
          expect(find.textContaining('1 loaf · 165 kcal'), findsNothing);
        },
      );
    }

    testWidgets('UX-050 an empty today shows the hint, + on every slot and '
        'the input bar', (tester) async {
      final nav = RecordingNavigator();
      await pumpToday(tester, fakeToday(navigator: nav));

      expect(
        find.text('A fresh day. Tap + on a meal to add your first food.'),
        findsOneWidget,
      );
      expect(find.byTooltip('Add food to Breakfast'), findsOneWidget);
      expect(find.byTooltip('Add food to Snacks'), findsOneWidget);
      expect(find.byTooltip('Add food to Lunch'), findsOneWidget);
      expect(find.byTooltip('Add food to Dinner'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);

      expect(find.text('Search foods'), findsNothing);
      await tester.tap(find.byType(FbInputBar));
      expect(nav.pushed.single, isA<FoodSearchRoute>());
      expect((nav.pushed.single as FoodSearchRoute).date, testToday);
    });

    testWidgets('UX-050 a past empty day suggests adding forgotten foods '
        'and has no search button', (tester) async {
      await pumpToday(tester, fakeToday());
      await tester.tap(find.byTooltip('Previous day'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Nothing logged on this day. Forgot something? Tap + on a meal.',
        ),
        findsOneWidget,
      );
      expect(find.text('Search foods'), findsNothing);
      expect(find.byTooltip('Add food to Breakfast'), findsOneWidget);
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

    testWidgets('HM-008 AI-001 the input bar is at the bottom and opens '
        'search for the viewed day', (tester) async {
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
      expect(find.text('Search for a food…'), findsOneWidget);
      // No suggestions, so no chip row (A09 D14).
      expect(find.byType(FbQuickAddChip), findsNothing);

      await tester.tap(bar);
      final route = nav.pushed.single as FoodSearchRoute;
      expect(route.date, testYesterday);
      expect(route.slotId, isNull);
    });

    testWidgets('HM-008 camera and barcode are not in staging or prod', (
      tester,
    ) async {
      await pumpToday(tester, fakeToday());

      expect(find.byTooltip('Take a photo'), findsNothing);
      expect(find.byTooltip('Scan a barcode'), findsNothing);
    });

    testWidgets('HM-008 camera and barcode show in dev, saying Coming soon', (
      tester,
    ) async {
      await pumpToday(tester, fakeToday(config: devConfig));

      await tester.tap(find.byTooltip('Take a photo'));
      await tester.pump();
      expect(find.text('Coming soon'), findsOneWidget);
      await tester.tap(find.byTooltip('Scan a barcode'));
      await tester.pump();
      expect(find.text('Coming soon'), findsOneWidget);
    });
  });

  group('details', () {
    testWidgets('DY-021 tapping an item shows amount, full nutrients, '
        'badge, assumptions and time; LC-005 shows the EN · AR name', (
      tester,
    ) async {
      final day = fakeDay(testToday, [
        fakeEntry(
          1,
          date: testToday,
          name: 'Pita bread, white',
          ar: 'خبز عربي',
          kcal: 165,
          grams: 60,
          input: Quantity(1, 'loaf'),
          minute: 5,
          extras: {NutrientKey.sugar: 1.6, NutrientKey.sodium: 322},
        ),
        fakeEntry(
          2,
          date: testToday,
          name: 'Falafel plate',
          kcal: 450,
          minute: 30,
          source: FoodSource.estimate,
          range: EstimateRange(380, 520),
          assumptions: ['6 pieces, fried', 'Includes tahini'],
        ),
      ]);
      await pumpToday(tester, fakeToday(days: {testToday: day}));
      await tester.tap(slotRow('Breakfast'));
      await tester.pump();

      await tester.tap(find.widgetWithText(FbListRow, 'Pita bread, white'));
      await tester.pump();

      final details = find.byType(EntryDetailsPanel);
      expect(details, findsOneWidget);
      for (final text in [
        'Pita bread, white · خبز عربي',
        'Food database',
        'Amount',
        '1 loaf (60 g)',
        'Time',
        '8:05 AM',
        'Nutrition for this amount',
        'Calories',
        '165 kcal',
        'Protein',
        'Sugar',
        '1.6 g',
        'Sodium',
        '322 mg',
      ]) {
        expect(
          find.descendant(of: details, matching: find.text(text)),
          findsOneWidget,
          reason: text,
        );
      }
      expect(
        find.descendant(of: details, matching: find.byType(FbSourceBadge)),
        findsOneWidget,
      );

      // One item open at a time; the estimate shows its range and
      // assumptions.
      final scrollable = find.descendant(
        of: find.byType(CustomScrollView),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.widgetWithText(FbListRow, 'Falafel plate'),
        200,
        scrollable: scrollable,
      );
      // Clear of the input bar at the bottom.
      await tester.drag(scrollable, const Offset(0, -120));
      await tester.pump();
      await tester.tap(find.widgetWithText(FbListRow, 'Falafel plate'));
      await tester.pump();
      expect(find.byType(EntryDetailsPanel), findsOneWidget);
      for (final text in [
        'Estimate',
        'Estimate range',
        '380–520 kcal',
        'Assumptions',
        '6 pieces, fried',
        'Includes tahini',
      ]) {
        expect(find.text(text), findsAtLeastNWidgets(1), reason: text);
      }
      expect(find.text('Pita bread, white · خبز عربي'), findsNothing);

      // A second tap closes it.
      await tester.scrollUntilVisible(
        find.widgetWithText(FbListRow, 'Falafel plate'),
        -100,
        scrollable: scrollable,
      );
      await tester.tap(find.widgetWithText(FbListRow, 'Falafel plate'));
      await tester.pump();
      expect(find.byType(EntryDetailsPanel), findsNothing);
    });

    testWidgets('AI-072 an edited item shows "edited by you" and the yours '
        'badge', (tester) async {
      final day = fakeDay(testToday, [
        fakeEntry(1, date: testToday, name: 'Hummus', edited: true),
      ]);
      await pumpToday(tester, fakeToday(days: {testToday: day}));
      await tester.tap(slotRow('Breakfast'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FbListRow, 'Hummus'));
      await tester.pump();

      expect(find.text('Your edit of food database values'), findsOneWidget);
    });
  });

  group('dish groups', () {
    testWidgets(
      'DY-024 split dish headers and members survive section updates',
      (tester) async {
        var entries = [
          fakeEntry(1, date: testToday, group: '1'),
          fakeEntry(
            2,
            date: testToday,
            group: '1',
            slotId: DefaultSlots.lunchId,
          ),
        ];
        final group = fakeGroup(1, date: testToday);
        await pumpToday(tester, [
          // Set up (no setup row, A13): both meals fit on the phone.
          ...fakeToday(fakeDays: false, setup: SetupStatus.setUp),
          dayViewProvider.overrideWith(
            (ref, date) => AsyncData(fakeView(fakeDay(date, entries, [group]))),
          ),
        ]);
        final container = ProviderScope.containerOf(
          tester.element(find.byType(TodayScreen)),
        );
        for (final meal in ['Breakfast', 'Lunch']) {
          await tester.tap(slotRow(meal));
          await tester.pump();
        }
        expect(find.byType(DishGroupTile), findsNWidgets(2));
        expect(find.byType(DiaryEntryTile), findsNWidgets(2));
        final keys = tester
            .widgetList<DishGroupTile>(find.byType(DishGroupTile))
            .map((w) => w.key)
            .toSet();
        expect(keys, hasLength(2));
        // Change both sections, including moving a member across the boundary.
        entries = [
          fakeEntry(2, date: testToday, group: '1'),
          fakeEntry(
            3,
            date: testToday,
            group: '1',
            slotId: DefaultSlots.lunchId,
          ),
        ];
        container.invalidate(dayViewProvider(testToday));
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.byType(DishGroupTile), findsNWidgets(2));
        expect(find.widgetWithText(FbListRow, 'Food 1'), findsNothing);
        expect(find.widgetWithText(FbListRow, 'Food 2'), findsOneWidget);
        expect(find.widgetWithText(FbListRow, 'Food 3'), findsOneWidget);
        final memberKeys = tester
            .widgetList<DiaryEntryTile>(find.byType(DiaryEntryTile))
            .map((w) => w.key)
            .toSet();
        expect(memberKeys, hasLength(2));
      },
    );

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

    testWidgets('UX-013 DY-024 the details of a grouped item are 2 taps from '
        'Today (open the slot, tap the item)', (tester) async {
      await pumpToday(
        tester,
        fakeToday(days: {testToday: fullDay(testToday)}),
        tall: true,
      );

      await tester.tap(slotRow('Lunch')); // tap 1
      await tester.pump();
      await tester.tap(
        find.widgetWithText(FbListRow, 'Chicken thigh'),
      ); // tap 2
      await tester.pump();

      expect(find.byType(EntryDetailsPanel), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(EntryDetailsPanel),
          matching: find.text('Chicken thigh'),
        ),
        findsOneWidget,
      );
    });
  });

  group('semantics', () {
    testWidgets('HM-007 UX-070 meal macros announce full names and grams', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpToday(tester, fakeToday(days: {testToday: fullDay(testToday)}));
      await tester.tap(slotRow('Breakfast'));
      await tester.pump();
      expect(
        find.bySemanticsLabel(
          'Protein 17 g, carbs 32 g, fat 8.5 g, fiber 4.3 g',
        ),
        findsOneWidget,
      );
      expect(find.text('P 17 · C 32 · F 8.5 · Fiber 4.3'), findsOneWidget);
      handle.dispose();
    });

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
