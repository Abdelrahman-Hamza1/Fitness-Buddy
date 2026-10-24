import 'package:fb_design_system/fb_design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

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

  testWidgets('D18 UX-070 FbChoiceChip: the target is at least 48 dp, also '
      'for a one-line chip', (tester) async {
    await pumpFb(tester, FbChoiceChip(label: 'Log as Rice', onTap: () {}));
    expect(
      tester.getSize(find.byType(FbChoiceChip)).height,
      greaterThanOrEqualTo(48),
    );
    expect(tester.getSize(find.byType(FbChoiceChip)).width, greaterThan(48));
  });

  testWidgets('D18 FbChoiceChip: the dropdown arrow is shown by default and '
      'can be turned off', (tester) async {
    await pumpFb(
      tester,
      FbChoiceChip(label: 'Meal', value: 'Lunch', onTap: () {}),
    );
    expect(find.byIcon(FbIcons.expand), findsOneWidget);
    await pumpFb(
      tester,
      FbChoiceChip(label: 'Meal', dropdown: false, onTap: () {}),
    );
    expect(find.byIcon(FbIcons.expand), findsNothing);
  });

  testWidgets('D18 UX-070 FbChoiceChip: a long value at text scale 2 wraps '
      'inside its width without overflow', (tester) async {
    await pumpFb(
      tester,
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: FbChoiceChip(
          label: 'Meal',
          value: 'Grilled chicken breast with roasted vegetables',
          onTap: () {},
        ),
      ),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(FbChoiceChip)).width,
      lessThanOrEqualTo(360),
    );
  });

  testWidgets('D18 FbChoiceChip: it starts at the start edge in RTL', (
    tester,
  ) async {
    await pumpFb(
      tester,
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: FbChoiceChip(label: 'Meal', value: 'Lunch', onTap: () {}),
      ),
      direction: TextDirection.rtl,
    );
    expect(tester.getTopRight(find.byType(FbChoiceChip)).dx, 360);
  });

  testWidgets('D18 FbChoiceChip: a leading icon shows, and the screen reader '
      'still hears only the label', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpFb(
      tester,
      FbChoiceChip(
        label: 'Change food',
        icon: FbIcons.search,
        dropdown: false,
        onTap: () {},
      ),
    );
    expect(find.byIcon(FbIcons.search), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(FbChoiceChip)),
      matchesSemantics(
        label: 'Change food',
        isButton: true,
        hasTapAction: true,
        hasEnabledState: true,
        isEnabled: true,
        hasSelectedState: true,
      ),
    );
    handle.dispose();
  });

  testWidgets(
    'UX-040 D18 FbChoiceChip: a semanticLabel replaces the label for a '
    'screen reader; the chip still shows the label',
    (tester) async {
      final handle = tester.ensureSemantics();
      await pumpFb(
        tester,
        FbChoiceChip(
          label: 'g',
          semanticLabel: 'Serving size in grams',
          dropdown: false,
          onTap: () {},
        ),
      );
      expect(find.text('g'), findsOneWidget);
      expect(
        tester.getSemantics(find.byType(FbChoiceChip)),
        matchesSemantics(
          label: 'Serving size in grams',
          isButton: true,
          hasTapAction: true,
          hasEnabledState: true,
          isEnabled: true,
          hasSelectedState: true,
        ),
      );
      handle.dispose();
    },
  );
}
