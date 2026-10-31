import 'package:fb_design_system/fb_design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump.dart';

List<FbWeekBar> _bars() => [
  for (var i = 0; i < 7; i++)
    FbWeekBar(
      value: i == 5 ? 2600 : 2150,
      valueLabel: i == 5 ? '2,600' : '2,150',
      label: 'SMTWTFS'[i],
      semanticLabel: 'Day $i',
      highlighted: i == 5,
    ),
];

void main() {
  testWidgets('D-090 FbWeekBars: each column is one button; a tap reports '
      'its index; read-only without onTap', (tester) async {
    final handle = tester.ensureSemantics();
    final taps = <int>[];
    await pumpFb(tester, FbWeekBars(bars: _bars(), onTap: taps.add));
    expect(find.text('2,600'), findsOneWidget);
    await tester.tap(find.text('2,600'));
    await tester.tap(find.bySemanticsLabel('Day 0'));
    expect(taps, [5, 0]);
    expect(
      tester.getSize(find.byType(InkWell).first).height,
      greaterThanOrEqualTo(48),
    );
    await pumpFb(tester, FbWeekBars(bars: _bars()));
    await tester.tap(find.text('2,600'));
    expect(taps, [5, 0]);
    handle.dispose();
  });
}
