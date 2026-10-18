import 'package:material_ui/material_ui.dart';

/// One measurement at a moment.
@immutable
class FbPoint {
  /// Creates a point.
  const new(this.at, this.value);

  /// When.
  final DateTime at;

  /// The value, in the series' unit.
  final double value;
}

/// How a series is drawn.
enum FbSeriesStyle {
  /// A line through the points.
  line,

  /// Only the points.
  points,

  /// A line with the points marked.
  linePoints,
}

/// A series of points, oldest first.
@immutable
class FbSeries {
  /// Creates a series.
  const new({
    required this.points,
    this.style = FbSeriesStyle.linePoints,
    this.semanticLabel,
  });

  /// The points.
  final List<FbPoint> points;

  /// How to draw them.
  final FbSeriesStyle style;

  /// A short description for screen readers (already translated).
  final String? semanticLabel;
}

/// The lower and upper edge of a band at one moment.
@immutable
class FbBandPoint {
  /// Creates a band point.
  const new(this.at, {required this.lower, required this.upper})
    : assert(lower <= upper, 'lower must not exceed upper');

  /// When.
  final DateTime at;

  /// The lower edge.
  final double lower;

  /// The upper edge.
  final double upper;
}

/// A shaded range over time, e.g. the likely range around a trend.
@immutable
class FbBand {
  /// Creates a band.
  const new({required this.points});

  /// The edges, oldest first.
  final List<FbBandPoint> points;
}

/// A horizontal goal line.
@immutable
class FbGoalLine {
  /// Creates a goal line at [value].
  const new({required this.value, this.label});

  /// Where the line sits.
  final double value;

  /// Its (already translated) label.
  final String? label;
}

/// The time window a chart shows.
@immutable
class FbChartRange {
  /// Creates a range from [start] to [end].
  const new({required this.start, required this.end})
    : assert(start != end, 'a range needs some length');

  /// The earliest moment shown.
  final DateTime start;

  /// The latest moment shown.
  final DateTime end;
}
