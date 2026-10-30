import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/ids/id_generator.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_mobile/features/workouts/application/exercise_library.dart';
import 'package:fb_mobile/features/workouts/presentation/set_row.dart';
import 'package:fb_mobile/features/workouts/workouts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../today/presentation/support/today_support.dart' show phoneApp;
import '../support/workout_harness.dart';

/// A navigator that records pushes and counts pops.
final class _Navigator implements AppNavigator {
  final List<AppRoute> pushed = [];
  int pops = 0;

  @override
  void go(AppRoute route) => throw UnimplementedError();

  @override
  void push(AppRoute route) => pushed.add(route);

  @override
  void pop() => pops++;
}

/// The workout screens on a real in-memory database and applier.
final class _Rig {
  new() {
    stack = UndoStack(
      revert: h.applier.revert,
      apply: h.applier.apply,
      clock: h.clock,
    );
  }

  final WorkoutHarness h = WorkoutHarness();
  final _Navigator navigator = _Navigator();
  late final UndoStack stack;

  List<Override> get overrides => [
    changeSetApplierProvider.overrideWithValue(h.applier),
    clockProvider.overrideWithValue(h.clock),
    idGeneratorProvider.overrideWithValue(
      SequenceIdGenerator(startMs: 0x0199e3c30000),
    ),
    undoStackProvider.overrideWithValue(stack),
    workoutRepositoryProvider.overrideWithValue(h.repository),
    appNavigatorProvider.overrideWithValue(navigator),
    weekStartProvider.overrideWith((ref) => Stream.value(DayOfWeek.saturday)),
    exerciseLibraryProvider.overrideWith(
      (ref) async => ExerciseLibrary([
        LibraryExercise(
          id: wid(1),
          name: 'Cable fly',
          aliases: const [],
          type: ExerciseType.weightReps,
          equipment: Equipment.cable,
          primary: Muscle.chest,
        ),
      ]),
    ),
  ];

  Future<void> seed(WidgetTester tester, List<ChangeOp> ops) =>
      tester.runAsync(() => h.apply(ops));

  Future<void> pump(WidgetTester tester, Widget screen) async {
    tester.view
      ..physicalSize = const Size(400, 1600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(overrides: overrides, child: phoneApp(screen)),
    );
    await settle(tester);
  }

  /// Lets the database answer, then settles the frames.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 40)),
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  /// Takes the screen down so streams and undo timers end.
  Future<void> unmount(WidgetTester tester) async {
    stack.dispose();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
  }
}

void main() {
  testWidgets('UX-010 Workouts tab first visit offers Pick exercises', (
    tester,
  ) async {
    final rig = _Rig();
    await rig.pump(tester, const WorkoutsScreen());
    expect(find.byKey(const ValueKey('workouts-pick')), findsOneWidget);
    expect(find.byKey(const ValueKey('workouts-log')), findsNothing);
    await rig.unmount(tester);
  });

  testWidgets("WO-034 form shows last session's numbers per exercise", (
    tester,
  ) async {
    final rig = _Rig();
    await rig.seed(tester, [
      CreateCustomExercise(wid(1), benchDraft()),
      LogWorkoutSession(wid(10), sessionDraft(date: today.plusDays(-2))),
    ]);
    await rig.pump(tester, WorkoutLogScreen.newSession(exercises: [wid(1)]));

    final rows = tester.widgetList<SetRow>(find.byType(SetRow)).toList();
    expect(
      [for (final r in rows) r.row.hint],
      const [
        SetValues(reps: 8, kg: 80),
        SetValues(reps: 8, kg: 80),
        SetValues(reps: 7, kg: 80),
      ],
    );
    expect(rows.every((r) => !r.row.checked), isTrue);
    // The fields carry last time's numbers as hints (D7).
    final fields = tester
        .widgetList<FbNumberField>(
          find.descendant(
            of: find.byWidget(rows.last),
            matching: find.byType(FbNumberField),
          ),
        )
        .toList();
    expect([for (final f in fields) f.hint], ['80', '7']);

    // A set is removed from its number's menu: a labelled 48 × 48 target.
    final menu = find.byKey(ValueKey('workout-set-menu-${rows.last.row.id}'));
    expect(tester.getSize(menu).width, greaterThanOrEqualTo(48));
    expect(tester.getSize(menu).height, greaterThanOrEqualTo(48));
    await tester.tap(menu);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('workout-set-remove')));
    await tester.pumpAndSettle();
    expect(find.byType(SetRow), findsNWidgets(2));
    await rig.unmount(tester);
  });

  testWidgets('WO-040 history lists sessions by date', (tester) async {
    final rig = _Rig();
    await rig.seed(tester, [
      CreateCustomExercise(wid(1), benchDraft()),
      LogWorkoutSession(wid(10), sessionDraft(date: today.plusDays(-3))),
      LogWorkoutSession(
        wid(11),
        sessionDraft(
          date: today.plusDays(-1),
          exerciseRow: 21,
          sets: [lifted(40, 5, 90)],
        ),
      ),
    ]);
    await rig.pump(tester, const WorkoutHistoryScreen());

    final newer = find.byKey(ValueKey('workout-history-${wid(11)}'));
    final older = find.byKey(ValueKey('workout-history-${wid(10)}'));
    expect(newer, findsOneWidget);
    expect(older, findsOneWidget);
    expect(tester.getTopLeft(newer).dy, lessThan(tester.getTopLeft(older).dy));
    expect(find.byType(FbSectionHeader), findsNWidgets(2));
    await tester.tap(newer);
    expect(rig.navigator.pushed.single, isA<WorkoutSessionRoute>());
    await rig.unmount(tester);
  });
}
