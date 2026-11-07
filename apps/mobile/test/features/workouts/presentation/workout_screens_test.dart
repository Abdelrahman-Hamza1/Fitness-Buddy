import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/ids/id_generator.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/core/ui/load_states.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_mobile/features/workouts/application/workout_log_state.dart';
import 'package:fb_mobile/features/workouts/application/workout_views.dart';
import 'package:fb_mobile/features/workouts/presentation/exercise_muscle_map.dart';
import 'package:fb_mobile/features/workouts/presentation/set_row.dart';
import 'package:fb_mobile/features/workouts/workouts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../today/presentation/support/today_support.dart' show phoneApp;
import '../support/workout_harness.dart';

/// A set row ID: the domain checks it is a canonical UUID.
const _setId = '00000000-0000-4000-8000-0000000000a1';

/// The "Same as last time" button of the (only) exercise card.
final Finder _sameAsLast = find.byWidgetPredicate(
  (w) =>
      w.key is ValueKey<String> &&
      (w.key! as ValueKey<String>).value.startsWith('workout-same-as-last-'),
);

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

  /// Replaces the fixture exercise library (a failing read, A57 A45).
  Override? library;

  /// More overrides (failing or never-answering providers, A57 A42–A45).
  List<Override> extra = const [];

  List<Override> get overrides => [
    ...extra,
    changeSetApplierProvider.overrideWithValue(h.applier),
    clockProvider.overrideWithValue(h.clock),
    idGeneratorProvider.overrideWithValue(
      SequenceIdGenerator(startMs: 0x0199e3c30000),
    ),
    undoStackProvider.overrideWithValue(stack),
    workoutRepositoryProvider.overrideWithValue(h.repository),
    appNavigatorProvider.overrideWithValue(navigator),
    weekStartProvider.overrideWith((ref) => Stream.value(DayOfWeek.saturday)),
    library ??
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

  Future<void> pump(
    WidgetTester tester,
    Widget screen, {
    Size size = const Size(400, 1600),
    double textScale = 1,
    bool disableAnimations = true,
    TextDirection? direction,
  }) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: phoneApp(
          direction == null
              ? screen
              : Directionality(textDirection: direction, child: screen),
          textScale: textScale,
          disableAnimations: disableAnimations,
        ),
      ),
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

    // A set with numbers counts the exercise as logged: no tick (D-097).
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
    await rig.settle(tester);
    expect(find.byType(Checkbox), findsNothing);
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
    expect(rows.every((r) => !r.row.counts), isTrue);
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
  /// hints, and a new session from the template with both sets filled by
  /// "Same as last time" (8, 8: it differs), left with Done. Returns the
  /// rig at the offer sheet.
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
    await tester.tap(_sameAsLast);
    await tester.pump();
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

  testWidgets('A57 A42 T-R2 Workouts tab: a failed read shows error + retry, '
      'not the first-visit state; loading shows rows', (tester) async {
    var fail = true;
    final rig = _Rig()
      ..extra = [
        recentWorkoutsProvider.overrideWith((ref) async {
          if (fail) throw StateError('read failed');
          return const <SessionSummary>[];
        }),
      ];
    await rig.pump(tester, const WorkoutsScreen());
    expect(find.byKey(LoadFailedView.viewKey), findsOneWidget);
    expect(find.byKey(const ValueKey('workouts-pick')), findsNothing);
    fail = false;
    await tester.tap(
      find.descendant(
        of: find.byKey(LoadFailedView.viewKey),
        matching: find.byType(TextButton),
      ),
    );
    await rig.settle(tester);
    expect(find.byKey(LoadFailedView.viewKey), findsNothing);
    expect(find.byKey(const ValueKey('workouts-pick')), findsOneWidget);
    await rig.unmount(tester);

    final waiting = _Rig()
      ..extra = [
        recentWorkoutsProvider.overrideWith(
          (ref) => Completer<List<SessionSummary>>().future,
        ),
      ];
    await waiting.pump(tester, const WorkoutsScreen());
    expect(find.byKey(LoadingRows.viewKey), findsOneWidget);
    expect(find.byType(FbEmptyState), findsNothing);
    await waiting.unmount(tester);
  });

  testWidgets('A57 A43 A44 A45 T-R3 history error is not "no workouts"; a '
      'loading plan is not all rest; a session read error is not "deleted"', (
    tester,
  ) async {
    final history = _Rig()
      ..extra = [
        workoutHistoryProvider.overrideWith(
          (ref) async => throw StateError('read failed'),
        ),
      ];
    await history.pump(tester, const WorkoutHistoryScreen());
    expect(find.byKey(LoadFailedView.viewKey), findsOneWidget);
    expect(find.byType(FbEmptyState), findsNothing);
    await history.unmount(tester);

    final plan = _Rig()
      ..extra = [
        workoutPlanProvider.overrideWith(
          (ref) => const Stream<Map<DayOfWeek, String>>.empty(),
        ),
      ];
    await plan.pump(tester, const WeeklyPlanScreen());
    expect(find.byKey(LoadingRows.viewKey), findsOneWidget);
    expect(
      find.byKey(const ValueKey('workout-plan-day-saturday')),
      findsNothing,
    );
    await plan.unmount(tester);

    final session = _Rig()
      ..library = exerciseLibraryProvider.overrideWith(
        (ref) async => throw StateError('read failed'),
      );
    await session.pump(tester, WorkoutLogScreen.session(wid(10)));
    expect(find.byKey(LoadFailedView.viewKey), findsOneWidget);
    expect(find.byType(FbEmptyState), findsNothing);
    await session.unmount(tester);
  });

  testWidgets('A57 A51 A05 T-A1 C1 set row: at 320 dp and 2.0 text "last '
      'time" sits above the inputs, the status line is reserved and the '
      'inputs stay on screen; the normal row keeps its input widths when '
      'PR appears', (tester) async {
    Future<void> pumpRow(
      Size size,
      double scale, {
      bool pr = false,
      bool counts = false,
    }) async {
      tester.view
        ..physicalSize = size
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        phoneApp(
          Scaffold(
            body: Padding(
              padding: const EdgeInsetsDirectional.all(FbSpace.s4),
              child: SetRow(
                row: LogSetRow(
                  id: _setId,
                  hint: const SetValues(reps: 8, kg: 60),
                  saved: counts
                      ? LoggedSet(_setId, const SetValues(reps: 8, kg: 60))
                      : null,
                ),
                number: 1,
                type: ExerciseType.weightReps,
                isPr: pr,
                onChanged: (_) {},
                onRemove: () {},
              ),
            ),
          ),
          textScale: scale,
        ),
      );
    }

    await pumpRow(const Size(320, 640), 2);
    final last = find.byKey(const ValueKey('workout-set-last-$_setId'));
    final status = find.byKey(const ValueKey('workout-set-status-$_setId'));
    expect(find.byKey(const ValueKey('workout-set-compact-$_setId')), findsOne);
    expect(
      tester.getBottomLeft(last).dy,
      lessThanOrEqualTo(tester.getTopLeft(find.byType(FbNumberField).first).dy),
    );
    expect(
      tester.getTopRight(find.byType(FbNumberField).last).dx,
      lessThanOrEqualTo(320),
    );
    final emptyLine = tester.getSize(status).height;
    expect(emptyLine, greaterThan(0));
    await pumpRow(const Size(320, 640), 2, pr: true, counts: true);
    expect(tester.getSize(status).height, emptyLine);

    await pumpRow(const Size(400, 800), 1);
    expect(
      find.byKey(const ValueKey('workout-set-compact-$_setId')),
      findsNothing,
    );
    final width = tester.getSize(find.byType(FbNumberField).first).width;
    await pumpRow(const Size(400, 800), 1, pr: true, counts: true);
    expect(tester.getSize(find.byType(FbNumberField).first).width, width);
  });

  group('A63 sets without ticks', () {
    /// A form for exercise 1 with last session's three sets as hints.
    Future<_Rig> openWithHints(
      WidgetTester tester, {
      Size size = const Size(400, 1600),
      double textScale = 1,
      bool disableAnimations = true,
      TextDirection? direction,
    }) async {
      final rig = _Rig();
      await rig.seed(tester, [
        CreateCustomExercise(wid(1), benchDraft()),
        LogWorkoutSession(wid(10), sessionDraft(date: today.plusDays(-2))),
      ]);
      await rig.pump(
        tester,
        WorkoutLogScreen.newSession(exercises: [wid(1)]),
        size: size,
        textScale: textScale,
        disableAnimations: disableAnimations,
        direction: direction,
      );
      return rig;
    }

    List<LogSetRow> rows(WidgetTester tester) => [
      for (final r in tester.widgetList<SetRow>(find.byType(SetRow))) r.row,
    ];

    Finder header() => find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('workout-set-header-'),
    );

    // The column's reveal around a set row: it carries the row's key (the
    // keyed child inside it does too) and animates the row's height.
    Finder setRowOf(String rowId) => find.byWidgetPredicate(
      (w) => w is FbReveal && w.key == ValueKey('workout-set-$rowId'),
    );

    Finder fieldsOf(String rowId) => find.descendant(
      of: find.byKey(ValueKey(rowId)),
      matching: find.byType(EditableText),
    );

    testWidgets('UX-070 UX-045 A63 D15 T-W7 set rows: one header per card and '
        'no checkbox at 1.0; compact rows keep their labels at 2.0 / 320 dp; '
        'the issue mark appears only after focus leaves the row', (
      tester,
    ) async {
      final rig = await openWithHints(tester);
      expect(header(), findsOne);
      expect(find.byType(Checkbox), findsNothing);
      expect(
        tester
            .widgetList<FbNumberField>(find.byType(FbNumberField))
            .every((f) => f.hideLabel && f.dashedWhenEmpty),
        isTrue,
      );
      // Half-typed: weight without reps. No error while typing.
      final first = rows(tester).first.id;
      final second = rows(tester)[1].id;
      await tester.enterText(fieldsOf(first).first, '60');
      await tester.pump();
      expect(rows(tester).first.issue, isNotNull);
      expect(find.byIcon(FbIcons.error), findsNothing);
      // Focus moves to the next row: the mark shows on the first.
      await tester.tap(fieldsOf(second).first);
      await tester.pump();
      expect(find.byIcon(FbIcons.error), findsOne);
      await rig.unmount(tester);

      final compact = await openWithHints(
        tester,
        size: const Size(320, 1600),
        textScale: 2,
      );
      expect(header(), findsNothing);
      expect(
        tester
            .widgetList<FbNumberField>(find.byType(FbNumberField))
            .every((f) => !f.hideLabel),
        isTrue,
      );
      expect(tester.takeException(), isNull);
      await compact.unmount(tester);
    });

    testWidgets('WO-034 D-097 T-W4 Same as last time fills the empty rows; '
        'the button goes when nothing is left to fill', (tester) async {
      final rig = await openWithHints(tester);
      expect(_sameAsLast, findsOne);
      await tester.tap(_sameAsLast);
      await rig.settle(tester);
      expect(rows(tester).every((r) => r.counts), isTrue);
      expect(_sameAsLast, findsNothing);
      expect(find.byType(Checkbox), findsNothing);
      await rig.unmount(tester);
    });

    testWidgets('W5 UX-030 T-W8 swiping a set row removes it with an Undo '
        'snackbar; Undo brings it back once, at full width, with its numbers', (
      tester,
    ) async {
      final rig = await openWithHints(tester);
      final id = rows(tester)[1].id;
      await tester.enterText(fieldsOf(id).first, '70');
      await tester.enterText(fieldsOf(id).last, '6');
      await tester.pump();
      final width = tester.getSize(setRowOf(id));
      // Drag from the set number (not a field) toward the start edge.
      await tester.drag(
        find.byKey(ValueKey('workout-set-menu-$id')),
        const Offset(-320, 0),
      );
      await rig.settle(tester);
      expect(rows(tester).map((r) => r.id), isNot(contains(id)));
      expect(find.byType(SnackBarAction), findsOne);
      await tester.tap(find.byType(SnackBarAction));
      await rig.settle(tester);
      expect(rows(tester)[1].id, id);
      expect(rows(tester)[1].saved!.values, const SetValues(reps: 6, kg: 70));
      expect(setRowOf(id), findsOne);
      expect(tester.getSize(setRowOf(id)), width);
      await rig.unmount(tester);
    });

    testWidgets('W5 A63 PA7 T-W8 with motion: one collapse, no full-height '
        'reappearance; Undo mid-exit shows the row once, not slid out', (
      tester,
    ) async {
      final rig = await openWithHints(tester, disableAnimations: false);
      final id = rows(tester)[1].id;
      final row = setRowOf(id);
      final full = tester.getSize(row).height;
      await tester.drag(
        find.byKey(ValueKey('workout-set-menu-$id')),
        const Offset(-320, 0),
      );
      // Let the slide finish, then watch the collapse frame by frame.
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (row.evaluate().isEmpty) break;
        expect(row, findsOne);
      }
      var previous = full;
      for (var i = 0; i < 8 && row.evaluate().isNotEmpty; i++) {
        final height = tester.getSize(row).height;
        expect(height, lessThanOrEqualTo(previous + 0.01));
        previous = height;
        await tester.pump(const Duration(milliseconds: 25));
      }
      await tester.pumpAndSettle();
      expect(row, findsNothing);

      // Swipe the next one and undo while it is still leaving.
      final next = rows(tester)[1].id;
      final nextRow = setRowOf(next);
      await tester.drag(
        find.byKey(ValueKey('workout-set-menu-$next')),
        const Offset(-320, 0),
      );
      // The slide ends and the row starts to collapse; one more frame shows
      // this removal's snackbar in place of the first one's.
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 50));
      expect(
        tester.widget<FbReveal>(nextRow).visible,
        isFalse,
        reason: 'still leaving',
      );
      tester.widget<SnackBarAction>(find.byType(SnackBarAction)).onPressed();
      await tester.pumpAndSettle();
      expect(nextRow, findsOne);
      expect(tester.getSize(nextRow).height, closeTo(full, 0.01));
      // Not slid out: the row's number is on screen where it was.
      final menu = tester.getRect(
        find.byKey(ValueKey('workout-set-menu-$next')),
      );
      expect(menu.left, greaterThanOrEqualTo(0));
      expect(tester.takeException(), isNull);
      await rig.unmount(tester);
    });

    testWidgets('W5 T-W8 the Remove set action (TalkBack) and the menu remove '
        'a set; reduced motion removes at once; RTL swipes toward the start '
        'edge', (tester) async {
      final rig = await openWithHints(tester);
      final first = rows(tester).first.id;
      FbSwipeActions swipeOf(String id) => tester.widget<FbSwipeActions>(
        find.ancestor(
          of: find.byKey(ValueKey(id)),
          matching: find.byType(FbSwipeActions),
        ),
      );
      expect(swipeOf(first).collapseOnDismiss, isFalse);
      // The custom semantics action runs the same callback.
      swipeOf(first).dismissAction!.onTriggered();
      await tester.pump();
      expect(rows(tester).map((r) => r.id), isNot(contains(first)));
      expect(find.byType(SnackBarAction), findsOne);
      // The number's menu removes another, also with Undo.
      final next = rows(tester).first.id;
      await tester.tap(find.byKey(ValueKey('workout-set-menu-$next')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('workout-set-remove')));
      await tester.pump();
      expect(rows(tester).map((r) => r.id), isNot(contains(next)));
      await rig.unmount(tester);

      final rtl = await openWithHints(tester, direction: TextDirection.rtl);
      final id = rows(tester).first.id;
      // In right-to-left the start edge is on the right.
      await tester.drag(
        find.byKey(ValueKey('workout-set-menu-$id')),
        const Offset(320, 0),
      );
      await rtl.settle(tester);
      expect(rows(tester).map((r) => r.id), isNot(contains(id)));
      await rtl.unmount(tester);
    });
  });
}
