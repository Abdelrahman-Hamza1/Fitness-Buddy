import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_design_system/src/charts/time_series_painter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump.dart';

final DateTime _t0 = DateTime.utc(2026, 9);

List<FbPoint> _points() => [
  for (var i = 0; i < 30; i++)
    FbPoint(_t0.add(Duration(days: i)), 90 - i * 0.1, key: 'w$i'),
];

FbChartRange _range() =>
    FbChartRange(start: _t0, end: _t0.add(const Duration(days: 30)));

Finder _paint() => find.descendant(
  of: find.byType(FbTimeSeriesChart),
  matching: find.byType(CustomPaint),
);

/// Where [point] is drawn, in global coordinates.
Offset _where(WidgetTester tester, FbPoint point) {
  final painter =
      tester.widget<CustomPaint>(_paint()).painter! as TimeSeriesPainter;
  final map = painter.lastMapping!;
  return tester.getTopLeft(_paint()) +
      Offset(map.xOf(point.at), map.y(point.value));
}

void main() {
  group('pan', () {
    for (final direction in TextDirection.values) {
      testWidgets('LC-003 a drag follows the finger in ${direction.name}', (
        tester,
      ) async {
        final ranges = <FbChartRange>[];
        await pumpFb(
          tester,
          direction: direction,
          FbTimeSeriesChart(
            series: [FbSeries(points: _points())],
            range: _range(),
            panBounds: FbChartRange(
              start: _t0.subtract(const Duration(days: 60)),
              end: _t0.add(const Duration(days: 60)),
            ),
            onRangeChanged: ranges.add,
          ),
        );
        // Dragging towards the end edge brings earlier days into view.
        final towardsEnd = direction == TextDirection.ltr ? 100.0 : -100.0;
        await tester.drag(
          find.byType(FbTimeSeriesChart),
          Offset(towardsEnd, 0),
        );
        await tester.pump();
        expect(ranges, hasLength(1));
        expect(ranges.single.start.isBefore(_t0), isTrue);
        expect(ranges.single.duration, _range().duration);
      });
    }

    testWidgets('WB-020 a drag pans with a transient offset and calls '
        'onRangeChanged once on drag end with a continuous start; a new range '
        'resets the offset; without panBounds drags do nothing', (
      tester,
    ) async {
      final ranges = <FbChartRange>[];
      Widget chart(FbChartRange range, {bool pan = true}) => FbTimeSeriesChart(
        series: [FbSeries(points: _points())],
        range: range,
        panBounds: pan
            ? FbChartRange(
                start: _t0.subtract(const Duration(days: 60)),
                end: _t0.add(const Duration(days: 60)),
              )
            : null,
        onRangeChanged: ranges.add,
      );
      await pumpFb(tester, chart(_range()));
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(FbTimeSeriesChart)),
      );
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(const Offset(7, 0));
        await tester.pump();
      }
      expect(ranges, isEmpty, reason: 'nothing is reported during the drag');
      await gesture.up();
      await tester.pump();
      expect(ranges, hasLength(1));
      // pan moves by fractional days.
      final shift = _t0.difference(ranges.single.start);
      expect(shift.inMilliseconds % Duration.millisecondsPerDay, isNot(0));

      // The parent adopts the window: the offset resets, a new drag starts
      // from it.
      await pumpFb(tester, chart(ranges.single));
      await tester.drag(find.byType(FbTimeSeriesChart), const Offset(-50, 0));
      await tester.pump();
      expect(ranges, hasLength(2));
      expect(ranges[1].start.isAfter(ranges[0].start), isTrue);

      await pumpFb(tester, chart(_range(), pan: false));
      await tester.drag(find.byType(FbTimeSeriesChart), const Offset(100, 0));
      await tester.pump();
      expect(ranges, hasLength(2));
    });
  });

  group('selection', () {
    testWidgets('WB-022 a tap within 24 dp selects the nearest point of a '
        'selectable series; a tap on empty space clears it', (tester) async {
      final picks = <FbPointRef?>[];
      final points = _points();
      await pumpFb(
        tester,
        FbTimeSeriesChart(
          series: [FbSeries(points: points, selectable: true)],
          range: _range(),
          onSelect: picks.add,
        ),
      );
      await tester.tapAt(_where(tester, points[10]) + const Offset(0, 10));
      expect(picks.last, const FbPointRef(series: 0, key: 'w10'));
      await tester.tapAt(_where(tester, points[10]) + const Offset(0, 60));
      expect(picks.last, isNull);
    });

    testWidgets('WB-022 the selected point is always drawn and semantics '
        'increase/decrease move the selection to the next/previous point', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var selected = const FbPointRef(series: 0, key: 'w5');
      await pumpFb(
        tester,
        StatefulBuilder(
          builder: (context, setState) => FbTimeSeriesChart(
            series: [FbSeries(points: _points(), selectable: true)],
            range: _range(),
            selected: selected,
            onSelect: (p) => setState(() => selected = p!),
            semanticLabel: 'Weight graph',
          ),
        ),
      );
      final painter =
          tester.widget<CustomPaint>(_paint()).painter! as TimeSeriesPainter;
      expect(painter.selected?.$1.key, 'w5');
      expect(find.bySemanticsLabel('Weight graph'), findsOneWidget);
      tester.semantics.increase(find.semantics.byLabel('Weight graph'));
      await tester.pump();
      expect(selected.key, 'w6');
      tester.semantics.decrease(find.semantics.byLabel('Weight graph'));
      await tester.pump();
      tester.semantics.decrease(find.semantics.byLabel('Weight graph'));
      await tester.pump();
      expect(selected.key, 'w4');
      handle.dispose();
    });
  });

  testWidgets('UX-071 series differ by style, not only colour (solid, '
      'dashed, dots)', (tester) async {
    expect(
      FbSeriesStyle.values,
      containsAll(<FbSeriesStyle>[
        FbSeriesStyle.line,
        FbSeriesStyle.dashedLine,
        FbSeriesStyle.points,
      ]),
    );
    await pumpFb(
      tester,
      FbTimeSeriesChart(
        series: [
          FbSeries(points: _points(), style: FbSeriesStyle.points),
          FbSeries(points: _points(), style: FbSeriesStyle.line),
          FbSeries(points: _points(), style: FbSeriesStyle.dashedLine),
        ],
        range: _range(),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
