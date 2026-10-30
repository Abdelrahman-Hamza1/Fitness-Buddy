import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/buddy_harness.dart';
import '../support/buddy_widgets.dart';

void main() {
  // rule: A22b drag-handle
  testWidgets('A22 drag handle expands the sheet', (tester) async {
    const size = Size(400, 800);
    final h = BuddyHarness();
    await pumpBuddyHost(tester, h, size: size);
    await openBuddySheet(tester);
    double top() => tester.getRect(find.byType(DraggableScrollableSheet)).top;
    expect(top(), closeTo(size.height * 0.4, 2));
    final handle = find.bySemanticsLabel('Expand chat');
    expect(handle, findsOneWidget);
    expect(tester.getSize(handle).height, greaterThanOrEqualTo(48));
    await tester.tap(handle);
    await tester.pumpAndSettle();
    expect(top(), lessThan(size.height * 0.1));
    await tester.tap(find.bySemanticsLabel('Shrink chat'));
    await tester.pumpAndSettle();
    expect(top(), closeTo(size.height * 0.4, 2));
    await unmountBuddy(tester, h);
  });
}
