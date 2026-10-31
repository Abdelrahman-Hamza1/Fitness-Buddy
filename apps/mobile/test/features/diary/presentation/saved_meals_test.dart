import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/diary/presentation/saved_meals/rename_saved_meal_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

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
    testWidgets('#107 the empty state offers Go to Today', (tester) async {
      final rig = TodayRig();
      tester.view
        ..physicalSize = const Size(360, 800)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...rig.overrides,
            savedMealsProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: phoneApp(const SavedMealsScreen()),
        ),
      );
      await settle(tester);
      expect(find.text('No saved meals yet'), findsOneWidget);

      await tester.tap(button('Go to Today'));
      await tester.pump();
      expect(rig.navigator.went, [const TodayRoute()]);
      await _finish(tester, rig);
    });
  });

  group('rtl', () {
    testWidgets('#105 the detail mirrors in RTL: badge at the start (right) '
        'of each item, the Meal chip first from the right', (tester) async {
      final rig = await _pumpMeal(
        tester,
        screen: Directionality(
          textDirection: TextDirection.rtl,
          child: _detail,
        ),
      );
      final width = tester.view.physicalSize.width;
      for (final name in ['Food 2', 'Food 3']) {
        final row = find.ancestor(
          of: find.text(name),
          matching: find.byType(FbListRow),
        );
        final badge = find.descendant(
          of: row,
          matching: find.byType(FbSourceBadge),
        );
        expect(
          tester.getCenter(badge).dx,
          greaterThan(tester.getCenter(find.text(name)).dx),
          reason: '$name: the badge leads, so it sits on the right',
        );
        expect(tester.getCenter(badge).dx, greaterThan(width / 2));
      }
      expect(
        tester.getCenter(chip('Meal')).dx,
        greaterThan(tester.getCenter(chip('Day')).dx),
      );
      await _finish(tester, rig);
    });
  });

  group('detail', () {
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

      await tester.tap(button('Log to Dinner'));
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
  });
}
