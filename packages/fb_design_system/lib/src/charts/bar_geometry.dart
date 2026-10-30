import 'dart:math' as math;

import 'package:fb_design_system/src/charts/chart_types.dart';
import 'package:fb_design_system/src/charts/nice_scale.dart';
import 'package:material_ui/material_ui.dart';

/// The value scale of a bar chart (A16 D7): from zero to a nice top over
/// every value **and** target, so a target mark is always on the chart.
NiceScale barScale(Iterable<FbBar> bars) {
  var high = 0.0;
  for (final bar in bars) {
    for (final v in [bar.value, bar.target]) {
      if (v != null && v.isFinite) high = math.max(high, v);
    }
  }
  if (high <= 0) high = 1;
  // A little headroom so the tallest bar's target mark isn't on the edge.
  return NiceScale.fit([0, high * 1.04], padding: 0);
}

/// Where the bars of a chart sit (A16 D7): equal slots in reading direction
/// (LC-003), the first bar at the start edge, so in right-to-left layouts it
/// is at the right.
@immutable
final class BarGeometry {
  /// [count] slots across [plot].
  const new({required this.plot, required this.count, required this.direction});

  /// The drawing area.
  final Rect plot;

  /// How many bars.
  final int count;

  /// The reading direction.
  final TextDirection direction;

  /// The width of one slot.
  double get slotWidth => count == 0 ? plot.width : plot.width / count;

  /// The width of a bar inside its slot.
  double get barWidth => math.max(2, math.min(slotWidth * 0.62, 32));

  /// The centre x of bar [index].
  double centerX(int index) {
    final offset = (index + 0.5) * slotWidth;
    return direction == TextDirection.ltr
        ? plot.left + offset
        : plot.right - offset;
  }

  /// The bar whose centre is nearest to [dx], within half a slot or
  /// [tolerance] logical pixels, whichever is larger; null when none is.
  int? nearest(double dx, {double tolerance = 24}) {
    if (count == 0) return null;
    final fromStart = direction == TextDirection.ltr
        ? dx - plot.left
        : plot.right - dx;
    final index = (fromStart / slotWidth - 0.5).round().clamp(0, count - 1);
    final reach = math.max(tolerance, slotWidth / 2);
    return (centerX(index) - dx).abs() <= reach ? index : null;
  }
}
