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
import 'package:fb_mobile/features/workouts/presentation/exercise_muscle_map.dart';
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
          secondaries: const [Muscle.triceps],
        ),
        LibraryExercise(
          id: wid(2),
          name: 'Lateral raise',
          aliases: const [],
          type: ExerciseType.weightReps,
          equipment: Equipment.dumbbell,
          primary: Muscle.shoulders,
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

  testWidgets('D-089 Workouts tab: plan card on a planned day, recent rows '
      'with maps and Repeat, Your plan row', (tester) async {
    final rig = _Rig();
    await rig.seed(tester, [
      CreateCustomExercise(wid(1), benchDraft()),
      LogWorkoutSession(wid(10), sessionDraft(date: today.plusDays(-2))),
      CreateWorkoutTemplate(
        wid(70),
        WorkoutTemplateDraft(
          name: 'Push',
          items: [
            TemplateItemDraft(
              id: wid(71),
              exerciseId: wid(1),
              sets: 3,
              reps: 8,
            ),
          ],
        ),
      ),
      SetPlanDay(today.weekday, wid(70)),
    ]);
    await rig.pump(tester, const WorkoutsScreen());
    expect(find.byKey(const ValueKey('workouts-plan-card')), findsOneWidget);
    expect(find.text('Log Push'), findsOneWidget);
    // "Something else" picks other exercises instead.
    expect(find.byKey(const ValueKey('workouts-log')), findsOneWidget);
    expect(find.text('This week'), findsOneWidget);
    final recent = find.byKey(ValueKey('workouts-recent-${wid(10)}'));
    expect(
      find.descendant(of: recent, matching: find.byType(ExerciseMuscleMap)),
      findsOneWidget,
    );
    await tester.tap(find.byKey(ValueKey('workouts-repeat-${wid(10)}')));
    expect((rig.navigator.pushed.last as WorkoutLogRoute).repeat, wid(10));
    // "Your plan · Push · Thu".
    expect(find.textContaining('Push · Thu'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('workouts-plan')));
    expect(rig.navigator.pushed.last, isA<WorkoutPlanRoute>());
    await tester.tap(find.byKey(const ValueKey('workouts-plan-log')));
    expect((rig.navigator.pushed.last as WorkoutLogRoute).template, wid(70));
    await rig.unmount(tester);
  });

  testWidgets('D-089 Workouts tab without a plan: Log a workout card; No plan '
      'row opens the chooser', (tester) async {
    final rig = _Rig();
    await rig.seed(tester, [
      CreateCustomExercise(wid(1), benchDraft()),
      LogWorkoutSession(wid(10), sessionDraft(date: today.plusDays(-1))),
    ]);
    await rig.pump(tester, const WorkoutsScreen());
    expect(find.byKey(const ValueKey('workouts-log-card')), findsOneWidget);
    expect(find.byKey(const ValueKey('workouts-plan-card')), findsNothing);
    expect(find.text('No plan'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('workouts-plan')));
    expect(rig.navigator.pushed.last, isA<WorkoutStarterPlansRoute>());
    await tester.tap(find.byKey(const ValueKey('workouts-exercises')));
    expect(rig.navigator.pushed.last, isA<WorkoutExercisesRoute>());
    await rig.unmount(tester);
  });

  testWidgets('D-089 log form: session muscles and progress on top, a map '
      'per card, untouched cards after the first hidden', (tester) async {
    final rig = _Rig();
    await rig.seed(tester, [
      CreateCustomExercise(wid(1), benchDraft()),
      CreateCustomExercise(
        wid(2),
        CustomExerciseDraft(
          name: 'Lateral raise',
          type: ExerciseType.weightReps,
          equipment: Equipment.dumbbell,
        ),
      ),
    ]);
    await rig.pump(
      tester,
      WorkoutLogScreen.newSession(exercises: [wid(1), wid(2)]),
    );
    expect(find.text('Chest · Shoulders'), findsOneWidget);
    expect(find.text('0 of 2 exercises logged · 0 sets'), findsOneWidget);
    // The summary's map and one per card.
    expect(find.byType(ExerciseMuscleMap), findsNWidgets(3));
    // The second card waits hidden: only the first card's set row shows.
    expect(find.byType(SetRow), findsOneWidget);
    expect(find.textContaining('1 set planned'), findsOneWidget);
    final second = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith(
            'workout-card-collapse-',
          ),
    );
    await tester.tap(second.last);
    await tester.pump();
    expect(find.byType(SetRow), findsNWidgets(2));

    // Checking a set counts the exercise as logged.
    final row = tester.widgetList<SetRow>(find.byType(SetRow)).first;
    await tester.enterText(
      find
          .descendant(
            of: find.byType(SetRow).first,
            matching: find.byType(EditableText),
          )
          .first,
      '60',
    );
    await tester.enterText(
      find
          .descendant(
            of: find.byType(SetRow).first,
            matching: find.byType(EditableText),
          )
          .last,
      '8',
    );
    await tester.tap(find.byKey(ValueKey('workout-set-done-${row.row.id}')));
    await rig.settle(tester);
    expect(find.text('1 of 2 exercises logged · 1 set'), findsOneWidget);
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

  /// A Push template (2 × 12 of exercise 1), a past session (8 @ 80 kg) for
  /// hints, and a new session from the template with both sets accepted
  /// (8, 8: it differs), left with Done. Returns the rig at the offer sheet.
  Future<_Rig> leaveDifferingTemplateVisit(WidgetTester tester) async {
    final rig = _Rig();
    await rig.seed(tester, [
      CreateCustomExercise(wid(1), benchDraft()),
      LogWorkoutSession(wid(10), sessionDraft(date: today.plusDays(-2))),
      CreateWorkoutTemplate(
        wid(70),
        WorkoutTemplateDraft(
          name: 'Push',
          items: [
            TemplateItemDraft(
              id: wid(71),
              exerciseId: wid(1),
              sets: 2,
              reps: 12,
            ),
          ],
        ),
      ),
    ]);
    await rig.pump(tester, WorkoutLogScreen.newSession(template: wid(70)));
    for (final row in tester.widgetList<SetRow>(find.byType(SetRow)).toList()) {
      await tester.tap(find.byKey(ValueKey('workout-set-done-${row.row.id}')));
      await tester.pump();
    }
    await tester.tap(find.byKey(const ValueKey('workout-log-done')));
    await rig.settle(tester);
    expect(
      find.byKey(const ValueKey('workout-template-offer-update')),
      findsOneWidget,
    );
    return rig;
  }

  Future<List<int>> templateReps(WidgetTester tester, _Rig rig) async => [
    for (final i in (await tester.runAsync(
      () => rig.h.repository.watchTemplates().first,
    ))!.single.draft.items)
      i.reps,
  ];

  Future<int> sessionCount(WidgetTester tester, _Rig rig) async =>
      (await tester.runAsync(rig.h.repository.allSessions))!.length;

  /// Taps the snackbar's Undo and lets the database answer.
  Future<void> tapUndo(WidgetTester tester, _Rig rig) async {
    await tester.tap(find.byType(SnackBarAction));
    await rig.settle(tester);
  }

  testWidgets('WO-022 Update writes the template; its Undo also undoes the '
      'workout', (tester) async {
    final rig = await leaveDifferingTemplateVisit(tester);
    await tester.tap(
      find.byKey(const ValueKey('workout-template-offer-update')),
    );
    await rig.settle(tester);
    expect(await templateReps(tester, rig), [8]);
    expect(await sessionCount(tester, rig), 2);
    await tapUndo(tester, rig);
    // The template update and the new session are both undone.
    expect(await templateReps(tester, rig), [12]);
    expect(await sessionCount(tester, rig), 1);
    await rig.unmount(tester);
  });

  testWidgets('WO-022 a refused Update keeps the workout Undo', (tester) async {
    final rig = await leaveDifferingTemplateVisit(tester);
    // The template changes elsewhere while the question is open.
    final template = (await tester.runAsync(
      () => rig.h.repository.watchTemplates().first,
    ))!.single;
    await rig.seed(tester, [
      UpdateWorkoutTemplate(
        template.ref,
        WorkoutTemplateDraft(
          name: 'Push',
          items: [
            TemplateItemDraft(
              id: wid(71),
              exerciseId: wid(1),
              sets: 2,
              reps: 15,
            ),
          ],
        ),
      ),
    ]);
    await tester.tap(
      find.byKey(const ValueKey('workout-template-offer-update')),
    );
    await rig.settle(tester);
    expect(await templateReps(tester, rig), [15]);
    expect(await sessionCount(tester, rig), 2);
    await tapUndo(tester, rig);
    expect(await sessionCount(tester, rig), 1);
    expect(await templateReps(tester, rig), [15]);
    await rig.unmount(tester);
  });

  testWidgets('WO-022 Not now leaves the template and keeps the workout '
      'Undo', (tester) async {
    final rig = await leaveDifferingTemplateVisit(tester);
    await tester.tap(find.byKey(const ValueKey('workout-template-offer-skip')));
    await rig.settle(tester);
    expect(await templateReps(tester, rig), [12]);
    expect(await sessionCount(tester, rig), 2);
    await tapUndo(tester, rig);
    expect(await sessionCount(tester, rig), 1);
    await rig.unmount(tester);
  });
}
