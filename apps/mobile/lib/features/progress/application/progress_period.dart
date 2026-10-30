import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'progress_period.g.dart';

/// The period every chart of the Progress tab shows (IN-009, A16 D3).
@immutable
sealed class ProgressPeriod {
  const new();

  /// Its kind.
  ProgressPeriodKind get kind;

  /// The period's first and last day. A phase without an end runs to
  /// [today]. The caller clamps data reads to today.
  ({LocalDate from, LocalDate end}) range(LocalDate today, GoalPhases phases);
}

/// The three kinds of period.
enum ProgressPeriodKind {
  /// A week from the week-start setting (LC-021).
  week,

  /// A calendar month.
  month,

  /// A goal phase (TG-012).
  phase,
}

/// The week starting on [start].
final class WeekPeriod extends ProgressPeriod {
  /// The week from [start] (a week-start day).
  const new(this.start);

  /// The first day.
  final LocalDate start;

  @override
  ProgressPeriodKind get kind => ProgressPeriodKind.week;

  @override
  ({LocalDate from, LocalDate end}) range(LocalDate today, GoalPhases phases) =>
      (from: start, end: start.plusDays(6));

  @override
  bool operator ==(Object other) => other is WeekPeriod && other.start == start;

  @override
  int get hashCode => Object.hash(WeekPeriod, start);
}

/// The calendar month [month] of [year].
final class MonthPeriod extends ProgressPeriod {
  /// The month.
  const new(this.year, this.month);

  /// The year.
  final int year;

  /// The month, 1–12.
  final int month;

  @override
  ProgressPeriodKind get kind => ProgressPeriodKind.month;

  @override
  ({LocalDate from, LocalDate end}) range(LocalDate today, GoalPhases phases) {
    final days = DateTime.utc(year, month + 1, 0).day;
    return (from: LocalDate(year, month, 1), end: LocalDate(year, month, days));
  }

  @override
  bool operator ==(Object other) =>
      other is MonthPeriod && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(MonthPeriod, year, month);
}

/// The goal phase [phaseId] (its projected dates, TG-012).
final class PhasePeriod extends ProgressPeriod {
  /// The phase.
  const new(this.phaseId);

  /// The phase's ID.
  final String phaseId;

  @override
  ProgressPeriodKind get kind => ProgressPeriodKind.phase;

  @override
  ({LocalDate from, LocalDate end}) range(LocalDate today, GoalPhases phases) {
    for (final phase in phases.history.phases) {
      if (phase.id == phaseId) {
        final end = phase.end;
        return (
          from: phase.start,
          end: end == null || end.isAfter(today)
              ? (phase.start.isAfter(today) ? phase.start : today)
              : end,
        );
      }
    }
    return (from: today, end: today);
  }

  @override
  bool operator ==(Object other) =>
      other is PhasePeriod && other.phaseId == phaseId;

  @override
  int get hashCode => Object.hash(PhasePeriod, phaseId);
}

/// What the period selector holds (A16 D3): the kind and how many periods
/// back from the current one (0 = this week, this month, the current or
/// latest phase). Relative, so it follows midnight and a week-start change.
typedef ProgressSelection = ({ProgressPeriodKind kind, int back});

/// The phases a phase period can show: started on or before [today], in
/// date order.
List<GoalPhase> selectablePhases(GoalPhases phases, LocalDate today) => [
  for (final phase in phases.history.phases)
    if (!phase.start.isAfter(today)) phase,
];

/// The period of [selection] on [today] (A16 D3). A phase selection without
/// phases shows this week.
ProgressPeriod resolvePeriod(
  ProgressSelection selection, {
  required LocalDate today,
  required WeekCalendar calendar,
  required GoalPhases phases,
}) {
  switch (selection.kind) {
    case ProgressPeriodKind.week:
      return WeekPeriod(
        calendar.weekStartOf(today).plusDays(-7 * selection.back),
      );
    case ProgressPeriodKind.month:
      final index = today.year * 12 + today.month - 1 - selection.back;
      return MonthPeriod(index ~/ 12, index % 12 + 1);
    case ProgressPeriodKind.phase:
      final list = selectablePhases(phases, today);
      if (list.isEmpty) return WeekPeriod(calendar.weekStartOf(today));
      final at = (list.length - 1 - selection.back).clamp(0, list.length - 1);
      return PhasePeriod(list[at].id);
  }
}

/// Whether ‹ can go to an earlier period: the earlier one must end on or
/// after [earliest] (the first data, A16 D14); phases stop at the first.
bool canGoBack(
  ProgressSelection selection, {
  required LocalDate today,
  required WeekCalendar calendar,
  required GoalPhases phases,
  required LocalDate earliest,
}) {
  if (selection.kind == ProgressPeriodKind.phase) {
    return selection.back < selectablePhases(phases, today).length - 1;
  }
  final earlier = resolvePeriod(
    (kind: selection.kind, back: selection.back + 1),
    today: today,
    calendar: calendar,
    phases: phases,
  );
  return !earlier.range(today, phases).end.isBefore(earliest);
}

/// Holds the [ProgressSelection]: session-only, kept while the app runs
/// (like the weight graph's window). Opens on this week (SC-5).
@Riverpod(keepAlive: true)
class ProgressPeriodController extends _$ProgressPeriodController {
  @override
  ProgressSelection build() => (kind: ProgressPeriodKind.week, back: 0);

  /// Switches to the current period of [kind].
  void setKind(ProgressPeriodKind kind) => state = (kind: kind, back: 0);

  /// One period earlier (the screen checks [canGoBack]).
  void previous() => state = (kind: state.kind, back: state.back + 1);

  /// One period later, never past the current one.
  void next() {
    if (state.back > 0) state = (kind: state.kind, back: state.back - 1);
  }
}
