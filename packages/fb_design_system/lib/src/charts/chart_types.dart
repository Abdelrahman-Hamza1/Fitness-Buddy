import 'package:material_ui/material_ui.dart';

/// One measurement at a moment.
///
/// [at] is a **naive wall-clock** time: callers pass
/// `DateTime.utc(<local fields>)`, so a daylight-saving change day has no
/// gap or kink (A15 PA7).
@immutable
class FbPoint {
  /// Creates a point. [key] identifies it for selection (required on
  /// selectable series).
  const new(this.at, this.value, {this.key});

  /// When (naive wall-clock, see the class docs).
  final DateTime at;

  /// The value, in the series' unit.
  final double value;

  /// The caller's identity of the point (e.g. a row ID), handed back in an
  /// [FbPointRef] when it is selected.
  final Object? key;
}

/// How a series is drawn. Open to additions (bars, steps, per-point
/// markers) when a chart needs them (A15 D3).
enum FbSeriesStyle {
  /// A solid line through the points.
  line,

  /// Only the points (dots).
  points,

  /// A solid line with the points marked.
  linePoints,

  /// A dashed line through the points, e.g. a projection.
  dashedLine,
}

/// Which token colour a series takes. Meaning never rests on colour alone:
/// the style (solid, dashed, dots) tells series apart too (UX-071).
enum FbSeriesTone {
  /// The brand colour: the main line (e.g. the trend).
  primary,

  /// A second line next to the main one.
  secondary,

  /// Faint: raw readings behind a trend.
  muted,
}

/// A series of points, oldest first.
@immutable
class FbSeries {
  /// Creates a series.
  const new({
    required this.points,
    this.style = FbSeriesStyle.linePoints,
    this.tone = FbSeriesTone.primary,
    this.selectable = false,
    this.semanticLabel,
  });

  /// The points, sorted by [FbPoint.at].
  final List<FbPoint> points;

  /// How to draw them.
  final FbSeriesStyle style;

  /// Which colour.
  final FbSeriesTone tone;

  /// Whether a tap can select its points (each needs a [FbPoint.key]).
  final bool selectable;

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

/// A shaded range over time, e.g. the likely range around a projection.
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

  /// Its (already translated) label. When the goal is far off the visible
  /// scale it shows as an edge marker with an arrow instead of a line
  /// ([FbGoalEdge]).
  final String? label;
}

/// Where an off-scale goal sits (A15 D6).
enum FbGoalEdge {
  /// Above the visible values.
  above,

  /// Below the visible values.
  below,
}

/// How a period is shaded.
enum FbPeriodTone {
  /// The first of two alternating tints (goal phases); label at the top.
  phaseA,

  /// The second alternating tint; label at the top.
  phaseB,

  /// A highlighted period (e.g. Ramadan, A41); label at the bottom.
  highlight,
}

/// A shaded stretch of time, e.g. a goal phase.
@immutable
class FbPeriod {
  /// Creates a period from [start] to [end] (naive wall-clock).
  const new({
    required this.start,
    required this.end,
    this.tone = FbPeriodTone.phaseA,
    this.label,
  });

  /// The first moment.
  final DateTime start;

  /// The last moment.
  final DateTime end;

  /// The tint and where the label sits.
  final FbPeriodTone tone;

  /// Its (already translated) label, or none.
  final String? label;
}

/// A point picked on a chart: the series index and the point's key.
@immutable
class FbPointRef {
  /// Creates a reference.
  const new({required this.series, required this.key});

  /// The index into the chart's series.
  final int series;

  /// The point's [FbPoint.key].
  final Object key;

  @override
  bool operator ==(Object other) =>
      other is FbPointRef && other.series == series && other.key == key;

  @override
  int get hashCode => Object.hash(series, key);
}

/// The spacing of the time-axis labels, so callers format dates to fit.
enum FbTimeStep {
  /// Days or weeks apart ("12 Oct").
  day,

  /// Months apart ("Oct").
  month,

  /// Years apart ("2026").
  year,
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

  /// Its length.
  Duration get duration => end.difference(start);

  /// The same length, moved by [offset].
  FbChartRange shift(Duration offset) =>
      FbChartRange(start: start.add(offset), end: end.add(offset));

  @override
  bool operator ==(Object other) =>
      other is FbChartRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}
