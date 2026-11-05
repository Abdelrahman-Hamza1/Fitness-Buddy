import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:fb_mobile/features/foods/presentation/personal_foods/merge_food_sheet.dart';
import 'package:fb_mobile/features/settings/settings.dart';
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

  testWidgets('A57 T-N2 LC-007 A38 Arabic: the merge picker, the confirmation '
      'and the merged message name the Arabic foods', (tester) async {
    const ar1 = 'لبنة';
    const ar2 = 'لبنة بلدي';
    final container = await pumpPersonal(
      tester,
      foods: [
        aFood(1, ar: ar1),
        aFood(2, name: 'Labne', ar: ar2),
      ],
      at: const PersonalFoodsRoute(),
      overrides: [
        foodNameSettingProvider.overrideWith(
          (ref) => Stream.value(FoodNameLanguage.arabic),
        ),
      ],
    );
    await tester.tap(find.text(ar1));
    await settle(tester);
    await tester.tap(find.byTooltip('More options'));
    await settle(tester);
    await tester.tap(find.text('Merge a duplicate into this food…'));
    await settle(tester);
    // The picker lists the other food by its Arabic name.
    await tester.tap(find.widgetWithText(FbListRow, ar2));
    await settle(tester);
    expect(
      tester.widget<FbListRow>(find.byKey(const ValueKey('merge-keep'))).title,
      ar1,
    );
    expect(find.textContaining('\u2068$ar1\u2069'), findsWidgets);
    expect(find.textContaining('\u2068$ar2\u2069'), findsWidgets);
    expect(
      find.descendant(
        of: find.byType(MergeConfirmSheet),
        matching: find.textContaining('Labne'),
      ),
      findsNothing,
    );

    await tester.tap(find.widgetWithText(FbButton, 'Merge'));
    await settle(tester);
    final snack = tester.widget<Text>(
      find
          .descendant(of: find.byType(SnackBar), matching: find.byType(Text))
          .first,
    );
    expect(snack.data, contains('\u2068$ar2\u2069'));
    expect(snack.data, isNot(contains('Labne')));
    await finish(tester, container);
  });

  testWidgets('A57 A70 T-R7 merge confirm can go back to the picker', (
    tester,
  ) async {
    final container = await pumpPersonal(
      tester,
      foods: [
        aFood(1),
        aFood(2, name: 'Labne'),
        aFood(3, name: 'Labna'),
      ],
      at: const PersonalFoodsRoute(),
    );
    await openMerge(tester);
    expect(find.byType(MergeConfirmSheet), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('merge-choose-another')));
    await settle(tester);
    expect(find.byType(MergeConfirmSheet), findsNothing);
    expect(find.byType(MergePickerSheet), findsOneWidget);
    await tester.tap(find.widgetWithText(FbListRow, 'Labna'));
    await settle(tester);
    expect(
      tester.widget<FbListRow>(find.byKey(const ValueKey('merge-other'))).title,
      'Labna',
    );
    await finish(tester, container);
  });
}
