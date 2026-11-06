import 'dart:ui';

/// The dash and gap lengths of every dashed outline (A63 D7, D15).
const double fbDashLength = 4;

/// The gap between dashes.
const double fbDashGap = 3;

/// [source] cut into dashes of [dash] with gaps of [gap], following each of
/// its contours (a rounded rectangle keeps its corners).
Path dashedPath(
  Path source, {
  double dash = fbDashLength,
  double gap = fbDashGap,
}) {
  final dashed = Path();
  for (final metric in source.computeMetrics()) {
    var distance = 0.0;
    while (distance < metric.length) {
      final end = distance + dash;
      dashed.addPath(
        metric.extractPath(distance, end < metric.length ? end : metric.length),
        Offset.zero,
      );
      distance = end + gap;
    }
  }
  return dashed;
}
