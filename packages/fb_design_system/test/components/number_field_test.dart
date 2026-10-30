import 'package:fb_design_system/fb_design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump.dart';

/// What the formatter makes of [typed] when it replaces an empty field.
String _filtered(String typed, {int maxDecimals = 2}) =>
    FbDecimalInputFormatter(maxDecimals: maxDecimals)
        .formatEditUpdate(
          TextEditingValue.empty,
          TextEditingValue(
            text: typed,
            selection: TextSelection.collapsed(offset: typed.length),
          ),
        )
        .text;

void main() {
  test('D16 FbDecimalInputFormatter: digits and one separator pass, '
      'everything else is dropped', () {
    expect(_filtered('12.5'), '12.5');
    expect(_filtered('12,5'), '12,5');
    expect(_filtered('12٫5'), '12٫5');
    expect(_filtered('٣٠.٥'), '٣٠.٥');
    expect(_filtered('-12'), '12');
    expect(_filtered('1 2'), '12');
    expect(_filtered('1e3'), '13');
    expect(_filtered('abc'), '');
    expect(_filtered('1.2.3'), '1.23');
    expect(_filtered('1.2,3'), '1.23');
    expect(_filtered('+5'), '5');
  });

  test('D16 FbDecimalInputFormatter: at most maxDecimals digits after the '
      'separator, none when it is 0', () {
    expect(_filtered('1.2345'), '1.23');
    expect(_filtered('1.2345', maxDecimals: 3), '1.234');
    expect(_filtered('1.5', maxDecimals: 0), '15');
    expect(_filtered('.5'), '.5');
    expect(_filtered('100', maxDecimals: 0), '100');
  });

  test('D16 FbDecimalInputFormatter: the caret stays after the characters '
      'that survive', () {
    const formatter = FbDecimalInputFormatter();
    final result = formatter.formatEditUpdate(
      const TextEditingValue(text: '12'),
      const TextEditingValue(
        text: '1a2',
        selection: TextSelection.collapsed(offset: 2),
      ),
    );
    expect(result.text, '12');
    expect(result.selection.baseOffset, 1);
  });

  testWidgets('D16 FbNumberField: shows the label and the unit, opens the '
      'decimal keyboard and filters what is typed', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final changes = <String>[];
    await pumpFb(
      tester,
      FbNumberField(
        controller: controller,
        label: 'Protein',
        unit: 'g',
        maxDecimals: 1,
        onChanged: changes.add,
      ),
    );
    expect(find.text('Protein'), findsOneWidget);
    expect(find.text('g'), findsOneWidget);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(
      field.keyboardType,
      const TextInputType.numberWithOptions(decimal: true),
    );
    await tester.enterText(find.byType(TextField), '12.56x');
    await tester.pump();
    expect(controller.text, '12.5');
    expect(changes.last, '12.5');
  });

  testWidgets('D16 FbNumberField: disabled, it takes no input', (tester) async {
    final controller = TextEditingController(text: '3');
    addTearDown(controller.dispose);
    await pumpFb(
      tester,
      FbNumberField(controller: controller, label: 'Size', enabled: false),
    );
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
  });
}
