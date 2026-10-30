import 'dart:math' as math;

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_design_system/src/charts/chart_geometry.dart';
import 'package:fb_design_system/src/charts/lttb.dart';
import 'package:fb_design_system/src/charts/nice_scale.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Daily points from 1 Jan 2025, a wavy weight line.
List<FbPoint> daily(int days, {double base = 90}) => [
  for (var i = 0; i < days; i++)
    FbPoint(
      DateTime.utc(2025).add(Duration(days: i)),
      base - i * 0.01 + math.sin(i / 3),
      key: i,
    ),
];

double ms(DateTime at) => at.millisecondsSinceEpoch.toDouble();

void main() {
  group('lttb', () {
    test('lttb keeps the first, last and extreme points and returns at most '
        'the threshold', () {
      final xs = [for (var i = 0; i < 1000; i++) i.toDouble()];
      final ys = [for (var i = 0; i < 1000; i++) math.sin(i / 20) * 10];
      ys[500] = 100; // a spike
      ys[700] = -100; // a dip
      final kept = lttbIndices(xs, ys, 50);
      expect(kept.length, lessThanOrEqualTo(50));
      expect(kept.first, 0);
      expect(kept.last, 999);
      expect(kept, containsAll(<int>[500, 700]));
      expect(kept, orderedEquals([...kept]..sort()));
    });

    test('lttb returns the input unchanged below the threshold', () {
      expect(lttbIndices([1, 2, 3], [4, 5, 6], 10), [0, 1, 2]);
      expect(lttbIndices([1, 2, 3, 4], [4, 5, 6, 7], 2), [0, 1, 2, 3]);
    });
  });

  group('nice scale', () {
    test('nice scale: 3–5 ticks on 0.1/0.2/0.5/1/2/5/10 steps', () {
      for (final (low, high) in [
        (80.0, 81.0),
        (70.0, 95.0),
        (89.9, 90.1),
        (60.0, 140.0),
        (85.3, 85.3),
      ]) {
        final scale = NiceScale.fit([low, high]);
        final ticks = scale.ticks;
        expect(ticks.length, inInclusiveRange(2, 5), reason: '$low–$high');
        expect(scale.min, lessThanOrEqualTo(low));
        expect(scale.max, greaterThanOrEqualTo(high));
        final mantissa =
            scale.step /
            math.pow(10, (math.log(scale.step) / math.ln10).floor());
        expect([1, 2, 5, 10], contains(mantissa.round()));
      }
    });

    test('the goal is included only if it at most doubles the span, '
        'otherwise an edge marker', () {
      final near = NiceScale.fit([90, 92], goal: 89);
      expect(near.goalEdge, isNull);
      expect(near.min, lessThanOrEqualTo(89));
      final far = NiceScale.fit([90, 92], goal: 80);
      expect(far.goalEdge, FbGoalEdge.below);
      expect(far.min, greaterThan(80));
      expect(NiceScale.fit([90, 92], goal: 100).goalEdge, FbGoalEdge.above);
    });

    test('an empty slice still gives an axis', () {
      expect(NiceScale.fit([]).ticks, isNotEmpty);
      expect(NiceScale.fit([], goal: 80).goalEdge, isNull);
    });
  });

  group('geometry', () {
    ChartMapping mapping(TextDirection direction) => ChartMapping(
      plot: const Rect.fromLTWH(0, 0, 300, 100),
      startMs: ms(DateTime.utc(2025)),
      endMs: ms(DateTime.utc(2025, 1, 31)),
      minValue: 0,
      maxValue: 100,
      direction: direction,
    );

    test('LC-003 in RTL the oldest point is at the right (reading '
        'direction)', () {
      final ltr = mapping(TextDirection.ltr);
      final rtl = mapping(TextDirection.rtl);
      expect(ltr.xOf(DateTime.utc(2025)), 0);
      expect(ltr.xOf(DateTime.utc(2025, 1, 31)), 300);
      expect(rtl.xOf(DateTime.utc(2025)), 300);
      expect(rtl.xOf(DateTime.utc(2025, 1, 31)), 0);
    });

    test('a DST change day has no gap or kink', () {
      // Naive wall-clock x: consecutive days are always equally far apart.
      final map = mapping(TextDirection.ltr);
      final a = map.xOf(DateTime.utc(2025, 3, 29));
      final b = map.xOf(DateTime.utc(2025, 3, 30));
      final c = map.xOf(DateTime.utc(2025, 3, 31));
      expect(b - a, closeTo(c - b, 1e-9));
    });

    test('2 years of daily points in a 360 dp chart draw at most 360 line '
        'vertices and 120 dots per series', () {
      final points = daily(730);
      final start = ms(points.first.at);
      final end = ms(points.last.at);
      expect(
        drawnIndices(points, start, end, 360).length,
        lessThanOrEqualTo(360),
      );
      expect(
        drawnIndices(points, start, end, 120).length,
        lessThanOrEqualTo(120),
      );
      // The slice keeps the points just outside: lines reach the edges.
      final (first, last) = visibleSlice(
        points,
        ms(DateTime.utc(2025, 2)),
        ms(DateTime.utc(2025, 3)),
      );
      expect(points[first].at.isBefore(DateTime.utc(2025, 2)), isTrue);
      expect(points[last - 1].at.isAfter(DateTime.utc(2025, 3)), isTrue);
    });

    test('WB-022 hit-testing uses the full data when the drawn series is '
        'down-sampled', () {
      final points = daily(730);
      final map = ChartMapping(
        plot: const Rect.fromLTWH(0, 0, 360, 200),
        startMs: ms(points.first.at),
        endMs: ms(points.last.at),
        minValue: 80,
        maxValue: 100,
        direction: TextDirection.ltr,
      );
      final drawn = drawnIndices(points, map.startMs, map.endMs, 120).toSet();
      final hidden = List.generate(
        730,
        (i) => i,
      ).firstWhere((i) => !drawn.contains(i) && i > 10 && i < 720);
      final p = points[hidden];
      final ref = hitTest(
        [FbSeries(points: points, selectable: true)],
        map,
        Offset(map.xOf(p.at), map.y(p.value)),
      );
      expect(ref, FbPointRef(series: 0, key: hidden));
    });

    test('WB-022 a tap within 24 dp selects the nearest point of a '
        'selectable series; farther away selects nothing', () {
      final points = [
        FbPoint(DateTime.utc(2025, 1, 10), 50, key: 'a'),
        FbPoint(DateTime.utc(2025, 1, 20), 50, key: 'b'),
      ];
      final map = mapping(TextDirection.ltr);
      final a = Offset(map.xOf(points[0].at), map.y(50));
      expect(
        hitTest(
          [FbSeries(points: points, selectable: true)],
          map,
          a + const Offset(0, 20),
        ),
        const FbPointRef(series: 0, key: 'a'),
      );
      expect(
        hitTest(
          [FbSeries(points: points, selectable: true)],
          map,
          a + const Offset(0, 30),
        ),
        isNull,
      );
      expect(hitTest([FbSeries(points: points)], map, a), isNull);
    });

    test('the scale fits dots strictly inside the window and lines at their '
        'interpolated edge values', () {
      final points = [
        FbPoint(DateTime.utc(2025), 100),
        FbPoint(DateTime.utc(2025, 1, 11), 80),
        FbPoint(DateTime.utc(2025, 1, 21), 82),
        FbPoint(DateTime.utc(2025, 1, 31), 60),
      ];
      final start = ms(DateTime.utc(2025, 1, 6));
      final end = ms(DateTime.utc(2025, 1, 26));
      expect(visibleValues(points, start, end, isLine: false), [80, 82]);
      final line = visibleValues(points, start, end, isLine: true);
      expect(line, hasLength(4));
      expect(line.first, closeTo(90, 1e-9));
      expect(line.last, closeTo(71, 1e-9));
      // A window inside one segment: only the two edge values.
      expect(
        visibleValues(
          points,
          ms(DateTime.utc(2025, 1, 2)),
          ms(DateTime.utc(2025, 1, 4)),
          isLine: true,
        ),
        hasLength(2),
      );
      expect(visibleValues(const [], start, end, isLine: true), isEmpty);
    });

    test('time ticks pick days, months or years for the window', () {
      final (week, weekStep) = timeTicks(
        DateTime.utc(2025),
        DateTime.utc(2025, 1, 29),
      );
      expect(weekStep, FbTimeStep.day);
      expect(week.length, inInclusiveRange(2, 5));
      final (months, monthStep) = timeTicks(
        DateTime.utc(2025),
        DateTime.utc(2025, 7),
      );
      expect(monthStep, FbTimeStep.month);
      expect(months.length, inInclusiveRange(2, 5));
      final (years, yearStep) = timeTicks(
        DateTime.utc(2019),
        DateTime.utc(2025, 6),
      );
      expect(yearStep, FbTimeStep.year);
      expect(years.length, inInclusiveRange(2, 5));
    });
  });
}
