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

  group('A45 steady chips', () {
    final variants = <String, FbChoiceChip Function({required bool selected})>{
      'label only': ({required selected}) => FbChoiceChip(
        label: '1M',
        selected: selected,
        dropdown: false,
        onTap: () {},
      ),
      'with icon': ({required selected}) => FbChoiceChip(
        label: 'Weight',
        icon: FbIcons.chart,
        selected: selected,
        dropdown: false,
        onTap: () {},
      ),
      'with value and dropdown': ({required selected}) => FbChoiceChip(
        label: 'Meal',
        value: 'Lunch',
        selected: selected,
        onTap: () {},
      ),
    };
    for (final scale in [1.0, 2.0]) {
      for (final MapEntry(key: name, value: chip) in variants.entries) {
        testWidgets('A45 FbChoiceChip keeps its size when selected ($name, '
            'text ×$scale)', (tester) async {
          await pumpFb(
            tester,
            Align(
              alignment: AlignmentDirectional.topStart,
              child: chip(selected: false),
            ),
            textScale: scale,
          );
          final before = tester.getSize(find.byType(FbChoiceChip));
          await pumpFb(
            tester,
            Align(
              alignment: AlignmentDirectional.topStart,
              child: chip(selected: true),
            ),
            textScale: scale,
          );
          expect(tester.getSize(find.byType(FbChoiceChip)), before);
          expect(before.width, greaterThanOrEqualTo(48));
          expect(before.height, greaterThanOrEqualTo(48));
        });
      }
    }

    testWidgets('A45 FbUnitPicker and FbAnswerChip keep their width when the '
        'selection moves', (tester) async {
      const units = [
        FbUnitOption(id: 'kg', label: 'kg'),
        FbUnitOption(id: 'lb', label: 'lb'),
        FbUnitOption(id: 'st', label: 'st'),
      ];
      Widget row(String selected) => Align(
        alignment: AlignmentDirectional.topStart,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FbUnitPicker(units: units, selected: selected, onSelected: (_) {}),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FbAnswerChip(
                  key: const ValueKey('cooked'),
                  label: 'Cooked',
                  selected: selected == 'kg',
                  onTap: () {},
                ),
                FbAnswerChip(
                  key: const ValueKey('raw'),
                  label: 'Raw',
                  isDefault: true,
                  selected: selected != 'kg',
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      );
      Map<String, Size> sizes() => {
        'picker': tester.getSize(find.byType(FbUnitPicker)),
        for (final unit in units)
          unit.id: tester.getSize(
            find.widgetWithText(FbChoiceChip, unit.label),
          ),
        'cooked': tester.getSize(find.byKey(const ValueKey('cooked'))),
        'raw': tester.getSize(find.byKey(const ValueKey('raw'))),
      };
      await pumpFb(tester, row('kg'));
      final before = sizes();
      await pumpFb(tester, row('lb'));
      expect(sizes(), before);
      expect(find.byIcon(FbIcons.check), findsNothing);
    });
  });
}
