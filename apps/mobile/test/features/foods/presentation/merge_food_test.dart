import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
