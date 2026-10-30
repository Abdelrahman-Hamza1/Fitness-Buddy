import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/personal_food_support.dart';

/// Types [text] into the field labelled [label].
Future<void> type(WidgetTester tester, String label, String text) async {
  final field = fieldLabelled(label);
  await tester.ensureVisible(field);
  await tester.enterText(field, text);
  await tester.pump();
}

/// Taps the widget [finder] after scrolling it into view.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await settle(tester);
}

/// The text now in the field labelled [label].
String textOf(WidgetTester tester, String label) => tester
    .widget<EditableText>(
      find.descendant(
        of: fieldLabelled(label),
        matching: find.byType(EditableText),
      ),
    )
    .controller
    .text;

/// Whether the chip with [label] is the selected one of its choice.
bool selected(WidgetTester tester, String label) => tester
    .widget<FbChoiceChip>(find.widgetWithText(FbChoiceChip, label))
    .selected;

/// The Save button's callback: null while Save is off.
VoidCallback? savePressed(WidgetTester tester) =>
    tester.widget<FbButton>(find.widgetWithText(FbButton, 'Save')).onPressed;

/// The macros that add up to ~180 kcal: 6 g protein, 4 g carbs, 15 g fat.
Future<void> fillValues(
  WidgetTester tester, {
  String kcal = '180',
  String protein = '6',
  String carbs = '4',
  String fat = '15',
}) async {
  await type(tester, 'Calories', kcal);
  await type(tester, 'Protein', protein);
  await type(tester, 'Carbs', carbs);
  await type(tester, 'Fat', fat);
}

void main() {
  testWidgets('FD-070 the form creates a food with values per 100 g and a '
      '30 g piece serving; Save shows Undo; it is listed under Your foods', (
    tester,
  ) async {
    final container = await pumpPersonal(
      tester,
      at: const PersonalFoodsRoute(),
    );
    await tester.tap(find.byTooltip('New food'));
    await settle(tester);
    expect(find.byType(PersonalFoodFormScreen), findsOneWidget);

    await type(tester, 'Name', 'Labneh');
    await fillValues(tester);
    await tapVisible(tester, find.text('More details'));
    await tapVisible(tester, find.text('Add serving'));
    await tapVisible(tester, find.text('Serving called'));
    await tester.tap(find.text('piece'));
    await settle(tester);
    await type(tester, 'Serving size', '30');

    await tapVisible(tester, find.text('Save'));

    expect(find.byType(PersonalFoodsScreen), findsOneWidget);
    expect(find.text('Saved Labneh'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
    expect(find.text('Labneh'), findsOneWidget);
    final foods = await storedFoods(tester, container);
    expect(foods.single.names.en, 'Labneh');
    expect(foods.single.per100.kcal, 180);
    expect(foods.single.basis, NutrientBasis.per100g);
    expect(foods.single.servings, [PersonalFoodServing('piece', 30)]);
    expect(foods.single.entryServing, isNull);

    await tester.tap(find.text('Undo'));
    await settle(tester);
    expect(await storedFoods(tester, container), isEmpty);
    await finish(tester, container);
  });

  testWidgets('FD-012 an impossible value blocks Save with a field error and '
      'a banner, and writes nothing', (tester) async {
    final container = await pumpPersonal(tester, at: const PersonalFoodRoute());
    await type(tester, 'Name', 'Impossible');
    await fillValues(tester, kcal: '1200', protein: '5', carbs: '10', fat: '2');
    await tapVisible(tester, find.text('Save'));

    expect(find.byType(PersonalFoodFormScreen), findsOneWidget);
    expect(find.text("That's more than a food can hold."), findsOneWidget);
    expect(
      find.text("Some fields need a look. They're marked below."),
      findsOneWidget,
    );
    expect(await storedFoods(tester, container), isEmpty);
    await finish(tester, container);
  });

  testWidgets("FD-073 rename from the form, then delete with Undo; Today's "
      'entries of that food are unchanged', (tester) async {
    final food = aFood(1);
    final container = await pumpPersonal(
      tester,
      foods: [food],
      at: const PersonalFoodsRoute(),
    );
    await applyOps(tester, container, [
      LogEntries([entryOfPersonal(container, food, n: 1)]),
    ]);
    final before = (await liveEntries(tester, container)).single;

    await tester.tap(find.text('Labneh'));
    await settle(tester);
    expect(find.text('Edit food'), findsOneWidget);
    await type(tester, 'Name', 'Labneh strained');
    await tapVisible(tester, find.text('Save'));

    expect(find.text('Saved Labneh strained'), findsOneWidget);
    expect(find.text('Labneh strained'), findsWidgets);
    var entry = (await liveEntries(tester, container)).single;
    expect(entry.nameEn, 'Labneh');
    expect(entry.per100Kcal, before.per100Kcal);
    expect(entry.kcal, before.kcal);
    await finish(tester, container);

    await tester.tap(find.text('Labneh strained'));
    await settle(tester);
    await tester.tap(find.byTooltip('More options'));
    await settle(tester);
    await tester.tap(find.text('Delete food'));
    await settle(tester);

    expect(find.byType(PersonalFoodsScreen), findsOneWidget);
    expect(find.text('Deleted Labneh strained'), findsOneWidget);
    expect(find.text('No foods of your own yet'), findsOneWidget);
    expect(await storedFoods(tester, container), isEmpty);
    entry = (await liveEntries(tester, container)).single;
    expect(entry.nameEn, 'Labneh');
    expect(entry.foodId, food.id);

    await tester.tap(find.text('Undo'));
    await settle(tester);
    expect(
      (await storedFoods(tester, container)).single.names.en,
      'Labneh strained',
    );
    expect((await liveEntries(tester, container)).single.nameEn, 'Labneh');
    await finish(tester, container);
  });

  testWidgets('UX-052 leaving a dirty form asks before discarding', (
    tester,
  ) async {
    final container = await pumpPersonal(
      tester,
      at: const PersonalFoodsRoute(),
    );
    await tester.tap(find.byTooltip('New food'));
    await settle(tester);
    await type(tester, 'Name', 'Draft');

    await tester.tap(find.byType(BackButton));
    await settle(tester);
    expect(find.text('Discard changes?'), findsOneWidget);
    expect(find.byType(PersonalFoodFormScreen), findsOneWidget);

    await tester.tap(find.text('Keep editing'));
    await settle(tester);
    expect(find.text('Discard changes?'), findsNothing);
    expect(textOf(tester, 'Name'), 'Draft');

    await tester.tap(find.byType(BackButton));
    await settle(tester);
    await tester.tap(find.text('Discard'));
    await settle(tester);
    expect(find.byType(PersonalFoodFormScreen), findsNothing);
    expect(find.byType(PersonalFoodsScreen), findsOneWidget);
    expect(await storedFoods(tester, container), isEmpty);
    await finish(tester, container);
  });
}
