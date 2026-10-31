import 'package:fb_domain/src/insights/progress_series.dart';
import 'package:fb_domain/src/time/local_date.dart';
import 'package:fb_domain/src/time/week_calendar.dart';
import 'package:fb_domain/src/workouts/weekly_workout_summary.dart';

/// One week at a glance (IN-001, A39a D1): the current week so far or any
/// past week. Numbers come from the same per-date series as the Progress
/// charts ([ProgressDay], G10), so the summary and the charts agree; only
/// counted days (logged, not marked incomplete, not today) enter averages
/// and day counts (A16 D4, TG-032). Content-free [toString].
final class WeeklySummary {
  /// A summary; see [WeeklySummary.of].
  const new({
    required this.start,
    required this.end,
    required this.elapsedDays,
    required this.countedDays,
    required this.targetDays,
    required this.daysWithinTarget,
    required this.proteinTargetDays,
    required this.proteinDaysHit,
    this.averageKcal,
    this.averageTargetKcal,
    this.averageFiber,
    this.trendChangeKg,
    this.workouts,
  });

  /// The summary of the week from [weekStart] as of [today], from the
  /// week's [days] (dates outside the week are ignored), the trend weight
  /// ([trendOn]) and the week's [workouts] (null when not read).
  ///
  /// Throws an `ArgumentError` for a week that starts after [today].
  factory of({
    required LocalDate weekStart,
    required LocalDate today,
    required Iterable<ProgressDay> days,
    required double? Function(LocalDate date) trendOn,
    WeeklyWorkoutSummary? workouts,
  }) {
    if (weekStart.isAfter(today)) {
      throw ArgumentError.value(weekStart, 'weekStart', 'is after today');
    }
    final end = weekStart.plusDays(6);
    final current = !today.isAfter(end);
    final week = [
      for (final day in days)
        if (!day.date.isBefore(weekStart) && !day.date.isAfter(end)) day,
    ];
    final counted = [
      for (final day in week)
        if (day.counted && day.date.isBefore(today)) day,
    ];
    final targeted = [
      for (final day in counted)
        if (day.targetKcal != null) day,
    ];
    final proteinTargeted = [
      for (final day in counted)
        if (day.targetMacros != null) day,
    ];
    double? mean(Iterable<double> values) {
      var sum = 0.0;
      var n = 0;
      for (final v in values) {
        sum += v;
        n++;
      }
      return n == 0 ? null : sum / n;
    }

    // The trend change runs to the last elapsed day of a past week, or to
    // today for the current one (the trend is known for today, A16 D10).
    final trendEnd = current ? today : end;
    final now = trendOn(trendEnd);
    final before = trendOn(weekStart.plusDays(-1));
    return WeeklySummary(
      start: weekStart,
      end: end,
      elapsedDays: current ? weekStart.daysUntil(today) : 7,
      countedDays: counted.length,
      targetDays: targeted.length,
      daysWithinTarget: targeted.where(_withinTarget).length,
      proteinTargetDays: proteinTargeted.length,
      proteinDaysHit: proteinTargeted
          .where((d) => d.eaten.protein >= d.targetMacros!.proteinGrams)
          .length,
      averageKcal: mean(targeted.map((d) => d.eaten.kcal)),
      averageTargetKcal: mean(targeted.map((d) => d.targetKcal!)),
      averageFiber: mean(counted.map((d) => d.eaten.fiber)),
      trendChangeKg: now == null || before == null ? null : now - before,
      workouts: workouts,
    );
  }

  /// How far from the day's calorie target still counts as within it: a
  /// 10 % band on either side (A39a D1).
  static const double withinTargetFraction = 0.10;

  static bool _withinTarget(ProgressDay day) =>
      (day.eaten.kcal - day.targetKcal!).abs() <=
      day.targetKcal! * withinTargetFraction;

  /// The weeks a summary can show from [earliest] (the first data date) to
  /// [today], newest first: each week's first day.
  static List<LocalDate> weekStarts({
    required LocalDate earliest,
    required LocalDate today,
    required WeekCalendar calendar,
  }) {
    final first = calendar.weekStartOf(
      earliest.isAfter(today) ? today : earliest,
    );
    return [
      for (
        var start = calendar.weekStartOf(today);
        !start.isBefore(first);
        start = start.plusDays(-7)
      )
        start,
    ];
  }

  /// The week's first day.
  final LocalDate start;

  /// The week's last day.
  final LocalDate end;

  /// Days of the week before today: 0–6 for the current week, 7 for a past
  /// week.
  final int elapsedDays;

  /// Elapsed days that count (logged, not marked incomplete).
  final int countedDays;

  /// Counted days with a calorie target.
  final int targetDays;

  /// Of [targetDays], the days within [withinTargetFraction] of the
  /// target.
  final int daysWithinTarget;

  /// Counted days with a protein target.
  final int proteinTargetDays;

  /// Of [proteinTargetDays], the days protein reached the target.
  final int proteinDaysHit;

  /// The average intake over [targetDays], or null without one.
  final double? averageKcal;

  /// The average calorie target over the same days.
  final double? averageTargetKcal;

  /// The average fiber over [countedDays], or null without one.
  final double? averageFiber;

  /// The trend change over the week (to today for the current week), or
  /// null when the trend isn't known at both ends.
  final double? trendChangeKg;

  /// Sessions, planned days (only with a plan) and PRs; null when not read.
  final WeeklyWorkoutSummary? workouts;

  /// Whether the week has nothing to summarize: no counted day, no trend
  /// change and no session.
  bool get isEmpty =>
      countedDays == 0 &&
      trendChangeKg == null &&
      (workouts == null || workouts!.sessions == 0);

  @override
  String toString() => 'WeeklySummary($start, $countedDays/$elapsedDays)';
}
