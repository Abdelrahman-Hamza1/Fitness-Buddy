import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/ui/revealed_column.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _column(List<int> rows) => MaterialApp(
  home: MediaQuery(
    data: const MediaQueryData(),
    child: Material(
      child: RevealedColumn(
        children: [
          for (final row in rows)
            SizedBox(key: ValueKey(row), height: 40, child: Text('row $row')),
        ],
      ),
    ),
  ),
);

Finder get _reveals => find.descendant(
  of: find.byType(RevealedColumn),
  matching: find.byType(FbReveal),
);

void main() {
  testWidgets('UX-046 A57 A22 a removed row shrinks away once and is then '
      'forgotten (no repeating exits)', (tester) async {
    await tester.pumpWidget(_column([1, 2, 3]));
    await tester.pumpWidget(_column([1, 3]));
    await tester.pump(FbMotion.local ~/ 2);
    expect(_reveals, findsNWidgets(3), reason: 'row 2 is leaving');
    await tester.pumpAndSettle();
    // The exit timer fires, then nothing is picked up again.
    for (var i = 0; i < 3; i++) {
      await tester.pump(FbMotion.local * 2);
      expect(_reveals, findsNWidgets(2));
      expect(tester.binding.hasScheduledFrame, isFalse);
    }
    expect(find.text('row 2'), findsNothing);
    // A row put back after its exit grows in again.
    await tester.pumpWidget(_column([1, 2, 3]));
    await tester.pumpAndSettle();
    expect(find.text('row 2'), findsOne);
    expect(_reveals, findsNWidgets(3));
  });
}
