import 'package:fb_domain/src/ramadan/ramadan_settings.dart';
import 'package:fb_domain/src/time/local_date.dart';

/// One day's intake for the comparison: `kcal` over `entryCount` entries,
/// and the user's incomplete mark.
typedef ComparisonDay = ({
  LocalDate date,
  double kcal,
  int entryCount,
  bool incomplete,
});

/// The numbers of one side of the Ramadan comparison (IN-008).
/// Content-free [toString].
final class ComparisonSide {
  const new _({
    required this.from,
    required this.to,
    required this.loggedDays,
    required this.averageKcal,
    required this.trendChangeKg,
    required this.workouts,
  });

  /// The first day.
  final LocalDate from;

  /// The last day (inclusive).
  final LocalDate to;

  /// The number of days.
  int get days => from.daysUntil(to) + 1;

  /// Days with food that are not marked incomplete (TG-032: other days
  /// are unknown, never zero).
  final int loggedDays;

  /// The average calories over [loggedDays], or null without any.
  final double? averageKcal;

  /// The trend weight's change from the day before [from] to [to], or null
  /// when the trend is unknown at either end.
  final double? trendChangeKg;

  /// Workouts logged in the period.
  final int workouts;

  /// Workouts per week (7 days).
  double get workoutsPerWeek => workouts * 7 / days;

  @override
  String toString() => 'ComparisonSide($from–$to)';
}

/// Ramadan vs the month before (IN-008, D-052): average intake, trend
/// weight change and workouts. Pure; the app gathers the rows.
final class RamadanComparison {
  const new _(this.period, this.ramadan, this.before);

  /// The comparison of [period] on [today] (Ramadan's side runs to today
  /// while it lasts; [today] must not be before its first day).
  /// [days] are diary days (others are unknown);
  /// [trendOn] gives the trend weight on a date, or null; [workoutDates]
  /// has one date per logged workout.
  factory compute({
    required RamadanPeriod period,
    required LocalDate today,
    required Iterable<ComparisonDay> days,
    required double? Function(LocalDate date) trendOn,
    required Iterable<LocalDate> workoutDates,
  }) {
    if (today.isBefore(period.start)) {
      throw ArgumentError('Ramadan has not started on today');
    }
    final ramadanEnd = today.isBefore(period.end) ? today : period.end;
    final beforeStart = period.start.plusDays(-beforeDays);
    final beforeEnd = period.start.plusDays(-1);
    final dayList = days.toList();
    final workouts = workoutDates.toList();
    ComparisonSide side(LocalDate from, LocalDate to) {
      var logged = 0;
      var kcal = 0.0;
      for (final d in dayList) {
        if (d.date.isBefore(from) || d.date.isAfter(to)) continue;
        if (d.incomplete || d.entryCount == 0) continue;
        logged++;
        kcal += d.kcal;
      }
      final startTrend = trendOn(from.plusDays(-1));
      final endTrend = trendOn(to);
      return ComparisonSide._(
        from: from,
        to: to,
        loggedDays: logged,
        averageKcal: logged == 0 ? null : kcal / logged,
        trendChangeKg: startTrend == null || endTrend == null
            ? null
            : endTrend - startTrend,
        workouts: workouts
            .where((d) => !d.isBefore(from) && !d.isAfter(to))
            .length,
      );
    }

    return RamadanComparison._(
      period,
      side(period.start, ramadanEnd),
      side(beforeStart, beforeEnd),
    );
  }

  /// The days before Ramadan that are compared ("the month before").
  static const int beforeDays = 30;

  /// The days after Ramadan's end the comparison is still shown.
  static const int showAfterDays = 30;

  /// The Ramadan compared.
  final RamadanPeriod period;

  /// Ramadan so far (up to today) or the whole of it.
  final ComparisonSide ramadan;

  /// The [beforeDays] days before it.
  final ComparisonSide before;

  /// Whether Ramadan is still going on.
  bool get inProgress => ramadan.to.isBefore(period.end);

  /// The Ramadan of [onPeriods] to compare on [today]: the latest one that
  /// has started by [today] and ended at most [showAfterDays] before it.
  /// Null when there is none.
  static RamadanPeriod? shownOn(
    LocalDate today,
    Iterable<RamadanPeriod> onPeriods,
  ) {
    RamadanPeriod? shown;
    for (final p in onPeriods) {
      if (today.isBefore(p.start)) continue;
      if (p.end.plusDays(showAfterDays).isBefore(today)) continue;
      if (shown == null || p.start.isAfter(shown.start)) shown = p;
    }
    return shown;
  }

  @override
  String toString() => 'RamadanComparison($period)';
}
