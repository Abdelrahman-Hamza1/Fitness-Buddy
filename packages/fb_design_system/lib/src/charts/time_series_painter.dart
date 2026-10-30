import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:fb_design_system/src/charts/chart_geometry.dart';
import 'package:fb_design_system/src/charts/chart_types.dart';
import 'package:fb_design_system/src/charts/nice_scale.dart';
import 'package:fb_design_system/src/tokens/spacing.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:material_ui/material_ui.dart';

/// The token colours a chart draws with, resolved from the theme.
@immutable
final class ChartColors {
  /// Reads the roles from [scheme].
  factory of(ColorScheme scheme) => ChartColors._(
    primary: scheme.primary,
    secondary: scheme.secondary,
    muted: scheme.onSurfaceVariant.withValues(alpha: 0.45),
    grid: scheme.outlineVariant,
    goal: scheme.onSurfaceVariant,
    band: scheme.primary.withValues(alpha: 0.14),
    phaseA: scheme.surfaceContainerHigh,
    phaseB: scheme.surfaceContainer,
    highlight: scheme.secondaryContainer.withValues(alpha: 0.6),
    label: scheme.onSurfaceVariant,
    surface: scheme.surface,
  );

  const new _({
    required this.primary,
    required this.secondary,
    required this.muted,
    required this.grid,
    required this.goal,
    required this.band,
    required this.phaseA,
    required this.phaseB,
    required this.highlight,
    required this.label,
    required this.surface,
  });

  /// The main series.
  final Color primary;

  /// A second series.
  final Color secondary;

  /// Faint raw readings.
  final Color muted;

  /// Grid lines and period edges.
  final Color grid;

  /// The goal line and marker.
  final Color goal;

  /// The cone fill.
  final Color band;

  /// The first phase tint.
  final Color phaseA;

  /// The second phase tint.
  final Color phaseB;

  /// The highlighted-period tint.
  final Color highlight;

  /// Axis labels.
  final Color label;

  /// The chart background (selection ring fill).
  final Color surface;

  /// The colour of [tone].
  Color series(FbSeriesTone tone) => switch (tone) {
    FbSeriesTone.primary => primary,
    FbSeriesTone.secondary => secondary,
    FbSeriesTone.muted => muted,
  };

  /// The tint of [tone].
  Color period(FbPeriodTone tone) => switch (tone) {
    FbPeriodTone.phaseA => phaseA,
    FbPeriodTone.phaseB => phaseB,
    FbPeriodTone.highlight => highlight,
  };

  @override
  bool operator ==(Object other) =>
      other is ChartColors &&
      other.primary == primary &&
      other.secondary == secondary &&
      other.muted == muted &&
      other.grid == grid &&
      other.goal == goal &&
      other.band == band &&
      other.phaseA == phaseA &&
      other.phaseB == phaseB &&
      other.highlight == highlight &&
      other.label == label &&
      other.surface == surface;

  @override
  int get hashCode => Object.hash(
    primary,
    secondary,
    muted,
    grid,
    goal,
    band,
    phaseA,
    phaseB,
    highlight,
    label,
    surface,
  );
}

/// Laid-out label text, cached per string (A15 D4): panning reuses the
/// painters instead of laying out every label each frame. The owner clears
/// it when the text scale, style or direction changes.
final class ChartLabelCache {
  final Map<String, TextPainter> _painters = {};

  /// The style, scale and direction labels are laid out with.
  TextStyle style = const TextStyle();

  /// How labels scale.
  TextScaler scaler = TextScaler.noScaling;

  /// The text direction of the labels.
  TextDirection direction = TextDirection.ltr;

  /// Laid-out [text].
  TextPainter of(String text) => _painters.putIfAbsent(
    text,
    () => TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: direction,
      textScaler: scaler,
      maxLines: 1,
    )..layout(),
  );

  /// Forgets every laid-out label.
  void clear() {
    for (final painter in _painters.values) {
      painter.dispose();
    }
    _painters.clear();
  }
}

/// Draws an `FbTimeSeriesChart` (TD-012: `CustomPainter`, no library).
/// Repaints on [range] (the eased window, A45 D5) and [offset] (the transient
/// pan, in ms) without a rebuild.
final class TimeSeriesPainter extends CustomPainter {
  /// Creates the painter.
  new({
    required this.series,
    required this.bands,
    required this.periods,
    required this.goal,
    required this.selected,
    required this.range,
    required this.offset,
    required this.colors,
    required this.labels,
    required this.direction,
    required this.formatValue,
    required this.formatDate,
  }) : super(repaint: Listenable.merge([range, offset]));

  /// What to draw.
  final List<FbSeries> series;

  /// The cone(s).
  final List<FbBand> bands;

  /// Shaded periods.
  final List<FbPeriod> periods;

  /// The goal line.
  final FbGoalLine? goal;

  /// The selected point and its tone, always drawn (A15 PA8).
  final (FbPoint, FbSeriesTone)? selected;

  /// The window before the transient [offset]; it moves while the chart
  /// eases from one range to the next.
  final ValueListenable<FbChartRange> range;

  /// The transient pan offset in ms.
  final ValueListenable<double> offset;

  /// Token colours.
  final ChartColors colors;

  /// Cached label layout.
  final ChartLabelCache labels;

  /// Reading direction (LC-003).
  final TextDirection direction;

  /// Formats axis values and the goal (already translated).
  final String Function(double value) formatValue;

  /// Formats axis dates (already translated).
  final String Function(DateTime at, FbTimeStep step) formatDate;

  /// The mapping of the last paint, for hit-testing taps.
  ChartMapping? lastMapping;

  /// Where the last paint drew its date labels (tests check they never
  /// overlap, A15 PA8).
  final List<Rect> timeLabelRects = [];

  /// The window on screen: [range] moved by the transient [offset].
  @visibleForTesting
  FbChartRange get shownWindow =>
      range.value.shift(Duration(milliseconds: offset.value.round()));

  /// Line width of the main series.
  static const double lineWidth = 2.5;

  /// Dot radius of point series.
  static const double dotRadius = 2.5;

  @override
  void paint(Canvas canvas, Size size) {
    final window = range.value;
    final startMs = window.start.millisecondsSinceEpoch + offset.value;
    final endMs = window.end.millisecondsSinceEpoch + offset.value;

    // The value scale from what's visible (A15 D6).
    final values = <double>[];
    for (final s in series) {
      values.addAll(
        visibleValues(
          s.points,
          startMs,
          endMs,
          isLine: s.style != FbSeriesStyle.points,
        ),
      );
    }
    for (final band in bands) {
      for (final p in band.points) {
        final ms = p.at.millisecondsSinceEpoch;
        if (ms >= startMs && ms <= endMs) values.addAll([p.lower, p.upper]);
      }
    }
    final scale = NiceScale.fit(values, goal: goal?.value);

    // Layout: value labels at the start edge, date labels below, phase
    // labels above.
    final ticks = scale.ticks;
    var gutter = 0.0;
    for (final tick in ticks) {
      gutter = math.max(gutter, labels.of(formatValue(tick)).width);
    }
    gutter += FbSpace.s2;
    final lineHeight = labels.of(formatValue(ticks.first)).height;
    final hasTopLabels = periods.any(
      (p) => p.label != null && p.tone != FbPeriodTone.highlight,
    );
    final top = hasTopLabels ? lineHeight + FbSpace.s1 : lineHeight / 2;
    final bottom = size.height - lineHeight - FbSpace.s1;
    final plot = direction == TextDirection.ltr
        ? Rect.fromLTRB(gutter, top, size.width - FbSpace.s1, bottom)
        : Rect.fromLTRB(FbSpace.s1, top, size.width - gutter, bottom);
    if (plot.width <= 0 || plot.height <= 0) return;
    final map = ChartMapping(
      plot: plot,
      startMs: startMs,
      endMs: endMs,
      minValue: scale.min,
      maxValue: scale.max,
      direction: direction,
    );
    lastMapping = map;

    _paintPeriods(canvas, map, size);
    _paintGrid(canvas, map, ticks);
    _paintTimeLabels(canvas, map, size);

    canvas
      ..save()
      ..clipRect(plot.inflate(dotRadius + 1));
    for (final band in bands) {
      _paintBand(canvas, map, band);
    }
    _paintGoal(canvas, map, scale);
    for (final s in series) {
      _paintSeries(canvas, map, s);
    }
    _paintSelection(canvas, map);
    canvas.restore();
    _paintGoalEdge(canvas, map, scale);
  }

  void _paintPeriods(Canvas canvas, ChartMapping map, Size size) {
    final plot = map.plot;
    final edge = Paint()
      ..color = colors.grid
      ..strokeWidth = 1;
    for (final period in periods) {
      final a = map.xOf(period.start);
      final b = map.xOf(period.end);
      final rect = Rect.fromLTRB(
        math.max(math.min(a, b), plot.left),
        plot.top,
        math.min(math.max(a, b), plot.right),
        plot.bottom,
      );
      if (rect.width <= 0) continue;
      canvas.drawRect(rect, Paint()..color = colors.period(period.tone));
      // A boundary line where the period starts: meaning not only by tint.
      if (a >= plot.left && a <= plot.right) {
        canvas.drawLine(Offset(a, plot.top), Offset(a, plot.bottom), edge);
      }
      final label = period.label;
      if (label == null) continue;
      final text = labels.of(label);
      if (text.width > rect.width - FbSpace.s1) continue;
      // Start-aligned inside the period's visible part.
      final x = direction == TextDirection.ltr
          ? rect.left + FbSpace.s1
          : rect.right - FbSpace.s1 - text.width;
      final y = period.tone == FbPeriodTone.highlight
          ? plot.bottom - text.height - FbSpace.s1
          : plot.top - text.height - FbSpace.s1 / 2;
      text.paint(canvas, Offset(x, y));
    }
  }

  void _paintGrid(Canvas canvas, ChartMapping map, List<double> ticks) {
    final paint = Paint()
      ..color = colors.grid
      ..strokeWidth = 1;
    final plot = map.plot;
    for (final tick in ticks) {
      final y = map.y(tick).roundToDouble() + 0.5;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), paint);
      final text = labels.of(formatValue(tick));
      final x = direction == TextDirection.ltr
          ? plot.left - FbSpace.s2 - text.width
          : plot.right + FbSpace.s2;
      text.paint(canvas, Offset(x, y - text.height / 2));
    }
  }

  void _paintTimeLabels(Canvas canvas, ChartMapping map, Size size) {
    final (ticks, step) = timeTicks(
      DateTime.fromMillisecondsSinceEpoch(map.startMs.round(), isUtc: true),
      DateTime.fromMillisecondsSinceEpoch(map.endMs.round(), isUtc: true),
    );
    // Labels never overlap: a label that would touch the previous one (in
    // reading order) is skipped (A15 PA8).
    double? previousEdge;
    timeLabelRects.clear();
    for (final tick in ticks) {
      final text = labels.of(formatDate(tick, step));
      final x = map.xOf(tick);
      var left = x - text.width / 2;
      left = left.clamp(0.0, math.max(0, size.width - text.width));
      final leading = direction == TextDirection.ltr ? left : left + text.width;
      if (previousEdge != null &&
          (direction == TextDirection.ltr
              ? leading < previousEdge + FbSpace.s2
              : leading > previousEdge - FbSpace.s2)) {
        continue;
      }
      final origin = Offset(left, map.plot.bottom + FbSpace.s1);
      text.paint(canvas, origin);
      timeLabelRects.add(origin & text.size);
      previousEdge = direction == TextDirection.ltr ? left + text.width : left;
    }
  }

  void _paintBand(Canvas canvas, ChartMapping map, FbBand band) {
    if (band.points.length < 2) return;
    final path = Path();
    for (final (i, p) in band.points.indexed) {
      final o = Offset(map.xOf(p.at), map.y(p.upper));
      i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
    }
    for (final p in band.points.reversed) {
      path.lineTo(map.xOf(p.at), map.y(p.lower));
    }
    path.close();
    canvas.drawPath(path, Paint()..color = colors.band);
  }

  void _paintGoal(Canvas canvas, ChartMapping map, NiceScale scale) {
    final goal = this.goal;
    if (goal == null || scale.goalEdge != null) return;
    final y = map.y(goal.value).roundToDouble() + 0.5;
    final path = Path()
      ..moveTo(map.plot.left, y)
      ..lineTo(map.plot.right, y);
    canvas.drawPath(
      _dashed(path, 6, 4),
      Paint()
        ..color = colors.goal
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );
    final label = goal.label;
    if (label == null) return;
    final text = labels.of(label);
    final x = direction == TextDirection.ltr
        ? map.plot.right - text.width - FbSpace.s1
        : map.plot.left + FbSpace.s1;
    final above = y - text.height - FbSpace.s1 / 2;
    text.paint(
      canvas,
      Offset(x, above < map.plot.top ? y + FbSpace.s1 / 2 : above),
    );
  }

  void _paintGoalEdge(Canvas canvas, ChartMapping map, NiceScale scale) {
    final edge = scale.goalEdge;
    final label = goal?.label;
    if (edge == null || label == null) return;
    final text = labels.of(label);
    const arrow = 8.0;
    final plot = map.plot;
    final width = text.width + FbSpace.s1 + arrow;
    final x = direction == TextDirection.ltr
        ? plot.right - width - FbSpace.s1
        : plot.left + FbSpace.s1;
    final y = edge == FbGoalEdge.above
        ? plot.top + FbSpace.s1
        : plot.bottom - text.height - FbSpace.s1;
    final textX = direction == TextDirection.ltr ? x : x + arrow + FbSpace.s1;
    text.paint(canvas, Offset(textX, y));
    final arrowX = direction == TextDirection.ltr
        ? x + text.width + FbSpace.s1
        : x;
    final midY = y + text.height / 2;
    final path = edge == FbGoalEdge.above
        ? (Path()
            ..moveTo(arrowX, midY + arrow / 2)
            ..lineTo(arrowX + arrow / 2, midY - arrow / 2)
            ..lineTo(arrowX + arrow, midY + arrow / 2))
        : (Path()
            ..moveTo(arrowX, midY - arrow / 2)
            ..lineTo(arrowX + arrow / 2, midY + arrow / 2)
            ..lineTo(arrowX + arrow, midY - arrow / 2));
    canvas.drawPath(path..close(), Paint()..color = colors.goal);
  }

  void _paintSeries(Canvas canvas, ChartMapping map, FbSeries s) {
    if (s.points.isEmpty) return;
    final color = colors.series(s.tone);
    final width = map.plot.width;
    final hasLine = s.style != FbSeriesStyle.points;
    final hasDots =
        s.style == FbSeriesStyle.points || s.style == FbSeriesStyle.linePoints;
    if (hasLine) {
      final indices = drawnIndices(
        s.points,
        map.startMs,
        map.endMs,
        math.max(3, width.floor()),
      );
      if (indices.length >= 2) {
        final path = Path();
        for (final (n, i) in indices.indexed) {
          final p = s.points[i];
          final x = map.xOf(p.at);
          final y = map.y(p.value);
          n == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
        }
        canvas.drawPath(
          s.style == FbSeriesStyle.dashedLine ? _dashed(path, 8, 5) : path,
          Paint()
            ..color = color
            ..strokeWidth = lineWidth
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      }
    }
    if (hasDots) {
      final indices = drawnIndices(
        s.points,
        map.startMs,
        map.endMs,
        math.max(3, (width / 3).floor()),
      );
      final dots = <Offset>[
        for (final i in indices)
          Offset(map.xOf(s.points[i].at), map.y(s.points[i].value)),
      ];
      canvas.drawPoints(
        ui.PointMode.points,
        dots,
        Paint()
          ..color = color
          ..strokeWidth = dotRadius * 2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _paintSelection(Canvas canvas, ChartMapping map) {
    final selected = this.selected;
    if (selected == null) return;
    final (point, tone) = selected;
    final center = Offset(map.xOf(point.at), map.y(point.value));
    canvas
      ..drawLine(
        Offset(center.dx, map.plot.top),
        Offset(center.dx, map.plot.bottom),
        Paint()
          ..color = colors.grid
          ..strokeWidth = 1,
      )
      ..drawCircle(center, 6, Paint()..color = colors.surface)
      ..drawCircle(
        center,
        6,
        Paint()
          ..color = tone == FbSeriesTone.muted
              ? colors.primary
              : colors.series(tone)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
  }

  static Path _dashed(Path source, double dash, double gap) {
    final out = Path();
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        out.addPath(
          metric.extractPath(
            distance,
            math.min(distance + dash, metric.length),
          ),
          Offset.zero,
        );
        distance += dash + gap;
      }
    }
    return out;
  }

  @override
  bool shouldRepaint(TimeSeriesPainter oldDelegate) =>
      !identical(oldDelegate.series, series) ||
      !identical(oldDelegate.bands, bands) ||
      !identical(oldDelegate.periods, periods) ||
      oldDelegate.goal != goal ||
      oldDelegate.selected != selected ||
      oldDelegate.range != range ||
      oldDelegate.colors != colors ||
      oldDelegate.direction != direction;
}
