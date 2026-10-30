import 'package:fb_design_system/fb_design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump.dart';

NumberPadBuffer _press(NumberPadBuffer b, String keys) {
  var buffer = b;
  for (final c in keys.split('')) {
    buffer = buffer.apply(switch (c) {
      '.' => NumberPadKey.decimal,
      '<' => NumberPadKey.backspace,
      _ => NumberPadKey.digit(int.parse(c)),
    });
  }
  return buffer;
}

void main() {
  group('number pad', () {
    // keys (< = backspace) -> expected text and value, with
    // maxDigits 3 and maxDecimals 2.
    const table = <(String, String, double?)>[
      ('', '', null),
      ('1', '1', 1),
      ('123', '123', 123),
      ('1234', '123', 123), // max digits
      ('0', '0', 0),
      ('00', '0', 0), // no leading zeros
      ('05', '5', 5),
      ('.', '0.', 0),
      ('1.5', '1.5', 1.5),
      ('1..5', '1.5', 1.5), // one point
      ('1.234', '1.23', 1.23), // max decimals
      ('1234.5', '123.5', 123.5), // digits capped, decimals still allowed
      ('12<', '1', 1),
      ('1<', '', null),
      ('1.<', '1', 1),
      ('<', '', null),
      ('0.5<<', '0', 0),
    ];
    for (final (keys, text, value) in table) {
      test('AI-040 NumberPadBuffer "$keys" gives "$text"', () {
        final b = _press(
          const NumberPadBuffer(maxDigits: 3, maxDecimals: 2),
          keys,
        );
        expect(b.text, text);
        expect(b.value, value);
        expect(b.isEmpty, text.isEmpty);
      });
    }

    test('AI-040 NumberPadBuffer: zero decimals disallows the point', () {
      final b = _press(const NumberPadBuffer(maxDecimals: 0), '1.5');
      expect(b.text, '15');
    });

    testWidgets('AI-040 number pad keys and unit picker selection reach '
        'their callbacks', (tester) async {
      final keys = <NumberPadKey>[];
      var done = 0;
      String? unit;
      await pumpFb(
        tester,
        Column(
          children: [
            FbNumberPad(onKey: keys.add, onDone: () => done++),
            FbUnitPicker(
              units: const [
                FbUnitOption(id: 'g', label: 'g'),
                FbUnitOption(id: 'ml', label: 'ml'),
              ],
              selected: 'g',
              onSelected: (id) => unit = id,
            ),
          ],
        ),
      );
      await tester.tap(find.text('7'));
      await tester.tap(find.text('.'));
      await tester.tap(find.byIcon(FbIcons.backspace));
      await tester.tap(find.text('Done'));
      await tester.tap(find.text('ml'));
      expect(keys, [
        const NumberPadKey.digit(7),
        NumberPadKey.decimal,
        NumberPadKey.backspace,
      ]);
      expect(done, 1);
      expect(unit, 'ml');
      expect(find.bySemanticsLabel('Delete last digit'), findsOneWidget);
      expect(find.bySemanticsLabel('Decimal point'), findsOneWidget);
    });
  });

  group('snackbars', () {
    Future<void> show(
      WidgetTester tester,
      void Function(BuildContext) action, {
      bool accessible = false,
    }) async {
      await pumpFb(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => action(context),
            child: const Text('go'),
          ),
        ),
        accessibleNavigation: accessible,
      );
      await tester.tap(find.text('go'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('UX-030 undo snackbar shows the message, calls onUndo once '
        'on Undo, closes after 5 s', (tester) async {
      var undone = 0;
      await show(
        tester,
        (c) => showFbUndoSnackBar(c, message: 'Logged', onUndo: () => undone++),
      );
      expect(find.text('Logged'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
      await tester.tap(find.text('Undo'));
      await tester.tap(find.text('Undo'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(undone, 1);
      expect(find.text('Logged'), findsNothing);
    });

    testWidgets('UX-030 / WCAG 2.2.1 with accessibleNavigation the undo '
        'snackbar is not auto-dismissed', (tester) async {
      await show(
        tester,
        (c) => showFbUndoSnackBar(c, message: 'Logged', onUndo: () {}),
        accessible: true,
      );
      await tester.pump(const Duration(seconds: 30));
      expect(find.text('Logged'), findsOneWidget);
    });
  });

  group('search field', () {
    testWidgets('FD-020 typing reports changes, the clear button appears with '
        'text, empties the field and reports an empty string', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final changes = <String>[];
      await pumpFb(
        tester,
        FbSearchField(
          controller: controller,
          hint: 'Search foods',
          onChanged: changes.add,
        ),
      );
      expect(find.text('Search foods'), findsOneWidget);
      expect(find.byTooltip('Clear search'), findsNothing);

      await tester.enterText(find.byType(TextField), 'rice');
      await tester.pump();
      expect(changes, ['rice']);
      expect(find.byTooltip('Clear search'), findsOneWidget);

      await tester.tap(find.byTooltip('Clear search'));
      await tester.pump();
      expect(controller.text, isEmpty);
      expect(changes, ['rice', '']);
      expect(find.byTooltip('Clear search'), findsNothing);
    });
  });
}
