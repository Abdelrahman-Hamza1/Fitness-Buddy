import 'dart:math' as math;

import 'package:fb_design_system/src/charts/bar_geometry.dart';
import 'package:fb_design_system/src/charts/chart_types.dart';
import 'package:fb_design_system/src/charts/nice_scale.dart';
import 'package:fb_design_system/src/charts/time_series_painter.dart'
    show ChartLabelCache;
import 'package:fb_design_system/src/tokens/colors.dart';
import 'package:fb_design_system/src/tokens/spacing.dart';
import 'package:flutter/semantics.dart' show SemanticsProperties;
import 'package:material_ui/material_ui.dart';

/// The token colours a bar chart draws with (A16 D5), resolved from the
/// theme: one tone for the bars, the neutral over-target grey (never red),
/// a dark target mark.
@immutable
final class BarChartColors {
  /// Reads the roles from [scheme] and [fb] for [tone].
  factory of(ColorScheme scheme, FbColors fb, FbBarTone tone) =>
      BarChartColors._(
        bar: switch (tone) {
          FbBarTone.primary => scheme.primary,
          FbBarTone.protein => fb.protein,
          FbBarTone.carbs => fb.carbs,
          FbBarTone.fat => fb.fat,
          FbBarTone.fiber => fb.fiber,
        },
        over: fb.overTarget,
        target: scheme.onSurface,
        missing: scheme.outline,
        grid: scheme.outlineVariant,
        selection: scheme.surfaceContainerHighest,
      );

  const new _({
    required this.bar,
    required this.over,
    required this.target,
    required this.missing,
    required this.grid,
    required this.selection,
  });

  /// The bars.
  final Color bar;

  /// The part above the target.
  final Color over;

  /// The target mark.
  final Color target;

  /// The baseline tick of a bar without a value.
  final Color missing;

  /// Grid lines.
  final Color grid;

  /// The selected slot's background.
  final Color selection;

  @override
  bool operator ==(Object other) =>
      other is BarChartColors &&
      other.bar == bar &&
      other.over == over &&
      other.target == target &&
      other.missing == missing &&
      other.grid == grid &&
      other.selection == selection;

  @override
  int get hashCode => Object.hash(bar, over, target, missing, grid, selection);
}

/// Draws an `FbBarChart` (TD-012: `CustomPainter`, no library).
final class BarChartPainter extends CustomPainter {
  /// Creates the painter.
  new({
    required this.bars,
    required this.selected,
    required this.colors,
    required this.labels,
    required this.direction,
    required this.formatValue,
    required this.formatLabel,
    required this.compact,
    this.describeBar,
    this.onSelectBar,
  });

  /// What to draw, in reading order.
  final List<FbBar> bars;

  /// The selected bar, or null.
  final int? selected;

  /// Token colours.
  final BarChartColors colors;

  /// Cached label layout.
  final ChartLabelCache labels;

  /// Reading direction (LC-003).
  final TextDirection direction;

  /// Formats axis values (already translated).
  final String Function(double value) formatValue;

  /// The label under bar `index` (already translated), or null for none.
  final String? Function(int index)? formatLabel;

  /// A short chart: only the top value label, no bar labels.
  final bool compact;

  /// Bar `index` in words for its semantics node, or null for none.
  final String Function(int index)? describeBar;

  /// Selects bar `index` from its semantics node (a screen reader's tap),
  /// or null when the chart isn't selectable.
  final void Function(int index)? onSelectBar;

  /// The geometry of the last paint, for hit-testing taps.
  BarGeometry? lastGeometry;

  /// The value-to-y mapping of the last paint (tests).
  double Function(double value)? lastY;

  /// The value scale, the plot and the bar slots for [size], or null when
  /// there is no room. Shared by painting and the per-bar semantics.
  ({NiceScale scale, BarGeometry geometry, bool hasLabels})? _layout(
    Size size,
  ) {
    final scale = barScale(bars);
    final ticks = scale.ticks;
    final shown = compact ? [ticks.last] : ticks;
    var gutter = 0.0;
    for (final tick in shown) {
      gutter = math.max(gutter, labels.of(formatValue(tick)).width);
    }
    gutter += FbSpace.s2;
    final lineHeight = labels.of(formatValue(ticks.last)).height;
    final top = lineHeight / 2;
    final hasLabels = !compact && formatLabel != null;
    final bottom = hasLabels
        ? size.height - lineHeight - FbSpace.s1
        : size.height - FbSpace.s1;
    final plot = direction == TextDirection.ltr
        ? Rect.fromLTRB(gutter, top, size.width - FbSpace.s1, bottom)
        : Rect.fromLTRB(FbSpace.s1, top, size.width - gutter, bottom);
    if (plot.width <= 0 || plot.height <= 0) return null;
    return (
      scale: scale,
      geometry: BarGeometry(
        plot: plot,
        count: bars.length,
        direction: direction,
      ),
      hasLabels: hasLabels,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final layout = _layout(size);
    if (layout == null) return;
    final (:scale, :geometry, :hasLabels) = layout;
    lastGeometry = geometry;
    final plot = geometry.plot;
    final ticks = scale.ticks;
    final shown = compact ? [ticks.last] : ticks;
    double y(double value) => plot.bottom - scale.fraction(value) * plot.height;
    lastY = y;

    _paintSelection(canvas, geometry);
    _paintGrid(canvas, plot, ticks, shown, y);
    for (final (i, bar) in bars.indexed) {
      _paintBar(canvas, geometry, i, bar, y);
    }
    if (hasLabels) _paintLabels(canvas, geometry, size);
  }

  /// One semantics node per bar (A16 review): each bar's slot with its
  /// words, so a screen reader can read every bar in reading order whether
  /// or not the chart is selectable. Placeholders (days to come) have none.
  @override
  SemanticsBuilderCallback? get semanticsBuilder => describeBar == null
      ? null
      : (size) {
          final layout = _layout(size);
          if (layout == null) return const [];
          final geometry = layout.geometry;
          final plot = geometry.plot;
          final half = geometry.slotWidth / 2;
          return [
            for (final (i, bar) in bars.indexed)
              if (!bar.placeholder)
                CustomPainterSemantics(
                  key: ValueKey<int>(i),
                  rect: Rect.fromLTRB(
                    geometry.centerX(i) - half,
                    plot.top,
                    geometry.centerX(i) + half,
                    plot.bottom,
                  ),
                  properties: SemanticsProperties(
                    label: describeBar!(i),
                    textDirection: direction,
                    selected: onSelectBar == null ? null : selected == i,
                    button: onSelectBar != null,
                    onTap: onSelectBar == null ? null : () => onSelectBar!(i),
                  ),
                ),
          ];
        };

  @override
  bool shouldRebuildSemantics(BarChartPainter oldDelegate) =>
      !identical(oldDelegate.bars, bars) ||
      oldDelegate.selected != selected ||
      oldDelegate.direction != direction ||
      oldDelegate.compact != compact ||
      // A new callback may say new words for the same bars (A16 review 2).
      !identical(oldDelegate.describeBar, describeBar) ||
      oldDelegate.onSelectBar != onSelectBar;

  void _paintSelection(Canvas canvas, BarGeometry geometry) {
    final index = selected;
    if (index == null || index < 0 || index >= bars.length) return;
    final x = geometry.centerX(index);
    final half = geometry.slotWidth / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(
          x - half,
          geometry.plot.top,
          x + half,
          geometry.plot.bottom,
        ),
        const Radius.circular(FbSpace.s1),
      ),
      Paint()..color = colors.selection,
    );
  }

  void _paintGrid(
    Canvas canvas,
    Rect plot,
    List<double> ticks,
    List<double> shown,
    double Function(double) y,
  ) {
    final paint = Paint()
      ..color = colors.grid
      ..strokeWidth = 1;
    for (final tick in ticks) {
      final ty = y(tick).roundToDouble() + 0.5;
      canvas.drawLine(Offset(plot.left, ty), Offset(plot.right, ty), paint);
    }
    for (final tick in shown) {
      final ty = y(tick).roundToDouble() + 0.5;
      final text = labels.of(formatValue(tick));
      final x = direction == TextDirection.ltr
          ? plot.left - FbSpace.s2 - text.width
          : plot.right + FbSpace.s2;
      text.paint(canvas, Offset(x, ty - text.height / 2));
    }
  }

  void _paintBar(
    Canvas canvas,
    BarGeometry geometry,
    int index,
    FbBar bar,
    double Function(double) y,
  ) {
    if (bar.placeholder) return;
    final x = geometry.centerX(index);
    final half = geometry.barWidth / 2;
    final base = geometry.plot.bottom;
    final value = bar.value;
    if (value == null) {
      // No data: a short baseline tick, never a zero bar (TG-032).
      canvas.drawLine(
        Offset(x - half, base - 1),
        Offset(x + half, base - 1),
        Paint()
          ..color = colors.missing
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    } else if (value > 0) {
      final target = bar.target;
      final split = target == null ? value : math.min(value, target);
      final barColor = bar.style == FbBarStyle.faint
          ? colors.bar.withValues(alpha: 0.45)
          : colors.bar;
      final under = Rect.fromLTRB(x - half, y(split), x + half, base);
      final whole = Rect.fromLTRB(x - half, y(value), x + half, base);
      final over = target != null && value > target
          ? Rect.fromLTRB(x - half, y(value), x + half, y(target))
          : null;
      const radius = Radius.circular(3);
      final clip = RRect.fromRectAndRadius(whole, radius);
      canvas
        ..save()
        ..clipRRect(clip);
      if (bar.style == FbBarStyle.hatched) {
        _hatch(canvas, under, colors.bar);
        if (over != null) _hatch(canvas, over, colors.over);
      } else {
        canvas.drawRect(under, Paint()..color = barColor);
        if (over != null) canvas.drawRect(over, Paint()..color = colors.over);
      }
      canvas.restore();
      if (bar.style == FbBarStyle.hatched) {
        canvas.drawRRect(
          clip.deflate(0.75),
          Paint()
            ..color = colors.bar
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }
    final target = bar.target;
    if (target != null) {
      final ty = y(target);
      final reach = half + math.min(4, geometry.slotWidth * 0.15);
      canvas.drawLine(
        Offset(x - reach, ty),
        Offset(x + reach, ty),
        Paint()
          ..color = colors.target
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  /// Diagonal hatching over [rect] on a faint fill of [color].
  void _hatch(Canvas canvas, Rect rect, Color color) {
    canvas
      ..drawRect(rect, Paint()..color = color.withValues(alpha: 0.16))
      ..save()
      ..clipRect(rect);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    const gap = 5.0;
    for (var d = -rect.height; d < rect.width; d += gap) {
      canvas.drawLine(
        Offset(rect.left + d, rect.bottom),
        Offset(rect.left + d + rect.height, rect.top),
        paint,
      );
    }
    canvas.restore();
  }

  void _paintLabels(Canvas canvas, BarGeometry geometry, Size size) {
    final format = formatLabel!;
    // Labels never overlap: one that would touch the previous one (in
    // reading order) is skipped.
    double? previousEdge;
    for (var i = 0; i < bars.length; i++) {
      final label = format(i);
      if (label == null) continue;
      final text = labels.of(label);
      final left = (geometry.centerX(i) - text.width / 2)
          .clamp(0.0, math.max(0.0, size.width - text.width))
          .toDouble();
      final leading = direction == TextDirection.ltr ? left : left + text.width;
      if (previousEdge != null &&
          (direction == TextDirection.ltr
              ? leading < previousEdge + FbSpace.s1
              : leading > previousEdge - FbSpace.s1)) {
        continue;
      }
      text.paint(canvas, Offset(left, geometry.plot.bottom + FbSpace.s1));
      previousEdge = direction == TextDirection.ltr ? left + text.width : left;
    }
  }

  @override
  bool shouldRepaint(BarChartPainter oldDelegate) =>
      !identical(oldDelegate.bars, bars) ||
      oldDelegate.selected != selected ||
      oldDelegate.colors != colors ||
      oldDelegate.direction != direction ||
      oldDelegate.compact != compact;
}
