import 'package:fb_design_system/src/charts/chart_types.dart';
import 'package:fb_design_system/src/charts/lttb.dart';
import 'package:material_ui/material_ui.dart';

/// Maps time to x along the reading direction (LC-003, A15 PA2): the
/// window's start sits at the [plot]'s start edge, so in right-to-left
/// layouts the oldest moment is at the right. Values map bottom up.
@immutable
final class ChartMapping {
  /// The mapping of the window (ms since epoch, naive wall-clock) and
  /// [minValue]–[maxValue] onto [plot].
  const new({
    required this.plot,
    required this.startMs,
    required this.endMs,
    required this.minValue,
    required this.maxValue,
    required this.direction,
  });

  /// The drawing area.
  final Rect plot;

  /// The window start.
  final double startMs;

  /// The window end.
  final double endMs;

  /// The value at the bottom.
  final double minValue;

  /// The value at the top.
  final double maxValue;

  /// The reading direction.
  final TextDirection direction;

  /// +1 when time runs to the right, −1 when it runs to the left.
  double get sign => direction == TextDirection.ltr ? 1 : -1;

  /// The x of [ms].
  double x(double ms) {
    final f = (ms - startMs) / (endMs - startMs);
    return direction == TextDirection.ltr
        ? plot.left + f * plot.width
        : plot.right - f * plot.width;
  }

  /// The x of [at].
  double xOf(DateTime at) => x(at.millisecondsSinceEpoch.toDouble());

  /// The y of [value].
  double y(double value) =>
      plot.bottom - (value - minValue) / (maxValue - minValue) * plot.height;

  /// The milliseconds one logical pixel spans.
  double get msPerPixel => (endMs - startMs) / plot.width;
}

/// The indices [first, last) of [points] inside [startMs]–[endMs], widened
/// by one on each side so lines run to the plot edges. Binary search: the
/// points are sorted by time.
(int, int) visibleSlice(List<FbPoint> points, double startMs, double endMs) {
  final first = _lowerBound(points, startMs);
  final last = _lowerBound(points, endMs, inclusive: true);
  return (first > 0 ? first - 1 : 0, last < points.length ? last + 1 : last);
}

int _lowerBound(List<FbPoint> points, double ms, {bool inclusive = false}) {
  var low = 0;
  var high = points.length;
  while (low < high) {
    final mid = (low + high) >> 1;
    final at = points[mid].at.millisecondsSinceEpoch;
    if (inclusive ? at <= ms : at < ms) {
      low = mid + 1;
    } else {
      high = mid;
    }
  }
  return low;
}

/// The values the value scale fits for [points] in [startMs]–[endMs]
/// (A15a review): the points strictly inside the window, and for a line
/// ([isLine]) also its value where it crosses each window edge, interpolated
/// between the neighbours on either side. A dot outside the window never
/// stretches the scale.
List<double> visibleValues(
  List<FbPoint> points,
  double startMs,
  double endMs, {
  required bool isLine,
}) {
  final first = _lowerBound(points, startMs);
  final last = _lowerBound(points, endMs, inclusive: true);
  final values = [for (var i = first; i < last; i++) points[i].value];
  if (!isLine) return values;
  double? edge(int before, double ms) {
    if (before < 0 || before + 1 >= points.length) return null;
    final a = points[before];
    final b = points[before + 1];
    final aMs = a.at.millisecondsSinceEpoch;
    final bMs = b.at.millisecondsSinceEpoch;
    if (!(aMs < ms && ms < bMs)) return null;
    return a.value + (b.value - a.value) * (ms - aMs) / (bMs - aMs);
  }

  return [?edge(first - 1, startMs), ...values, ?edge(last - 1, endMs)];
}

/// The indices of [points] to draw in the visible slice (A15 D4): LTTB
/// down to [maxPoints] (a line: one vertex per logical pixel; dots: one per
/// three), the whole slice when it is smaller.
List<int> drawnIndices(
  List<FbPoint> points,
  double startMs,
  double endMs,
  int maxPoints,
) {
  final (first, last) = visibleSlice(points, startMs, endMs);
  final count = last - first;
  if (count <= maxPoints) {
    return List<int>.generate(count, (i) => first + i);
  }
  final xs = List<double>.generate(
    count,
    (i) => points[first + i].at.millisecondsSinceEpoch.toDouble(),
  );
  final ys = List<double>.generate(count, (i) => points[first + i].value);
  return [for (final i in lttbIndices(xs, ys, maxPoints)) first + i];
}

/// The nearest selectable point to [position] within [tolerance] logical
/// pixels, searched in the full data (A15 PA8), or null.
FbPointRef? hitTest(
  List<FbSeries> series,
  ChartMapping mapping,
  Offset position, {
  double tolerance = 24,
}) {
  FbPointRef? best;
  var bestDistance = tolerance;
  final halfWindow = tolerance * mapping.msPerPixel;
  // The time under the finger, whatever the direction.
  final f = (position.dx - mapping.plot.left) / mapping.plot.width;
  final ms = mapping.direction == TextDirection.ltr
      ? mapping.startMs + f * (mapping.endMs - mapping.startMs)
      : mapping.endMs - f * (mapping.endMs - mapping.startMs);
  for (final (index, s) in series.indexed) {
    if (!s.selectable) continue;
    final (first, last) = visibleSlice(
      s.points,
      ms - halfWindow,
      ms + halfWindow,
    );
    for (var i = first; i < last; i++) {
      final point = s.points[i];
      final key = point.key;
      if (key == null) continue;
      final distance =
          (Offset(mapping.xOf(point.at), mapping.y(point.value)) - position)
              .distance;
      if (distance <= bestDistance) {
        bestDistance = distance;
        best = FbPointRef(series: index, key: key);
      }
    }
  }
  return best;
}

/// The time-axis ticks of a window (naive wall-clock, so plain calendar
/// arithmetic on UTC fields): weekly up to ~2 months, then monthly, every
/// 2/3/6 months, then yearly, aiming at [maxTicks] or fewer.
(List<DateTime>, FbTimeStep) timeTicks(
  DateTime start,
  DateTime end, {
  int maxTicks = 5,
}) {
  final days = end.difference(start).inHours / 24;
  if (days <= 7 * maxTicks) {
    final step = days <= maxTicks ? 1 : 7;
    var day = DateTime.utc(start.year, start.month, start.day);
    if (day.isBefore(start)) day = day.add(const Duration(days: 1));
    final ticks = <DateTime>[];
    for (; !day.isAfter(end); day = day.add(Duration(days: step))) {
      ticks.add(day);
    }
    return (ticks, FbTimeStep.day);
  }
  final months = days / 30.44;
  for (final step in const [1, 2, 3, 6]) {
    if (months / step <= maxTicks) {
      return (_monthTicks(start, end, step), FbTimeStep.month);
    }
  }
  final years = (months / 12 / maxTicks).ceil();
  final ticks = <DateTime>[];
  for (
    var year = start.year + (start.month == 1 && start.day == 1 ? 0 : 1);
    !DateTime.utc(year).isAfter(end);
    year += years
  ) {
    ticks.add(DateTime.utc(year));
  }
  return (ticks, FbTimeStep.year);
}

List<DateTime> _monthTicks(DateTime start, DateTime end, int step) {
  var month = DateTime.utc(start.year, start.month);
  if (month.isBefore(start)) month = DateTime.utc(start.year, start.month + 1);
  // Align to multiples of the step (Jan, Apr, Jul, Oct for 3).
  while ((month.month - 1) % step != 0) {
    month = DateTime.utc(month.year, month.month + 1);
  }
  final ticks = <DateTime>[];
  for (
    ;
    !month.isAfter(end);
    month = DateTime.utc(month.year, month.month + step)
  ) {
    ticks.add(month);
  }
  return ticks;
}
