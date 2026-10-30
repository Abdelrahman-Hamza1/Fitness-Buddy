import 'package:fb_domain/src/time/local_date.dart';
import 'package:fb_domain/src/workouts/workout_history.dart';

/// One week's workouts for the weekly summary and review (WO-043, A37
/// D22): sessions done, planned training days only when there's a plan
/// (never a "missed" count, WO-024), and how many exercises set a PR.
final class WeeklyWorkoutSummary {
  /// A summary.
  const new({required this.sessions, required this.planned, required this.prs});

  /// The summary of the week from [weekStart] (seven days) over
  /// [history], with [plan] (weekday → template; empty without a plan)
  /// and the PR count of each session from [prCountOf].
  factory of({
    required Iterable<SessionEntry> history,
    required Map<DayOfWeek, String> plan,
    required LocalDate weekStart,
    required int Function(String sessionId) prCountOf,
  }) {
    final end = weekStart.plusDays(6);
    final week = [
      for (final s in history)
        if (!s.draft.date.isBefore(weekStart) && !s.draft.date.isAfter(end)) s,
    ];
    return WeeklyWorkoutSummary(
      sessions: week.length,
      // Each weekday appears once a week.
      planned: plan.isEmpty ? null : plan.length,
      prs: week.fold(0, (n, s) => n + prCountOf(s.id)),
    );
  }

  /// Sessions logged in the week.
  final int sessions;

  /// Planned training days, or `null` without a plan.
  final int? planned;

  /// Exercises that set a PR, summed over the week's sessions.
  final int prs;

  @override
  bool operator ==(Object other) =>
      other is WeeklyWorkoutSummary &&
      other.sessions == sessions &&
      other.planned == planned &&
      other.prs == prs;

  @override
  int get hashCode => Object.hash(sessions, planned, prs);

  @override
  String toString() =>
      'WeeklyWorkoutSummary($sessions sessions, $planned planned, $prs PRs)';
}
