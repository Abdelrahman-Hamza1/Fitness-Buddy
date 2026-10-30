import 'package:fb_domain/src/body/measurement.dart';
import 'package:fb_domain/src/body/smooth_daily.dart';
import 'package:fb_domain/src/body/trend_weight.dart';
import 'package:fb_domain/src/time/local_date.dart';

/// One day of a measurement trend: the day choice and the trend after it.
final class MeasurementTrendPoint {
  /// The trend [trend] on [localDate] after the measurement
  /// [measurementId].
  const new({
    required this.localDate,
    required this.measurementId,
    required this.trend,
  });

  /// The day.
  final LocalDate localDate;

  /// The day's earliest measurement.
  final String measurementId;

  /// The trend after it (cm, or %), unrounded. User content.
  final double trend;

  @override
  bool operator ==(Object other) =>
      other is MeasurementTrendPoint &&
      other.localDate == localDate &&
      other.measurementId == measurementId &&
      other.trend == trend;

  @override
  int get hashCode => Object.hash(localDate, measurementId, trend);

  /// Never the value.
  @override
  String toString() => 'MeasurementTrendPoint($localDate, $measurementId)';
}

/// One type's measurements for its graph (WB-041, WB-042, A15b D16).
///
/// Every measurement is a point. The trend is [smoothDaily] (TD-088) over
/// the day choices (the earliest measurement of each `localDate`, ties by
/// ID), shown only when the type has at least [minTrendPoints] entries
/// (WB-041: points, not days). No rate and no projection.
final class MeasurementSeries {
  new _(
    Iterable<Measurement> points,
    Iterable<Measurement> dayChoices,
    Iterable<MeasurementTrendPoint>? trend,
  ) : points = List.unmodifiable(points),
      dayChoices = List.unmodifiable(dayChoices),
      trend = trend == null ? null : List.unmodifiable(trend);

  /// The series of [measurements] (one type's live rows, any order), with
  /// the smoothing [config] ([TrendWeightConfig.standard] by default).
  factory of(Iterable<Measurement> measurements, {TrendWeightConfig? config}) {
    final points = measurements.toList()..sort(_byTime);
    final byDay = <LocalDate, Measurement>{};
    for (final point in points) {
      byDay.putIfAbsent(point.localDate, () => point);
    }
    final days = byDay.values.toList()
      ..sort((a, b) => a.localDate.compareTo(b.localDate));
    if (points.length < minTrendPoints) {
      return MeasurementSeries._(points, days, null);
    }
    final smoothed = smoothDaily([
      for (final day in days) (day.localDate, day.value),
    ], config ?? TrendWeightConfig.standard);
    return MeasurementSeries._(points, days, [
      for (final (i, day) in days.indexed)
        MeasurementTrendPoint(
          localDate: day.localDate,
          measurementId: day.id,
          trend: smoothed[i],
        ),
    ]);
  }

  /// The fewest entries that show a trend line (WB-041).
  static const int minTrendPoints = 5;

  /// Every measurement, oldest first by measured time (ties by ID).
  /// Unmodifiable.
  final List<Measurement> points;

  /// The earliest measurement of each day, by date. Unmodifiable.
  final List<Measurement> dayChoices;

  /// The trend, one point per day choice, or `null` below
  /// [minTrendPoints] entries. Unmodifiable.
  final List<MeasurementTrendPoint>? trend;

  /// The newest measurement, or `null` when there is none.
  Measurement? get latest => points.isEmpty ? null : points.last;

  /// The oldest measurement, or `null` when there is none.
  Measurement? get first => points.isEmpty ? null : points.first;

  /// The latest value minus the first (cm, or %), or `null` with fewer than
  /// two entries. Unrounded.
  double? get change =>
      points.length < 2 ? null : points.last.value - points.first.value;

  static int _byTime(Measurement a, Measurement b) {
    final byTime = a.time.occurredAtUtc.compareTo(b.time.occurredAtUtc);
    return byTime != 0 ? byTime : a.id.compareTo(b.id);
  }

  @override
  String toString() =>
      'MeasurementSeries(${points.length} points, '
      'trend: ${trend == null ? 'no' : 'yes'})';
}
