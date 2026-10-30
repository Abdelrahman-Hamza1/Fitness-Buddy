import 'dart:math' as math;

import 'package:fb_domain/src/body/trend_weight.dart';
import 'package:fb_domain/src/targets/goals.dart';
import 'package:fb_domain/src/time/local_date.dart';

/// The constants of the weight projection (A15 D7/PA5). Derived, never
/// stored, so retuning needs no migration. A documented option not built:
/// widen σ for sparse data (e.g. × √(minPoints / n)).
final class ProjectionConfig {
  /// The A15 defaults.
  const new({
    this.seWindowDays = 56,
    this.minPoints = 4,
    this.minSpanDays = 14,
    this.sigmaFloorKgPerWeek = 0.1,
    this.z = 1.28,
    this.minRateKgPerWeek = 0.05,
    this.maxHorizonDays = 730,
  });

  /// The slope's standard error comes from the day choices of this many
  /// days, ending at the anchor.
  final int seWindowDays;

  /// At least this many day choices in that window…
  final int minPoints;

  /// …spanning at least this many days.
  final int minSpanDays;

  /// σ is never below this (kg/week).
  final double sigmaFloorKgPerWeek;

  /// The cone's half-width in σ (1.28: the central 80 % of a normal; a
  /// heuristic, never shown as a probability).
  final double z;

  /// Slower than this (kg/week) is flat: no projection.
  final double minRateKgPerWeek;

  /// Nothing is drawn or dated beyond this many days.
  final int maxHorizonDays;
}

/// Why no projection is shown.
enum ProjectionAbsence {
  /// No goal weight (no phase, or a weekly/monthly goal).
  noGoal,

  /// No weigh-ins, or the last one is outside the last 4 weeks.
  stale,

  /// Not enough history for a weekly rate.
  noRate,

  /// The rate is under [ProjectionConfig.minRateKgPerWeek].
  flat,

  /// The trend moves away from the goal.
  awayFromGoal,

  /// The trend has reached or passed the goal.
  reached,

  /// Too few day choices in the σ window.
  tooFewPoints,
}

/// The outcome of [WeightProjection.of].
sealed class ProjectionOutcome {
  const new _();
}

/// No projection, and why.
final class NoProjection extends ProjectionOutcome {
  /// Because of [reason].
  const new(this.reason) : super._();

  /// Why.
  final ProjectionAbsence reason;

  @override
  String toString() => 'NoProjection(${reason.name})';
}

/// The projected path to the goal with its "likely range at the current
/// rate" (WB-021, A15 D7/PA5): rate uncertainty only, a heuristic.
final class WeightProjection extends ProjectionOutcome {
  const new _({
    required this.anchorDate,
    required this.anchorKg,
    required this.kgPerWeek,
    required this.sigmaKgPerWeek,
    required this.goalKg,
    required this.drawUntil,
    required this.z,
    this.reachDate,
  }) : super._();

  /// The projection from [trend]'s latest point as of [today] towards
  /// [goalKg], or why there is none.
  ///
  /// Centre `T + r·t/7` from the latest trend point `(D, T)` with the
  /// card's weekly rate `r`; σ the OLS slope standard error of the day
  /// choices of the [ProjectionConfig.seWindowDays] days ending at `D`
  /// (floor [ProjectionConfig.sigmaFloorKgPerWeek]); edges centre ±
  /// `z·σ·t/7`, clamped at the goal; drawn until the slow edge reaches the
  /// goal or the horizon; the reach date where the centre meets the goal,
  /// none past the horizon.
  static ProjectionOutcome of({
    required WeightTrend trend,
    required LocalDate today,
    double? goalKg,
    ProjectionConfig config = const ProjectionConfig(),
  }) {
    if (goalKg == null) return const NoProjection(ProjectionAbsence.noGoal);
    final asOf = trend.asOf(today);
    final last = asOf.lastWeighIn;
    if (last == null || asOf.isStale) {
      return const NoProjection(ProjectionAbsence.stale);
    }
    final rate = asOf.weeklyRateKg;
    if (rate == null) return const NoProjection(ProjectionAbsence.noRate);
    final toGoal = goalKg - last.trendKg;
    if (toGoal.abs() < config.minRateKgPerWeek) {
      return const NoProjection(ProjectionAbsence.reached);
    }
    if (rate.abs() < config.minRateKgPerWeek) {
      return const NoProjection(ProjectionAbsence.flat);
    }
    if (rate.sign != toGoal.sign) {
      return const NoProjection(ProjectionAbsence.awayFromGoal);
    }
    final sigma = slopeStandardError(trend, last.localDate, config);
    if (sigma == null) {
      return const NoProjection(ProjectionAbsence.tooFewPoints);
    }
    final s = math.max(sigma, config.sigmaFloorKgPerWeek);
    final reachDays = (toGoal / rate * _daysPerWeek).ceil();
    // The slow edge moves towards the goal at |r| − zσ per week.
    final slowRate = rate.abs() - config.z * s;
    final slowDays = slowRate <= 0
        ? config.maxHorizonDays
        : math.min(
            (toGoal.abs() / slowRate * _daysPerWeek).ceil(),
            config.maxHorizonDays,
          );
    return WeightProjection._(
      anchorDate: last.localDate,
      anchorKg: last.trendKg,
      kgPerWeek: rate,
      sigmaKgPerWeek: s,
      goalKg: goalKg,
      z: config.z,
      drawUntil: last.localDate.plusDays(slowDays),
      reachDate: reachDays <= config.maxHorizonDays
          ? last.localDate.plusDays(reachDays)
          : null,
    );
  }

  /// The OLS slope's standard error in kg/week over the day choices in the
  /// [ProjectionConfig.seWindowDays] days ending at [anchor], or null with
  /// fewer than [ProjectionConfig.minPoints] or a span under
  /// [ProjectionConfig.minSpanDays].
  static double? slopeStandardError(
    WeightTrend trend,
    LocalDate anchor,
    ProjectionConfig config,
  ) {
    final from = anchor.plusDays(-config.seWindowDays);
    final points = [
      for (final p in trend.points)
        if (p.localDate.isAfter(from) && !p.localDate.isAfter(anchor)) p,
    ];
    if (points.length < config.minPoints) return null;
    if (points.first.localDate.daysUntil(points.last.localDate) <
        config.minSpanDays) {
      return null;
    }
    final xs = [for (final p in points) anchor.daysUntil(p.localDate) * -1.0];
    final ys = [for (final p in points) p.rawKg];
    final n = points.length;
    final meanX = xs.reduce((a, b) => a + b) / n;
    final meanY = ys.reduce((a, b) => a + b) / n;
    var sxx = 0.0;
    var sxy = 0.0;
    for (var i = 0; i < n; i++) {
      sxx += (xs[i] - meanX) * (xs[i] - meanX);
      sxy += (xs[i] - meanX) * (ys[i] - meanY);
    }
    final slope = sxy / sxx;
    final intercept = meanY - slope * meanX;
    var sse = 0.0;
    for (var i = 0; i < n; i++) {
      final residual = ys[i] - intercept - slope * xs[i];
      sse += residual * residual;
    }
    return math.sqrt(sse / (n - 2) / sxx) * _daysPerWeek;
  }

  /// The latest trend point's day.
  final LocalDate anchorDate;

  /// The trend there. User content.
  final double anchorKg;

  /// The weekly rate (the weight card's). User content.
  final double kgPerWeek;

  /// The rate's uncertainty, kg/week.
  final double sigmaKgPerWeek;

  /// The goal weight. User content.
  final double goalKg;

  /// The cone's half-width in σ.
  final double z;

  /// Where the drawing stops: the slow edge reaches the goal, or the
  /// horizon.
  final LocalDate drawUntil;

  /// Where the centre meets the goal ("Goal around {month} at your current
  /// trend"), or null beyond the horizon.
  final LocalDate? reachDate;

  /// The lower edge, centre and upper edge on [date], each clamped at the
  /// goal (no edge goes past it).
  ({double lower, double centre, double upper}) at(LocalDate date) {
    final weeks = anchorDate.daysUntil(date) / _daysPerWeek;
    final centre = anchorKg + kgPerWeek * weeks;
    final spread = z * sigmaKgPerWeek * weeks.abs();
    double clamp(double v) =>
        goalKg < anchorKg ? math.max(v, goalKg) : math.min(v, goalKg);
    return (
      lower: clamp(centre - spread),
      centre: clamp(centre),
      upper: clamp(centre + spread),
    );
  }

  /// Never the values.
  @override
  String toString() =>
      'WeightProjection($anchorDate → $drawUntil, '
      'reach: ${reachDate == null ? 'none' : 'yes'})';
}

/// The summary numbers under the weight graph (WB-023, A15 D10/PA11).
final class WeightStats {
  const new _({
    this.startDate,
    this.startKg,
    this.changeKg,
    this.monthFrom,
    this.monthChangeKg,
    this.monthTargetKg,
    this.averageSince,
    this.averageWeeklyKg,
  });

  /// The stats of [trend] on [today]. The reference is the active phase's
  /// start in [history], else the first weigh-in. [monthTargetKgPerWeek] is
  /// the rate the targets show on their TG-011 line (A13's achievable,
  /// SF-011-capped rate); it gives this month's target, pro-rated when the
  /// phase started this month.
  factory of({
    required WeightTrend trend,
    required LocalDate today,
    GoalHistory? history,
    double? monthTargetKgPerWeek,
  }) {
    final now = trend.trendOn(today);
    if (now == null) return empty;
    final phase = history?.at(today);
    final reference = phase?.start ?? trend.points.first.localDate;
    final start = _startPoint(trend, reference, today);

    final monthStart = LocalDate(today.year, today.month, 1);
    final phaseThisMonth = phase != null && !phase.start.isBefore(monthStart);
    final monthBase = phaseThisMonth
        ? start
        : _startPoint(trend, monthStart.plusDays(-1), today);
    double? monthTarget;
    if (phase != null && monthTargetKgPerWeek != null) {
      final full = monthlyKgFromWeeklyRate(monthTargetKgPerWeek, monthStart);
      final days = MonthlyGoal.daysIn(monthStart);
      monthTarget = phaseThisMonth
          ? full * (phase.start.daysUntil(monthStart.plusDays(days)) / days)
          : full;
    }

    final latest = trend.pointOn(today)!.localDate;
    final spanDays = start == null ? 0 : start.localDate.daysUntil(latest);
    return WeightStats._(
      startDate: start?.localDate,
      startKg: start?.trendKg,
      changeKg: start == null ? null : now - start.trendKg,
      monthFrom: phaseThisMonth ? phase.start : monthStart,
      monthChangeKg: monthBase == null ? null : now - monthBase.trendKg,
      monthTargetKg: monthTarget,
      averageSince: spanDays >= _minAverageDays ? start!.localDate : null,
      averageWeeklyKg: spanDays >= _minAverageDays
          ? (now - start!.trendKg) * _daysPerWeek / spanDays
          : null,
    );
  }

  /// No weigh-ins.
  static const WeightStats empty = WeightStats._();

  /// The trend point a change is measured from at [date]: the last on or
  /// before it, unless that is more than the stale limit earlier (or there
  /// is none), then the first after it, up to [today] (PA11).
  static TrendPoint? _startPoint(
    WeightTrend trend,
    LocalDate date,
    LocalDate today,
  ) {
    final before = trend.pointOn(date);
    if (before != null &&
        before.localDate.daysUntil(date) <= trend.config.staleAfterDays) {
      return before;
    }
    for (final p in trend.points) {
      if (p.localDate.isAfter(date)) {
        return p.localDate.isAfter(today) ? null : p;
      }
    }
    return null;
  }

  static const int _minAverageDays = 14;

  /// The day the change is measured from (the trend point used).
  final LocalDate? startDate;

  /// The trend there. User content.
  final double? startKg;

  /// The trend today minus [startKg]. User content.
  final double? changeKg;

  /// Where "this month" starts: the 1st, or a phase start this month.
  final LocalDate? monthFrom;

  /// The change this month. User content.
  final double? monthChangeKg;

  /// This month's target change (pro-rated from a phase start this month),
  /// or null without an active goal rate.
  final double? monthTargetKg;

  /// "Average since {date}", after 14 days.
  final LocalDate? averageSince;

  /// The average weekly change since [averageSince]. User content.
  final double? averageWeeklyKg;

  /// Never the values.
  @override
  String toString() =>
      'WeightStats(from $startDate, month from $monthFrom, '
      'target: ${monthTargetKg == null ? 'none' : 'yes'})';
}

const int _daysPerWeek = 7;
