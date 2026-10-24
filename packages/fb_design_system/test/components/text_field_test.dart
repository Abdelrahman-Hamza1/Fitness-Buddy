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

  testWidgets('D18 FbTextField: errorText is shown under the field', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await pumpFb(
      tester,
      FbTextField(
        controller: controller,
        label: 'Name',
        errorText: 'Give it a name',
      ),
    );
    expect(find.text('Give it a name'), findsOneWidget);
  });

  testWidgets('D18 FbTextField: the keyboard action and submit are passed '
      'on', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final submitted = <String>[];
    await pumpFb(
      tester,
      FbTextField(
        controller: controller,
        label: 'Name',
        textInputAction: TextInputAction.done,
        onSubmitted: submitted.add,
      ),
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).textInputAction,
      TextInputAction.done,
    );
    await tester.enterText(find.byType(TextField), 'Oats');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(submitted, ['Oats']);
  });

  testWidgets('D18 FbTextField: it is one text field for a screen reader '
      'with the label', (tester) async {
    final handle = tester.ensureSemantics();
    final controller = TextEditingController(text: 'Oats');
    addTearDown(controller.dispose);
    await pumpFb(
      tester,
      FbTextField(controller: controller, label: 'Name', maxLength: 60),
    );
    final node = tester.getSemantics(find.byType(EditableText));
    expect(node.label, 'Name');
    expect(node.value, 'Oats');
    expect(node.maxValueLength, 60);
    expect(node.currentValueLength, 4);
    expect(node.flagsCollection.isTextField, isTrue);
    handle.dispose();
  });

  testWidgets('D18 UX-070 FbTextField: error colour is the neutral error '
      'colour from the theme, not a literal', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await pumpFb(
      tester,
      FbTextField(controller: controller, label: 'Name', errorText: 'Oops'),
    );
    final style = tester.widget<Text>(find.text('Oops')).style;
    expect(style?.color, FbTheme.light().colorScheme.error);
  });

  testWidgets(
    'UX-040 D18 FbTextField: textDirection sets the direction of the typed '
    'text; by default it follows the layout',
    (tester) async {
      final controller = TextEditingController(text: 'لبنة');
      addTearDown(controller.dispose);
      await pumpFb(
        tester,
        FbTextField(
          controller: controller,
          label: 'Arabic name',
          textDirection: TextDirection.rtl,
        ),
      );
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).textDirection,
        TextDirection.rtl,
      );
      await pumpFb(tester, FbTextField(controller: controller, label: 'Name'));
      expect(
        tester
            .state<EditableTextState>(find.byType(EditableText))
            .renderEditable
            .textDirection,
        TextDirection.ltr,
      );
    },
  );
}
