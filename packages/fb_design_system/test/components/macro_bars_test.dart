import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_design_system/src/components/progress_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump.dart';

// The identity's sample day (design/embrace/README.md).
const _sampleDay = [
  FbMacroValue(
    kind: FbMacroKind.protein,
    value: 92,
    target: 150,
    label: 'Protein',
    valueText: '92 / 150 g',
  ),
  FbMacroValue(
    kind: FbMacroKind.carbs,
    value: 130,
    target: 220,
    label: 'Carbs',
    valueText: '130 / 220 g',
  ),
  FbMacroValue(
    kind: FbMacroKind.fat,
    value: 48,
    target: 70,
    label: 'Fat',
    valueText: '48 / 70 g',
  ),
  FbMacroValue(
    kind: FbMacroKind.fiber,
    value: 18,
    target: 30,
    label: 'Fiber',
    valueText: '18 / 30 g',
  ),
];

Future<void> _pump(
  WidgetTester tester, {
  required double width,
  double textScale = 1,
}) => pumpFb(
  tester,
  const Padding(
    padding: EdgeInsetsDirectional.all(FbSpace.s4),
    child: FbMacroBars(macros: _sampleDay),
  ),
  width: width,
  textScale: textScale,
);

bool _inColumns(WidgetTester tester) {
  final tops = {
    for (final m in _sampleDay) tester.getTopLeft(find.text(m.label)).dy,
  };
  return tops.length == 1;
}

void main() {
  testWidgets('HM-003 compact macro bars show four columns, each with a text '
      'label and a value next to its colour', (tester) async {
    await _pump(tester, width: 390);
    expect(FbDensity.macroColumns, isTrue);
    expect(_inColumns(tester), isTrue);
    final tracks = tester.widgetList<FbBarTrack>(find.byType(FbBarTrack));
    expect(tracks, hasLength(4));
    for (final m in _sampleDay) {
      final label = tester.getRect(find.text(m.label));
      final value = tester.getRect(find.text(m.valueText));
      // Label above, amounts below, in the same column.
      expect(value.top, greaterThan(label.bottom));
      expect((value.left - label.left).abs(), lessThan(1));
    }
    expect(find.bySemanticsLabel('Protein, 92 / 150 g'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('UX-070 macro bars use rows when the widest label or value '
      "doesn't fit a quarter of the width: 360 dp at text scale 1.3 with the "
      'sample-day strings, no overflow', (tester) async {
    await _pump(tester, width: 360, textScale: 1.3);
    expect(_inColumns(tester), isFalse);
    expect(tester.takeException(), isNull);
  });

  for (final scale in [1.4, 2.0]) {
    testWidgets('UX-070 macro bars use rows at text scale >= 1.4 and never '
        'overflow (x$scale)', (tester) async {
      await _pump(tester, width: 600, textScale: scale);
      expect(_inColumns(tester), isFalse);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('UX-070 macro bars never overflow at 2.0 on a narrow phone', (
    tester,
  ) async {
    await _pump(tester, width: 320, textScale: 2);
    expect(tester.takeException(), isNull);
  });
}
