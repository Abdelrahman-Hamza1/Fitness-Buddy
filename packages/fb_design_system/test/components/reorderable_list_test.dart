import 'package:fb_design_system/fb_design_system.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump.dart';

const List<String> _meals = ['Breakfast', 'Lunch', 'Dinner', 'Snacks'];

Widget _list({
  required List<(int, int)> moves,
  bool enabled = true,
  List<String> items = _meals,
}) => FbReorderableList<String>(
  items: items,
  idOf: (meal) => meal,
  enabled: enabled,
  header: const Text('Header'),
  footer: const Text('Footer'),
  itemBuilder: (context, meal, handle) =>
      FbListRow(title: meal, subtitle: 'Any time', trailing: handle),
  onReorder: (oldIndex, newIndex) => moves.add((oldIndex, newIndex)),
);

void main() {
  testWidgets('DY-010 FbReorderableList: dragging the handle reports the '
      'old and the final position and ticks once', (tester) async {
    final haptics = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptics.add(call.arguments);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final moves = <(int, int)>[];
    await pumpFb(tester, _list(moves: moves));

    // Breakfast's grip dragged below the last row: it ends up last.
    final grips = find.byType(FbDragHandle);
    expect(grips, findsNWidgets(4));
    // Down past the last row in small steps, whatever the row height
    // (density).
    final distance =
        tester.getCenter(find.text('Footer')).dy -
        tester.getCenter(grips.first).dy;
    final gesture = await tester.startGesture(tester.getCenter(grips.first));
    await tester.pump(const Duration(milliseconds: 100));
    for (var moved = 0.0; moved < distance; moved += 20) {
      await gesture.moveBy(const Offset(0, 20));
      await tester.pump();
    }
    await gesture.up();
    await tester.pumpAndSettle();

    expect(moves, [(0, 3)]);
    expect(haptics, ['HapticFeedbackType.selectionClick']);
    // The header and the footer are not rows.
    expect(find.text('Header'), findsOneWidget);
    expect(find.text('Footer'), findsOneWidget);
  });

  testWidgets('DY-010 FbReorderableList: every row offers Move up and Move '
      'down to a screen reader, and they reorder', (tester) async {
    final handle = tester.ensureSemantics();
    final moves = <(int, int)>[];
    await pumpFb(tester, _list(moves: moves));

    // The node of the row that carries the move actions: the closest
    // ancestor of the meal's text that has custom actions.
    SemanticsNode rowOf(String meal) {
      SemanticsNode? node = tester.getSemantics(find.text(meal));
      while (node != null &&
          (node.getSemanticsData().customSemanticsActionIds ?? []).isEmpty) {
        node = node.parent;
      }
      return node!;
    }

    List<String> actionLabelsOf(String meal) => [
      for (final id in rowOf(meal).getSemanticsData().customSemanticsActionIds!)
        CustomSemanticsAction.getAction(id)!.label!,
    ];

    // Material's own words, in the device's language; the first meal can't
    // move up and the last can't move down.
    final first = actionLabelsOf('Breakfast');
    expect(first, contains('Move down'));
    expect(first, isNot(contains('Move up')));
    final middle = actionLabelsOf('Lunch');
    expect(middle, containsAll(['Move up', 'Move down']));
    final last = actionLabelsOf('Snacks');
    expect(last, contains('Move up'));
    expect(last, isNot(contains('Move down')));

    // The actions reorder through the same callback.
    final lunch = rowOf('Lunch');
    lunch.owner!.performAction(
      lunch.id,
      SemanticsAction.customAction,
      CustomSemanticsAction.getIdentifier(
        const CustomSemanticsAction(label: 'Move up'),
      ),
    );
    await tester.pumpAndSettle();
    expect(moves, [(1, 0)]);
    handle.dispose();
  });

  testWidgets('DY-010 FbReorderableList: while disabled no drag reorders', (
    tester,
  ) async {
    final moves = <(int, int)>[];
    await pumpFb(tester, _list(moves: moves, enabled: false));
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(FbDragHandle).first),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.moveBy(const Offset(0, 160));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(moves, isEmpty);
  });
}
