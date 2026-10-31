import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/ids/id_generator.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_mobile/features/workouts/application/exercise_library.dart';
import 'package:fb_mobile/features/workouts/application/workout_actions.dart';
import 'package:fb_mobile/features/workouts/presentation/plan_setup_screen.dart';
import 'package:fb_mobile/features/workouts/presentation/template_editor_screen.dart';
import 'package:fb_mobile/features/workouts/workouts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/catalog/support/catalog_support.dart';
import '../../today/presentation/support/today_support.dart' show phoneApp;
import '../support/workout_harness.dart';

final class _Navigator implements AppNavigator {
  int pops = 0;

  @override
  void go(AppRoute route) => throw UnimplementedError();

  @override
  void push(AppRoute route) {}

  @override
  void pop() => pops++;
}

/// The plan screens over a real database (with the starter exercises'
/// pack) and applier.
final class _Rig {
  new() {
    final ids = {
      for (final t in StarterTemplate.values)
        for (final i in t.items) i.exerciseId,
    };
    final rows = [
      for (final id in ids)
        "  ('$id', '$id', 'weight_reps', 'barbell', 'chest', '', 1, 1)",
    ];
    final (db, catalog) = fixtureCatalog(
      extraSql: 'INSERT INTO exercises VALUES\n${rows.join(',\n')};',
    );
    addTearDown(catalog.dispose);
    h = WorkoutHarness(database: db);
    stack = UndoStack(
      revert: h.applier.revert,
      apply: h.applier.apply,
      clock: h.clock,
    );
  }

  late final WorkoutHarness h;
  late final UndoStack stack;
  final _Navigator navigator = _Navigator();

  /// How many of the next writes are refused (a failed save).
  int refuse = 0;

  /// When set, writes wait for it (a slow save).
  Completer<void>? gate;

  Future<ApplyResult> _apply(ChangeSet set) async {
    await gate?.future;
    if (refuse > 0) {
      refuse--;
      return const Rejected(InvalidOp('test'));
    }
    return await h.applier.apply(set);
  }

  Future<void> pump(
    WidgetTester tester,
    Widget screen, {
    double textScale = 1,
  }) async {
    tester.view
      ..physicalSize = const Size(400, 1600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          changeSetApplierProvider.overrideWithValue(h.applier),
          clockProvider.overrideWithValue(h.clock),
          idGeneratorProvider.overrideWithValue(
            SequenceIdGenerator(startMs: 0x0199e3c30000),
          ),
          undoStackProvider.overrideWithValue(stack),
          workoutRepositoryProvider.overrideWithValue(h.repository),
          appNavigatorProvider.overrideWithValue(navigator),
          workoutActionsProvider.overrideWith(
            (ref) => WorkoutActions(
              apply: _apply,
              undoStack: stack,
              ids: SequenceIdGenerator(startMs: 0x0199e3c50000),
              repository: h.repository,
            ),
          ),
          weekStartProvider.overrideWith(
            (ref) => Stream.value(DayOfWeek.saturday),
          ),
          exerciseLibraryProvider.overrideWith(
            (ref) async => ExerciseLibrary([
              LibraryExercise(
                id: 'ex:barbell_bench_press',
                name: 'Barbell bench press',
                aliases: const [],
                type: ExerciseType.weightReps,
                equipment: Equipment.barbell,
                primary: Muscle.chest,
              ),
              LibraryExercise(
                id: 'ex:plank',
                name: 'Plank',
                aliases: const [],
                type: ExerciseType.duration,
                equipment: Equipment.bodyweight,
                primary: Muscle.abs,
              ),
            ]),
          ),
        ],
        child: phoneApp(screen, textScale: textScale),
      ),
    );
    await settle(tester);
  }

  /// The chooser, pushed on a navigator over an opener screen (as the
  /// router does), so its closing is visible.
  Future<void> pumpChooser(WidgetTester tester) async {
    await pump(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FbButton.primary(
              label: 'open',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const StarterPlansScreen(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(FbButton));
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

  Future<void> unmount(WidgetTester tester) async {
    stack.dispose();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
  }
}

void main() {
  testWidgets('WO-023 D-089 a plan starts empty: only the exercises the user '
      'adds are saved, with the chosen days, in one change', (tester) async {
    final rig = _Rig();
    await rig.pumpChooser(tester);
    // Nothing is chosen until the user picks an option.
    expect(
      tester
          .widget<FbButton>(
            find.byKey(const ValueKey('workout-starter-continue')),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const ValueKey('workout-starter-fullBody')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('workout-starter-continue')));
    await rig.settle(tester);
    // Pre-filled Saturday, Monday, Wednesday: swap Monday for Tuesday.
    await tester.tap(find.byKey(const ValueKey('workout-starter-day-monday')));
    await tester.pump();
    // Two days don't fit a 3-day plan.
    expect(
      tester
          .widget<FbButton>(find.byKey(const ValueKey('workout-starter-apply')))
          .onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const ValueKey('workout-starter-day-tuesday')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('workout-starter-apply')));
    await rig.settle(tester);

    // Day A starts empty, with suggestions to add.
    expect(find.byType(PlanSetupScreen), findsOneWidget);
    expect(find.text('Your Full body A exercises'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey('workout-setup-line-fullBodyA-ex:barbell_back_squat'),
      ),
      findsNothing,
    );
    await tester.tap(
      find.byKey(const ValueKey('workout-setup-add-ex:barbell_back_squat')),
    );
    await tester.pump();
    expect(
      find.byKey(
        const ValueKey('workout-setup-line-fullBodyA-ex:barbell_back_squat'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('workout-setup-next')));
    await rig.settle(tester);
    // Day B is still empty: Save waits for it.
    expect(
      tester
          .widget<FbButton>(find.byKey(const ValueKey('workout-setup-next')))
          .onPressed,
      isNull,
    );
    await tester.tap(
      find.byKey(const ValueKey('workout-setup-add-all-fullBodyB')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('workout-setup-next')));
    await rig.settle(tester);

    final templates = (await tester.runAsync(
      () => rig.h.repository.watchTemplates().first,
    ))!;
    final byName = {for (final t in templates) t.draft.name: t};
    expect(byName.keys.toSet(), {'Full body A', 'Full body B'});
    expect(
      [for (final i in byName['Full body A']!.draft.items) i.exerciseId],
      ['ex:barbell_back_squat'],
    );
    expect(
      [for (final i in byName['Full body B']!.draft.items) i.exerciseId],
      [for (final i in StarterTemplate.fullBodyB.items) i.exerciseId],
    );
    final plan = (await tester.runAsync(rig.h.repository.plan))!;
    expect(plan.keys.toSet(), {
      DayOfWeek.saturday,
      DayOfWeek.tuesday,
      DayOfWeek.wednesday,
    });
    // A, B, A.
    expect(plan[DayOfWeek.saturday], plan[DayOfWeek.wednesday]);
    expect(plan[DayOfWeek.tuesday], isNot(plan[DayOfWeek.saturday]));
    // The chooser closed itself through its own navigator; the router's
    // current location (maybe another tab) was never popped.
    expect(find.byType(StarterPlansScreen), findsNothing);
    expect(rig.navigator.pops, 0);
    // One change: one Undo takes it all back.
    await tester.tap(find.byType(SnackBarAction));
    await rig.settle(tester);
    expect(
      await tester.runAsync(() => rig.h.repository.watchTemplates().first),
      isEmpty,
    );
    await rig.unmount(tester);
  });

  testWidgets('D-089 a refused save keeps every choice for another try', (
    tester,
  ) async {
    final rig = _Rig();
    await rig.pump(
      tester,
      const PlanSetupScreen(
        plan: StarterPlan.fullBody,
        days: {DayOfWeek.saturday, DayOfWeek.monday, DayOfWeek.wednesday},
        weekStart: DayOfWeek.saturday,
      ),
    );
    await tester.tap(
      find.byKey(const ValueKey('workout-setup-add-all-fullBodyA')),
    );
    await tester.tap(find.byKey(const ValueKey('workout-setup-next')));
    await rig.settle(tester);
    await tester.tap(
      find.byKey(const ValueKey('workout-setup-add-all-fullBodyB')),
    );
    await tester.pump();
    rig.refuse = 1;
    await tester.tap(find.byKey(const ValueKey('workout-setup-next')));
    await rig.settle(tester);
    // Still here, with the choices.
    expect(find.byType(PlanSetupScreen), findsOneWidget);
    expect(
      await tester.runAsync(() => rig.h.repository.watchTemplates().first),
      isEmpty,
    );
    await tester.tap(find.byKey(const ValueKey('workout-setup-next')));
    await rig.settle(tester);
    expect(
      (await tester.runAsync(() => rig.h.repository.watchTemplates().first))!
          .map((t) => t.draft.items.length),
      [
        StarterTemplate.fullBodyA.items.length,
        StarterTemplate.fullBodyB.items.length,
      ],
    );
    await rig.unmount(tester);
  });

  testWidgets('D-089 while Save plan runs nothing else navigates; the save '
      'closes the setup screen only', (tester) async {
    final rig = _Rig();
    bool? saved;
    await rig.pump(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FbButton.primary(
              label: 'open',
              onPressed: () async => saved = await openPlanSetup(
                context,
                StarterPlan.fullBody,
                days: StarterPlan.fullBody
                    .defaultDays(DayOfWeek.saturday)
                    .toSet(),
                weekStart: DayOfWeek.saturday,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(FbButton));
    await rig.settle(tester);
    await tester.tap(
      find.byKey(const ValueKey('workout-setup-add-all-fullBodyA')),
    );
    await tester.tap(find.byKey(const ValueKey('workout-setup-next')));
    await rig.settle(tester);
    await tester.tap(
      find.byKey(const ValueKey('workout-setup-add-all-fullBodyB')),
    );
    await tester.pump();
    rig.gate = Completer<void>();
    await tester.tap(find.byKey(const ValueKey('workout-setup-next')));
    await tester.pump();
    // The save is pending: search and Back do nothing.
    await tester.tap(
      find.byKey(const ValueKey('workout-setup-find-fullBodyB')),
      warnIfMissed: false,
    );
    await tester.pump();
    expect(find.byType(ExercisePickerScreen), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(PlanSetupScreen), findsOneWidget);
    rig.gate!.complete();
    await rig.settle(tester);
    expect(find.byType(PlanSetupScreen), findsNothing);
    expect(find.byType(FbButton), findsOneWidget);
    expect(saved, isTrue);
    await rig.unmount(tester);
  });

  testWidgets('D-089 the day tabs fit at text scale 2.0', (tester) async {
    for (final plan in StarterPlan.values) {
      final rig = _Rig();
      await rig.pump(
        tester,
        PlanSetupScreen(
          plan: plan,
          days: plan.defaultDays(DayOfWeek.saturday).toSet(),
          weekStart: DayOfWeek.saturday,
        ),
        textScale: 2,
      );
      tester.view.physicalSize = const Size(360, 800);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: plan.name);
      await rig.unmount(tester);
    }
  });

  testWidgets('D-089 No plan clears the weekly plan once, with Undo', (
    tester,
  ) async {
    final rig = _Rig();
    await tester.runAsync(
      () => rig.h.apply([
        CreateWorkoutTemplate(
          wid(5),
          WorkoutTemplateDraft(name: 'Mine', items: const []),
        ),
        SetPlanDay(DayOfWeek.monday, wid(5)),
      ]),
    );
    await rig.pumpChooser(tester);
    await tester.tap(find.byKey(const ValueKey('workout-starter-none')));
    await tester.pump();
    // A double tap runs it once and closes the chooser once.
    await tester.tap(find.byKey(const ValueKey('workout-starter-continue')));
    await tester.tap(
      find.byKey(const ValueKey('workout-starter-continue')),
      warnIfMissed: false,
    );
    await rig.settle(tester);
    expect(await tester.runAsync(rig.h.repository.plan), isEmpty);
    // The chooser closed itself through its own navigator; the router's
    // current location (maybe another tab) was never popped.
    expect(find.byType(StarterPlansScreen), findsNothing);
    expect(rig.navigator.pops, 0);
    await tester.tap(find.byType(SnackBarAction));
    await rig.settle(tester);
    expect(await tester.runAsync(rig.h.repository.plan), {
      DayOfWeek.monday: wid(5),
    });
    await rig.unmount(tester);
  });

  testWidgets('WO-020 template editor saves a template', (tester) async {
    final rig = _Rig();
    String? saved;
    await rig.pump(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FbButton.primary(
              label: 'open',
              onPressed: () async => saved = await openTemplateEditor(context),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(FbButton));
    await rig.settle(tester);
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('workout-template-name')),
        matching: find.byType(EditableText),
      ),
      'Push',
    );
    await tester.tap(find.byKey(const ValueKey('workout-template-add')));
    await rig.settle(tester);
    // Time exercises aren't offered for template lines (A37 D17).
    expect(find.byKey(const ValueKey('workout-pick-ex:plank')), findsNothing);
    await tester.tap(
      find.byKey(const ValueKey('workout-pick-ex:barbell_bench_press')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('workout-pick-add')));
    await rig.settle(tester);
    // 3 × 10 by default; one more set.
    final lines = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith(
            'workout-template-sets-',
          ),
    );
    expect(lines, findsOneWidget);
    await tester.tap(
      find.descendant(of: lines, matching: find.byIcon(FbIcons.add)),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('workout-template-save')));
    await rig.settle(tester);

    final stored = (await tester.runAsync(
      () => rig.h.repository.watchTemplates().first,
    ))!.single;
    expect(saved, stored.ref.id);
    expect(stored.draft.name, 'Push');
    expect(stored.draft.items.single.exerciseId, 'ex:barbell_bench_press');
    expect(stored.draft.items.single.sets, 4);
    expect(stored.draft.items.single.reps, 10);
    await rig.unmount(tester);
  });

  testWidgets('WO-021 weekly plan sets a weekday template', (tester) async {
    final rig = _Rig();
    await tester.runAsync(
      () => rig.h.apply([
        CreateWorkoutTemplate(
          wid(5),
          WorkoutTemplateDraft(
            name: 'Mine',
            items: [
              TemplateItemDraft(
                id: wid(6),
                exerciseId: 'ex:barbell_bench_press',
                sets: 3,
                reps: 8,
              ),
            ],
          ),
        ),
      ]),
    );
    await rig.pump(tester, const WeeklyPlanScreen());
    await tester.tap(find.byKey(const ValueKey('workout-plan-day-monday')));
    await rig.settle(tester);
    // The template's name is user content, shown as an option.
    await tester.tap(find.text('Mine').last);
    await rig.settle(tester);
    expect(await tester.runAsync(rig.h.repository.plan), {
      DayOfWeek.monday: wid(5),
    });
    await rig.unmount(tester);
  });
}
