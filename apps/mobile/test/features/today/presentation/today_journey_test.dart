import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import '../../diary/support/diary_harness.dart';
import 'support/today_support.dart';
import 'today_actions_test.dart' show settle;
import 'today_edit_test.dart' show button, chip, pad, pitaLoaf, useTallPhone;

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

/// Header and every slot row of [date] against what is stored.
Future<void> expectTotalsStored(
  WidgetTester tester,
  TodayRig rig,
  LocalDate date,
  String step,
) async {
  final stored = (await tester.runAsync(() => rig.diary.reads.day(date)))!;
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

    Future<void> expectStored(String step) =>
        expectTotalsStored(tester, rig, testYesterday, step);

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

  testWidgets('A08 journey (full) on yesterday: add pita to breakfast and '
      'rice to lunch, edit pita to 2 loaves, move rice to dinner, delete rice, '
      'undo, copy breakfast to the next day; header and slot kcal equal the '
      'stored totals after each step', (tester) async {
    final rig = TodayRig();
    usePhone(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: rig.overrides,
        child: phoneApp(const TodayScreen()),
      ),
    );
    await settle(tester);
    useTallPhone(tester);
    await tester.tap(find.byTooltip('Previous day'));
    await settle(tester);
    Future<void> stored(String step) =>
        expectTotalsStored(tester, rig, testYesterday, step);
    await stored('empty day');

    // Add pita (1 loaf, 165 kcal) and rice (205 kcal).
    await tester.runAsync(
      () => rig.diary.apply([
        LogEntries([
          pitaLoaf(1, testYesterday),
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
    await stored('added');
    expect(find.text('370'), findsOneWidget);

    // Edit pita to 2 loaves: 330 kcal.
    await tester.tap(find.widgetWithText(FbDisclosureRow, 'Breakfast'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FbListRow, 'Pita bread, white'));
    await tester.pump();
    await tester.tap(chip('Amount'));
    await tester.pumpAndSettle();
    await pad(tester, '2');
    await tester.tap(button('Save'));
    await settle(tester);
    await stored('pita edited');
    expect(find.text('Changed Pita bread, white to 2 loaves'), findsOneWidget);
    expect(find.text('535'), findsOneWidget);

    // Move rice to dinner.
    await tester.tap(find.widgetWithText(FbDisclosureRow, 'Lunch'));
    await tester.pump();
    await tester.drag(
      find.widgetWithText(FbListRow, 'Rice, white, cooked'),
      const Offset(400, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FbListRow, 'Dinner').last);
    await settle(tester);
    await stored('rice moved');

    // Delete rice with the details' Delete button, then Undo.
    await tester.tap(find.widgetWithText(FbDisclosureRow, 'Dinner'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FbListRow, 'Rice, white, cooked'));
    await tester.pump();
    await tester.tap(button('Delete'));
    await settle(tester);
    await stored('rice deleted');
    expect(find.text('330'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await settle(tester);
    await stored('undo');
    expect(find.text('535'), findsOneWidget);

    // Copy breakfast to the next day (today).
    await tester.tap(find.byTooltip('More for Breakfast'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy to…'));
    await tester.pumpAndSettle();
    await tester.tap(button('Copy'));
    await settle(tester);
    expect(find.text('Copied 1 item to Today'), findsOneWidget);
    await stored('breakfast copied (yesterday unchanged)');

    // Today's breakfast holds 2 loaves of pita.
    await tester.tap(find.byTooltip('Next day'));
    await settle(tester);
    await expectTotalsStored(tester, rig, testToday, 'today');
    expect(find.text('330'), findsOneWidget);
    final today = (await tester.runAsync(
      () => rig.diary.reads.day(testToday),
    ))!;
    expect(today.entries.single.amount.input, Quantity(2, 'loaf'));
    expect(today.entries.single.slotId, DefaultSlots.breakfastId);
    rig.stack.dispose();
  });
}
