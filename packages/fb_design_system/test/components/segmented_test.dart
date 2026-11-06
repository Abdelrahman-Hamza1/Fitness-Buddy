import 'dart:ui' show Tristate;

import 'package:fb_design_system/fb_design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump.dart';

void main() {
  testWidgets('TG-043 UX-048 A63 FbSegmented(enabled: false) takes no taps '
      'and is announced as disabled', (tester) async {
    final semantics = tester.ensureSemantics();
    final picked = <bool>[];
    Widget segmented({required bool enabled}) => FbSegmented<bool>(
      options: const [
        FbOption(value: false, label: 'Same every day'),
        FbOption(value: true, label: 'Different by day'),
      ],
      selected: false,
      enabled: enabled,
      onSelected: picked.add,
    );
    await pumpFb(tester, segmented(enabled: false));
    await tester.tap(find.text('Different by day'));
    expect(picked, isEmpty);
    expect(
      tester
          .getSemantics(find.text('Different by day'))
          .flagsCollection
          .isEnabled,
      Tristate.isFalse,
    );

    await pumpFb(tester, segmented(enabled: true));
    await tester.tap(find.text('Different by day'));
    expect(picked, [true]);
    semantics.dispose();
  });
}
