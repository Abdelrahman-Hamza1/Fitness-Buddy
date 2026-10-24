import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/row_ops.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/diary/presentation/saved_meals/rename_saved_meal_sheet.dart';
import 'package:fb_mobile/features/me/me.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/changes/support/test_db.dart' show ScriptOp;
import '../../../helpers/pump_app.dart';
import '../../foods/presentation/support/personal_food_support.dart'
    show finish;
import '../../today/presentation/support/today_support.dart';
import '../../today/presentation/today_actions_test.dart' show settle;
import '../../today/presentation/today_edit_test.dart' show button, chip;
import '../support/diary_fixtures.dart' show fixtureId;
import 'saved_meals_support.dart';

Future<TodayRig> _pumpMeal(
  WidgetTester tester, {
  TodayRig? rig,
  Widget screen = const SizedBox(),
  Size size = const Size(360, 800),
  double scale = 1,
}) async {
  rig ??= TodayRig();
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await seedMeals(tester, rig);
  await tester.pumpWidget(
    ProviderScope(
      overrides: rig.overrides,
      child: phoneApp(screen, textScale: scale),
    ),
  );
  await settle(tester);
  return rig;
}

final Widget _detail = SavedMealScreen(id: fixtureId(90));

Future<void> _finish(WidgetTester tester, TodayRig rig) async {
  rig.stack.dispose();
  await tester.pump(const Duration(seconds: 7));
}

void main() {
  group('list', () {
    testWidgets('DY-031 FD-010 the saved meals list shows name, item count, '
        'kcal and the badge, by name; a tap opens the meal', (tester) async {
      final rig = await _pumpMeal(tester, screen: const SavedMealsScreen());

      final titles = tester
          .widgetList<FbListRow>(find.byType(FbListRow))
          .map((r) => r.title)
          .toList();
      expect(titles, ['Breakfast set', 'Usual lunch']);
      expect(find.text('2 items · 600 kcal'), findsOneWidget);
      expect(find.text('1 item · 300 kcal'), findsOneWidget);
      expect(find.byType(FbSourceBadge), findsNWidgets(2));
      expect(
        tester
            .widgetList<FbSourceBadge>(find.byType(FbSourceBadge))
            .map((b) => b.source),
        everyElement(FbSource.yours),
      );

      await tester.tap(find.text('Usual lunch'));
      expect(rig.navigator.pushed.single, isA<SavedMealRoute>());
      expect((rig.navigator.pushed.single as SavedMealRoute).id, fixtureId(90));
      await _finish(tester, rig);
    });

    testWidgets('UX-050 DY-031 an empty list explains how to save a meal', (
      tester,
    ) async {
      final rig = TodayRig();
      tester.view
        ..physicalSize = const Size(360, 800)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: rig.overrides,
          child: phoneApp(const SavedMealsScreen()),
        ),
      );
      await settle(tester);

      expect(find.text('No saved meals yet'), findsOneWidget);
      expect(
        find.text("Open a meal's menu on Today and choose Save as meal."),
        findsOneWidget,
      );
      await _finish(tester, rig);
    });

    testWidgets('UX-013 Saved meals is 2 taps from Today', (tester) async {
      final container = await pumpApp(tester);
      var taps = 0;
      Future<void> tap(Finder finder) async {
        await tester.tap(finder);
        taps++;
        await settle(tester);
      }

      await tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Me'),
        ),
      );
      expect(find.byType(MeScreen), findsOneWidget);
      await tap(find.text('Saved meals'));

      expect(taps, 2);
      expect(find.byType(SavedMealsScreen), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      await finish(tester, container);
    });
  });

  group('detail', () {
    testWidgets('DY-031 FD-010 the detail shows each item with its own '
        'badge and the totals', (tester) async {
      final rig = await _pumpMeal(tester, screen: _detail);

      expect(find.text('Usual lunch'), findsOneWidget);
      expect(find.text('600 kcal'), findsOneWidget);
      expect(find.text('Food 2'), findsOneWidget);
      expect(find.text('Food 3'), findsOneWidget);
      // The two items keep their own sources: a database item and your own.
      expect(
        tester
            .widgetList<FbSourceBadge>(find.byType(FbSourceBadge))
            .map((b) => b.source),
        [FbSource.database, FbSource.yours],
      );
      expect(tester.widget<FbChoiceChip>(chip('Meal')).value, 'Lunch');
      expect(tester.widget<FbChoiceChip>(chip('Day')).value, 'Today');
      await _finish(tester, rig);
    });

    testWidgets('DY-031 Log copies the meal into the chosen meal and day with '
        'one Undo', (tester) async {
      final rig = await _pumpMeal(tester, screen: _detail);

      await tester.tap(chip('Meal'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FbListRow, 'Dinner').last);
      await tester.pumpAndSettle();
      await tester.tap(chip('Day'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('16'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(tester.widget<FbChoiceChip>(chip('Meal')).value, 'Dinner');
      expect(tester.widget<FbChoiceChip>(chip('Day')).value, 'Yesterday');

      await tester.tap(button('Log'));
      await settle(tester);

      final day = (await tester.runAsync(
        () => rig.diary.reads.day(testYesterday),
      ))!;
      expect(day.entries.map((e) => e.food.names.en), ['Food 2', 'Food 3']);
      expect(
        day.entries.map((e) => e.slotId),
        everyElement(DefaultSlots.dinnerId),
      );
      expect(day.entries.last.food.provenance.source, FoodSource.yours);
      expect(
        find.text('Logged Usual lunch, 2 items for yesterday'),
        findsOneWidget,
      );

      await tester.tap(find.text('Undo'));
      await settle(tester);
      final after = (await tester.runAsync(
        () => rig.diary.reads.day(testYesterday),
      ))!;
      expect(after.entries, isEmpty);
      await _finish(tester, rig);
    });

    testWidgets(
      'DY-031 logging today says "Logged {name}, {count} items" and shows Undo',
      (tester) async {
        final rig = await _pumpMeal(tester, screen: _detail);

        await tester.tap(button('Log'));
        await settle(tester);

        expect(find.text('Logged Usual lunch, 2 items'), findsOneWidget);
        expect(find.text('Undo'), findsOneWidget);
        await _finish(tester, rig);
      },
    );

    testWidgets('DY-031 a refused log is never silent: it says "That changed. '
        'Nothing was logged."', (tester) async {
      final rig = TodayRig(
        apply: (change) async => const Rejected(InvalidOp('sourceChanged')),
      );
      await _pumpMeal(tester, rig: rig, screen: _detail);

      await tester.tap(button('Log'));
      await settle(tester);

      expect(find.text('That changed. Nothing was logged.'), findsOneWidget);
      expect(find.text('Undo'), findsNothing);
      await _finish(tester, rig);
    });

    testWidgets('DY-031 a meal with no items says so and Log is off', (
      tester,
    ) async {
      final rig = TodayRig();
      await seedMeals(tester, rig);
      final items = await tester.runAsync(
        () => rig.diary.db.select(rig.diary.db.savedMealItems).get(),
      );
      await tester.runAsync(
        () => rig.diary.applier.apply(
          ChangeSet([
            ScriptOp.rows([
              for (final item in items!.where(
                (i) => i.savedMealId == fixtureId(90),
              ))
                TombstoneRow(rig.diary.db.savedMealItems, item.id),
            ]),
          ], origin: Origin.direct),
        ),
      );
      tester.view
        ..physicalSize = const Size(360, 800)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(overrides: rig.overrides, child: phoneApp(_detail)),
      );
      await settle(tester);

      expect(find.text('This meal has no items.'), findsOneWidget);
      expect(tester.widget<FbButton>(button('Log')).onPressed, isNull);
      await _finish(tester, rig);
    });

    testWidgets('DY-031 the detail follows its meal: renamed elsewhere shows '
        'the new name, deleted elsewhere says so and offers no Log', (
      tester,
    ) async {
      final rig = await _pumpMeal(tester, screen: _detail);

      await tester.runAsync(
        () => rig.diary.apply([RenameSavedMeal(fixtureId(90), 1, 'Big lunch')]),
      );
      await settle(tester);
      expect(find.text('Big lunch'), findsOneWidget);

      await tester.runAsync(
        () => rig.diary.apply([DeleteSavedMeal(fixtureId(90), 2)]),
      );
      await settle(tester);
      expect(find.text('This saved meal was deleted.'), findsOneWidget);
      expect(button('Log'), findsNothing);
      expect(find.byTooltip('Rename meal'), findsNothing);
      await _finish(tester, rig);
    });

    testWidgets('UX-070 the detail fits a 320 x 640 phone at text scale 2.0 '
        'and Log stays reachable', (tester) async {
      final rig = await _pumpMeal(
        tester,
        screen: _detail,
        size: const Size(320, 640),
        scale: 2,
      );

      expect(tester.takeException(), isNull);
      // Name, amount and calories all stay readable at the large size: the
      // amount and kcal wrap together under the name (UX review).
      expect(find.text('Food 2'), findsOneWidget);
      expect(find.textContaining('150 g · '), findsNWidgets(2));
      expect(find.textContaining(' kcal'), findsWidgets);
      final log = tester.getRect(button('Log'));
      expect(log.bottom, lessThanOrEqualTo(640));
      expect(log.top, greaterThan(0));
      // The items scroll above it instead of pushing it away.
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pump();
      expect(tester.takeException(), isNull);
      await _finish(tester, rig);
    });
  });

  group('rename and delete', () {
    testWidgets('DY-031 the pencil renames the meal with Undo', (tester) async {
      final rig = await _pumpMeal(tester, screen: _detail);

      await tester.tap(find.byTooltip('Rename meal'));
      await tester.pumpAndSettle();
      expect(find.byType(RenameSavedMealSheet), findsOneWidget);
      await tester.enterText(find.byType(TextField), '  Lunch box ');
      await tester.pump();
      await tester.tap(button('Save'));
      await settle(tester);

      expect(find.byType(RenameSavedMealSheet), findsNothing);
      expect(find.text('Lunch box'), findsOneWidget);
      expect(find.text('Renamed to "Lunch box"'), findsOneWidget);
      await tester.tap(find.text('Undo'));
      await settle(tester);
      expect(find.text('Usual lunch'), findsOneWidget);
      await _finish(tester, rig);
    });

    testWidgets('DY-031 rename needs 1 to 60 characters and writes nothing '
        'for the same name', (tester) async {
      final rig = await _pumpMeal(tester, screen: _detail);

      await tester.tap(find.byTooltip('Rename meal'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump();
      expect(tester.widget<FbButton>(button('Save')).onPressed, isNull);
      expect(find.text('Give the meal a name.'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Usual lunch');
      await tester.pump();
      await tester.tap(button('Save'));
      await settle(tester);
      expect(find.byType(RenameSavedMealSheet), findsNothing);
      expect(find.textContaining('Renamed'), findsNothing);
      await _finish(tester, rig);
    });

    testWidgets('UX-052 DY-031 a rename sheet watches its meal: renamed '
        'elsewhere offers Reload and keeps the typed name; deleted '
        'disables Save', (tester) async {
      final rig = await _pumpMeal(tester, screen: _detail);

      await tester.tap(find.byTooltip('Rename meal'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'My typed name');
      await tester.pump();

      await tester.runAsync(
        () => rig.diary.apply([RenameSavedMeal(fixtureId(90), 1, 'Elsewhere')]),
      );
      await settle(tester);
      expect(
        find.text('This meal was renamed. Reload to see its new name.'),
        findsOneWidget,
      );
      expect(tester.widget<FbButton>(button('Save')).onPressed, isNull);

      await tester.tap(find.text('Reload'));
      await tester.pump();
      expect(find.textContaining('was renamed'), findsNothing);
      expect(find.text('My typed name'), findsOneWidget);
      expect(tester.widget<FbButton>(button('Save')).onPressed, isNotNull);

      await tester.runAsync(
        () => rig.diary.apply([DeleteSavedMeal(fixtureId(90), 2)]),
      );
      await settle(tester);
      expect(
        find.text("This meal was deleted, so it can't be renamed."),
        findsOneWidget,
      );
      expect(tester.widget<FbButton>(button('Save')).onPressed, isNull);
      await _finish(tester, rig);
    });

    testWidgets('DY-031 a rename refused by the data says "That meal changed. '
        'Nothing was renamed."', (tester) async {
      final rig = TodayRig(
        apply: (change) async => const Rejected(
          VersionConflict(
            entity: 'saved_meal',
            id: 'x',
            expected: 1,
            actual: 2,
          ),
        ),
      );
      await _pumpMeal(tester, rig: rig, screen: _detail);

      await tester.tap(find.byTooltip('Rename meal'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Other');
      await tester.pump();
      await tester.tap(button('Save'));
      await settle(tester);

      expect(
        find.text('That meal changed. Nothing was renamed.'),
        findsOneWidget,
      );
      expect(find.byType(RenameSavedMealSheet), findsOneWidget);
      await _finish(tester, rig);
    });

    testWidgets('DY-031 FD-010 Delete meal removes it with Undo, and Undo '
        'brings it back', (tester) async {
      final rig = await _pumpMeal(tester, screen: _detail);

      await tester.tap(find.byTooltip('More for this meal'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete meal'));
      await settle(tester);

      // The screen goes back to the list (the test navigator only records).
      expect(find.text('Deleted "Usual lunch"'), findsOneWidget);
      expect(find.text('This saved meal was deleted.'), findsOneWidget);
      await tester.tap(find.text('Undo'));
      await settle(tester);
      expect(find.text('Usual lunch'), findsOneWidget);
      expect(find.text('Food 2'), findsOneWidget);
      await _finish(tester, rig);
    });

    testWidgets('DY-031 a delete refused by the data says so', (tester) async {
      final rig = TodayRig(
        apply: (change) async => const Rejected(
          VersionConflict(
            entity: 'saved_meal',
            id: 'x',
            expected: 1,
            actual: 2,
          ),
        ),
      );
      await _pumpMeal(tester, rig: rig, screen: _detail);

      await tester.tap(find.byTooltip('More for this meal'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete meal'));
      await settle(tester);

      expect(
        find.text('That meal changed. Nothing was deleted.'),
        findsOneWidget,
      );
      expect(find.text('Usual lunch'), findsOneWidget);
      await _finish(tester, rig);
    });
  });
}
