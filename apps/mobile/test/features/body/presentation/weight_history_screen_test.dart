import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/body/application/weight_history_form.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

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

  testWidgets('UX-045 A57 T-S7 A15 a value crossing validation keeps the '
      'next row still', (tester) async {
    final rig = HistoryRig();
    await openHistory(tester, rig);
    await pickRowDate(tester, 0, 3);
    await tester.tap(button('Add row'));
    await tester.pump();
    final next = find.byType(FbNumberField).at(1);
    final top = tester.getTopLeft(next).dy;
    for (final value in ['19', '97', '9', '970', '97.4']) {
      await typeRow(tester, 0, value);
      expect(tester.getTopLeft(next).dy, top, reason: value);
    }
    expect(rowError(tester, 0), isNull);
    await typeRow(tester, 0, '19');
    expect(rowError(tester, 0), isNotNull);
    expect(tester.getTopLeft(next).dy, top);
    await unmountHistory(tester, rig);
  });

  WeightHistoryForm mixUp() =>
      WeightHistoryForm.start(MassUnit.kilogram)
          .withDate(0, LocalDate(2026, 10, 7))
          .withText(0, '97')
          .addRow(LocalDate(2026, 10, 17))
          .withText(1, '214');

  testWidgets('A57 A22 A69 removing a focused row and Undo at once keeps its '
      'text; the leaving row takes no focus', (tester) async {
    final rig = HistoryRig();
    await openHistory(tester, rig, initial: mixUp(), disableAnimations: false);
    await tester.showKeyboard(find.byType(TextField).at(1));
    await tester.pump();
    await tester.tap(find.byTooltip('Remove row').at(1));
    await tester.pump(FbMotion.local ~/ 2);
    // Mid-exit the field is still painted but has let go of focus.
    expect(find.text('214'), findsOne);
    final leaving = find.byType(EditableText).at(1);
    expect(tester.widget<EditableText>(leaving).focusNode.hasFocus, isFalse);
    // Undo while the row is still leaving (the snackbar may still be
    // sliding in, so its action is run directly).
    tester.widget<SnackBarAction>(find.byType(SnackBarAction)).onPressed();
    await tester.pumpAndSettle();
    expect(find.byType(FbNumberField), findsNWidgets(2));
    expect(find.text('214'), findsOne);
    expect(tester.takeException(), isNull);
    // Removed for good: one row stays, and the exit ends.
    await tester.tap(find.byTooltip('Remove row').at(1));
    await tester.pumpAndSettle();
    await tester.pump(FbMotion.local * 2);
    expect(find.byType(FbNumberField), findsOne);
    expect(tester.takeException(), isNull);
    await unmountHistory(tester, rig);
  });

  testWidgets('A57 A15 at 320 dp and 2x text the row answers keep 48 dp '
      'targets', (tester) async {
    final rig = HistoryRig();
    await openHistory(
      tester,
      rig,
      initial: mixUp(),
      size: const Size(320, 2400),
      textScale: 2,
    );
    for (final label in ['Use lb', 'Keep']) {
      final size = tester.getSize(button(label));
      expect(size.height, greaterThanOrEqualTo(48), reason: label);
      expect(size.width, greaterThanOrEqualTo(48), reason: label);
      // Fully on screen, inside the row.
      expect(tester.getTopRight(button(label)).dx, lessThanOrEqualTo(320));
    }
    // The line is as tall with or without answers: Keep the row and what
    // follows doesn't move.
    final top = tester.getTopLeft(button('Add row')).dy;
    await tester.tap(button('Keep'));
    await tester.pump();
    expect(find.text('Kept'), findsOne);
    expect(tester.getTopLeft(button('Add row')).dy, top);
    expect(tester.takeException(), isNull);
    await unmountHistory(tester, rig);
  });
}
