import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:fb_mobile/app/router/app_router.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'personal_food_form_test.dart' show fillValues, tapVisible, textOf, type;
import 'support/personal_food_support.dart';
import 'support/search_screen_support.dart';

Future<void> search(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField).first, text);
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('FD-020 #86 no match offers "Create … as your own food"; '
      'saving opens the food sheet with it; Add logs it with ⓨ', (
    tester,
  ) async {
    final container = await pumpPersonal(
      tester,
      at: FoodSearchRoute(
        date: LocalDate(2026, 10, 20),
        slotId: DefaultSlots.dinnerId,
      ),
      overrides: [
        clockProvider.overrideWithValue(
          ManualClock(DateTime.utc(2026, 10, 23, 12)),
        ),
      ],
    );
    await search(tester, 'Labneh');
    expect(find.text('No match for "Labneh"'), findsOneWidget);

    await tester.tap(
      find.widgetWithText(FbButton, 'Create "Labneh" as your own food'),
    );
    await settle(tester);

    // The form opened over the search with the name filled in; the name is
    // not in the location (backlog #42).
    expect(find.byType(PersonalFoodFormScreen), findsOneWidget);
    expect(textOf(tester, 'Name'), 'Labneh');
    expect(
      container.read(appRouterProvider).config.state.uri.toString(),
      '/today/add-food/new-food?date=2026-10-20&slot=${DefaultSlots.dinnerId}',
    );
    expect(find.byType(NavigationBar), findsOneWidget);

    await fillValues(tester);
    await tapVisible(tester, find.text('Save'));

    // The form closes and the food sheet takes over, for the new food.
    expect(find.byType(PersonalFoodFormScreen), findsNothing);
    expect(find.byType(FoodSheet), findsOneWidget);
    expect(find.widgetWithText(FbSourceBadge, 'Y'), findsOneWidget);
    expect(find.text('180 kcal'), findsWidgets);

    await tester.tap(find.widgetWithText(FbButton, 'Add'));
    await settle(tester);

    expect(find.byType(FoodSheet), findsNothing);
    expect(find.byType(FoodSearchScreen), findsNothing);
    expect(find.byType(TodayScreen), findsOneWidget);
    expect(find.textContaining('Added Labneh to'), findsOneWidget);
    final food = (await storedFoods(tester, container)).single;
    final entry = (await liveEntries(tester, container)).single;
    expect(entry.foodKind, 'personal');
    expect(entry.foodId, food.id);
    expect(entry.nameEn, 'Labneh');
    expect(entry.source, 'yours');
    expect(entry.localDate, '2026-10-20');
    expect(entry.slotId, DefaultSlots.dinnerId);
    expect(find.text('Undo'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await settle(tester);
    expect(await liveEntries(tester, container), isEmpty);
    expect((await storedFoods(tester, container)).single.id, food.id);
    await finish(tester, container);
  });

  testWidgets(
    'FD-020 #86 a search with results ends with the create row, which '
    'opens the form with the query as the name',
    (tester) async {
      final labneh = aFood(1);
      final row = FoodSearchRow(
        choice: personalChoice(labneh),
        tier: SourceTier.personal,
      );
      final container = await pumpPersonal(
        tester,
        search: FakeFoodSearch(
          answers: {
            'Lab': [row],
          },
        ),
        foods: [labneh],
        at: const FoodSearchRoute(),
      );
      await search(tester, 'Lab');

      final rows = tester
          .widgetList<FbListRow>(find.byType(FbListRow))
          .map((r) => r.title)
          .toList();
      expect(rows.last, 'Create "Lab" as your own food');

      await tester.tap(find.text('Create "Lab" as your own food'));
      await settle(tester);
      expect(textOf(tester, 'Name'), 'Lab');
      await finish(tester, container);
    },
  );

  testWidgets(
    "FD-020 the create row is hidden when changing a logged item's food",
    (tester) async {
      final container = await pumpPersonal(
        tester,
        at: FoodSearchRoute(replace: VersionedId(aFood(9).id, 1)),
      );
      await search(tester, 'Labneh');
      expect(find.text('No match for "Labneh"'), findsOneWidget);
      expect(find.textContaining('as your own food'), findsNothing);
      await finish(tester, container);
    },
  );

  testWidgets('FD-020 #86 an empty search offers no create row', (
    tester,
  ) async {
    final container = await pumpPersonal(tester, at: const FoodSearchRoute());
    expect(find.textContaining('as your own food'), findsNothing);
    await search(tester, '   ');
    expect(find.textContaining('as your own food'), findsNothing);
    await finish(tester, container);
  });

  testWidgets('FD-073 adding a food that was deleted meanwhile offers Close', (
    tester,
  ) async {
    final labneh = aFood(1);
    final row = FoodSearchRow(
      choice: personalChoice(labneh),
      tier: SourceTier.personal,
    );
    final container = await pumpPersonal(
      tester,
      search: FakeFoodSearch(recent: [row]),
      foods: [labneh],
      at: const FoodSearchRoute(),
    );
    await tester.tap(find.text('Labneh'));
    await settle(tester);
    expect(find.byType(FoodSheet), findsOneWidget);

    // Deleted in another place while the sheet is open.
    await applyOps(tester, container, [
      DeletePersonalFood(VersionedId(labneh.id, labneh.version)),
    ]);
    await settle(tester);
    await tester.tap(find.widgetWithText(FbButton, 'Add'));
    await settle(tester);

    expect(
      find.text('This food changed, so nothing was logged. Pick it again.'),
      findsOneWidget,
    );
    expect(find.byType(FoodSheet), findsOneWidget);
    expect(await liveEntries(tester, container), isEmpty);
    await tester.tap(find.text('Close'));
    await settle(tester);
    expect(find.byType(FoodSheet), findsNothing);
    await finish(tester, container);
  });

  testWidgets('FD-073 adding a food that was edited meanwhile logs nothing '
      'and says so', (tester) async {
    final labneh = aFood(1);
    final row = FoodSearchRow(
      choice: personalChoice(labneh),
      tier: SourceTier.personal,
    );
    final container = await pumpPersonal(
      tester,
      search: FakeFoodSearch(recent: [row]),
      foods: [labneh],
      at: const FoodSearchRoute(),
    );
    await tester.tap(find.text('Labneh'));
    await settle(tester);

    await applyOps(tester, container, [
      UpdatePersonalFood(
        labneh.id,
        labneh.version,
        PersonalFoodDraft(
          names: labneh.names,
          per100: Nutrients(kcal: 200, protein: 6, carbs: 4, fat: 15, fiber: 0),
        ),
      ),
    ]);
    await settle(tester);
    await tester.tap(find.widgetWithText(FbButton, 'Add'));
    await settle(tester);

    expect(
      find.text('This food changed, so nothing was logged. Pick it again.'),
      findsOneWidget,
    );
    expect(await liveEntries(tester, container), isEmpty);
    // Release the open sheet's settings watch before database teardown.
    await tester.binding.handlePopRoute();
    await settle(tester);
    await finish(tester, container);
  });
  testWidgets(
    'FD-070 separate tabs keep independent new-food drafts and saves',
    (tester) async {
      final container = await pumpPersonal(
        tester,
        at: const PersonalFoodRoute(),
      );
      await type(tester, 'Name', 'Me draft');
      await fillValues(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Today'),
        ),
      );
      await settle(tester);
      container.read(appRouterProvider).go(const FoodSearchRoute());
      await settle(tester);
      await search(tester, 'Search draft');
      await tester.tap(find.text('Create "Search draft" as your own food'));
      await settle(tester);
      expect(textOf(tester, 'Name'), 'Search draft');
      expect(
        tester.widget<TextField>(fieldLabelled('Calories')).focusNode!.hasFocus,
        isTrue,
      );
      await fillValues(tester);
      await tapVisible(tester, find.text('Save'));
      expect(find.byType(FoodSheet), findsOneWidget);
      expect(find.text('Saved Search draft'), findsNothing);
      // Closing without logging never offers a covered or expired
      // creation Undo.
      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(find.text('Saved Search draft'), findsNothing);
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Me'),
        ),
      );
      await settle(tester);
      expect(textOf(tester, 'Name'), 'Me draft');
      await tapVisible(tester, find.text('Save'));
      expect(
        (await storedFoods(tester, container)).map((f) => f.names.en).toSet(),
        {'Me draft', 'Search draft'},
      );
      await finish(tester, container);
    },
  );

  testWidgets('FD-020 UX-070 not-ready Create has an icon and short label '
      'while passing the whole query on a 320 x 640 phone', (tester) async {
    const query = 'A very long private food name from a label';
    final container = await pumpPersonal(
      tester,
      at: const FoodSearchRoute(),
      search: FakeFoodSearch(packReady: false),
      window: const Size(320, 640),
    );
    await search(tester, query);
    final create = find.widgetWithText(
      FbButton,
      'Create "A very long private foo…" as your own food',
    );
    expect(create, findsOneWidget);
    expect(tester.widget<FbButton>(create).icon, FbIcons.add);
    expect(tester.takeException(), isNull);
    await tester.tap(create);
    await settle(tester);
    expect(textOf(tester, 'Name'), query);
    await finish(tester, container);
  });
  testWidgets('FD-073 replacing with a changed personal food offers Close '
      'and keeps the logged entry', (tester) async {
    final food = aFood(1);
    final row = FoodSearchRow(
      choice: personalChoice(food),
      tier: SourceTier.personal,
    );
    final container = await pumpPersonal(
      tester,
      foods: [food],
      search: FakeFoodSearch(recent: [row]),
    );
    await applyOps(tester, container, [
      LogEntries([entryOfPersonal(container, food, n: 1)]),
    ]);
    final before = (await liveEntries(tester, container)).single;
    container
        .read(appRouterProvider)
        .go(FoodSearchRoute(replace: VersionedId(before.id, before.version)));
    await settle(tester);
    await tester.tap(find.text('Labneh'));
    await settle(tester);
    await applyOps(tester, container, [
      DeletePersonalFood(VersionedId(food.id, 1)),
    ]);
    await settle(tester);
    await tester.tap(find.widgetWithText(FbButton, 'Use this food'));
    await settle(tester);
    expect(
      find.text('This food changed, so nothing was changed. Pick it again.'),
      findsOneWidget,
    );
    expect(
      (await liveEntries(tester, container)).single.version,
      before.version,
    );
    await tester.tap(find.text('Close'));
    await settle(tester);
    expect(find.byType(FoodSheet), findsNothing);
    // Release the open sheet's settings watch before database teardown.
    await tester.binding.handlePopRoute();
    await settle(tester);
    await finish(tester, container);
  });
}
