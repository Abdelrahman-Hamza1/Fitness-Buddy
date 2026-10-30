import 'package:fb_design_system/fb_design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump.dart';

void main() {
  testWidgets('D18 FbTextField: shows the label, the counter and stops at '
      'maxLength', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await pumpFb(
      tester,
      FbTextField(controller: controller, label: 'Name', maxLength: 5),
    );
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('0/5'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'abcdefgh');
    await tester.pump();
    expect(controller.text, 'abcde');
    expect(find.text('5/5'), findsOneWidget);
  });

  testWidgets('D18 FbTextField: the clear button shows only with text, '
      'empties the field and reports ""', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final changes = <String>[];
    await pumpFb(
      tester,
      FbTextField(
        controller: controller,
        label: 'Name',
        onChanged: changes.add,
      ),
    );
    expect(find.byTooltip('Clear'), findsNothing);
    await tester.enterText(find.byType(TextField), 'Oats');
    await tester.pump();
    expect(find.byTooltip('Clear'), findsOneWidget);
    await tester.tap(find.byTooltip('Clear'));
    await tester.pump();
    expect(controller.text, isEmpty);
    expect(changes, ['Oats', '']);
    expect(find.byTooltip('Clear'), findsNothing);
  });
}
