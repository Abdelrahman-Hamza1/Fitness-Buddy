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
    for (final shape in [...fbEmbraceMark, ...fbEmbraceMini]) {
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

  test('A44-D9 every mark shape lies inside the adaptive-icon safe zone', () {
    const centre = Offset(54, 54);
    const safe = 33.0;
    var worst = 0.0;
    for (final shape in fbEmbraceMark) {
      final half = (shape.strokeWidth ?? 0) / 2;
      for (final metric in parseFbMarkPath(shape.d).computeMetrics()) {
        final steps = (metric.length / 0.5).ceil();
        for (var i = 0; i <= steps; i++) {
          final p = metric
              .getTangentForOffset(math.min(metric.length, i * 0.5))!
              .position;
          worst = math.max(worst, (p - centre).distance + half);
        }
      }
    }
    expect(worst, lessThanOrEqualTo(safe));
    // The design aims for r <= 31 (A44 D9); keep a little margin visible.
    expect(worst, lessThan(31.5));
  });

  test('A44-D10 the mark has two figures, each a filled head and one stroke '
      'of a single weight', () {
    for (final part in FbMarkPart.values) {
      final shapes = fbEmbraceMark.where((s) => s.part == part);
      expect(shapes.where((s) => s.strokeWidth == null), hasLength(1));
      expect(shapes.where((s) => s.strokeWidth != null), hasLength(1));
    }
    expect(
      {
        for (final s in fbEmbraceMark)
          if (s.strokeWidth != null) s.strokeWidth,
      },
      {12.5},
    );
  });

  test('UX-071 A44-D10 the two figures never touch: at least 3.5 units of '
      'background between them, so the one-colour mark shows two people', () {
    List<(Offset, double)> samples(FbMarkPart part) => [
      for (final shape in fbEmbraceMark.where((s) => s.part == part))
        for (final metric in parseFbMarkPath(shape.d).computeMetrics())
          for (var t = 0.0; t <= metric.length; t += 0.25)
            (
              metric.getTangentForOffset(t)!.position,
              // A filled head is sampled on its outline: no padding.
              (shape.strokeWidth ?? 0) / 2,
            ),
    ];
    final a = samples(FbMarkPart.a);
    final b = samples(FbMarkPart.b);
    var gap = double.infinity;
    for (final (p, pa) in a) {
      for (final (q, pb) in b) {
        gap = math.min(gap, (p - q).distance - pa - pb);
      }
    }
    expect(gap, greaterThanOrEqualTo(3.5));
  });

  test(
    'UX-040 A44-D10 the fixed brand colours are the light palette roles',
    () {
      final light = FbPalette.of(Brightness.light);
      expect(FbBrandColors.plate, light.brand);
      expect(FbBrandColors.reversedA, light.surface);
      expect(FbBrandColors.mint, light.mint);
    },
  );
}
