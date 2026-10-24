import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/personal_food_support.dart';

/// Opens the merge confirmation of "Labneh" with "Labne" picked.
Future<void> openMerge(WidgetTester tester) async {
  await tester.tap(find.text('Labneh'));
  await settle(tester);
  await tester.tap(find.byTooltip('More options'));
  await settle(tester);
  await tester.tap(find.text('Merge a duplicate into this food…'));
  await settle(tester);
  await tester.tap(find.text('Labne'));
  await settle(tester);
}

void main() {
  testWidgets('FD-073 merge: pick a duplicate, swap which one is kept, '
      'confirm; Undo restores both', (tester) async {
    final labneh = aFood(1);
    final labne = aFood(2, name: 'Labne');
    final container = await pumpPersonal(
      tester,
      foods: [labneh, labne],
      at: const PersonalFoodsRoute(),
    );
    await applyOps(tester, container, [
      LogEntries([entryOfPersonal(container, labneh, n: 1)]),
    ]);

    await openMerge(tester);
    expect(find.text('Merge these foods?'), findsOneWidget);
    expect(find.text('Stays · 180 kcal per 100 g'), findsOneWidget);
    expect(
      find.text('Merged in and removed · 180 kcal per 100 g'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Labneh stays, with its numbers. Labne is removed.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Keep the other one instead'));
    await settle(tester);
    expect(
      find.textContaining('Labne stays, with its numbers. Labneh is removed.'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(FbButton, 'Merge'));
    await settle(tester);

    // Labne is kept; Labneh is gone from the list; the diary entry of
    // Labneh keeps its name and numbers but now points at Labne.
    expect(find.byType(PersonalFoodsScreen), findsOneWidget);
    expect(find.text('Merged Labneh into Labne'), findsOneWidget);
    final foods = await storedFoods(tester, container);
    expect(foods.map((f) => f.id), [labne.id]);
    expect(foods.single.aliases, contains('Labneh'));
    var entry = (await liveEntries(tester, container)).single;
    expect(entry.foodId, labne.id);
    expect(entry.nameEn, 'Labneh');
    expect(entry.per100Kcal, 180);

    await tester.tap(find.text('Undo'));
    await settle(tester);
    expect((await storedFoods(tester, container)).map((f) => f.id).toSet(), {
      labneh.id,
      labne.id,
    });
    entry = (await liveEntries(tester, container)).single;
    expect(entry.foodId, labneh.id);
    expect(find.text('Labneh'), findsOneWidget);
    expect(find.text('Labne'), findsOneWidget);
    await finish(tester, container);
  });

  testWidgets('FD-073 merge keeps the food it was opened from when it is not '
      'swapped', (tester) async {
    final labneh = aFood(1);
    final labne = aFood(2, name: 'Labne');
    final container = await pumpPersonal(
      tester,
      foods: [labneh, labne],
      at: const PersonalFoodsRoute(),
    );
    await openMerge(tester);
    await tester.tap(find.widgetWithText(FbButton, 'Merge'));
    await settle(tester);

    expect(find.text('Merged Labne into Labneh'), findsOneWidget);
    final foods = await storedFoods(tester, container);
    expect(foods.map((f) => f.id), [labneh.id]);
    expect(foods.single.aliases, contains('Labne'));
    await finish(tester, container);
  });

  testWidgets('FD-073 the merge list shows only foods measured the same way, '
      'and says so when there are none', (tester) async {
    final container = await pumpPersonal(
      tester,
      foods: [
        aFood(1),
        aFood(2, name: 'Labne'),
        aFood(3, name: 'Laban', basis: NutrientBasis.per100ml),
      ],
      at: const PersonalFoodsRoute(),
    );
    await tester.tap(find.text('Labneh'));
    await settle(tester);
    await tester.tap(find.byTooltip('More options'));
    await settle(tester);
    await tester.tap(find.text('Merge a duplicate into this food…'));
    await settle(tester);

    expect(find.text('Merge a duplicate'), findsOneWidget);
    expect(find.text('Labne'), findsOneWidget);
    expect(find.text('Laban'), findsNothing);
    expect(find.text('180 kcal per 100 g'), findsOneWidget);
    await finish(tester, container);
  });

  for (final (basis, words) in [
    (NutrientBasis.per100g, 'grams'),
    (NutrientBasis.per100ml, 'millilitres'),
  ]) {
    testWidgets('FD-073 merge with nothing to merge says so, in $words', (
      tester,
    ) async {
      // The other food is measured the other way, so it can't be merged.
      final other = basis == NutrientBasis.per100g
          ? NutrientBasis.per100ml
          : NutrientBasis.per100g;
      final container = await pumpPersonal(
        tester,
        foods: [
          aFood(1, basis: basis),
          aFood(2, name: 'Laban', basis: other),
        ],
        at: PersonalFoodRoute(id: aFood(1).id),
      );
      await tester.tap(find.byTooltip('More options'));
      await settle(tester);
      await tester.tap(find.text('Merge a duplicate into this food…'));
      await settle(tester);

      expect(
        find.text('You have no other food in $words to merge.'),
        findsOneWidget,
      );
      await finish(tester, container);
    });
  }

  testWidgets('UX-052 a duplicate deleted while the confirmation is open '
      'turns Merge off and says so', (tester) async {
    final labne = aFood(2, name: 'Labne');
    final container = await pumpPersonal(
      tester,
      foods: [aFood(1), labne],
      at: const PersonalFoodsRoute(),
    );
    await openMerge(tester);
    expect(
      tester.widget<FbButton>(find.widgetWithText(FbButton, 'Merge')).onPressed,
      isNotNull,
    );

    await applyOps(tester, container, [
      DeletePersonalFood(VersionedId(labne.id, labne.version)),
    ]);
    await settle(tester);

    expect(
      find.text('One of these foods was deleted, so nothing was merged.'),
      findsOneWidget,
    );
    expect(
      tester.widget<FbButton>(find.widgetWithText(FbButton, 'Merge')).onPressed,
      isNull,
    );
    expect((await storedFoods(tester, container)).single.names.en, 'Labneh');
    await finish(tester, container);
  });

  testWidgets('UX-052 a duplicate that changed while the confirmation is '
      'open offers Reload and merges the latest', (tester) async {
    final labne = aFood(2, name: 'Labne');
    final container = await pumpPersonal(
      tester,
      foods: [aFood(1), labne],
      at: const PersonalFoodsRoute(),
    );
    await openMerge(tester);

    await applyOps(tester, container, [
      UpdatePersonalFood(
        labne.id,
        labne.version,
        PersonalFoodDraft(
          names: FoodNames('Labne', ar: 'لبنة'),
          per100: labne.per100,
        ),
      ),
    ]);
    await settle(tester);

    expect(find.textContaining('One of these foods changed'), findsOneWidget);
    expect(
      tester.widget<FbButton>(find.widgetWithText(FbButton, 'Merge')).onPressed,
      isNull,
    );
    await tester.tap(find.text('Reload'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FbButton, 'Merge'));
    await settle(tester);

    final kept = (await storedFoods(tester, container)).single;
    expect(kept.names.en, 'Labneh');
    // The latest of the duplicate was merged: its Arabic name too.
    expect(kept.aliases, containsAll(['Labne']));
    expect(kept.names.ar, 'لبنة');
    await finish(tester, container);
  });
  testWidgets('FD-073 UX-070 equal-name merge labels both roles and confirms '
      'without overflow on a 320 x 640 phone', (tester) async {
    final container = await pumpPersonal(
      tester,
      foods: [aFood(1), aFood(2)],
      at: PersonalFoodRoute(id: aFood(1).id),
      window: const Size(320, 640),
    );
    await tester.tap(find.byTooltip('More options'));
    await settle(tester);
    await tester.tap(find.text('Merge a duplicate into this food…'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FbListRow, 'Labneh'));
    await settle(tester);
    expect(find.text('Stays · 180 kcal per 100 g'), findsOneWidget);
    expect(
      find.text('Merged in and removed · 180 kcal per 100 g'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.widgetWithText(FbButton, 'Merge'));
    await tester.tap(find.widgetWithText(FbButton, 'Merge'));
    await settle(tester);
    expect(find.text('Merged into Labneh'), findsOneWidget);
    expect(await storedFoods(tester, container), hasLength(1));
    await finish(tester, container);
  });
}
