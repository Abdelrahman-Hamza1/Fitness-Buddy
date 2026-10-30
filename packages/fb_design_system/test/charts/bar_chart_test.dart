import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_design_system/src/charts/bar_chart_painter.dart';
import 'package:fb_design_system/src/charts/bar_geometry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump.dart';

final DateTime _d0 = DateTime.utc(2026, 10, 24);

List<FbBar> _week() => [
  for (var i = 0; i < 7; i++)
    FbBar(
      at: _d0.add(Duration(days: i)),
      value: 1800 + i * 100.0,
      target: 2000,
      style: i == 3 ? FbBarStyle.hatched : FbBarStyle.solid,
    ),
];

Finder _paint() => find.descendant(
  of: find.byType(FbBarChart),
  matching: find.byType(CustomPaint),
);

void main() {
  for (final direction in TextDirection.values) {
    testWidgets('LC-003 IN-002 bar chart runs in reading direction and a tap '
        'picks the nearest bar within 24 dp (${direction.name})', (
      tester,
    ) async {
      final picked = <int?>[];
      await pumpFb(
        tester,
        direction: direction,
        FbBarChart(bars: _week(), onSelect: picked.add),
      );
      final painter =
          tester.widget<CustomPaint>(_paint()).painter! as BarChartPainter;
      final geometry = painter.lastGeometry!;
      // The first (oldest) bar sits at the start edge.
      final first = geometry.centerX(0);
      final last = geometry.centerX(6);
      expect(
        direction == TextDirection.ltr ? first < last : first > last,
        isTrue,
      );
      final origin = tester.getTopLeft(_paint());
      final y = geometry.plot.center.dy;
      // A tap a little off bar 2's centre (towards bar 3) picks bar 2.
      final towardsNext = direction == TextDirection.ltr ? 1 : -1;
      await tester.tapAt(
        origin + Offset(geometry.centerX(2) + towardsNext * 10, y),
      );
      expect(picked.last, 2);
      // Beyond the last bar by more than the tolerance: nothing.
      final beyond = direction == TextDirection.ltr
          ? geometry.plot.right + geometry.slotWidth / 2 + 30
          : geometry.plot.left - geometry.slotWidth / 2 - 30;
      expect(geometry.nearest(beyond), isNull);
      // Within 20 dp past the centre of the last bar: still the last bar.
      expect(geometry.nearest(geometry.centerX(6) + towardsNext * 20), 6);
    });
  }

  test('IN-002 bar scale starts at zero and includes the targets', () {
    final scale = barScale([
      FbBar(at: _d0, value: 900, target: 2400),
      FbBar(at: _d0, value: 2100),
      FbBar(at: _d0, target: 1800),
    ]);
    expect(scale.min, 0);
    expect(scale.max, greaterThanOrEqualTo(2400));
    expect(scale.fraction(2400), lessThan(1));
    // Values only, a target far above: still on the chart.
    final low = barScale([FbBar(at: _d0, value: 10, target: 300)]);
    expect(low.min, 0);
    expect(low.max, greaterThanOrEqualTo(300));
    // Nothing at all: a usable axis from zero.
    final empty = barScale([FbBar(at: _d0)]);
    expect(empty.min, 0);
    expect(empty.max, greaterThan(0));
    // Geometry: equal slots, mirrored in right-to-left.
    const plot = Rect.fromLTRB(0, 0, 70, 100);
    const ltr = BarGeometry(plot: plot, count: 7, direction: TextDirection.ltr);
    const rtl = BarGeometry(plot: plot, count: 7, direction: TextDirection.rtl);
    expect(ltr.centerX(0), 5);
    expect(rtl.centerX(0), 65);
    expect(ltr.nearest(36), 3);
    expect(rtl.nearest(36), 3);
  });

  testWidgets('UX-071 IN-003 every bar reads its own words, selectable or '
      'not; a screen-reader tap selects it; new words replace old ones', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final bars = [
      ..._week(),
      FbBar(at: _d0.add(const Duration(days: 7)), placeholder: true),
    ];
    // No selection at all (the macro charts): each bar is still readable.
    await pumpFb(tester, FbBarChart(bars: bars, describeBar: (i) => 'bar $i'));
    for (var i = 0; i < 7; i++) {
      expect(find.semantics.byLabel('bar $i'), findsOne, reason: 'bar $i');
    }
    expect(find.semantics.byLabel('bar 7'), findsNothing, reason: 'to come');

    final picked = <int?>[];
    await pumpFb(
      tester,
      FbBarChart(
        bars: bars,
        describeBar: (i) => 'bar $i',
        onSelect: picked.add,
      ),
    );
    tester.semantics.tap(find.semantics.byLabel('bar 2'));
    expect(picked.last, 2);

    // The same bars and the same onSelect with new words: only the
    // description callback changes, and the nodes say the new words.
    await pumpFb(
      tester,
      FbBarChart(
        bars: bars,
        describeBar: (i) => 'day $i',
        onSelect: picked.add,
      ),
    );
    expect(find.semantics.byLabel('day 2'), findsOne);
    expect(find.semantics.byLabel('bar 2'), findsNothing);
    semantics.dispose();
  });
}
