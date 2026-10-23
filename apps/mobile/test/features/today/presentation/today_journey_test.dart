import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import '../../diary/support/diary_harness.dart';
import 'support/today_support.dart';
import 'today_actions_test.dart' show settle;

NewDiaryEntry entryOfFood(
  int n,
  String name,
  double kcalPer100,
  double grams,
  String slotId,
  int hour,
) {
  final base = newEntry(n, when: atDay(testYesterday, hour), slotId: slotId);
  return NewDiaryEntry(
    id: base.id,
    when: base.when,
    slotId: slotId,
    food: EntryFood(
      ref: FoodRef.catalog('food-$n', version: '1'),
      names: FoodNames(name),
      per100: Nutrients(
        kcal: kcalPer100,
        protein: 5,
        carbs: 20,
        fat: 2,
        fiber: 1,
      ),
      provenance: Provenance(source: FoodSource.database),
    ),
    amount: EntryAmount(
      input: Quantity(grams, 'g'),
      amount: grams,
      basis: NutrientBasis.per100g,
    ),
  );
}

void main() {
  testWidgets('A08 journey on yesterday: add pita to breakfast and rice to '
      'lunch, move rice to dinner, delete pita, undo; header and slot kcal '
      'equal the stored totals after each step', (tester) async {
    final rig = TodayRig();
    usePhone(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: rig.overrides,
        child: phoneApp(const TodayScreen()),
      ),
    );
    await settle(tester);
    await tester.tap(find.byTooltip('Previous day'));
    await settle(tester);
    expect(find.text('Yesterday'), findsOneWidget);

    // Header and every slot row against what is stored.
    Future<void> expectStored(String step) async {
      final day = await tester.runAsync(
        () => rig.diary.reads.day(testYesterday),
      );
      final stored = day!;
      final number = NumberFormat.decimalPattern();
      expect(
        tester.widget<FbBigNumber>(find.byType(FbBigNumber)).value,
        number.format(DisplayRounding.kcal(stored.totals.kcal)),
        reason: '$step: header',
      );
      for (final (slot, name) in [
        (DefaultSlots.breakfastId, 'Breakfast'),
        (DefaultSlots.lunchId, 'Lunch'),
        (DefaultSlots.snacksId, 'Snacks'),
        (DefaultSlots.dinnerId, 'Dinner'),
      ]) {
        final rows = stored.entries.where((e) => e.slotId == slot);
        final kcal = DiaryTotals.day(rows).kcal;
        expect(
          find.descendant(
            of: find.widgetWithText(FbDisclosureRow, name),
            matching: find.text(
              rows.isEmpty
                  ? '—'
                  : '${number.format(DisplayRounding.kcal(kcal))} kcal',
            ),
          ),
          findsOneWidget,
          reason: '$step: $name',
        );
      }
    }

    await expectStored('empty day');

    // Add: pita to breakfast (165 kcal), rice to lunch (205 kcal).
    await tester.runAsync(
      () => rig.diary.apply([
        LogEntries([
          entryOfFood(
            1,
            'Pita bread, white',
            275,
            60,
            DefaultSlots.breakfastId,
            8,
          ),
        ]),
      ]),
    );
    await settle(tester);
    await expectStored('pita added');
    await tester.runAsync(
      () => rig.diary.apply([
        LogEntries([
          entryOfFood(
            2,
            'Rice, white, cooked',
            130,
            158,
            DefaultSlots.lunchId,
            13,
          ),
        ]),
      ]),
    );
    await settle(tester);
    await expectStored('rice added');
    expect(find.text('370'), findsOneWidget);

    // Move rice to dinner: open lunch, swipe the row toward the end edge.
    await tester.tap(find.widgetWithText(FbDisclosureRow, 'Lunch'));
    await tester.pump();
    await tester.drag(
      find.widgetWithText(FbListRow, 'Rice, white, cooked'),
      const Offset(400, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FbListRow, 'Dinner').last);
    await settle(tester);
    await expectStored('rice moved');
    expect(find.text('Moved Rice, white, cooked to Dinner'), findsOneWidget);

    // Delete pita: open breakfast, swipe toward the start edge.
    await tester.tap(find.widgetWithText(FbDisclosureRow, 'Breakfast'));
    await tester.pump();
    await tester.drag(
      find.widgetWithText(FbListRow, 'Pita bread, white'),
      const Offset(-400, 0),
    );
    await settle(tester);
    await expectStored('pita deleted');
    expect(find.text('205'), findsOneWidget);
    expect(find.text('Deleted Pita bread, white'), findsOneWidget);

    // Undo brings it back.
    await tester.tap(find.text('Undo'));
    await settle(tester);
    await expectStored('undo');
    expect(find.text('370'), findsOneWidget);
    expect(find.widgetWithText(FbListRow, 'Pita bread, white'), findsOneWidget);
    rig.stack.dispose();
  });
}
