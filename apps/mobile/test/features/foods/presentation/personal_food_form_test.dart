import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/ids/id_generator.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:fb_mobile/features/foods/presentation/personal_foods/personal_food_form_sections.dart';
import 'package:fb_mobile/l10n/gen/app_localizations_en.dart';
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

  testWidgets('FD-070 a label typed per serving is saved per 100 and reopens '
      'per serving', (tester) async {
    final container = await pumpPersonal(tester, at: const PersonalFoodRoute());
    await type(tester, 'Name', 'Protein bar');
    await tapVisible(tester, find.text('One serving'));
    expect(selected(tester, 'One serving'), isTrue);
    await type(tester, 'Serving size', '30');
    // The label: 120 kcal, 3 g protein, 2 g carbs, 10 g fat per serving.
    await fillValues(tester, kcal: '120', protein: '3', carbs: '2', fat: '10');
    await tapVisible(tester, find.text('Save'));

    final food = (await storedFoods(tester, container)).single;
    expect(food.per100.kcal, closeTo(400, 1e-9));
    expect(food.per100.fat, closeTo(100.0 / 3, 1e-9));
    expect(food.entryServing, PersonalFoodServing('serving', 30));
    await finish(tester, container);

    // Reopened from the list, it shows the label's numbers again.
    await tester.tap(find.text('Protein bar'));
    await settle(tester);
    expect(selected(tester, 'One serving'), isTrue);
    expect(selected(tester, '100 g'), isFalse);
    expect(textOf(tester, 'Serving size'), '30');
    expect(textOf(tester, 'Calories'), '120');
    expect(textOf(tester, 'Fat'), '10');
    await finish(tester, container);
  });

  testWidgets('FD-012 a mismatched food shows the gentle warning and still '
      'saves', (tester) async {
    final container = await pumpPersonal(tester, at: const PersonalFoodRoute());
    await type(tester, 'Name', 'Mystery');
    // 5 g protein, 10 g carbs, 2 g fat give about 78 kcal, not 500.
    await fillValues(tester, kcal: '500', protein: '5', carbs: '10', fat: '2');
    expect(
      find.text(
        "These numbers don't quite add up: protein, carbs and fat give about "
        '78 kcal. Check the label, or save anyway.',
      ),
      findsOneWidget,
    );
    expect(savePressed(tester), isNotNull);
    expect(
      tester
          .getTopLeft(find.textContaining("These numbers don't quite add up"))
          .dy,
      greaterThan(tester.getBottomLeft(fieldLabelled('Fiber')).dy),
    );
    expect(
      tester
          .getBottomLeft(
            find.textContaining("These numbers don't quite add up"),
          )
          .dy,
      lessThan(tester.getTopLeft(find.text('More nutrients')).dy),
    );

    await tapVisible(tester, find.text('Save'));

    expect(find.byType(PersonalFoodsScreen), findsOneWidget);
    final food = (await storedFoods(tester, container)).single;
    expect(food.per100.kcal, 500);
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

  testWidgets('FD-012 macros heavier than the food show the impossible note '
      'under Fiber and write nothing', (tester) async {
    final container = await pumpPersonal(tester, at: const PersonalFoodRoute());
    await type(tester, 'Name', 'Heavy');
    await fillValues(
      tester,
      kcal: '600',
      protein: '60',
      carbs: '30',
      fat: '20',
    );
    const impossible =
        'Those numbers are higher than any food can have. Check them against '
        'the label.';
    expect(find.text(impossible), findsOneWidget);
    expect(
      tester.getTopLeft(find.text(impossible)).dy,
      greaterThan(tester.getBottomLeft(fieldLabelled('Fiber')).dy),
    );
    await tapVisible(tester, find.text('Save'));
    expect(await storedFoods(tester, container), isEmpty);

    await finish(tester, container);
  });

  test('FD-070 a value too small to store has its own words, not the '
      'upper-bound ones', () {
    final l10n = AppLocalizationsEn();
    expect(
      PersonalFormBinding.errorWords(l10n, PersonalFoodFieldError.tooSmall),
      "That's too small to save. Use 0 or a bigger number.",
    );
    expect(
      PersonalFormBinding.errorWords(l10n, PersonalFoodFieldError.bounds),
      "That's more than a food can hold.",
    );
  });

  for (final (label, food, open) in [
    ('with an Arabic name opens', aFood(1, ar: 'لبنة'), true),
    ('without details keeps closed', aFood(1), false),
  ]) {
    testWidgets('FD-070 editing a food $label More details', (tester) async {
      final container = await pumpPersonal(
        tester,
        foods: [food],
        at: PersonalFoodRoute(id: food.id),
      );
      expect(
        fieldLabelled('Arabic name (optional)'),
        open ? findsOneWidget : findsNothing,
      );
      expect(fieldLabelled('Name'), findsOneWidget);
      // Editing never moves the keyboard to Calories.
      expect(
        tester.widget<TextField>(fieldLabelled('Calories')).focusNode!.hasFocus,
        isFalse,
      );
      await finish(tester, container);
    });
  }

  testWidgets('UX-052 a refused save says why and keeps what was typed', (
    tester,
  ) async {
    // The writer refuses: the food changed meanwhile.
    final container = await pumpPersonal(
      tester,
      at: PersonalFoodRoute(id: aFood(1).id),
      foods: [aFood(1)],
      overrides: [
        personalFoodActionsProvider.overrideWith(
          (ref) => PersonalFoodActions(
            apply: (_) async => const Rejected(
              VersionConflict(
                entity: 'personalFood',
                id: '0199e3c2-5b1a-7c3d-8e4f-000000000001',
                expected: 1,
                actual: 2,
              ),
            ),
            undoStack: ref.watch(undoStackProvider),
            ids: ref.watch(idGeneratorProvider),
          ),
        ),
      ],
    );
    await type(tester, 'Name', 'Labneh typed');
    await fillValues(tester);
    await tapVisible(tester, find.text('Save'));

    expect(find.byType(PersonalFoodFormScreen), findsOneWidget);
    expect(
      find.text(
        'This food changed elsewhere. Reload to see the latest. '
        'What you typed stays.',
      ),
      findsOneWidget,
    );
    await applyOps(tester, container, [
      UpdatePersonalFood(aFood(1).id, 1, aFood(1, name: 'Remote').draft),
    ]);
    await settle(tester);
    expect(savePressed(tester), isNull);
    final refused = find.byWidgetPredicate(
      (w) =>
          w is FbInlineBanner &&
          w.message.startsWith('This food changed elsewhere.'),
    );
    await tester.tap(
      find.descendant(of: refused, matching: find.text('Reload')),
    );
    await settle(tester);
    expect(textOf(tester, 'Name'), 'Labneh typed');
    expect(textOf(tester, 'Calories'), '180');
    expect(savePressed(tester), isNotNull);
    expect((await storedFoods(tester, container)).single.version, 2);
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

  testWidgets('UX-052 an untouched form leaves without asking', (tester) async {
    final container = await pumpPersonal(
      tester,
      at: const PersonalFoodsRoute(),
    );
    await tester.tap(find.byTooltip('New food'));
    await settle(tester);
    await tester.tap(find.byType(BackButton));
    await settle(tester);
    expect(find.text('Discard changes?'), findsNothing);
    expect(find.byType(PersonalFoodsScreen), findsOneWidget);
    await finish(tester, container);
  });

  testWidgets('UX-052 a deleted food turns Save off and says so', (
    tester,
  ) async {
    final food = aFood(1);
    final container = await pumpPersonal(
      tester,
      foods: [food],
      at: PersonalFoodRoute(id: food.id),
    );
    expect(savePressed(tester), isNotNull);

    await applyOps(tester, container, [
      DeletePersonalFood(VersionedId(food.id, food.version)),
    ]);
    await settle(tester);

    expect(find.text('This food was deleted.'), findsOneWidget);
    expect(savePressed(tester), isNull);
    expect(find.byTooltip('More options'), findsNothing);
    await finish(tester, container);
  });

  testWidgets('UX-052 a changed food offers Reload, which keeps the typed '
      'values', (tester) async {
    final food = aFood(1);
    final container = await pumpPersonal(
      tester,
      foods: [food],
      at: PersonalFoodRoute(id: food.id),
    );
    await type(tester, 'Name', 'Labneh typed');

    // Another screen (or device) changes the calories meanwhile.
    final changed = PersonalFoodDraft(
      names: food.names,
      basis: food.basis,
      per100: Nutrients(kcal: 190, protein: 6, carbs: 4, fat: 16, fiber: 0),
    );
    await applyOps(tester, container, [
      UpdatePersonalFood(food.id, food.version, changed),
    ]);
    await settle(tester);

    expect(find.text('This food changed.'), findsOneWidget);
    expect(savePressed(tester), isNull);
    expect(textOf(tester, 'Calories'), '180');

    await tester.tap(find.text('Reload'));
    await settle(tester);

    expect(find.text('This food changed.'), findsNothing);
    expect(textOf(tester, 'Name'), 'Labneh typed');
    expect(textOf(tester, 'Calories'), '190');
    expect(savePressed(tester), isNotNull);

    await tapVisible(tester, find.text('Save'));
    final saved = (await storedFoods(tester, container)).single;
    expect(saved.names.en, 'Labneh typed');
    expect(saved.per100.kcal, 190);
    expect(saved.version, 3);
    await finish(tester, container);
  });

  testWidgets('FD-070 saving an untouched form writes nothing', (tester) async {
    final food = aFood(1, entryServing: PersonalFoodServing('piece', 30));
    final container = await pumpPersonal(
      tester,
      foods: [food],
      at: PersonalFoodRoute(id: food.id),
    );
    await tapVisible(tester, find.text('Save'));

    expect(find.byType(PersonalFoodsScreen), findsOneWidget);
    expect((await storedFoods(tester, container)).single.version, 1);
    expect(find.textContaining('Saved'), findsNothing);
    await finish(tester, container);
  });

  testWidgets('UX-070 the form is usable on a 320 x 640 phone at text scale '
      '2.0: every field can be reached and Save stays on screen', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final container = await pumpPersonal(
      tester,
      at: const PersonalFoodRoute(),
      window: const Size(320, 640),
    );
    expect(tester.takeException(), isNull);
    // Save is pinned under the scrolling form.
    final save = find.widgetWithText(FbButton, 'Save');
    expect(tester.getBottomLeft(save).dy, lessThanOrEqualTo(640));
    await type(tester, 'Name', 'Small phone');
    await fillValues(tester);
    await tapVisible(tester, find.text('More details'));
    await tester.ensureVisible(fieldLabelled('Barcodes (optional)'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tapVisible(tester, find.text('Save'));
    expect(
      (await storedFoods(tester, container)).single.names.en,
      'Small phone',
    );
    await finish(tester, container);
  });
  testWidgets(
    'FD-070 duplicate Save awaits the first failure without leaving',
    (tester) async {
      final pending = Completer<ApplyResult>();
      var calls = 0;
      final container = await pumpPersonal(
        tester,
        foods: [aFood(1)],
        at: PersonalFoodRoute(id: aFood(1).id),
        overrides: [
          personalFoodActionsProvider.overrideWith(
            (ref) => PersonalFoodActions(
              apply: (_) {
                calls++;
                return pending.future;
              },
              undoStack: ref.watch(undoStackProvider),
              ids: ref.watch(idGeneratorProvider),
            ),
          ),
        ],
      );
      await type(tester, 'Name', 'Typed');
      final save = savePressed(tester)!;
      save();
      save();
      expect(calls, 1);
      pending.complete(const Rejected(InvalidOp('synthetic')));
      await settle(tester);
      expect(find.byType(PersonalFoodFormScreen), findsOneWidget);
      expect(textOf(tester, 'Name'), 'Typed');
      expect(
        find.text("Couldn't save that. Check the numbers and try again."),
        findsOneWidget,
      );
      expect((await storedFoods(tester, container)).single.version, 1);
      await finish(tester, container);
    },
  );

  testWidgets('FD-070 UX-070 details collapse, errors open them, and serving '
      'controls fit a 320 x 640 phone with context labels', (tester) async {
    final semantics = tester.ensureSemantics();
    final container = await pumpPersonal(
      tester,
      at: const PersonalFoodRoute(),
      window: const Size(320, 640),
    );
    expect(fieldLabelled('Arabic name (optional)'), findsNothing);
    await type(tester, 'Name', 'Label');
    await tapVisible(tester, find.text('One serving'));
    await type(tester, 'Serving size', '30');
    expect(
      find.text('Shown in your diary as 1 serving (30 g)'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Serving size in grams'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Serving size in millilitres'),
      findsOneWidget,
    );
    await fillValues(tester, kcal: '120', protein: '3', carbs: '2', fat: '10');
    expect(find.text('Numbers stay as typed.'), findsOneWidget);
    await tapVisible(tester, find.text('More nutrients'));
    expect(find.text("Leave blank if you don't know"), findsOneWidget);
    await tapVisible(tester, find.text('More details'));
    final arabic = tester.widget<TextField>(
      fieldLabelled('Arabic name (optional)'),
    );
    expect(arabic.textDirection, TextDirection.rtl);
    await tapVisible(tester, find.text('Add serving'));
    // The blank row, rather than the list, gets the serving error.
    expect(
      tester
          .widgetList<FbNumberField>(find.byType(FbNumberField))
          .where((f) => f.errorText != null)
          .length,
      1,
    );
    await tapVisible(tester, find.text('More details'));
    await tapVisible(tester, find.text('Save'));
    expect(fieldLabelled('Arabic name (optional)'), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
    await finish(tester, container);
  });

  for (final action in ['Delete food', 'Merge a duplicate into this food…']) {
    testWidgets('UX-052 dirty form asks before $action', (tester) async {
      final container = await pumpPersonal(
        tester,
        foods: [aFood(1)],
        at: PersonalFoodRoute(id: aFood(1).id),
      );
      await type(tester, 'Name', 'Draft');
      await tester.tap(find.byTooltip('More options'));
      await settle(tester);
      await tester.tap(find.text(action));
      await settle(tester);
      expect(find.text('Discard changes?'), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      await settle(tester);
      expect(textOf(tester, 'Name'), 'Draft');
      expect((await storedFoods(tester, container)).single.version, 1);
      await tester.tap(find.byTooltip('More options'));
      await settle(tester);
      await tester.tap(find.text(action));
      await settle(tester);
      await tester.tap(find.text('Discard'));
      await settle(tester);
      if (action == 'Delete food') {
        expect(await storedFoods(tester, container), isEmpty);
      } else {
        expect(find.text('Merge a duplicate'), findsOneWidget);
      }
      await finish(tester, container);
    });
  }
  testWidgets('FD-070 bad barcodes get the label-check error', (tester) async {
    final container = await pumpPersonal(tester, at: const PersonalFoodRoute());
    await type(tester, 'Name', 'Test');
    await fillValues(tester);
    await tapVisible(tester, find.text('More details'));
    await type(tester, 'Barcodes (optional)', '123');
    expect(
      find.text('Check this barcode. It should have 8, 12, 13 or 14 digits.'),
      findsOneWidget,
    );
    await finish(tester, container);
  });
}
