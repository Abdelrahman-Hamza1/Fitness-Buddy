import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../diary/support/diary_harness.dart';
import 'support/today_support.dart';
import 'today_actions_test.dart' show log, pumpRig, settle;
import 'today_edit_test.dart' show chip, pad, pitaLoaf, useTallPhone;

// T-N2 (diary part, A57 WP5, LC-007): one food (English + Arabic) through
// the meal preview, the edit-sheet title and the amount, move and delete
// messages. Names are data, not UI copy: the checks look for the food's own
// names, never for the sentences around them.

const _en = 'Pita bread, white';
const _ar = 'خبز عربي';
const _isoAr = '\u2068$_ar\u2069';

/// The breakfast row's subtitle (the meal preview).
String _preview(WidgetTester tester) => tester
    .widget<FbDisclosureRow>(find.widgetWithText(FbDisclosureRow, 'Breakfast'))
    .subtitle!;

/// The text of the snackbar on screen.
String _snack(WidgetTester tester) => tester
    .widget<Text>(
      find
          .descendant(of: find.byType(SnackBar), matching: find.byType(Text))
          .first,
    )
    .data!;

Future<TodayRig> _pita(WidgetTester tester, FoodNameLanguage names) async {
  final rig = TodayRig(names: names);
  await pumpRig(tester, rig);
  useTallPhone(tester);
  await log(tester, rig, [pitaLoaf(1, testToday)]);
  return rig;
}

void main() {
  testWidgets('A57 T-N2 LC-007 Arabic: the meal preview, the amount sheet '
      'title and the amount, move and delete messages name the Arabic food', (
    tester,
  ) async {
    final rig = await _pita(tester, FoodNameLanguage.arabic);
    expect(_preview(tester), contains(_isoAr));
    expect(_preview(tester), isNot(contains(_en)));

    await tester.tap(find.widgetWithText(FbDisclosureRow, 'Breakfast'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FbListRow, _ar));
    await tester.pump();

    // The amount sheet: its title, then the message after Save.
    await tester.tap(chip('Amount'));
    await tester.pumpAndSettle();
    expect(find.text(_isoAr), findsWidgets);
    expect(find.text(_en), findsNothing);
    await pad(tester, '2');
    await tester.tap(find.byKey(const ValueKey('entry-amount-save')));
    await settle(tester);
    expect(_snack(tester), contains(_isoAr));
    expect(_snack(tester), isNot(contains(_en)));

    // Move: one tap on another meal.
    await tester.tap(chip('Meal'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FbListRow, 'Lunch').last);
    await settle(tester);
    expect(_snack(tester), contains(_isoAr));
    expect(_snack(tester), isNot(contains(_en)));

    // Delete: a swipe on the row.
    await tester.drag(
      find.widgetWithText(FbListRow, _ar),
      const Offset(-400, 0),
    );
    await settle(tester);
    expect(_snack(tester), contains(_isoAr));
    expect(_snack(tester), isNot(contains(_en)));
    rig.stack.dispose();
  });

  testWidgets('A57 T-N2 LC-007 Both: rows keep two lines, sentences and the '
      'meal preview name the English food only', (tester) async {
    final rig = await _pita(tester, FoodNameLanguage.both);
    expect(_preview(tester), contains(_en));
    expect(_preview(tester), isNot(contains(_ar)));

    await tester.tap(find.widgetWithText(FbDisclosureRow, 'Breakfast'));
    await tester.pump();
    final row = tester.widget<FbListRow>(find.widgetWithText(FbListRow, _en));
    expect(row.subtitle, contains(_isoAr));

    await tester.drag(
      find.widgetWithText(FbListRow, _en),
      const Offset(-400, 0),
    );
    await settle(tester);
    expect(_snack(tester), contains(_en));
    expect(_snack(tester), isNot(contains(_ar)));
    rig.stack.dispose();
  });

  testWidgets('A57 LC-007 a typed dish name shows as typed in every setting', (
    tester,
  ) async {
    for (final names in [FoodNameLanguage.arabic, FoodNameLanguage.both]) {
      final rig = TodayRig(names: names);
      await pumpRig(tester, rig);
      await tester.runAsync(
        () => rig.diary.apply([
          CreateDishGroup(
            id: newId(1),
            name: 'Mama dish',
            date: testToday,
            slotId: DefaultSlots.breakfastId,
          ),
          LogEntries([
            NewDiaryEntry(
              id: newId(2),
              when: atDay(testToday, 8),
              slotId: DefaultSlots.breakfastId,
              dishGroupId: newId(1),
              food: foodOf(1),
              amount: EntryAmount(
                input: Quantity(100, 'g'),
                amount: 100,
                basis: NutrientBasis.per100g,
              ),
            ),
          ]),
        ]),
      );
      await settle(tester);
      expect(_preview(tester), contains('Mama dish'), reason: '$names');
      await tester.pumpWidget(const SizedBox());
      rig.stack.dispose();
    }
  });
}
