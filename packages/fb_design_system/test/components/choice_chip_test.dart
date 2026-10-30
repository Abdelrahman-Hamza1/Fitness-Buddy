import 'package:fb_design_system/fb_design_system.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump.dart';

void main() {
  testWidgets('D18 FbChoiceChip: a screen reader hears one button with the '
      'label and the value', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpFb(
      tester,
      FbChoiceChip(label: 'Meal', value: 'Lunch', onTap: () {}),
    );
    expect(
      tester.getSemantics(find.byType(FbChoiceChip)),
      matchesSemantics(
        label: 'Meal',
        value: 'Lunch',
        isButton: true,
        hasTapAction: true,
        hasEnabledState: true,
        isEnabled: true,
        hasSelectedState: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('D18 FbChoiceChip: selected is announced; disabled is not '
      'tappable', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpFb(
      tester,
      FbChoiceChip(label: 'Meal', value: 'Lunch', selected: true, onTap: () {}),
    );
    expect(
      tester.getSemantics(find.byType(FbChoiceChip)),
      matchesSemantics(
        label: 'Meal',
        value: 'Lunch',
        isButton: true,
        hasTapAction: true,
        hasEnabledState: true,
        isEnabled: true,
        hasSelectedState: true,
        isSelected: true,
      ),
    );
    await pumpFb(
      tester,
      const FbChoiceChip(label: 'Meal', value: 'Lunch', onTap: null),
    );
    expect(
      tester.getSemantics(find.byType(FbChoiceChip)),
      matchesSemantics(
        label: 'Meal',
        value: 'Lunch',
        isButton: true,
        hasEnabledState: true,
        hasSelectedState: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('D18 FbChoiceChip: a tap calls onTap once; disabled does '
      'nothing', (tester) async {
    var taps = 0;
    await pumpFb(
      tester,
      FbChoiceChip(label: 'Meal', value: 'Lunch', onTap: () => taps++),
    );
    await tester.tap(find.text('Lunch'));
    expect(taps, 1);
    await pumpFb(
      tester,
      const FbChoiceChip(label: 'Meal', value: 'Lunch', onTap: null),
    );
    await tester.tap(find.text('Lunch'));
    expect(taps, 1);
  });
}
