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
    final gesture = await tester.startGesture(tester.getCenter(grips.first));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.moveBy(const Offset(0, 20));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 180));
    await tester.pump();
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

  testWidgets('DY-010 FbReorderableList: disabled rows retain labels '
      'without move semantics', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpFb(tester, _list(moves: [], enabled: false));
    for (final meal in _meals) {
      SemanticsNode? node = tester.getSemantics(find.text(meal));
      expect(node.getSemanticsData().label, contains(meal));
      while (node != null) {
        expect(node.getSemanticsData().customSemanticsActionIds ?? [], isEmpty);
        node = node.parent;
      }
    }
    handle.dispose();
  });

  testWidgets('DY-010 FbReorderableList: toggling pending writes preserves '
      'the scroll position', (tester) async {
    final items = [for (var i = 0; i < 30; i++) 'Meal $i'];
    await pumpFb(tester, _list(moves: [], items: items));
    await tester.drag(
      find.byType(FbReorderableList<String>),
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();
    double offset() =>
        tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels;
    final before = offset();
    expect(before, greaterThan(0));
    await pumpFb(tester, _list(moves: [], items: items, enabled: false));
    expect(offset(), before);
    await pumpFb(tester, _list(moves: [], items: items));
    expect(offset(), before);
  });

  testWidgets('DY-010 FbReorderableList: the grip is at the end of the row, '
      'mirrored in RTL, and at least 48 dp', (tester) async {
    await pumpFb(tester, _list(moves: []));
    final ltr = tester.getCenter(find.byType(FbDragHandle).first).dx;
    expect(tester.getSize(find.byType(FbDragHandle).first).shortestSide, 48);
    await pumpFb(tester, _list(moves: []), direction: TextDirection.rtl);
    final rtl = tester.getCenter(find.byType(FbDragHandle).first).dx;
    expect(ltr, greaterThan(180));
    expect(rtl, lessThan(180));
  });

  testWidgets('UX-070 FbReorderableList: no overflow at text scale 2.0 on a '
      'small phone', (tester) async {
    await pumpFb(
      tester,
      _list(
        moves: [],
        items: const ['A meal with a rather long name to wrap', 'Lunch'],
      ),
      textScale: 2,
      width: 320,
      height: 640,
    );
    expect(tester.takeException(), isNull);
  });
}
