import 'package:fb_design_system/fb_design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump.dart';

Widget _row({bool value = true, ValueChanged<bool>? onChanged}) => FbSwitchRow(
  title: 'Halal food',
  subtitle: 'Only halal foods',
  value: value,
  onChanged: onChanged,
);

void main() {
  testWidgets('UX-040 FbSwitchRow: tap toggles, toggled semantics, RTL '
      'mirrored', (tester) async {
    final handle = tester.ensureSemantics();
    final values = <bool>[];

    // A tap calls onChanged once with the new value.
    await pumpFb(tester, _row(onChanged: values.add));
    await tester.tap(find.text('Halal food'));
    expect(values, [false]);

    // The row is one toggle that reads title, subtitle and state.
    expect(
      tester.getSemantics(find.byType(ListTile)),
      matchesSemantics(
        label: 'Halal food\nOnly halal foods',
        hasTapAction: true,
        hasFocusAction: true,
        isFocusable: true,
        hasEnabledState: true,
        isEnabled: true,
        hasSelectedState: true,
        hasToggledState: true,
        isToggled: true,
      ),
    );
    await pumpFb(tester, _row(value: false, onChanged: (_) {}));
    expect(
      tester.getSemantics(find.byType(ListTile)),
      matchesSemantics(
        label: 'Halal food\nOnly halal foods',
        hasTapAction: true,
        hasFocusAction: true,
        isFocusable: true,
        hasEnabledState: true,
        isEnabled: true,
        hasSelectedState: true,
        hasToggledState: true,
      ),
    );

    // The switch is at the end of the row: right in LTR, left in RTL.
    final ltr = tester.getCenter(find.byType(Switch)).dx;
    await pumpFb(tester, _row(onChanged: (_) {}), direction: TextDirection.rtl);
    final rtl = tester.getCenter(find.byType(Switch)).dx;
    expect(ltr, greaterThan(180));
    expect(rtl, lessThan(180));
    handle.dispose();
  });

  testWidgets('UX-040 FbSwitchRow: a null onChanged disables the row', (
    tester,
  ) async {
    await pumpFb(tester, _row());
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).onChanged,
      isNull,
    );
  });
}
