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
        "  ('$id', '$id', 'weight_reps', 'barbell', 'chest', '', 1)",
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

  Future<void> pump(WidgetTester tester, Widget screen) async {
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
        child: phoneApp(screen),
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

  Future<void> unmount(WidgetTester tester) async {
    stack.dispose();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
  }
}

void main() {
  testWidgets('WO-023 gallery applies Full body with chosen days', (
    tester,
  ) async {
    final rig = _Rig();
    await rig.pump(tester, const StarterPlansScreen());
    await tester.tap(find.byKey(const ValueKey('workout-starter-fullBody')));
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

    final templates = await tester.runAsync(
      () => rig.h.repository.watchTemplates().first,
    );
    expect(templates, hasLength(2));
    final plan = (await tester.runAsync(rig.h.repository.plan))!;
    expect(plan.keys.toSet(), {
      DayOfWeek.saturday,
      DayOfWeek.tuesday,
      DayOfWeek.wednesday,
    });
    // A, B, A.
    expect(plan[DayOfWeek.saturday], plan[DayOfWeek.wednesday]);
    expect(plan[DayOfWeek.tuesday], isNot(plan[DayOfWeek.saturday]));
    expect(rig.navigator.pops, 1);
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
