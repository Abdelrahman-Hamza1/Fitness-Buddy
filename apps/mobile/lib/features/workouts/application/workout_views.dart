import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_mobile/features/workouts/application/exercise_library.dart';
import 'package:fb_mobile/features/workouts/data/workout_repository.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workout_views.g.dart';

/// The local day the Workouts screens treat as today (new sessions, the
/// week strip, the date picker's limit).
@riverpod
LocalDate workoutToday(Ref ref) =>
    EntryTime.now(ref.watch(clockProvider)).localDate;

/// Every live session, by date then ID (A37 D24).
@riverpod
Stream<List<Stored<WorkoutSessionDraft>>> allWorkoutSessions(Ref ref) =>
    ref.watch(workoutRepositoryProvider).watchAllSessions();

/// The PR markers of the whole history (WO-042, D11).
@riverpod
Future<SessionPrs> workoutPrs(Ref ref) async {
  final sessionsFuture = ref.watch(allWorkoutSessionsProvider.future);
  final libraryFuture = ref.watch(exerciseLibraryProvider.future);
  final sessions = await sessionsFuture;
  final library = await libraryFuture;
  return SessionPrs.of([
    for (final s in sessions) (id: s.ref.id, draft: s.draft),
  ], library.typeOf);
}

/// One session as lists show it (WO-040): its title (D10), counts and PR
/// count.
@immutable
final class SessionSummary {
  /// A summary of [session].
  const new({
    required this.session,
    required this.title,
    required this.exerciseCount,
    required this.setCount,
    required this.prCount,
  });

  /// The stored session.
  final Stored<WorkoutSessionDraft> session;

  /// What it's called.
  final SessionTitle title;

  /// How many exercises.
  final int exerciseCount;

  /// How many sets.
  final int setCount;

  /// How many exercises set a PR ("1 PR").
  final int prCount;

  /// The session's ID.
  String get id => session.ref.id;

  /// Its training day.
  LocalDate get date => session.draft.date;
}

/// Every session, newest first, summarized: the history list (WO-040).
@riverpod
Future<List<SessionSummary>> workoutHistory(Ref ref) async {
  final sessionsFuture = ref.watch(allWorkoutSessionsProvider.future);
  final libraryFuture = ref.watch(exerciseLibraryProvider.future);
  final prsFuture = ref.watch(workoutPrsProvider.future);
  final sessions = await sessionsFuture;
  final library = await libraryFuture;
  final prs = await prsFuture;
  return [
    for (final s in sessions.reversed)
      SessionSummary(
        session: s,
        title: library.titleOf(s.draft),
        exerciseCount: s.draft.exercises.length,
        setCount: s.draft.exercises.fold(0, (n, e) => n + e.sets.length),
        prCount: prs.countOf(s.ref.id),
      ),
  ];
}

/// How many recent sessions the Workouts tab lists.
const int recentSessionCount = 5;

/// The latest sessions, newest first (the Workouts tab, with Repeat).
@riverpod
Future<List<SessionSummary>> recentWorkouts(Ref ref) async =>
    (await ref.watch(workoutHistoryProvider.future))
        .take(recentSessionCount)
        .toList();

/// The current week for the Workouts tab (D19): its days from the week
/// start, and the days with a session. A37c adds plan hints.
@immutable
final class WorkoutWeek {
  /// The week of [days] with sessions on [trained].
  new({required Iterable<LocalDate> days, required this.trained})
    : days = List.unmodifiable(days);

  /// The seven days in order.
  final List<LocalDate> days;

  /// Days with at least one live session.
  final Set<LocalDate> trained;
}

/// The week containing [today], with trained days only (WO-024: no
/// "missed" days, ever).
@riverpod
Future<WorkoutWeek> workoutWeek(Ref ref, LocalDate today) async {
  final weekStartFuture = ref.watch(weekStartProvider.future);
  final sessionsFuture = ref.watch(allWorkoutSessionsProvider.future);
  final start = WeekCalendar(weekStart: await weekStartFuture)
      .weekStartOf(today);
  final days = [for (var i = 0; i < 7; i++) start.plusDays(i)];
  final sessions = await sessionsFuture;
  return WorkoutWeek(
    days: days,
    trained: {
      for (final s in sessions)
        if (!s.draft.date.isBefore(start) && !s.draft.date.isAfter(days.last))
          s.draft.date,
    },
  );
}

/// The Today screen's workout row (HM-006, D20): the latest session of the
/// day, with how many more there are.
@immutable
final class TodayWorkout {
  /// The row for [summary] with [more] other sessions that day.
  const new({required this.summary, required this.more});

  /// The latest session of the day.
  final SessionSummary summary;

  /// How many other sessions the day has ("+1").
  final int more;
}

/// The workout row of [date] (D20, A37a: the logged branch only), or `null`
/// without a session (no-plan users see nothing until they log).
@riverpod
Future<TodayWorkout?> todayWorkout(Ref ref, LocalDate date) async {
  final day = [
    for (final s in await ref.watch(workoutHistoryProvider.future))
      if (s.date == date) s,
  ];
  if (day.isEmpty) return null;
  // History is newest first: the first of the day is the latest.
  return TodayWorkout(summary: day.first, more: day.length - 1);
}
