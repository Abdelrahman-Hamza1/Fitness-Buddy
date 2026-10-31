import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_mobile/features/workouts/application/exercise_library.dart';
import 'package:fb_mobile/features/workouts/data/workout_repository.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:riverpod_annotation/riverpod_annotation.dart';

// Screens name stored aggregates through the application layer.
export 'package:fb_mobile/features/workouts/data/workout_repository.dart'
    show Stored;

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

/// How many exercises the picker's "Your recent" lists (A52 D3).
const int recentExerciseCount = 5;

/// The user's recent exercises, newest first, with their top set (A52 D3,
/// D-089): the picker's "Your recent".
@riverpod
Future<List<RecentExercise>> recentExercises(Ref ref) async {
  final sessionsFuture = ref.watch(allWorkoutSessionsProvider.future);
  final libraryFuture = ref.watch(exerciseLibraryProvider.future);
  final sessions = await sessionsFuture;
  final library = await libraryFuture;
  final recent = RecentExercises.of(
    [for (final s in sessions) (id: s.ref.id, draft: s.draft)],
    library.typeOf,
    limit: sessions.length * WorkoutLimits.exercisesMax,
  );
  // Exercises the library no longer knows (a deleted custom one) are left
  // out.
  return [
    for (final r in recent)
      if (library.byId.containsKey(r.exerciseId)) r,
  ].take(recentExerciseCount).toList();
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
    required this.muscles,
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

  /// Its exercises' muscles together, for its small map (A52 D4).
  final MuscleUnion muscles;

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
        muscles: library.musclesOf([
          for (final e in s.draft.exercises) e.exerciseId,
        ]),
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

/// The live templates, by name (WO-020).
@riverpod
Stream<List<Stored<WorkoutTemplateDraft>>> workoutTemplates(Ref ref) =>
    ref.watch(workoutRepositoryProvider).watchTemplates();

/// The weekly plan: each planned weekday's live template (WO-021). Empty
/// without a plan: a plan is never required (D-085).
@riverpod
Stream<Map<DayOfWeek, String>> workoutPlan(Ref ref) =>
    ref.watch(workoutRepositoryProvider).watchPlan();

/// The planned template of [date]'s weekday in [plan], or `null`.
Stored<WorkoutTemplateDraft>? plannedTemplate(
  LocalDate date,
  Map<DayOfWeek, String> plan,
  List<Stored<WorkoutTemplateDraft>> templates,
) {
  final id = plan[date.weekday];
  if (id == null) return null;
  return templates.where((t) => t.ref.id == id).firstOrNull;
}

/// The current week for the Workouts tab (D19): its days from the week
/// start, the days with a session, and plan hints for today and later.
@immutable
final class WorkoutWeek {
  /// The week of [days] with sessions on [trained] and [planned] names.
  new({
    required Iterable<LocalDate> days,
    required this.trained,
    this.sessionCount = 0,
    Map<LocalDate, String> planned = const {},
  }) : days = List.unmodifiable(days),
       planned = Map.unmodifiable(planned);

  /// The seven days in order.
  final List<LocalDate> days;

  /// Days with at least one live session.
  final Set<LocalDate> trained;

  /// How many sessions the week has ("This week · 2 workouts", D-089).
  final int sessionCount;

  /// The planned template's name of today and later days (A37c D19). Past
  /// planned days without a session aren't here: they look like any other
  /// day, never "missed" (WO-024).
  final Map<LocalDate, String> planned;
}

/// The week containing [today]: trained days, and plan hints for today and
/// later (WO-024: no "missed" days, ever).
@riverpod
Future<WorkoutWeek> workoutWeek(Ref ref, LocalDate today) async {
  final weekStartFuture = ref.watch(weekStartProvider.future);
  final sessionsFuture = ref.watch(allWorkoutSessionsProvider.future);
  final planFuture = ref.watch(workoutPlanProvider.future);
  final templatesFuture = ref.watch(workoutTemplatesProvider.future);
  final start = WeekCalendar(weekStart: await weekStartFuture)
      .weekStartOf(today);
  final days = [for (var i = 0; i < 7; i++) start.plusDays(i)];
  final sessions = await sessionsFuture;
  final plan = await planFuture;
  final templates = await templatesFuture;
  final inWeek = [
    for (final s in sessions)
      if (!s.draft.date.isBefore(start) && !s.draft.date.isAfter(days.last)) s,
  ];
  return WorkoutWeek(
    days: days,
    trained: {for (final s in inWeek) s.draft.date},
    sessionCount: inWeek.length,
    planned: {
      for (final day in days)
        if (!day.isBefore(today))
          if (plannedTemplate(day, plan, templates) case final t?)
            day: t.draft.name,
    },
  );
}

/// The weekly plan as the Workouts tab's "Your plan" row shows it (D-089):
/// the planned workouts' names and the training days, in week order.
@immutable
final class PlanOverview {
  /// A plan training [names] on [days].
  new({required Iterable<String> names, required Iterable<DayOfWeek> days})
    : names = List.unmodifiable(names),
      days = List.unmodifiable(days);

  /// The distinct planned workouts' names, in week order ("Push", "Pull",
  /// "Legs").
  final List<String> names;

  /// The training days, in week order.
  final List<DayOfWeek> days;
}

/// The weekly plan's overview, or `null` without a plan (D-089).
@riverpod
Future<PlanOverview?> workoutPlanOverview(Ref ref) async {
  final weekStartFuture = ref.watch(weekStartProvider.future);
  final planFuture = ref.watch(workoutPlanProvider.future);
  final templatesFuture = ref.watch(workoutTemplatesProvider.future);
  final order = WeekCalendar(weekStart: await weekStartFuture).daysInOrder;
  final plan = await planFuture;
  final templates = await templatesFuture;
  final named = [
    for (final day in order)
      if (templates.where((t) => t.ref.id == plan[day]).firstOrNull
          case final t?)
        (day, t.draft.name),
  ];
  if (named.isEmpty) return null;
  return PlanOverview(
    names: {for (final (_, name) in named) name},
    days: [for (final (day, _) in named) day],
  );
}

/// The Today screen's workout row (HM-006, D20): a logged session, or a
/// planned template.
@immutable
sealed class TodayWorkout {
  const new _();
}

/// The day has sessions: the latest, with how many more there are.
final class TodayWorkoutLogged extends TodayWorkout {
  /// The row for [summary] with [more] other sessions that day.
  const new({required this.summary, required this.more}) : super._();

  /// The latest session of the day.
  final SessionSummary summary;

  /// How many other sessions the day has ("+1").
  final int more;
}

/// No session yet, and the day's weekday has a live template (A37c).
final class TodayWorkoutPlanned extends TodayWorkout {
  /// The row for [template].
  const new({required this.template}) : super._();

  /// The planned template.
  final Stored<WorkoutTemplateDraft> template;
}

/// The last session strictly before the viewed day.
final class TodayWorkoutLast extends TodayWorkout {
  /// Creates the last-session summary.
  const new({required this.summary, required this.daysAgo}) : super._();

  /// The latest session strictly before the viewed day.
  final SessionSummary summary;

  /// Calendar days between the session and the viewed day.
  final int daysAgo;
}

/// No sessions and no planned workout.
final class TodayWorkoutNone extends TodayWorkout {
  /// An empty workout summary.
  const new() : super._();
}

/// The workout row of [date] (D20): its latest session; else, for today or
/// a later day, its planned template; else the last earlier session or an
/// empty state. Past days are never "missed" (D-092).
@riverpod
Future<TodayWorkout> todayWorkout(Ref ref, LocalDate date) async {
  final historyFuture = ref.watch(workoutHistoryProvider.future);
  final planFuture = ref.watch(workoutPlanProvider.future);
  final templatesFuture = ref.watch(workoutTemplatesProvider.future);
  final today = ref.watch(workoutTodayProvider);
  final day = [
    for (final s in await historyFuture)
      if (s.date == date) s,
  ];
  final plan = await planFuture;
  final templates = await templatesFuture;
  // History is newest first: the first of the day is the latest.
  if (day.isNotEmpty) {
    return TodayWorkoutLogged(summary: day.first, more: day.length - 1);
  }
  if (!date.isBefore(today)) {
    final template = plannedTemplate(date, plan, templates);
    if (template != null) return TodayWorkoutPlanned(template: template);
  }
  final last = (await historyFuture)
      .where((s) => s.date.isBefore(date))
      .firstOrNull;
  return last == null
      ? const TodayWorkoutNone()
      : TodayWorkoutLast(summary: last, daysAgo: last.date.daysUntil(date));
}

/// One exercise's page (WO-041, IN-006): the exercise and its progress.
@immutable
final class ExerciseProgressView {
  /// The page of [exercise] with [progress].
  const new({required this.exercise, required this.progress});

  /// The exercise (built-in or custom).
  final LibraryExercise exercise;

  /// Its sessions, series and bests.
  final ExerciseProgress progress;
}

/// The page of exercise [exerciseId], or `null` when the library doesn't
/// know it (a removed custom exercise, D15).
@riverpod
Future<ExerciseProgressView?> exerciseProgress(
  Ref ref,
  String exerciseId,
) async {
  final sessionsFuture = ref.watch(allWorkoutSessionsProvider.future);
  final libraryFuture = ref.watch(exerciseLibraryProvider.future);
  final sessions = await sessionsFuture;
  final exercise = (await libraryFuture).byId[exerciseId];
  if (exercise == null) return null;
  return ExerciseProgressView(
    exercise: exercise,
    progress: ExerciseProgress.of(
      [for (final s in sessions) (id: s.ref.id, draft: s.draft)],
      exerciseId,
      exercise.type,
    ),
  );
}

/// Whether exercise [exerciseId]'s graph shows the estimated 1RM instead
/// of the heaviest set (WO-041: a toggle; the heaviest set by default).
@riverpod
class ExerciseGraphE1rm extends _$ExerciseGraphE1rm {
  @override
  bool build(String exerciseId) => false;

  /// Shows the estimated 1RM when [on], else the heaviest set.
  // A named intent, like the other view models' intents.
  // ignore: use_setters_to_change_properties
  void show({required bool on}) => state = on;
}

/// The workouts of the week starting on [weekStart] (WO-043, A37 D22):
/// sessions done, planned days only with a plan, PRs. For the weekly
/// summary and review (A39a); no display here.
@riverpod
Future<WeeklyWorkoutSummary> weeklyWorkoutSummary(
  Ref ref,
  LocalDate weekStart,
) async {
  final sessionsFuture = ref.watch(allWorkoutSessionsProvider.future);
  final planFuture = ref.watch(workoutPlanProvider.future);
  final prsFuture = ref.watch(workoutPrsProvider.future);
  final sessions = await sessionsFuture;
  final plan = await planFuture;
  final prs = await prsFuture;
  return WeeklyWorkoutSummary.of(
    history: [for (final s in sessions) (id: s.ref.id, draft: s.draft)],
    plan: plan,
    weekStart: weekStart,
    prCountOf: prs.countOf,
  );
}
