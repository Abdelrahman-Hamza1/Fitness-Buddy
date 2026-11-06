import 'dart:math' as math;

import 'package:fb_design_system/fb_design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test('A44-D9 parseFbMarkPath reads absolute M L C Q A Z and two-arc '
      'dots', () {
    final lines = parseFbMarkPath('M0 0 L10 0 L10 10 Z');
    expect(lines.getBounds(), const Rect.fromLTRB(0, 0, 10, 10));
    expect(lines.contains(const Offset(8, 2)), isTrue);
    expect(lines.contains(const Offset(2, 8)), isFalse);

    final curves = parseFbMarkPath('M0,0 C0 10, 10 10, 10 0 Q5 -5 0 0 Z');
    expect(curves.getBounds().width, closeTo(10, 0.01));

    // A head dot: two half-circle arcs.
    final dot = parseFbMarkPath('M4 10 A6 6 0 1 1 16 10 A6 6 0 1 1 4 10 Z');
    final b = dot.getBounds();
    expect(b.left, closeTo(4, 0.01));
    expect(b.right, closeTo(16, 0.01));
    expect(b.top, closeTo(4, 0.01));
    expect(b.bottom, closeTo(16, 0.01));
    expect(dot.contains(const Offset(10, 10)), isTrue);

    // Sweep flag 1 runs clockwise on screen: from the left point over the top.
    final arc = parseFbMarkPath('M0 10 A10 10 0 0 1 20 10');
    expect(arc.getBounds().top, closeTo(0, 0.01));

    // Every shape of both marks parses.
    for (final shape in [...fbMomentumMark, ...fbMomentumMini]) {
      expect(() => parseFbMarkPath(shape.d), returnsNormally, reason: shape.d);
    }
  });

  test('A44-D9 parseFbMarkPath rejects relative commands, H/V/S/T, malformed '
      'numbers and empty input', () {
    for (final bad in [
      '',
      '   ',
      'L0 0',
      'm0 0 l10 10',
      'M0 0 l10 10',
      'M0 0 a5 5 0 0 1 10 0',
      'M0 0 H10',
      'M0 0 V10',
      'M0 0 C1 1 2 2 3 3 S4 4 5 5',
      'M0 0 Q1 1 2 2 T3 3',
      'M0 0 L1.2.3 4',
      'M0 0 L1e3 4',
      'M0 0 L--1 4',
      'M0 0 L10',
      'M0 0 L1 2 3 4',
      'M0 0 A5 5 0 2 1 10 0',
      'M0 0 L1 x',
      'M0 0 # 1 2',
    ]) {
      expect(
        () => parseFbMarkPath(bad),
        throwsFormatException,
        reason: '"$bad"',
      );
    }
  });

  test('A64 the Momentum paths are the reference pills skewed 22°, scaled '
      'about the centre of their enclosing circle', () {
    // The owner-approved drawing (A64 card): rects on a 100 canvas with
    // corner radius w / 2, under translate(3.17, 3) skewX(-22°).
    const pills = [
      (x: 32.32, y: 48.0, w: 19.0, h: 32.0),
      (x: 55.32, y: 32.0, w: 19.0, h: 48.0),
      (x: 78.32, y: 14.0, w: 21.0, h: 66.0),
    ];
    const k = 0.5522847498307936;
    final tan = math.tan(22 * math.pi / 180);
    const centre = Offset(49.78289487858571, 50.127645657822924);
    const enclosing = 52.26074955015602;

    List<Offset> outline(({double x, double y, double w, double h}) p) {
      final (:x, :y, :w, :h) = p;
      final r = w / 2;
      return [
        Offset(x, y + r),
        Offset(x, y + r - k * r),
        Offset(x + r - k * r, y),
        Offset(x + r, y),
        Offset(x + r + k * r, y),
        Offset(x + w, y + r - k * r),
        Offset(x + w, y + r),
        Offset(x + w, y + h - r),
        Offset(x + w, y + h - r + k * r),
        Offset(x + r + k * r, y + h),
        Offset(x + r, y + h),
        Offset(x + r - k * r, y + h),
        Offset(x, y + h - r + k * r),
        Offset(x, y + h - r),
      ];
    }

    for (final (marks, canvas, radius) in [
      (fbMomentumMark, fbMomentumMarkCanvas, 31.0),
      (fbMomentumMini, fbMomentumMiniCanvas, 10.5),
    ]) {
      expect(marks.map((s) => s.tone), FbMarkTone.values);
      final scale = radius / enclosing;
      for (var i = 0; i < pills.length; i++) {
        final d = marks[i].d;
        expect(
          RegExp('[A-Z]').allMatches(d).map((m) => m[0]).join(),
          'MCCLCCZ',
          reason: d,
        );
        final numbers = [
          for (final m in RegExp(r'-?\d+(\.\d+)?').allMatches(d))
            double.parse(m[0]!),
        ];
        final expected = [
          for (final p in outline(pills[i])) ...[
            (p.dx - tan * p.dy + 3.17 - centre.dx) * scale + canvas / 2,
            (p.dy + 3 - centre.dy) * scale + canvas / 2,
          ],
        ];
        expect(numbers, hasLength(expected.length), reason: d);
        for (var j = 0; j < numbers.length; j++) {
          expect(numbers[j], closeTo(expected[j], 0.006), reason: '$d #$j');
        }
      }
    }
  });

  test('A64 the mark lies inside the adaptive-icon safe zone, the mini mark '
      'inside its disc, and the figure rect holds the mark', () {
    // Points along the outline (getBounds would include control points).
    List<Offset> outline(List<FbMarkShape> shapes) => [
      for (final shape in shapes)
        for (final metric in parseFbMarkPath(shape.d).computeMetrics())
          for (var i = 0; i <= (metric.length / 0.25).ceil(); i++)
            metric
                .getTangentForOffset(math.min(metric.length, i * 0.25))!
                .position,
    ];
    double reach(List<FbMarkShape> shapes, Offset centre) =>
        outline(shapes).map((p) => (p - centre).distance).reduce(math.max);

    final mark = reach(fbMomentumMark, const Offset(54, 54));
    expect(mark, lessThanOrEqualTo(33));
    // The design aims for r 31 (a little margin inside the safe circle).
    expect(mark, lessThan(31.1));
    expect(reach(fbMomentumMini, const Offset(14, 14)), lessThan(10.6));

    final figure = fbMomentumMarkFigure.inflate(0.01);
    for (final p in outline(fbMomentumMark)) {
      expect(figure.contains(p), isTrue, reason: '$p');
    }
  });

  test('A64 the fixed launcher colours equal the light palette roles', () {
    final light = FbPalette.of(Brightness.light);
    expect(FbBrandColors.plate, light.brand);
    expect(FbBrandColors.soft, light.markSoft);
    expect(FbBrandColors.mid, light.markMid);
    expect(FbBrandColors.spark, light.spark);
  });
}
