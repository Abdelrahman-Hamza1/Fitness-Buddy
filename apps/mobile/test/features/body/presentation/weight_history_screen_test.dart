import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/weight_history_support.dart';

/// The suffix (unit) of row [row]'s value field.
String rowUnit(WidgetTester tester, int row) =>
    tester.widget<FbNumberField>(find.byType(FbNumberField).at(row)).unit!;

/// The error under row [row]'s value field, or null.
String? rowError(WidgetTester tester, int row) =>
    tester.widget<FbNumberField>(find.byType(FbNumberField).at(row)).errorText;

void main() {
  testWidgets('WB-001 weight history: rows with a date and value; Save adds '
      'them with one undo and the graph shows them', (tester) async {
    final rig = HistoryRig();
    await openHistory(tester, rig);
    expect(find.text('Past weigh-ins'), findsOneWidget);
    expect(find.text('Pick a date'), findsOneWidget);
    expect(isEnabled(tester, button('Save')), isFalse);

    await pickRowDate(tester, 0, 3);
    await typeRow(tester, 0, '97.4');
    await tester.tap(button('Add row'));
    await tester.pump();
    // A week later: 10 October.
    expect(find.text('Sat, Oct 10'), findsOneWidget);
    await typeRow(tester, 1, '97,1');
    expect(find.text('2 weigh-ins to save'), findsOneWidget);
    expect(isEnabled(tester, button('Save')), isTrue);

    await tester.tap(button('Save'));
    await settle(tester);
    final live = await rig.live(tester);
    expect(live.map((w) => (w.localDate, w.kg)).toSet(), {
      (LocalDate(2026, 10, 3), 97.4),
      (LocalDate(2026, 10, 10), 97.1),
    });
    // 08:00 local on past days.
    expect(live.every((w) => w.time.localDateTime.hour == 8), isTrue);
    expect(rig.navigator.pops, 1);
    expect(find.text('2 weigh-ins added'), findsOneWidget);
    expect(rig.stack.latest!.label.key, 'weighInsLogged');

    await tester.tap(find.text('Undo'));
    await settle(tester);
    expect(await rig.live(tester), isEmpty);
    await unmountHistory(tester, rig);
  });

  testWidgets('WB-005 WB-031 weight history: a duplicate or a large jump is '
      'excluded until Keep; Use lb fixes a mix-up; a same-day different value '
      'shows an info line', (tester) async {
    final rig = HistoryRig();
    await rig.seed(tester, [
      weighInDraft(97, date: LocalDate(2026, 10, 7)),
      weighInDraft(97.2, date: LocalDate(2026, 10, 14)),
    ]);
    await openHistory(tester, rig);

    // 7 Oct, 97.0: a duplicate of the stored one.
    await pickRowDate(tester, 0, 7);
    await typeRow(tester, 0, '97');
    expect(find.text('Already logged on this day'), findsOneWidget);
    expect(find.text('Nothing to save yet'), findsOneWidget);
    expect(isEnabled(tester, button('Save')), isFalse);
    await tester.tap(button('Keep'));
    await tester.pump();
    expect(find.text('Kept'), findsOneWidget);
    expect(find.text('1 weigh-in to save'), findsOneWidget);

    // 14 Oct, 98.0: another value that day, still saved.
    await tester.tap(button('Add row'));
    await tester.pump();
    await typeRow(tester, 1, '98');
    expect(
      find.textContaining('The earliest one of the day is used for the trend'),
      findsOneWidget,
    );
    expect(find.text('2 weigh-ins to save'), findsOneWidget);

    // 17 Oct (capped at today), 214 "kg": likely lb.
    await tester.tap(button('Add row'));
    await tester.pump();
    await typeRow(tester, 2, '214');
    expect(find.text('Did you mean 214.0 lb?'), findsOneWidget);
    await tester.tap(button('Use lb'));
    await tester.pump();
    expect(find.text('Did you mean 214.0 lb?'), findsNothing);
    expect(rowUnit(tester, 2), 'lb');

    // 17 Oct, 101.5 kg: a jump from the row above, asked.
    await tester.tap(button('Add row'));
    await tester.pump();
    await typeRow(tester, 3, '101.5');
    expect(find.textContaining('Is that right?'), findsOneWidget);
    expect(find.text('3 weigh-ins to save'), findsOneWidget);
    await tester.tap(button('Keep'));
    await tester.pump();
    expect(find.text('4 weigh-ins to save'), findsOneWidget);
    // Editing a kept row clears its Keep.
    await typeRow(tester, 3, '101.6');
    expect(find.text('3 weigh-ins to save'), findsOneWidget);
    await tester.tap(button('Keep'));
    await tester.pump();

    await tester.tap(button('Save'));
    await settle(tester);
    final live = await rig.live(tester);
    expect(live, hasLength(6));
    expect(
      live.where((w) => w.input == const WeighInInput(214, MassUnit.pound)),
      hasLength(1),
    );
    await unmountHistory(tester, rig);
  });

  testWidgets('UX-052 weight history: incomplete, out-of-range or future rows '
      'disable Save; leaving with typed rows asks first; nothing typed is lost '
      'after a refused save', (tester) async {
    final rig = HistoryRig();
    await openHistory(tester, rig);
    expect(find.text('Every row needs a date and a weight'), findsOneWidget);

    await typeRow(tester, 0, '19');
    expect(find.text('Every row needs a date and a weight'), findsOneWidget);
    await pickRowDate(tester, 0, 17);
    expect(rowError(tester, 0), 'Enter a weight between 20 kg and 500 kg');
    expect(isEnabled(tester, button('Save')), isFalse);
    await typeRow(tester, 0, '97');
    expect(rowError(tester, 0), isNull);
    expect(isEnabled(tester, button('Save')), isTrue);

    // The day goes back (a zone or clock change): 17 Oct is in the future.
    rig.h.clock.advance(const Duration(days: -1));
    await typeRow(tester, 0, '97.0');
    expect(rowError(tester, 0), 'That date is in the future');
    expect(isEnabled(tester, button('Save')), isFalse);
    rig.h.clock.advance(const Duration(days: 1));
    await typeRow(tester, 0, '97');
    expect(isEnabled(tester, button('Save')), isTrue);

    // The clock moves before 08:00 while Save is shown: refused, kept.
    rig.h.clock.utc = DateTime.utc(2026, 10, 17, 3);
    await tester.tap(button('Save'));
    await settle(tester);
    expect(
      find.text('A date is in the future. Check the rows and try again.'),
      findsOneWidget,
    );
    expect(await rig.live(tester), isEmpty);
    expect(find.text('97'), findsOneWidget);
    expect(rig.navigator.pops, 0);

    // Leaving with typed rows asks first.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Discard these rows?'), findsOneWidget);
    await tester.tap(button('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.text('97'), findsOneWidget);
    expect(rig.navigator.pops, 0);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(button('Discard'));
    await tester.pumpAndSettle();
    expect(rig.navigator.pops, 1);
    await unmountHistory(tester, rig);
  });

  testWidgets('LC-010 weight history defaults to the unit setting and accepts '
      'the other unit', (tester) async {
    final rig = HistoryRig()..units.value = UnitSystem.imperial;
    await openHistory(tester, rig);
    expect(rowUnit(tester, 0), 'lb');
    expect(
      tester
          .widget<FbChoiceChip>(find.widgetWithText(FbChoiceChip, 'lb'))
          .selected,
      isTrue,
    );
    await pickRowDate(tester, 0, 10);
    await typeRow(tester, 0, '214');
    await tester.tap(find.widgetWithText(FbChoiceChip, 'kg'));
    await tester.pump();
    expect(rowUnit(tester, 0), 'kg');
    await typeRow(tester, 0, '97.4');
    await tester.tap(button('Save'));
    await settle(tester);
    expect(
      (await rig.live(tester)).single.input,
      const WeighInInput(97.4, MassUnit.kilogram),
    );
    await unmountHistory(tester, rig);
  });
}
