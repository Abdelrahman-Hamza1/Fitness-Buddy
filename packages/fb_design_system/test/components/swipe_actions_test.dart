import 'package:fb_design_system/fb_design_system.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump.dart';

/// A list of rows, each with both actions, that removes a row it dismissed.
class _Rows extends StatefulWidget {
  const new({required this.log});

  final List<String> log;

  @override
  State<_Rows> createState() => _RowsState();
}

class _RowsState extends State<_Rows> {
  final _items = ['Oats', 'Banana'];

  @override
  Widget build(BuildContext context) => ListView(
    children: [
      for (final item in _items)
        FbSwipeActions(
          key: ValueKey(item),
          dismissAction: FbSwipeAction(
            label: 'Delete',
            icon: FbIcons.delete,
            onTriggered: () {
              widget.log.add('delete $item');
              setState(() => _items.remove(item));
            },
          ),
          confirmAction: FbSwipeAction(
            label: 'Move to another meal',
            icon: FbIcons.move,
            onTriggered: () => widget.log.add('move $item'),
          ),
          child: SizedBox(height: 56, child: Center(child: Text(item))),
        ),
    ],
  );
}

Future<void> _pump(
  WidgetTester tester,
  List<String> log, {
  TextDirection direction = TextDirection.ltr,
  bool disableAnimations = true,
}) => pumpFb(
  tester,
  _Rows(log: log),
  direction: direction,
  disableAnimations: disableAnimations,
);

void main() {
  testWidgets('DY-022 FbSwipeActions: end-to-start past the threshold '
      'dismisses the row and calls the dismiss action once', (tester) async {
    final log = <String>[];
    await _pump(tester, log);

    await tester.drag(find.text('Oats'), const Offset(-200, 0));
    await tester.pumpAndSettle();

    expect(log, ['delete Oats']);
    expect(find.text('Oats'), findsNothing);
    expect(find.text('Banana'), findsOneWidget);
  });

  testWidgets('DY-022 FbSwipeActions: start-to-end calls confirm and snaps '
      'back', (tester) async {
    final log = <String>[];
    await _pump(tester, log);
    final home = tester.getTopLeft(find.text('Oats'));

    await tester.drag(find.text('Oats'), const Offset(200, 0));
    await tester.pumpAndSettle();

    expect(log, ['move Oats']);
    expect(find.text('Oats'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Oats')), home);
  });

  testWidgets('DY-022 FbSwipeActions: under 40% of the width nothing '
      'happens and the row snaps back', (tester) async {
    final log = <String>[];
    await _pump(tester, log);
    final home = tester.getTopLeft(find.text('Oats'));

    // 360 wide: 40% is 144.
    await tester.drag(find.text('Oats'), const Offset(-120, 0));
    await tester.pumpAndSettle();
    await tester.drag(find.text('Oats'), const Offset(120, 0));
    await tester.pumpAndSettle();

    expect(log, isEmpty);
    expect(tester.getTopLeft(find.text('Oats')), home);
  });

  testWidgets('DY-022 UX-040 FbSwipeActions mirrors in right-to-left: '
      'dragging right dismisses, dragging left calls confirm', (tester) async {
    final log = <String>[];
    await _pump(tester, log, direction: TextDirection.rtl);

    await tester.drag(find.text('Oats'), const Offset(-200, 0));
    await tester.pumpAndSettle();
    expect(log, ['move Oats']);

    await tester.drag(find.text('Oats'), const Offset(200, 0));
    await tester.pumpAndSettle();
    expect(log, ['move Oats', 'delete Oats']);
    expect(find.text('Oats'), findsNothing);
  });

  testWidgets('DY-022 FbSwipeActions: both actions are semantics custom '
      'actions that call the same callbacks', (tester) async {
    final handle = tester.ensureSemantics();
    final log = <String>[];
    await _pump(tester, log);

    final node = tester.getSemantics(find.text('Oats'));
    final labels = {
      for (final id in node.getSemanticsData().customSemanticsActionIds!)
        CustomSemanticsAction.getAction(id)!.label: id,
    };
    expect(labels.keys, containsAll(['Delete', 'Move to another meal']));

    node.owner!.performAction(
      node.id,
      SemanticsAction.customAction,
      labels['Move to another meal'],
    );
    expect(log, ['move Oats']);
    handle.dispose();
  });
}
