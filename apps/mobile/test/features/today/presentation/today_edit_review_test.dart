import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../diary/support/diary_harness.dart';
import 'support/today_support.dart';
import 'today_actions_test.dart' show log, pumpRig, settle;
import 'today_edit_test.dart'
    show button, chip, foodsDetails, isEnabled, pad, useTallPhone;

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
}
