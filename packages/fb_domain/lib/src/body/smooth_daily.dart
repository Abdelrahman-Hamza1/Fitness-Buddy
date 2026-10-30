import 'package:fb_domain/src/body/trend_weight.dart';
import 'package:fb_domain/src/time/local_date.dart';

/// The time-aware exponential smoothing of every body series (A14 D1,
/// TD-088; A15b D16): the weight trend and the measurement trends.
///
/// [dayValues] are one value per day, sorted by strictly increasing date
/// (the caller's day choices). The first value sets the trend; each next
/// one, `Δd` days after the previous, moves it by `α(Δd)` of the distance
/// ([TrendWeightConfig.alpha]). Returns the trend after each day, in the
/// same order. Throws an `ArgumentError` when the dates aren't strictly
/// increasing.
List<double> smoothDaily(
  List<(LocalDate, double)> dayValues,
  TrendWeightConfig config,
) {
  final trend = <double>[];
  LocalDate? previousDay;
  for (final (day, value) in dayValues) {
    if (previousDay == null) {
      trend.add(value);
    } else {
      if (!day.isAfter(previousDay)) {
        throw ArgumentError.value(
          day,
          'dayValues',
          'dates must be strictly increasing',
        );
      }
      final last = trend.last;
      trend.add(
        last + config.alpha(previousDay.daysUntil(day)) * (value - last),
      );
    }
    previousDay = day;
  }
  return trend;
}
