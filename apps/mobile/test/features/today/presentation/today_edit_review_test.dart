import 'package:drift/drift.dart' show Value;
import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/row_ops.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../core/changes/support/test_db.dart' show ScriptOp;
import '../../diary/support/diary_fixtures.dart' show fixtureId;
import '../../diary/support/diary_harness.dart';
import 'support/today_support.dart';
import 'today_actions_test.dart' show log, pumpRig, settle;
import 'today_edit_test.dart'
    show button, chip, foodsDetails, isEnabled, pad, useTallPhone, vid;

/// Finder of the meal row [name] in the move sheet.
Finder mealRow(String name) => find.widgetWithText(FbListRow, name).last;

bool canPick(WidgetTester tester, String name) =>
    tester.widget<FbListRow>(mealRow(name)).onTap != null;

EntryAmount grams(double g) => EntryAmount(
  input: Quantity(g, 'g'),
  amount: g,
  basis: NutrientBasis.per100g,
);

void main() {
  group('move sheet follows its item', () {
    testWidgets('D12 a move sheet whose entry is deleted says "This item was '
        'removed" and disables the meals', (tester) async {
      final rig = await foodsDetails(tester);
      await tester.tap(chip('Meal'));
      await tester.pumpAndSettle();
      expect(canPick(tester, 'Lunch'), isTrue);

      await tester.runAsync(
        () => rig.diary.apply([
          DeleteEntries([vid(1)]),
        ]),
      );
      await settle(tester);

      expect(find.text('This item was removed.'), findsOneWidget);
      expect(canPick(tester, 'Lunch'), isFalse);
      expect(find.text('Move to'), findsOneWidget);
      rig.stack.dispose();
    });

    testWidgets('D12 a move sheet whose entry moved elsewhere stays usable', (
      tester,
    ) async {
      final rig = await foodsDetails(tester);
      await tester.tap(chip('Meal'));
      await tester.pumpAndSettle();

      // Moved to Lunch and re-timed, while the sheet is open.
      await tester.runAsync(
        () => rig.diary.apply([
          MoveEntries([vid(1)], toSlotId: DefaultSlots.lunchId),
        ]),
      );
      await tester.runAsync(
        () => rig.diary.apply([
          UpdateDiaryEntry(
            fixtureId(1),
            2,
            EntryPatch(localTime: LocalTime(10)),
          ),
        ]),
      );
      await settle(tester);
      expect(find.text('This item changed.'), findsNothing);
      expect(canPick(tester, 'Dinner'), isTrue);
      // Lunch is the current meal now.
      expect(canPick(tester, 'Lunch'), isFalse);

      await tester.tap(mealRow('Dinner'));
      await settle(tester);
      expect(find.text('Move to'), findsNothing);
      expect(find.text('Moved Food 1 to Dinner'), findsOneWidget);
      final stored = (await tester.runAsync(() => rig.diary.entry(1)))!;
      expect(stored.slotId, DefaultSlots.dinnerId);
      expect(stored.version, 4);
      rig.stack.dispose();
    });

    testWidgets('D12 a move sheet whose entry was edited offers Reload', (
      tester,
    ) async {
      final rig = await foodsDetails(tester);
      await tester.tap(chip('Meal'));
      await tester.pumpAndSettle();

      await tester.runAsync(
        () => rig.diary.apply([
          UpdateDiaryEntry(fixtureId(1), 1, EntryPatch(amount: grams(200))),
        ]),
      );
      await settle(tester);
      expect(find.text('This item changed.'), findsOneWidget);
      expect(canPick(tester, 'Lunch'), isFalse);

      await tester.tap(find.text('Reload'));
      await tester.pumpAndSettle();
      expect(find.text('This item changed.'), findsNothing);
      expect(canPick(tester, 'Lunch'), isTrue);
      await tester.tap(mealRow('Lunch'));
      await settle(tester);
      expect(find.text('Moved Food 1 to Lunch'), findsOneWidget);
      expect(
        (await tester.runAsync(() => rig.diary.entry(1)))!.slotId,
        DefaultSlots.lunchId,
      );
      rig.stack.dispose();
    });

    testWidgets('D12 a refused move keeps the sheet open and says so', (
      tester,
    ) async {
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
      await foodsDetails(tester, rig: rig);
      await tester.tap(chip('Meal'));
      await tester.pumpAndSettle();

      await tester.tap(mealRow('Lunch'));
      await settle(tester);

      expect(find.text('Move to'), findsOneWidget);
      expect(
        find.text('That item was changed, so nothing was saved.'),
        findsOneWidget,
      );
      rig.stack.dispose();
    });
  });

  group('refused saves are never silent', () {
    for (final (name, failure, message) in [
      (
        'changed',
        const VersionConflict(
          entity: 'diary_entry',
          id: 'x',
          expected: 1,
          actual: 2,
        ) as ChangeFailure,
        'That item was changed, so nothing was saved.',
      ),
      (
        'removed',
        const RowNotFound(entity: 'diary_entry', id: 'x') as ChangeFailure,
        'That item was removed, so nothing was saved.',
      ),
    ]) {
      testWidgets('D12 a refused amount save ($name) keeps the sheet open '
          'and says so', (tester) async {
        useTallPhone(tester);
        final rig = TodayRig(apply: (change) async => Rejected(failure));
        await foodsDetails(tester, rig: rig);
        await tester.tap(chip('Amount'));
        await tester.pumpAndSettle();
        await pad(tester, '2');
        await tester.tap(button('Save'));
        await settle(tester);

        expect(find.byType(EntryAmountSheet), findsOneWidget);
        expect(find.text(message), findsOneWidget);
        rig.stack.dispose();
      });
    }
  });

  group('copy stays honest about its source', () {
    testWidgets('DY-023 a split dish whose other member is deleted elsewhere '
        'shows "This meal changed", and Copy works after Reload', (
      tester,
    ) async {
      final rig = TodayRig();
      await pumpRig(tester, rig);
      useTallPhone(tester);
      await tester.runAsync(() async {
        await rig.diary.apply([
          CreateDishGroup(
            id: fixtureId(50),
            name: 'Dish',
            date: testToday,
            slotId: DefaultSlots.lunchId,
          ),
          LogEntries([
            newEntry(
              1,
              group: 50,
              slotId: DefaultSlots.lunchId,
              when: atDay(testToday, 12),
            ),
            newEntry(
              2,
              group: 50,
              slotId: DefaultSlots.lunchId,
              when: atDay(testToday, 12, 10),
            ),
          ]),
        ]);
        // A sync race leaves one member in a meal that no longer exists: it
        // shows under "Other", the dish only partly in it.
        await rig.diary.applier.apply(
          ChangeSet([
            ScriptOp.rows([
              UpdateRow(
                rig.diary.db.diaryEntries,
                fixtureId(2),
                DiaryEntriesCompanion(slotId: Value(fixtureId(55))),
              ),
            ]),
          ], origin: Origin.direct),
        );
      });
      await settle(tester);

      await tester.tap(find.byTooltip('More for Other'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Copy to…'));
      await tester.pumpAndSettle();
      expect(isEnabled(tester, button('Copy')), isTrue);

      // The other member goes: the dish is now wholly in this section, so a
      // copy takes it along. No row of this section changed.
      await tester.runAsync(
        () => rig.diary.apply([
          DeleteEntries([vid(1)]),
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

      expect(find.text('Copied 1 item to Today'), findsOneWidget);
      expect(find.text('That meal changed. Nothing was copied.'), findsNothing);
      final day = (await tester.runAsync(
        () => rig.diary.reads.day(testToday),
      ))!;
      final copy = day.entries.singleWhere(
        (e) => e.slotId == DefaultSlots.breakfastId,
      );
      expect(copy.dishGroupId, isNotNull);
      rig.stack.dispose();
    });

    testWidgets('DY-023 on today the copy defaults to the next meal; the last '
        'meal asks where to copy; both sheets summarise the meal', (
      tester,
    ) async {
      final rig = TodayRig();
      await pumpRig(tester, rig);
      useTallPhone(tester);
      await log(tester, rig, [
        newEntry(
          1,
          when: atDay(testToday, 8),
          slotId: DefaultSlots.breakfastId,
        ),
        newEntry(
          2,
          when: atDay(testToday, 9),
          slotId: DefaultSlots.breakfastId,
        ),
        newEntry(3, when: atDay(testToday, 15), slotId: DefaultSlots.snacksId),
      ]);

      await tester.tap(find.byTooltip('More for Breakfast'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Copy to…'));
      await tester.pumpAndSettle();
      expect(tester.widget<FbChoiceChip>(chip('Day')).value, 'Today');
      expect(tester.widget<FbChoiceChip>(chip('Meal')).value, 'Lunch');
      expect(find.text('2 items · 600 kcal'), findsOneWidget);
      expect(find.text('Choose where to copy this meal.'), findsNothing);
      expect(isEnabled(tester, button('Copy')), isTrue);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Snacks is the last meal: nothing follows, so it asks.
      await tester.tap(find.byTooltip('More for Snacks'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Copy to…'));
      await tester.pumpAndSettle();
      expect(tester.widget<FbChoiceChip>(chip('Meal')).value, 'Snacks');
      expect(find.text('1 item · 300 kcal'), findsOneWidget);
      expect(find.text('Choose where to copy this meal.'), findsOneWidget);
      expect(isEnabled(tester, button('Copy')), isFalse);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('More for Breakfast'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save as meal…'));
      await tester.pumpAndSettle();
      expect(find.text('2 items · 600 kcal'), findsOneWidget);
      rig.stack.dispose();
    });
  });

  group('reload re-reads untouched fields', () {
    testWidgets('DY-021 Reload without typing shows the reloaded amount', (
      tester,
    ) async {
      final rig = await foodsDetails(tester);
      await tester.tap(chip('Amount'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Amount, 150 g'), findsOneWidget);

      await tester.runAsync(
        () => rig.diary.apply([
          UpdateDiaryEntry(fixtureId(1), 1, EntryPatch(amount: grams(200))),
        ]),
      );
      await settle(tester);
      expect(find.text('This item changed.'), findsOneWidget);
      // Nothing was typed, so nothing is kept yet.
      await tester.tap(find.text('Reload'));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Amount, 200 g'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(EntryAmountSheet),
          matching: find.text('400 kcal'),
        ),
        findsOneWidget,
      );
      rig.stack.dispose();
    });

    testWidgets('AI-072 Reload without typing shows the reloaded value', (
      tester,
    ) async {
      final rig = await foodsDetails(tester);
      await tester.tap(find.text('Protein'));
      await tester.pumpAndSettle();
      final stored = (await tester.runAsync(
        () => rig.diary.reads.day(testToday),
      ))!.entries.firstWhere((e) => e.id == fixtureId(1)).snapshot.protein;
      expect(
        find.bySemanticsLabel('Protein, ${stored.toStringAsFixed(1)} g'),
        findsOneWidget,
      );

      await tester.runAsync(
        () => rig.diary.apply([
          UpdateDiaryEntry(fixtureId(1), 1, EntryPatch(amount: grams(200))),
        ]),
      );
      await settle(tester);
      await tester.tap(find.text('Reload'));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Protein, 14.6 g'), findsOneWidget);
      rig.stack.dispose();
    });
  });

  group('sheet copy', () {
    testWidgets('DY-021 a disabled amount Save says why', (tester) async {
      final rig = await foodsDetails(tester);
      await tester.tap(chip('Amount'));
      await tester.pumpAndSettle();
      expect(find.text('Enter an amount above 0.'), findsNothing);

      await pad(tester, '0');
      expect(isEnabled(tester, button('Save')), isFalse);
      expect(find.text('Enter an amount above 0.'), findsOneWidget);
      await pad(tester, '<');
      expect(find.text('Enter an amount above 0.'), findsOneWidget);
      await pad(tester, '4');
      expect(find.text('Enter an amount above 0.'), findsNothing);
      rig.stack.dispose();
    });

    testWidgets('AI-072 an empty value says why Save is off; energy has its '
        'own title; a refused value is explained', (tester) async {
      final rig = TodayRig(
        apply: (change) async => const Rejected(InvalidOp('outOfRange')),
      );
      await foodsDetails(tester, rig: rig);

      await tester.tap(find.text('Calories'));
      await tester.pumpAndSettle();
      expect(find.text('Edit calories'), findsOneWidget);
      expect(find.text('Enter a value.'), findsNothing);
      await pad(tester, '<<<');
      expect(isEnabled(tester, button('Save')), isFalse);
      expect(find.text('Enter a value.'), findsOneWidget);
      await pad(tester, '5');
      expect(find.text('Enter a value.'), findsNothing);

      await tester.tap(button('Save'));
      await settle(tester);
      expect(
        find.text("Couldn't save that value. Check it and try again."),
        findsOneWidget,
      );
      expect(find.byType(NutrientOverrideSheet), findsOneWidget);
      rig.stack.dispose();
    });
  });
}
