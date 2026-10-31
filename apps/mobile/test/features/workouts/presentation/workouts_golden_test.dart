import 'package:alchemist/alchemist.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/workouts/application/exercise_library.dart';
import 'package:fb_mobile/features/workouts/application/workout_views.dart';
import 'package:fb_mobile/features/workouts/workouts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:material_ui/material_ui.dart';

import '../../today/presentation/support/today_support.dart' show phoneApp;
import '../support/workout_harness.dart';

LibraryExercise _ex(String id, String name, Muscle primary, List<Muscle> s) =>
    LibraryExercise(
      id: id,
      name: name,
      aliases: const [],
      type: ExerciseType.weightReps,
      equipment: Equipment.barbell,
      primary: primary,
      secondaries: s,
    );

final ExerciseLibrary _library = ExerciseLibrary([
  _ex('ex:bench', 'Bench press', Muscle.chest, [
    Muscle.triceps,
    Muscle.shoulders,
  ]),
  _ex('ex:ohp', 'Overhead press', Muscle.shoulders, [Muscle.triceps]),
  _ex('ex:incline', 'Incline dumbbell press', Muscle.chest, [Muscle.shoulders]),
  _ex('ex:raise', 'Lateral raise', Muscle.shoulders, const []),
  _ex('ex:squat', 'Squat', Muscle.quadriceps, [
    Muscle.glutes,
    Muscle.hamstrings,
  ]),
  _ex('ex:row', 'Barbell row', Muscle.upperBack, [Muscle.biceps]),
]);

final Stored<WorkoutTemplateDraft> _push = (
  ref: VersionedId(wid(70), 1),
  draft: WorkoutTemplateDraft(
    name: 'Push',
    items: [
      for (final (i, id) in [
        'ex:bench',
        'ex:ohp',
        'ex:incline',
        'ex:raise',
      ].indexed)
        TemplateItemDraft(id: wid(71 + i), exerciseId: id, sets: 3, reps: 8),
    ],
  ),
);

SessionSummary _session(int n, LocalDate date, String name, List<String> ids) {
  final draft = WorkoutSessionDraft(
    date: date,
    name: name,
    exercises: [
      for (final (i, id) in ids.indexed)
        SessionExerciseDraft(
          id: wid(n * 10 + i),
          exerciseId: id,
          sets: [lifted(n * 100 + i, 8, 60)],
        ),
    ],
  );
  return SessionSummary(
    session: (ref: VersionedId(wid(n), 1), draft: draft),
    title: _library.titleOf(draft),
    exerciseCount: ids.length,
    setCount: ids.length,
    prCount: 0,
    muscles: _library.musclesOf(ids),
  );
}

final class _Navigator implements AppNavigator {
  const new();

  @override
  void go(AppRoute route) {}

  @override
  void push(AppRoute route) {}

  @override
  void pop() {}
}

// Built outside the ProviderScope literal (riverpod_lint scoped-provider rule).
List<Override> _overrides(List<SessionSummary> sessions, WorkoutWeek week) => [
  appNavigatorProvider.overrideWithValue(const _Navigator()),
  workoutTodayProvider.overrideWithValue(today),
  exerciseLibraryProvider.overrideWith((ref) async => _library),
  recentWorkoutsProvider.overrideWith((ref) async => sessions),
  todayWorkoutProvider(today)
      .overrideWith((ref) async => TodayWorkoutPlanned(template: _push)),
  workoutTemplatesProvider.overrideWith((ref) => Stream.value([_push])),
  workoutPlanOverviewProvider.overrideWith(
    (ref) async => PlanOverview(
      names: const ['Push', 'Pull', 'Legs'],
      days: const [DayOfWeek.monday, DayOfWeek.wednesday, DayOfWeek.friday],
    ),
  ),
  workoutWeekProvider(today).overrideWith((ref) async => week),
];

Widget _cell(Brightness brightness, double scale) {
  final sessions = [
    _session(1, today.plusDays(-1), 'Legs', ['ex:squat']),
    _session(2, today.plusDays(-3), 'Back', ['ex:row']),
  ];
  final week = WorkoutWeek(
    days: [for (var i = 0; i < 7; i++) LocalDate(2026, 10, 24).plusDays(i)],
    trained: {for (final s in sessions) s.date},
    sessionCount: 2,
  );
  return SizedBox(
    width: 360,
    height: 1100,
    child: ProviderScope(
      overrides: [..._overrides(sessions, week)],
      child: phoneApp(
        const WorkoutsScreen(),
        brightness: brightness,
        textScale: scale,
      ),
    ),
  );
}

Future<void> main() async {
  // A key screen (A46, D-089): the week, today's plan card with its map,
  // recent sessions with maps and Repeat, and the plan row.
  await goldenTest(
    'D-089 Workouts tab: plan card, recent sessions, your plan',
    fileName: 'workouts_tab',
    builder: () => GoldenTestGroup(
      columns: 3,
      children: [
        GoldenTestScenario(name: 'light', child: _cell(Brightness.light, 1)),
        GoldenTestScenario(name: 'dark', child: _cell(Brightness.dark, 1)),
        GoldenTestScenario(
          name: 'light, text 2.0',
          child: _cell(Brightness.light, 2),
        ),
      ],
    ),
  );
}
