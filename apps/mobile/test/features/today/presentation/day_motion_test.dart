import 'package:fb_design_system/fb_design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/today_support.dart';
import 'today_actions_test.dart' show log, pumpRig;
import 'today_edit_test.dart' show pitaLoaf, useTallPhone;

void main() {
  testWidgets('A57 A16 A17 T-M2 UX-046 meal expansion animates and the '
      "tapped header doesn't move; closed rows are gone after FbMotion.local", (
    tester,
  ) async {
    final rig = TodayRig();
    await pumpRig(tester, rig, disableAnimations: false);
    useTallPhone(tester);
    await log(tester, rig, [pitaLoaf(1, testToday)]);
    final header = find.widgetWithText(FbDisclosureRow, 'Breakfast');
    final row = find.widgetWithText(FbListRow, 'Pita bread, white');
    final top = tester.getTopLeft(header).dy;

    await tester.tap(header);
    await tester.pump();
    await tester.pump(FbMotion.local ~/ 2);
    expect(row, findsOneWidget);
    expect(tester.getTopLeft(header).dy, top);
    final growing = tester.widget<Align>(
      find.ancestor(of: row, matching: find.byType(Align)).last,
    );
    expect(growing.heightFactor, inExclusiveRange(0, 1));
    await tester.pump(FbMotion.local);
    expect(tester.getTopLeft(header).dy, top);

    await tester.tap(header);
    await tester.pump();
    await tester.pump(FbMotion.local ~/ 2);
    // Still shrinking at its old place, not tappable.
    expect(row, findsOneWidget);
    expect(tester.getTopLeft(header).dy, top);
    await tester.pump(FbMotion.local);
    await tester.pump();
    expect(row, findsNothing);
    expect(tester.getTopLeft(header).dy, top);
  });
}
