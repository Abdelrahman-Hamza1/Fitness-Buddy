import 'package:fb_design_system/fb_design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump.dart';

void main() {
  testWidgets('HM-009 FbDateHeader: a label tap calls onLabelTap and the '
      'label is a button with the "Choose a date" hint', (tester) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    await pumpFb(
      tester,
      FbDateHeader(label: 'Today', onPrevious: () {}, onLabelTap: () => taps++),
    );

    await tester.tap(find.text('Today'));
    expect(taps, 1);
    expect(find.byIcon(FbIcons.expand), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byIcon(FbIcons.expand),
        matching: find.byType(ExcludeSemantics),
      ),
      findsOneWidget,
    );
    final node = tester.getSemantics(find.text('Today'));
    expect(node.label, 'Today');
    expect(node.getSemanticsData().tooltip, isEmpty);
    expect(node.hintOverrides?.onTapHint, 'Choose a date');
    expect(
      node,
      matchesSemantics(
        isHeader: true,
        isButton: true,
        hasTapAction: true,
        label: 'Today',
        hasFocusAction: true,
        isFocusable: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('HM-009 FbDateHeader: without onLabelTap the label is plain '
      'header text', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpFb(tester, FbDateHeader(label: 'Today', onPrevious: () {}));
    expect(
      tester.getSemantics(find.text('Today')),
      matchesSemantics(isHeader: true, label: 'Today'),
    );
    expect(find.byType(InkWell), findsNWidgets(2));
    expect(find.byIcon(FbIcons.expand), findsNothing);
    handle.dispose();
  });

  testWidgets('HM-009 FbDateHeader: next is disabled on today (no onNext) '
      'and previous works', (tester) async {
    var previous = 0;
    await pumpFb(
      tester,
      FbDateHeader(label: 'Today', onPrevious: () => previous++),
    );
    final buttons = tester.widgetList<IconButton>(find.byType(IconButton));
    expect(buttons.last.onPressed, isNull);
    await tester.tap(find.byTooltip('Previous day'));
    expect(previous, 1);
  });
}
