import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../diary/support/diary_fixtures.dart' show fixtureId;
import '../../diary/support/diary_harness.dart';
import 'support/today_support.dart';
import 'today_actions_test.dart' show log, pumpRig, row, settle;

/// A loaf of pita: 60 g, 275 kcal per 100 g, so 165 kcal.
NewDiaryEntry pitaLoaf(
  int n,
  LocalDate date, {
  String slotId = DefaultSlots.breakfastId,
  int hour = 8,
}) => NewDiaryEntry(
  id: fixtureId(n),
  when: atDay(date, hour),
  slotId: slotId,
  food: EntryFood(
    ref: FoodRef.catalog('usda:pita_white', version: '6'),
    names: FoodNames('Pita bread, white', ar: 'خبز عربي'),
    per100: Nutrients(
      kcal: 275,
      protein: 9.1,
      carbs: 55.7,
      fat: 1.2,
      fiber: 2.2,
    ),
    provenance: Provenance(source: FoodSource.database),
  ),
  amount: EntryAmount(
    input: Quantity(1, 'loaf'),
    amount: 60,
    basis: NutrientBasis.per100g,
  ),
);

/// The v1 id and version of entry [n], as an op expects them.
VersionedId vid(int n, [int version = 1]) => VersionedId(fixtureId(n), version);

Finder chip(String label) => find.byWidgetPredicate(
  (w) => w is FbChoiceChip && w.label == label,
  description: 'FbChoiceChip "$label"',
);

Finder button(String label) => find.widgetWithText(FbButton, label);

bool isEnabled(WidgetTester tester, Finder finder) =>
    tester.widget<FbButton>(finder).onPressed != null;

/// Types [keys] on the number pad (`<` is backspace).
Future<void> pad(WidgetTester tester, String keys) async {
  for (final key in keys.split('')) {
    await tester.tap(
      find.descendant(
        of: find.byType(FbNumberPad),
        matching: key == '<' ? find.byIcon(FbIcons.backspace) : find.text(key),
      ),
    );
    await tester.pump();
  }
}

/// A taller phone, so a sheet with its pad shows whole (and the day's rows
/// stay on screen under the header's weight card, A14).
void useTallPhone(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(360, 1500)
    ..devicePixelRatio = 1;
}

/// Today with a pita loaf in an opened breakfast and its details open.
Future<TodayRig> pitaDetails(WidgetTester tester, {TodayRig? rig}) async {
  rig ??= TodayRig();
  await pumpRig(tester, rig);
  useTallPhone(tester);
  await log(tester, rig, [pitaLoaf(1, testToday)]);
  await tester.tap(find.widgetWithText(FbDisclosureRow, 'Breakfast'));
  await tester.pump();
  await tester.tap(row('Pita bread, white'));
  await tester.pump();
  return rig;
}

/// Two plain entries (Food 1, Food 2) in an opened breakfast on today.
Future<TodayRig> foodsDetails(WidgetTester tester, {TodayRig? rig}) async {
  rig ??= TodayRig();
  await pumpRig(tester, rig);
  useTallPhone(tester);
  await log(tester, rig, [
    newEntry(1, when: atDay(testToday, 8), slotId: DefaultSlots.breakfastId),
    newEntry(2, when: atDay(testToday, 9), slotId: DefaultSlots.breakfastId),
  ]);
  await tester.tap(find.widgetWithText(FbDisclosureRow, 'Breakfast'));
  await tester.pump();
  await tester.tap(row('Food 1'));
  await tester.pump();
  return rig;
}

Finder slotKcal(String slot, String kcal) => find.descendant(
  of: find.widgetWithText(FbDisclosureRow, slot),
  matching: find.text(kcal),
);

void main() {
  group('amount', () {
    testWidgets('DY-021 the amount chip opens the sheet; 2 loaves saves with '
        'Undo and updates the slot kcal', (tester) async {
      final rig = await pitaDetails(tester);
      expect(slotKcal('Breakfast', '165 kcal'), findsOneWidget);

      await tester.tap(chip('Amount'));
      await tester.pumpAndSettle();
      // The pita's own loaf, 60 g; the first key replaces the 1.
      expect(find.text('Pita bread, white'), findsAtLeastNWidgets(1));
      expect(find.text('165 kcal'), findsAtLeastNWidgets(1));
      await pad(tester, '2');
      expect(find.text('330 kcal'), findsOneWidget);
      await tester.tap(button('Save'));
      await settle(tester);

      expect(
        find.text('Changed Pita bread, white to 2 loaves'),
        findsOneWidget,
      );
      expect(find.text('Undo'), findsOneWidget);
      final stored = (await tester.runAsync(() => rig.diary.entry(1)))!;
      expect(stored.amount, 120);
      expect(stored.inputAmount, 2);
      expect(stored.inputUnit, 'loaf');
      expect(slotKcal('Breakfast', '330 kcal'), findsOneWidget);
      expect(find.text('330'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await settle(tester);
      expect(slotKcal('Breakfast', '165 kcal'), findsOneWidget);
      expect(find.text('165'), findsOneWidget);
      rig.stack.dispose();
    });

    testWidgets('DY-021 the same amount writes nothing', (tester) async {
      final rig = await pitaDetails(tester);

      await tester.tap(chip('Amount'));
      await tester.pumpAndSettle();
      await tester.tap(button('Save'));
      await settle(tester);

      expect(find.text('Undo'), findsNothing);
      expect(find.byType(EntryAmountSheet), findsNothing);
      expect((await tester.runAsync(() => rig.diary.entry(1)))!.version, 1);
      rig.stack.dispose();
    });

    testWidgets('DY-021 an amount of 0 or nothing leaves Save off', (
      tester,
    ) async {
      await pitaDetails(tester);

      await tester.tap(chip('Amount'));
      await tester.pumpAndSettle();
      await pad(tester, '0');
      expect(isEnabled(tester, button('Save')), isFalse);
      await pad(tester, '<');
      expect(isEnabled(tester, button('Save')), isFalse);
      await pad(tester, '3');
      expect(isEnabled(tester, button('Save')), isTrue);
    });
  });

  group('slot and time', () {
    testWidgets('DY-021 the slot chip moves the item in one tap; the time '
        'chip changes the time; same value writes nothing', (tester) async {
      final rig = await foodsDetails(tester);

      // Meal: open the list, one tap on Lunch. No Save step.
      await tester.tap(chip('Meal'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FbListRow, 'Lunch').last);
      await settle(tester);
      expect(find.text('Moved Food 1 to Lunch'), findsOneWidget);
      expect(
        (await tester.runAsync(() => rig.diary.entry(1)))!.slotId,
        DefaultSlots.lunchId,
      );
      // The details follow the item to its new meal.
      expect(chip('Meal'), findsOneWidget);
      expect(tester.widget<FbChoiceChip>(chip('Meal')).value, 'Lunch');

      // Time: 10:30 through the picker's text mode.
      await tester.tap(chip('Time'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.keyboard_outlined));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), '10');
      await tester.enterText(find.byType(TextField).at(1), '30');
      await tester.tap(find.text('OK'));
      await settle(tester);
      expect(
        find.text('Changed the time of Food 1 to 10:30 AM'),
        findsOneWidget,
      );
      final changed = (await tester.runAsync(() => rig.diary.entry(1)))!;
      expect(changed.slotId, DefaultSlots.lunchId, reason: 'time keeps meal');
      expect(
        DateTime.fromMillisecondsSinceEpoch(changed.occurredAtUtc, isUtc: true),
        DateTime.utc(2026, 10, 17, 10, 30),
      );
      final version = changed.version;

      // The same time again: OK on the picker writes nothing.
      await tester.tap(chip('Time'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await settle(tester);
      expect(
        (await tester.runAsync(() => rig.diary.entry(1)))!.version,
        version,
      );
      rig.stack.dispose();
    });
  });

  group('change food', () {
    testWidgets('DY-021 Change food opens the search in replace mode with '
        'the item and its version', (tester) async {
      final rig = await foodsDetails(tester);

      await tester.tap(chip('Change food'));
      await tester.pump();

      final route = rig.navigator.pushed.single as FoodSearchRoute;
      expect(route.replace, vid(1));
      expect(route.date, testToday);
      expect(route.slotId, DefaultSlots.breakfastId);
      rig.stack.dispose();
    });
  });

  group('nutrient values', () {
    testWidgets('AI-072 tapping Protein opens the override sheet; Save shows '
        'the yours badge and "edited by you"', (tester) async {
      final rig = await pitaDetails(tester);
      expect(find.text('Food database'), findsOneWidget);

      await tester.tap(find.text('Protein'));
      await tester.pumpAndSettle();
      expect(find.text('Edit Protein'), findsOneWidget);
      await pad(tester, '30');
      await tester.tap(button('Save'));
      await settle(tester);

      expect(find.text('Edited Protein of Pita bread, white'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
      expect(find.text('Your edit of food database values'), findsOneWidget);
      final details = find.byType(EntryDetailsPanel);
      expect(
        tester
            .widget<FbSourceBadge>(
              find.descendant(
                of: details,
                matching: find.byType(FbSourceBadge),
              ),
            )
            .source,
        FbSource.yours,
      );
      expect(
        find.descendant(of: details, matching: find.text('30 g')),
        findsOneWidget,
      );
      final stored = (await tester.runAsync(() => rig.diary.entry(1)))!;
      expect(stored.editedByUser, isTrue);

      await tester.tap(find.text('Undo'));
      await settle(tester);
      expect(find.text('Food database'), findsOneWidget);
      expect(find.text('Your edit of food database values'), findsNothing);
      rig.stack.dispose();
    });

    testWidgets('AI-072 a value above the limit is explained and Save stays '
        'off', (tester) async {
      await pitaDetails(tester);

      await tester.tap(find.text('Calories'));
      await tester.pumpAndSettle();
      await pad(tester, '30000');

      expect(find.text('Enter 20,000 kcal or less.'), findsOneWidget);
      expect(isEnabled(tester, button('Save')), isFalse);
      await pad(tester, '<');
      expect(find.text('Enter 20,000 kcal or less.'), findsNothing);
      expect(isEnabled(tester, button('Save')), isTrue);
    });

    testWidgets('AI-072 grams take one decimal, kcal and mg none', (
      tester,
    ) async {
      await pitaDetails(tester);

      await tester.tap(find.text('Protein'));
      await tester.pumpAndSettle();
      await pad(tester, '1.55');
      // The second decimal is refused by the pad.
      expect(find.bySemanticsLabel('Protein, 1.5 g'), findsOneWidget);
    });
  });

  group('details buttons', () {
    testWidgets('DY-021 DY-022 UX-013 the Meal chip is the visible Move '
        'control and the details have a visible Delete button', (tester) async {
      final rig = await foodsDetails(tester);
      // One Move control, the chip; no second button for it.
      expect(button('Move to another meal'), findsNothing);

      await tester.tap(chip('Meal'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FbListRow, 'Dinner').last);
      await settle(tester);
      expect(find.text('Moved Food 1 to Dinner'), findsOneWidget);
      expect(
        (await tester.runAsync(() => rig.diary.entry(1)))!.slotId,
        DefaultSlots.dinnerId,
      );

      await tester.tap(button('Delete'));
      await settle(tester);
      expect(find.text('Deleted Food 1'), findsOneWidget);
      expect(
        (await tester.runAsync(() => rig.diary.entry(1)))!.deletedAt,
        isNotNull,
      );
      expect(find.byType(EntryDetailsPanel), findsNothing);

      await tester.tap(find.text('Undo'));
      await settle(tester);
      expect(
        (await tester.runAsync(() => rig.diary.entry(1)))!.deletedAt,
        isNull,
      );
      rig.stack.dispose();
    });

    testWidgets('DY-021 the Change food chip has a leading search icon', (
      tester,
    ) async {
      await foodsDetails(tester);

      expect(
        find.descendant(
          of: chip('Change food'),
          matching: find.byIcon(FbIcons.search),
        ),
        findsOneWidget,
      );
    });
  });

  group('open sheets follow their item', () {
    testWidgets('D12 a sheet whose entry is deleted says "This item was '
        'removed" and disables Save', (tester) async {
      final rig = await foodsDetails(tester);
      await tester.tap(chip('Amount'));
      await tester.pumpAndSettle();
      await pad(tester, '2');
      expect(isEnabled(tester, button('Save')), isTrue);

      await tester.runAsync(
        () => rig.diary.apply([
          DeleteEntries([vid(1)]),
        ]),
      );
      await settle(tester);

      expect(find.text('This item was removed.'), findsOneWidget);
      expect(isEnabled(tester, button('Save')), isFalse);
      expect(find.byType(EntryAmountSheet), findsOneWidget);
      rig.stack.dispose();
    });

    testWidgets('D12 a sheet whose entry moved to another slot or day stays '
        'usable', (tester) async {
      final rig = await foodsDetails(tester);
      await tester.tap(chip('Amount'));
      await tester.pumpAndSettle();
      await pad(tester, '2');

      await tester.runAsync(
        () => rig.diary.apply([
          MoveEntries([vid(1)], toSlotId: DefaultSlots.lunchId),
        ]),
      );
      await settle(tester);
      expect(find.text('This item changed.'), findsNothing);
      expect(find.text('This item was removed.'), findsNothing);
      expect(isEnabled(tester, button('Save')), isTrue);

      // Another day: the same entry, a new version.
      await tester.runAsync(
        () => rig.diary.apply([
          UpdateDiaryEntry(
            fixtureId(1),
            2,
            EntryPatch(localDate: testYesterday, localTime: LocalTime(9)),
          ),
        ]),
      );
      await settle(tester);
      expect(find.text('This item changed.'), findsNothing);
      expect(isEnabled(tester, button('Save')), isTrue);

      await tester.tap(button('Save'));
      await settle(tester);
      expect(find.byType(EntryAmountSheet), findsNothing);
      expect(find.text('Changed Food 1 to 2 g'), findsOneWidget);
      final stored = (await tester.runAsync(() => rig.diary.entry(1)))!;
      expect(stored.amount, 2);
      expect(stored.version, 4);
      rig.stack.dispose();
    });

    testWidgets('D12 a changed version keeps the typed value and offers '
        'Reload', (tester) async {
      final rig = await foodsDetails(tester);
      await tester.tap(chip('Amount'));
      await tester.pumpAndSettle();
      await pad(tester, '5');

      await tester.runAsync(
        () => rig.diary.apply([
          UpdateDiaryEntry(
            fixtureId(1),
            1,
            EntryPatch(
              amount: EntryAmount(
                input: Quantity(200, 'g'),
                amount: 200,
                basis: NutrientBasis.per100g,
              ),
            ),
          ),
        ]),
      );
      await settle(tester);

      expect(find.text('This item changed.'), findsOneWidget);
      expect(isEnabled(tester, button('Save')), isFalse);
      expect(find.bySemanticsLabel('Amount, 5 g'), findsOneWidget);

      await tester.tap(find.text('Reload'));
      await tester.pumpAndSettle();
      expect(find.text('This item changed.'), findsNothing);
      expect(find.bySemanticsLabel('Amount, 5 g'), findsOneWidget);
      expect(isEnabled(tester, button('Save')), isTrue);

      await tester.tap(button('Save'));
      await settle(tester);
      final stored = (await tester.runAsync(() => rig.diary.entry(1)))!;
      expect(stored.amount, 5);
      expect(stored.version, 3);
      rig.stack.dispose();
    });

    testWidgets('D12 the value sheet follows its item too', (tester) async {
      final rig = await foodsDetails(tester);
      await tester.tap(find.text('Protein'));
      await tester.pumpAndSettle();
      await pad(tester, '9');

      await tester.runAsync(
        () => rig.diary.apply([
          DeleteEntries([vid(1)]),
        ]),
      );
      await settle(tester);

      expect(find.text('This item was removed.'), findsOneWidget);
      expect(isEnabled(tester, button('Save')), isFalse);
      rig.stack.dispose();
    });
  });

  group('meals', () {
    /// Yesterday with two entries in an opened breakfast.
    Future<TodayRig> yesterday(WidgetTester tester, {TodayRig? rig}) async {
      rig ??= TodayRig();
      await pumpRig(tester, rig);
      useTallPhone(tester);
      await tester.tap(find.byTooltip('Previous day'));
      await settle(tester);
      await log(tester, rig, [
        newEntry(
          1,
          when: atDay(testYesterday, 8),
          slotId: DefaultSlots.breakfastId,
        ),
        newEntry(
          2,
          when: atDay(testYesterday, 9),
          slotId: DefaultSlots.breakfastId,
        ),
      ]);
      return rig;
    }

    testWidgets('DY-023 the menu shows only for slots with entries; Copy '
        'to… defaults to the next day; Copy is disabled for the same day '
        'and slot; copying shows Undo', (tester) async {
      final rig = await yesterday(tester);

      // Only Breakfast has items, so only it has a menu.
      expect(find.byTooltip('More for Breakfast'), findsOneWidget);
      expect(find.byTooltip('More for Lunch'), findsNothing);
      expect(find.byTooltip('More for Snacks'), findsNothing);
      expect(find.byTooltip('More for Dinner'), findsNothing);

      await tester.tap(find.byTooltip('More for Breakfast'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Copy to…'));
      await tester.pumpAndSettle();

      // The day after yesterday is today; the meal stays Breakfast.
      expect(find.text('Copy Breakfast'), findsOneWidget);
      expect(tester.widget<FbChoiceChip>(chip('Day')).value, 'Today');
      expect(tester.widget<FbChoiceChip>(chip('Meal')).value, 'Breakfast');
      expect(isEnabled(tester, button('Copy')), isTrue);

      // Back to yesterday and Breakfast: the meal itself.
      await tester.tap(chip('Day'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('16'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(tester.widget<FbChoiceChip>(chip('Day')).value, 'Yesterday');
      expect(isEnabled(tester, button('Copy')), isFalse);
      expect(find.text('Choose where to copy this meal.'), findsOneWidget);

      // Another meal on the same day is a different target.
      await tester.tap(chip('Meal'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FbListRow, 'Lunch').last);
      await tester.pumpAndSettle();
      expect(find.text('Choose where to copy this meal.'), findsNothing);
      expect(isEnabled(tester, button('Copy')), isTrue);
      await tester.tap(button('Copy'));
      await settle(tester);

      expect(find.byType(CopyMealSheet), findsNothing);
      expect(find.text('Copied 2 items to Yesterday'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
      // The view stays on the day; Lunch now shows the copies.
      expect(find.text('Yesterday'), findsOneWidget);
      expect(slotKcal('Lunch', '600 kcal'), findsOneWidget);
      expect(slotKcal('Breakfast', '600 kcal'), findsOneWidget);
      final day = (await tester.runAsync(
        () => rig.diary.reads.day(testYesterday),
      ))!;
      expect(day.entries, hasLength(4));

      await tester.tap(find.text('Undo'));
      await settle(tester);
      expect(slotKcal('Lunch', '—'), findsOneWidget);
      rig.stack.dispose();
    });

    testWidgets('DY-023 copying to the next day lands on that day', (
      tester,
    ) async {
      final rig = await yesterday(tester);

      await tester.tap(find.byTooltip('More for Breakfast'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Copy to…'));
      await tester.pumpAndSettle();
      await tester.tap(button('Copy'));
      await settle(tester);

      expect(find.text('Copied 2 items to Today'), findsOneWidget);
      final today = (await tester.runAsync(
        () => rig.diary.reads.day(testToday),
      ))!;
      expect(today.entries.map((e) => e.food.names.en), ['Food 1', 'Food 2']);
      expect(find.text('Yesterday'), findsOneWidget);
      rig.stack.dispose();
    });

    testWidgets('DY-023 a copy sheet whose meal changed says "That meal '
        'changed. Nothing was copied." and stays open', (tester) async {
      final rig = TodayRig(
        apply: (change) async => const Rejected(InvalidOp('sourceChanged')),
      );
      await yesterday(tester, rig: rig);

      await tester.tap(find.byTooltip('More for Breakfast'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Copy to…'));
      await tester.pumpAndSettle();
      await tester.tap(button('Copy'));
      await settle(tester);

      expect(
        find.text('That meal changed. Nothing was copied.'),
        findsOneWidget,
      );
      expect(find.byType(CopyMealSheet), findsOneWidget);
      expect(find.text('Undo'), findsNothing);
      rig.stack.dispose();
    });

    testWidgets('DY-023 a meal edited under the open copy sheet shows "This '
        'meal changed" with Reload and keeps Copy off until then', (
      tester,
    ) async {
      final rig = await yesterday(tester);
      await tester.tap(find.byTooltip('More for Breakfast'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Copy to…'));
      await tester.pumpAndSettle();
      expect(isEnabled(tester, button('Copy')), isTrue);

      await tester.runAsync(
        () => rig.diary.apply([
          LogEntries([
            newEntry(
              3,
              when: atDay(testYesterday, 10),
              slotId: DefaultSlots.breakfastId,
            ),
          ]),
        ]),
      );
      await settle(tester);

      expect(find.text('This meal changed.'), findsOneWidget);
      expect(isEnabled(tester, button('Copy')), isFalse);
      await tester.tap(find.text('Reload'));
      await tester.pumpAndSettle();
      expect(find.text('This meal changed.'), findsNothing);
      expect(isEnabled(tester, button('Copy')), isTrue);
      await tester.tap(button('Copy'));
      await settle(tester);
      expect(find.text('Copied 3 items to Today'), findsOneWidget);
      rig.stack.dispose();
    });

    testWidgets('DY-023 Save as meal requires 1–60 characters; Save shows '
        'Undo', (tester) async {
      final rig = await yesterday(tester);

      await tester.tap(find.byTooltip('More for Breakfast'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save as meal…'));
      await tester.pumpAndSettle();

      // Prefilled with the meal's name.
      final field = find.byType(TextField);
      expect(tester.widget<TextField>(field).controller!.text, 'Breakfast');
      expect(isEnabled(tester, button('Save')), isTrue);

      await tester.enterText(field, '');
      await tester.pump();
      expect(isEnabled(tester, button('Save')), isFalse);
      expect(find.text('Give the meal a name.'), findsOneWidget);
      await tester.enterText(field, '   ');
      await tester.pump();
      expect(isEnabled(tester, button('Save')), isFalse);

      // 61 characters: the field keeps 60.
      await tester.enterText(field, 'a' * 61);
      await tester.pump();
      expect(tester.widget<TextField>(field).controller!.text, hasLength(60));
      expect(find.text('60/60'), findsOneWidget);
      expect(isEnabled(tester, button('Save')), isTrue);

      await tester.enterText(field, 'My usual breakfast');
      await tester.pump();
      await tester.tap(button('Save'));
      await settle(tester);

      expect(find.byType(SaveMealSheet), findsNothing);
      expect(find.text('Saved "My usual breakfast"'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
      final db = rig.diary.db;
      Future<int> liveMeals() async =>
          (await db
                  .customSelect(
                    'SELECT COUNT(*) AS n FROM saved_meals '
                    'WHERE deleted_at IS NULL',
                  )
                  .getSingle())
              .read<int>('n');
      expect(await tester.runAsync(liveMeals), 1);

      await tester.tap(find.text('Undo'));
      await settle(tester);
      expect(await tester.runAsync(liveMeals), 0);
      rig.stack.dispose();
    });

    testWidgets('DY-023 a save sheet whose meal changed says "That meal '
        'changed. Nothing was saved." and stays open', (tester) async {
      final rig = TodayRig(
        apply: (change) async => const Rejected(
          VersionConflict(
            entity: 'diary_entry',
            id: 'x',
            expected: 1,
            actual: 2,
          ),
        ),
      );
      await yesterday(tester, rig: rig);

      await tester.tap(find.byTooltip('More for Breakfast'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save as meal…'));
      await tester.pumpAndSettle();
      await tester.tap(button('Save'));
      await settle(tester);

      expect(
        find.text('That meal changed. Nothing was saved.'),
        findsOneWidget,
      );
      expect(find.byType(SaveMealSheet), findsOneWidget);
      rig.stack.dispose();
    });
  });
}
