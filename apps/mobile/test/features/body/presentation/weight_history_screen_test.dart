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
}
