import 'package:fb_domain/src/body/trend_weight.dart';
import 'package:fb_domain/src/body/weigh_in.dart';
import 'package:fb_domain/src/time/local_date.dart';
import 'package:fb_domain/src/units/units.dart';

/// The main weight number as of a day (WB-011, D-102): the latest weigh-in
/// as entered while the user weighs in rarely, the trend once they weigh in
/// often. The weekly rate always comes from the trend. Holds user data:
/// content-free [toString]s.
sealed class WeightReading {
  const new _({
    required this.lastDate,
    required this.lastKg,
    required this.lastInput,
    required this.weeklyRateKg,
    required this.isStale,
  });

  /// The reading as of [date] over [trend] (computed from [weighIns]), or
  /// `null` before the first weigh-in. Fewer than [frequentMin] weigh-in
  /// days in [date] and the [windowDays] − 1 days before → a
  /// [LatestWeightReading]; else a [TrendWeightReading]. Several weigh-ins
  /// on a day count once: the trend's points are the day choices (WB-003).
  /// [weighIns] give the typed value of the day choice (TD-017); a choice
  /// missing from them reads in kg.
  static WeightReading? of({
    required WeightTrend trend,
    required Iterable<WeighIn> weighIns,
    required LocalDate date,
  }) {
    final asOf = trend.asOf(date);
    final last = asOf.lastWeighIn;
    if (last == null) return null;
    final from = date.plusDays(1 - windowDays);
    var recent = 0;
    TrendPoint? previous;
    for (final point in trend.points) {
      if (point.localDate.isAfter(date)) break;
      if (!point.localDate.isBefore(from)) recent++;
      if (point.localDate.isBefore(last.localDate)) previous = point;
    }
    WeighInInput? input;
    for (final weighIn in weighIns) {
      if (weighIn.id == last.weighInId) input = weighIn.input;
    }
    final lastInput = input ?? WeighInInput(last.rawKg, MassUnit.kilogram);
    if (recent < frequentMin) {
      return LatestWeightReading._(
        lastDate: last.localDate,
        lastKg: last.rawKg,
        lastInput: lastInput,
        changeKg: previous == null ? null : last.rawKg - previous.rawKg,
        daysSincePrevious: previous?.localDate.daysUntil(last.localDate),
        weeklyRateKg: asOf.weeklyRateKg,
        isStale: asOf.isStale,
      );
    }
    return TrendWeightReading._(
      trendKg: asOf.trendKg!,
      lastDate: last.localDate,
      lastKg: last.rawKg,
      lastInput: lastInput,
      weeklyRateKg: asOf.weeklyRateKg,
      isStale: asOf.isStale,
    );
  }

  /// The days the frequency counts over: the day and the 13 before.
  static const int windowDays = 14;

  /// Weigh-in days in the window from which the trend is the number.
  static const int frequentMin = 3;

  /// The day of the last weigh-in day on or before the date.
  final LocalDate lastDate;

  /// Its day choice in kg. User content.
  final double lastKg;

  /// The day choice as the user typed it (value and unit, TD-017).
  final WeighInInput lastInput;

  /// The trend's change per week in kg, or `null` (too little history, or
  /// stale; [WeightTrend.asOf]).
  final double? weeklyRateKg;

  /// Whether the last weigh-in is 28 days or more before the date.
  final bool isStale;

  /// The big number in kg: the latest weigh-in or the trend.
  double get mainKg;
}

/// Fewer than 3 weigh-in days in the last 14 (WB-011): the latest weigh-in
/// as entered, its day and the change since the weigh-in day before it.
final class LatestWeightReading extends WeightReading {
  const new _({
    required super.lastDate,
    required super.lastKg,
    required super.lastInput,
    required super.weeklyRateKg,
    required super.isStale,
    this.changeKg,
    this.daysSincePrevious,
  }) : super._();

  /// The latest minus the previous weigh-in day's choice, kg; `null` for
  /// the first weigh-in.
  final double? changeKg;

  /// The days between the two; `null` for the first weigh-in.
  final int? daysSincePrevious;

  @override
  double get mainKg => lastKg;

  @override
  String toString() => 'LatestWeightReading($lastDate)';
}

/// 3 or more weigh-in days in the last 14 (WB-011): the trend, with the
/// latest weigh-in next to it.
final class TrendWeightReading extends WeightReading {
  const new _({
    required this.trendKg,
    required super.lastDate,
    required super.lastKg,
    required super.lastInput,
    required super.weeklyRateKg,
    required super.isStale,
  }) : super._();

  /// The trend on the date, unrounded. User content.
  final double trendKg;

  @override
  double get mainKg => trendKg;

  @override
  String toString() => 'TrendWeightReading($lastDate)';
}
