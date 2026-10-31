import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/ids/id_generator.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/workouts/application/exercise_library.dart';
import 'package:fb_mobile/features/workouts/application/workout_views.dart';
import 'package:fb_mobile/features/workouts/data/workout_repository.dart';
import 'package:fb_mobile/features/workouts/presentation/custom_exercise_screen.dart';
import 'package:fb_mobile/features/workouts/presentation/exercise_muscle_map.dart';
import 'package:fb_mobile/features/workouts/presentation/exercise_picker_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../today/presentation/support/today_support.dart' show phoneApp;
import '../support/workout_harness.dart';

LibraryExercise _exercise(
  String id,
  String name,
  Muscle primary, {
  int? popularity,
  Equipment equipment = Equipment.barbell,
}) => LibraryExercise(
  id: id,
  name: name,
  aliases: const [],
  type: ExerciseType.weightReps,
  equipment: equipment,
  primary: primary,
  popularity: popularity,
);

final ExerciseLibrary _library = ExerciseLibrary([
  _exercise(
    'ex:barbell_bench_press',
    'Barbell bench press',
    Muscle.chest,
    popularity: 1,
  ),
  _exercise('ex:barbell_row', 'Barbell row', Muscle.upperBack, popularity: 12),
  _exercise('ex:squat', 'Squat', Muscle.quadriceps, popularity: 2),
  _exercise(
    'ex:lat_pulldown',
    'Lat pulldown',
    Muscle.upperBack,
    popularity: 3,
    equipment: Equipment.cable,
  ),
]);

/// A screen with one button that runs [open] and keeps its result.
Widget _opener(Future<void> Function(BuildContext context) open) => Builder(
  builder: (context) => Scaffold(
    body: Center(
      child: FbButton.primary(label: 'open', onPressed: () => open(context)),
    ),
  ),
);

void main() {
  testWidgets('WO-001 picker multi-selects and returns the order', (
    tester,
  ) async {
    usePhoneTall(tester);
    List<String>? picked;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          exerciseLibraryProvider.overrideWith((ref) async => _library),
        ],
        child: phoneApp(
          _opener((context) async => picked = await pickExercises(context)),
        ),
      ),
    );
    await tester.tap(find.byType(FbButton));
    await tester.pumpAndSettle();
    expect(find.byType(ExercisePickerScreen), findsOneWidget);
    // No history yet: the list is still headed "Most popular" (D-089).
    expect(find.byKey(const ValueKey('workout-pick-recent')), findsNothing);
    expect(find.byKey(const ValueKey('workout-pick-popular')), findsOneWidget);
    // WO-007: every row shows its exercise's muscle map.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('workout-pick-ex:squat')),
        matching: find.byType(ExerciseMuscleMap),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('workout-pick-ex:squat')));
    await tester.tap(
      find.byKey(const ValueKey('workout-pick-ex:barbell_bench_press')),
    );
    await tester.pump();
    // Unpicking and picking again moves it to the end.
    await tester.tap(find.byKey(const ValueKey('workout-pick-ex:squat')));
    await tester.tap(find.byKey(const ValueKey('workout-pick-ex:squat')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('workout-pick-add')));
    await tester.pumpAndSettle();
    expect(picked, ['ex:barbell_bench_press', 'ex:squat']);
  });

  testWidgets('WO-001 D-089 picker lists Your recent with the last result, '
      'then the rest by popularity; equipment filters both', (tester) async {
    usePhoneTall(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          exerciseLibraryProvider.overrideWith((ref) async => _library),
          recentExercisesProvider.overrideWith(
            (ref) async => [
              (
                exerciseId: 'ex:barbell_row',
                date: today,
                top: const SetValues(reps: 8, kg: 62.5),
              ),
            ],
          ),
        ],
        child: phoneApp(_opener(pickExercises)),
      ),
    );
    await tester.tap(find.byType(FbButton));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('workout-pick-recent')), findsOneWidget);
    expect(find.textContaining('last: 62.5 × 8'), findsOneWidget);
    double top(String id) =>
        tester.getTopLeft(find.byKey(ValueKey('workout-pick-$id'))).dy;
    // Recent first, then the popular section, most popular first; a recent
    // exercise isn't listed twice.
    expect(
      top('ex:barbell_row'),
      lessThan(
        tester
            .getTopLeft(find.byKey(const ValueKey('workout-pick-popular')))
            .dy,
      ),
    );
    expect(
      find.byKey(const ValueKey('workout-pick-ex:barbell_row')),
      findsOneWidget,
    );
    expect(top('ex:barbell_bench_press'), lessThan(top('ex:squat')));
    expect(top('ex:squat'), lessThan(top('ex:lat_pulldown')));

    // Cable only: the barbell recent and popular rows go.
    await tester.tap(find.byKey(const ValueKey('workout-pick-equipment')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cable').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('workout-pick-recent')), findsNothing);
    expect(find.byKey(const ValueKey('workout-pick-ex:squat')), findsNothing);
    expect(
      find.byKey(const ValueKey('workout-pick-ex:lat_pulldown')),
      findsOneWidget,
    );

    // Typing leaves the sections: plain search results.
    await tester.tap(find.byKey(const ValueKey('workout-pick-equipment')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Any equipment').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).first, 'barbell');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('workout-pick-recent')), findsNothing);
    expect(top('ex:barbell_bench_press'), lessThan(top('ex:barbell_row')));
  });

  testWidgets(
    'WO-003 WO-007 custom exercise form creates an exercise with muscles, '
    'map live',
    (tester) async {
      usePhoneTall(tester);
      final h = WorkoutHarness();
      final stack = UndoStack(revert: h.applier.revert, clock: h.clock);
      String? created;
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
            exerciseLibraryProvider.overrideWith((ref) async => _library),
          ],
          child: phoneApp(
            _opener(
              (context) async => created = await openCustomExercise(
                context,
                initialName: 'Cable fly',
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(FbButton));
      await tester.pumpAndSettle();
      expect(find.byType(CustomExerciseScreen), findsOneWidget);

      // Too many aliases: a field error instead of a silent Save.
      final aliases = find.byKey(const ValueKey('workout-custom-aliases'));
      await tester.enterText(
        find.descendant(of: aliases, matching: find.byType(EditableText)),
        List.generate(11, (i) => 'fly $i').join(', '),
      );
      await tester.pump();
      expect(tester.widget<FbTextField>(aliases).errorText, isNotNull);
      // An alias over 80 characters: a field error too.
      await tester.enterText(
        find.descendant(of: aliases, matching: find.byType(EditableText)),
        'low fly, ${'x' * 81}',
      );
      await tester.pump();
      expect(tester.widget<FbTextField>(aliases).errorText, isNotNull);
      await tester.enterText(
        find.descendant(of: aliases, matching: find.byType(EditableText)),
        'low fly',
      );
      await tester.pump();
      expect(tester.widget<FbTextField>(aliases).errorText, isNull);

      // WO-007: the muscle map follows the muscle chips live.
      FbMuscleMap map() => tester.widget<FbMuscleMap>(
        find.descendant(
          of: find.byKey(const ValueKey('workout-custom-map')),
          matching: find.byType(FbMuscleMap),
        ),
      );
      expect(map().primary, isEmpty);
      await tester.tap(
        find.byKey(const ValueKey('workout-custom-primary-chest')),
      );
      await tester.pump();
      expect(map().primary, {FbBodyRegion.chest});
      await tester.tap(
        find.byKey(const ValueKey('workout-custom-secondary-shoulders')),
      );
      await tester.pump();
      expect(map().secondary, {FbBodyRegion.deltoids});
      await tester.ensureVisible(
        find.byKey(const ValueKey('workout-custom-save')),
      );
      await tester.tap(find.byKey(const ValueKey('workout-custom-save')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();

      final rows = await tester.runAsync(
        () => h.repository.watchCustomExercises().first,
      );
      final stored = rows!.single;
      expect(created, stored.ref.id);
      expect(stored.draft.name, 'Cable fly');
      expect(stored.draft.primaryMuscle, Muscle.chest);
      expect(stored.draft.secondaryMuscles, [Muscle.shoulders]);
      expect(stored.draft.aliases, ['low fly']);

      // Let the undo snackbar expire before the tree goes.
      stack.dispose();
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(seconds: 6));
      }
      await tester.pumpWidget(const SizedBox());
    },
  );
}

/// A 360 x 1600 phone, so every chip fits.
void usePhoneTall(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(360, 1600)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}
