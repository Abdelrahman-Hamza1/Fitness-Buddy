import 'package:fb_design_system/fb_design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump.dart';

FbDisclosureRow _row({required bool expanded, VoidCallback? onToggle}) =>
    FbDisclosureRow(
      title: 'Breakfast',
      subtitle: 'Oats',
      trailing: const Text('150 kcal'),
      expanded: expanded,
      onToggle: onToggle ?? () {},
    );

void main() {
  testWidgets('HM-007 FbDisclosureRow: the expanded state is announced and '
      'the row is one button', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpFb(tester, _row(expanded: false));
    expect(
      tester.getSemantics(find.byType(ListTile)),
      matchesSemantics(
        label: 'Breakfast\nOats\n150 kcal',
        isButton: true,
        hasTapAction: true,
        hasFocusAction: true,
        isFocusable: true,
        hasEnabledState: true,
        isEnabled: true,
        hasSelectedState: true,
        hasExpandedState: true,
      ),
    );

    await pumpFb(tester, _row(expanded: true));
    expect(
      tester.getSemantics(find.byType(ListTile)),
      matchesSemantics(
        label: 'Breakfast\nOats\n150 kcal',
        isButton: true,
        hasTapAction: true,
        hasFocusAction: true,
        isFocusable: true,
        hasEnabledState: true,
        isEnabled: true,
        hasSelectedState: true,
        hasExpandedState: true,
        isExpanded: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('HM-007 FbDisclosureRow: a tap calls onToggle once', (
    tester,
  ) async {
    var taps = 0;
    await pumpFb(tester, _row(expanded: false, onToggle: () => taps++));
    await tester.tap(find.text('Breakfast'));
    expect(taps, 1);
  });
}
