import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/workouts/application/exercise_library.dart';
import 'package:fb_mobile/features/workouts/application/workout_views.dart';
import 'package:fb_mobile/features/workouts/presentation/exercise_muscle_map.dart';
import 'package:fb_mobile/features/workouts/workouts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../today/presentation/support/today_support.dart' show phoneApp;
import '../support/workout_harness.dart';

const _bench = 'ex:barbell_bench_press';

final class _Navigator implements AppNavigator {
  final List<AppRoute> pushed = [];

  @override
  void go(AppRoute route) => throw UnimplementedError();

  @override
  void push(AppRoute route) => pushed.add(route);

  @override
  void pop() {}
}

Stored<WorkoutSessionDraft> _session(
  int n,
  LocalDate date,
  List<LoggedSet> s,
) => (
  ref: VersionedId(wid(n), 1),
  draft: WorkoutSessionDraft(
    date: date,
    exercises: [
      SessionExerciseDraft(id: wid(n + 50), exerciseId: _bench, sets: s),
    ],
  ),
);

void main() {
  testWidgets('WO-041 exercise page toggles e1RM', (tester) async {
    tester.view
      ..physicalSize = const Size(400, 1600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final navigator = _Navigator();
    final sessions = [
      _session(1, LocalDate(2026, 10, 20), [lifted(60, 8, 80)]),
      _session(2, LocalDate(2026, 10, 24), [lifted(61, 5, 85)]),
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clockProvider.overrideWithValue(WorkoutHarness().clock),
          appNavigatorProvider.overrideWithValue(navigator),
          allWorkoutSessionsProvider.overrideWith(
            (ref) => Stream.value(sessions),
          ),
          exerciseLibraryProvider.overrideWith(
            (ref) async => ExerciseLibrary([
              LibraryExercise(
                id: _bench,
                name: 'Barbell bench press',
                aliases: const [],
                type: ExerciseType.weightReps,
                equipment: Equipment.barbell,
                primary: Muscle.chest,
                secondaries: const [Muscle.triceps, Muscle.shoulders],
              ),
            ]),
          ),
        ],
        child: phoneApp(
          const ExerciseScreen(
            exerciseId: _bench,
            tab: ExerciseBrowseTab.workouts,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // WO-007: the page shows the exercise's muscle map.
    final map = tester.widget<ExerciseMuscleMap>(
      find.byType(ExerciseMuscleMap),
    );
    expect(map.primary, Muscle.chest);
    expect(map.secondaries, [Muscle.triceps, Muscle.shoulders]);

    // The main line is the heaviest set; the toggle swaps in the e1RM.
    List<double> plotted() => tester
        .widget<FbTimeSeriesChart>(find.byType(FbTimeSeriesChart))
        .series
        .single
        .points
        .map((p) => p.value)
        .toList();
    expect(plotted(), [80, 85]);
    await tester.tap(find.byKey(const ValueKey('exercise-graph-e1rm')));
    await tester.pumpAndSettle();
    expect(plotted(), [
      closeTo(80 * (1 + 8 / 30), 1e-9),
      closeTo(85 * (1 + 5 / 30), 1e-9),
    ]);
    await tester.tap(find.byKey(const ValueKey('exercise-graph-heaviest')));
    await tester.pumpAndSettle();
    expect(plotted(), [80, 85]);

    // Past sessions, newest first, open the session.
    await tester.tap(find.byKey(ValueKey('exercise-session-${wid(2)}')));
    expect(navigator.pushed.single, isA<WorkoutSessionRoute>());
    expect((navigator.pushed.single as WorkoutSessionRoute).id, wid(2));
  });
}
