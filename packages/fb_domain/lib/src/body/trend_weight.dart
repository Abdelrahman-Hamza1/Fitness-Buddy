import 'dart:math' as math;

import 'package:fb_domain/src/body/weigh_in.dart';
import 'package:fb_domain/src/time/local_date.dart';

/// The constants of the trend weight (A14 D1/D2, TD-088). The trend is
/// derived, never stored, so retuning them needs no migration.
final class TrendWeightConfig {
  /// The defaults are the A14 plan's. Throws an `ArgumentError` for a
  /// non-positive half-life, a cap outside (0, 1], or a negative or zero
  /// day count.
  new({
    this.halfLifeDays = 7,
    this.maxAlpha = 0.75,
    this.rateWindowDays = 28,
    this.minRateSpanDays = 14,
    this.staleAfterDays = 28,
  }) {
    if (!(halfLifeDays > 0) || !halfLifeDays.isFinite) {
      throw ArgumentError.value(halfLifeDays, 'halfLifeDays', 'must be > 0');
    }
    if (!(maxAlpha > 0 && maxAlpha <= 1)) {
      throw ArgumentError.value(maxAlpha, 'maxAlpha', 'must be in (0, 1]');
    }
    for (final (value, name) in [
      (rateWindowDays, 'rateWindowDays'),
      (minRateSpanDays, 'minRateSpanDays'),
      (staleAfterDays, 'staleAfterDays'),
    ]) {
      if (value < 1) throw ArgumentError.value(value, name, 'must be >= 1');
    }
  }

  /// The A14 defaults.
  static final TrendWeightConfig standard = TrendWeightConfig();

  /// After this many days a weigh-in counts half (7: a weekly weigh-in
  /// moves the trend halfway, a daily one 9.4 %).
  final double halfLifeDays;

  /// The most one weigh-in can move the trend, after any gap (0.75: a
  /// single weigh-in never moves it all the way, WB-010).
  final double maxAlpha;

  /// The weekly rate compares the trend with this many days earlier (28).
  final int rateWindowDays;

  /// A shorter history gives a rate only from this span (14 days).
  final int minRateSpanDays;

  /// No rate when the last weigh-in day is this many days or more before
  /// the evaluation date (28: outside "the last 4 weeks", A14 PA2).
  final int staleAfterDays;

  /// How much a weigh-in [days] (≥ 1) after the previous one counts:
  /// `min(1 − 2^(−days / halfLifeDays), maxAlpha)`.
  double alpha(int days) =>
      math.min(1 - math.pow(2, -days / halfLifeDays).toDouble(), maxAlpha);

  @override
  bool operator ==(Object other) =>
      other is TrendWeightConfig &&
      other.halfLifeDays == halfLifeDays &&
      other.maxAlpha == maxAlpha &&
      other.rateWindowDays == rateWindowDays &&
      other.minRateSpanDays == minRateSpanDays &&
      other.staleAfterDays == staleAfterDays;

  @override
  int get hashCode => Object.hash(
    halfLifeDays,
    maxAlpha,
    rateWindowDays,
    minRateSpanDays,
    staleAfterDays,
  );

  @override
  String toString() =>
      'TrendWeightConfig(halfLife $halfLifeDays d, maxAlpha $maxAlpha, '
      'rate $rateWindowDays d from $minRateSpanDays d, '
      'stale after $staleAfterDays d)';
}

/// One day of the trend: the day choice's raw value and the trend after it.
final class TrendPoint {
  /// The trend [trendKg] on [localDate] after the weigh-in [weighInId] of
  /// [rawKg].
  const new({
    required this.localDate,
    required this.weighInId,
    required this.rawKg,
    required this.trendKg,
  });

  /// The day.
  final LocalDate localDate;

  /// The day choice (WB-003).
  final String weighInId;

  /// Its value in kg. User content.
  final double rawKg;

  /// The trend after it, unrounded. User content.
  final double trendKg;

  @override
  bool operator ==(Object other) =>
      other is TrendPoint &&
      other.localDate == localDate &&
      other.weighInId == weighInId &&
      other.rawKg == rawKg &&
      other.trendKg == trendKg;

  @override
  int get hashCode => Object.hash(localDate, weighInId, rawKg, trendKg);

  /// Never the values.
  @override
  String toString() => 'TrendPoint($localDate, $weighInId)';
}

/// The trend as of a date (WB-011, A14 D2/D9).
final class WeightAsOf {
  /// See [WeightTrend.asOf].
  const new({
    this.trendKg,
    this.weeklyRateKg,
    this.lastWeighIn,
    this.isStale = false,
  });

  /// No weigh-in on or before the date.
  static const WeightAsOf none = WeightAsOf();

  /// The trend on the date, or `null` before the first weigh-in.
  final double? trendKg;

  /// The trend's change per week in kg (negative: losing), or `null`: no
  /// weigh-in yet, under [TrendWeightConfig.minRateSpanDays] of history, or
  /// [isStale].
  final double? weeklyRateKg;

  /// The last weigh-in day on or before the date: its day choice's raw
  /// value and the trend there.
  final TrendPoint? lastWeighIn;

  /// Whether [lastWeighIn] is [TrendWeightConfig.staleAfterDays] or more
  /// before the date, so outside the last 4 weeks ("from {date}", no rate;
  /// A14 PA2).
  final bool isStale;

  @override
  bool operator ==(Object other) =>
      other is WeightAsOf &&
      other.trendKg == trendKg &&
      other.weeklyRateKg == weeklyRateKg &&
      other.lastWeighIn == lastWeighIn &&
      other.isStale == isStale;

  @override
  int get hashCode => Object.hash(trendKg, weeklyRateKg, lastWeighIn, isStale);

  /// Never the values.
  @override
  String toString() =>
      'WeightAsOf(${lastWeighIn?.localDate}, '
      'rate: ${weeklyRateKg == null ? 'none' : 'yes'}, stale: $isStale)';
}

/// The smoothed trend over a user's weigh-ins (WB-010–012, A14 D1/D2).
final class WeightTrend {
  new _(this.config, Iterable<TrendPoint> points)
    : points = List.unmodifiable(points);

  /// What it was computed with.
  final TrendWeightConfig config;

  /// One point per weigh-in day, oldest first. Unmodifiable.
  final List<TrendPoint> points;

  /// The newest point, or `null` without weigh-ins. Its trend is the app's
  /// current weight (A14 PA1).
  TrendPoint? get latest => points.isEmpty ? null : points.last;

  /// The last point on or before [date], or `null`.
  TrendPoint? pointOn(LocalDate date) {
    // The first index after [date]: the points are sorted by distinct days.
    var low = 0;
    var high = points.length;
    while (low < high) {
      final mid = (low + high) >> 1;
      if (points[mid].localDate.isAfter(date)) {
        high = mid;
      } else {
        low = mid + 1;
      }
    }
    return low == 0 ? null : points[low - 1];
  }

  /// The trend on [date] (WB-022): the trend of the last weigh-in day on or
  /// before it (it holds between weigh-ins), `null` before the first.
  double? trendOn(LocalDate date) => pointOn(date)?.trendKg;

  /// The trend, the weekly rate and the last weigh-in day as of [date]
  /// (A14 D2). With `D` the last weigh-in day on or before [date]:
  /// - **stale** when `date − D` ≥ [TrendWeightConfig.staleAfterDays]: no
  ///   rate;
  /// - else, with a full window, `(T(D) − T(D − 28)) · 7 / 28`;
  /// - else, with a span `s = D − first` of at least
  ///   [TrendWeightConfig.minRateSpanDays], `(T(D) − T(first)) · 7 / s`;
  /// - else no rate yet.
  WeightAsOf asOf(LocalDate date) {
    final last = pointOn(date);
    if (last == null) return WeightAsOf.none;
    final isStale = last.localDate.daysUntil(date) >= config.staleAfterDays;
    double? rate;
    if (!isStale) {
      final first = points.first;
      final windowStart = last.localDate.plusDays(-config.rateWindowDays);
      if (!first.localDate.isAfter(windowStart)) {
        rate =
            (last.trendKg - trendOn(windowStart)!) *
            _daysPerWeek /
            config.rateWindowDays;
      } else {
        final span = first.localDate.daysUntil(last.localDate);
        if (span >= config.minRateSpanDays) {
          rate = (last.trendKg - first.trendKg) * _daysPerWeek / span;
        }
      }
    }
    return WeightAsOf(
      trendKg: last.trendKg,
      weeklyRateKg: rate,
      lastWeighIn: last,
      isStale: isStale,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is WeightTrend &&
      other.config == config &&
      other.points.length == points.length &&
      other.points.indexed.every((pair) => pair.$2 == points[pair.$1]);

  @override
  int get hashCode => Object.hash(config, Object.hashAll(points));

  @override
  String toString() => 'WeightTrend(${points.length} points)';
}

/// Computes the [WeightTrend] (WB-010, A14 D1, TD-088): a time-aware
/// exponential smoothing over one weigh-in per day.
///
/// The day choices ([DayChoice.of]) are taken in date order. The first sets
/// the trend; each next one, `Δd` days after the previous, moves it by
/// `α(Δd)` of the distance ([TrendWeightConfig.alpha]): a convex
/// combination, so the trend never leaves the range of its inputs and a
/// constant series stays constant. Rows whose kg isn't readable
/// ([WeighIn.isReadable]: not finite, not positive or absurdly large;
/// possible only via sync) are skipped before the day choice.
final class TrendWeight {
  /// With [config] ([TrendWeightConfig.standard] by default).
  new([TrendWeightConfig? config])
    : config = config ?? TrendWeightConfig.standard;

  /// The constants.
  final TrendWeightConfig config;

  /// The trend over [weighIns] (live rows, any order, repeats allowed).
  WeightTrend compute(Iterable<WeighIn> weighIns) {
    final days = DayChoice.of(weighIns.where((weighIn) => weighIn.isReadable));
    final points = <TrendPoint>[];
    for (final day in days) {
      final previous = points.isEmpty ? null : points.last;
      final trend = previous == null
          ? day.kg
          : previous.trendKg +
                config.alpha(previous.localDate.daysUntil(day.localDate)) *
                    (day.kg - previous.trendKg);
      points.add(
        TrendPoint(
          localDate: day.localDate,
          weighInId: day.id,
          rawKg: day.kg,
          trendKg: trend,
        ),
      );
    }
    return WeightTrend._(config, points);
  }
}

const int _daysPerWeek = 7;
