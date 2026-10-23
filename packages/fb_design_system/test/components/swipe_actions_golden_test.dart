import 'package:fb_design_system/fb_design_system.dart';
import 'package:flutter/foundation.dart' show AsyncCallback;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/golden_matrix.dart';

const ValueKey<String> _towardStart = ValueKey('toward start');
const ValueKey<String> _towardEnd = ValueKey('toward end');

Widget _row(Key? key) => ClipRect(child: _swipe(key));

Widget _swipe(Key? key) => FbSwipeActions(
  key: key,
  dismissAction: FbSwipeAction(
    label: 'Delete',
    icon: FbIcons.delete,
    onTriggered: () {},
  ),
  confirmAction: FbSwipeAction(
    label: 'Move to another meal',
    icon: FbIcons.move,
    onTriggered: () {},
  ),
  child: const FbListRow(
    title: 'Oats',
    subtitle: '40 g',
    trailing: Text('150 kcal'),
  ),
);

/// Holds a drag on every keyed row, toward the edge its key names (the
/// direction of "start" follows the cell's text direction), so the golden
/// shows the revealed background.
Future<AsyncCallback?> _hold(WidgetTester tester) async {
  final gestures = <TestGesture>[];
  for (final element in find.byType(FbSwipeActions).evaluate()) {
    final key = element.widget.key;
    if (key == null) continue;
    final rtl = Directionality.of(element) == TextDirection.rtl;
    final towardStart = key == _towardStart;
    final sign = (towardStart != rtl) ? -1.0 : 1.0;
    final gesture = await tester.startGesture(
      tester.getCenter(find.byWidget(element.widget)),
    );
    await gesture.moveBy(Offset(sign * 30, 0));
    await tester.pump();
    await gesture.moveBy(Offset(sign * 90, 0));
    await tester.pump();
    gestures.add(gesture);
  }
  return () async {
    for (final gesture in gestures) {
      await gesture.up();
    }
  };
}

Future<void> main() => fbGoldenMatrix(
  'DY-022 UX-070 UX-040 swipe actions golden matrix',
  fileName: 'swipe_actions',
  whilePerforming: _hold,
  states: {
    'at rest': (_) => _row(null),
    'dragged toward the start edge (delete)': (_) => _row(_towardStart),
    'dragged toward the end edge (move)': (_) => _row(_towardEnd),
  },
);
