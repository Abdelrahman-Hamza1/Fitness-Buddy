import 'dart:math' as math;

import 'package:fb_design_system/src/charts/chart_types.dart';

/// A readable value axis (A15 D6): ticks on 0.1/0.2/0.5/1/2/5/10… steps.
final class NiceScale {
  const new _({
    required this.min,
    required this.max,
    required this.step,
    this.goalEdge,
  });

  /// Fits [values] (the visible slice) with [padding] (a fraction of the
  /// span) on each side and 3–5 ticks. A [goal] is included only when it at
  /// most doubles the span; otherwise [goalEdge] says where it sits.
  factory fit(Iterable<double> values, {double? goal, double padding = 0.08}) {
    var low = double.infinity;
    var high = double.negativeInfinity;
    for (final v in values) {
      if (!v.isFinite) continue;
      low = math.min(low, v);
      high = math.max(high, v);
    }
    if (low > high) {
      if (goal == null) return const NiceScale._(min: 0, max: 1, step: 0.5);
      low = high = goal;
    }
    FbGoalEdge? edge;
    if (goal != null && goal.isFinite) {
      final span = high - low;
      final withLow = math.min(low, goal);
      final withHigh = math.max(high, goal);
      if (withHigh - withLow <= 2 * math.max(span, _minSpan)) {
        low = withLow;
        high = withHigh;
      } else {
        edge = goal > high ? FbGoalEdge.above : FbGoalEdge.below;
      }
    }
    var span = high - low;
    if (span < _minSpan) {
      final mid = (low + high) / 2;
      low = mid - _minSpan / 2;
      high = mid + _minSpan / 2;
      span = _minSpan;
    }
    low -= span * padding;
    high += span * padding;
    for (final step in _steps(high - low)) {
      final bottom = (low / step).floorToDouble() * step;
      final top = (high / step).ceilToDouble() * step;
      if (((top - bottom) / step).round() + 1 <= _maxTicks) {
        return NiceScale._(min: bottom, max: top, step: step, goalEdge: edge);
      }
    }
    throw StateError('unreachable: a step always fits'); // coverage:ignore-line
  }

  /// The smallest span a scale shows (a flat series still gets an axis).
  static const double _minSpan = 0.4;

  static const int _maxTicks = 5;

  /// 1/2/5 × 10^k steps from 0.1, starting near span / 8.
  static Iterable<double> _steps(double span) sync* {
    var magnitude = math
        .pow(10, (math.log(math.max(span / 8, 0.1)) / math.ln10).floor())
        .toDouble();
    while (true) {
      for (final m in const [1, 2, 5]) {
        final step = m * magnitude;
        if (step >= 0.1 - 1e-9) yield step;
      }
      magnitude *= 10;
    }
  }

  /// The axis bottom.
  final double min;

  /// The axis top.
  final double max;

  /// The tick spacing.
  final double step;

  /// Where an off-scale goal sits, or null when it is on the scale or absent.
  final FbGoalEdge? goalEdge;

  /// The tick values, bottom up.
  List<double> get ticks {
    final count = ((max - min) / step).round();
    return [for (var i = 0; i <= count; i++) _clean(min + i * step)];
  }

  static double _clean(double v) => (v * 1000).roundToDouble() / 1000;

  /// Where [value] sits from 0 (bottom) to 1 (top).
  double fraction(double value) => (value - min) / (max - min);
}
