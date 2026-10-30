import 'package:fb_domain/src/body/trend_weight.dart';
import 'package:fb_domain/src/body/weight_graph.dart';
import 'package:fb_domain/src/targets/goals.dart';
import 'package:fb_domain/src/time/local_date.dart';

/// How far a goal phase has come (IN-007, A16 D9): from the trend at the
/// phase start to the latest trend, towards the target weight. Never
/// negative: moving away from the target is 0 (IN-020). Content-free
/// [toString].
final class GoalProgress {
  const new _({
    this.startDate,
    this.startKg,
    this.latestKg,
    this.targetKg,
    this.fraction,
    this.weeklyKg,
  });

  /// The progress of [phase] (a projected phase, its end already set by a
  /// later start) on [trend] as of [today]. A past phase is measured to its
  /// end. The start is A15a's stale-start point ([WeightStats.startPoint]):
  /// the trend on the start day, or the first weigh-in after it.
  factory of({
    required GoalPhase phase,
    required WeightTrend trend,
    required LocalDate today,
  }) {
    final end = phase.end;
    final until = end != null && end.isBefore(today) ? end : today;
    final targetKg = switch (phase.expression) {
      TargetDateGoal(:final targetKg) ||
      TargetRateGoal(:final targetKg) => targetKg,
      _ => null,
    };
    if (until.isBefore(phase.start)) {
      return GoalProgress._(targetKg: targetKg);
    }
    final start = WeightStats.startPoint(trend, phase.start, until);
    final latest = trend.pointOn(until);
    if (start == null || latest == null) {
      return GoalProgress._(targetKg: targetKg);
    }
    final startKg = start.trendKg;
    final latestKg = latest.trendKg;
    double? fraction;
    if (targetKg != null && (startKg - targetKg).abs() > _epsilon) {
      fraction = ((startKg - latestKg) / (startKg - targetKg)).clamp(0.0, 1.0);
    }
    final spanDays = start.localDate.daysUntil(latest.localDate);
    return GoalProgress._(
      startDate: start.localDate,
      startKg: startKg,
      latestKg: latestKg,
      targetKg: targetKg,
      fraction: fraction,
      weeklyKg: spanDays >= minRateDays
          ? (latestKg - startKg) * 7 / spanDays
          : null,
    );
  }

  /// The average weekly change shows after this many days.
  static const int minRateDays = 14;

  static const double _epsilon = 1e-9;

  /// The day the progress is measured from.
  final LocalDate? startDate;

  /// The trend there. User content.
  final double? startKg;

  /// The latest trend (at the phase end for a past phase). User content.
  final double? latestKg;

  /// The target weight, for target-date and target-rate goals. User content.
  final double? targetKg;

  /// The share of the way to [targetKg], 0…1; null without a target, a
  /// trend, or when the start is the target.
  final double? fraction;

  /// The average weekly change since [startDate], after [minRateDays].
  /// User content.
  final double? weeklyKg;

  /// [latestKg] − [startKg], or null. User content.
  double? get changeKg =>
      startKg == null || latestKg == null ? null : latestKg! - startKg!;

  /// Whether the target is reached.
  bool get reached => fraction != null && fraction! >= 1;

  @override
  String toString() =>
      'GoalProgress(from $startDate, '
      'target: ${targetKg == null ? 'none' : 'yes'}, reached: $reached)';
}
