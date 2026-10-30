import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:fb_mobile/core/ids/id_generator.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/workouts/application/exercise_library.dart';
import 'package:fb_mobile/features/workouts/application/template_editor.dart';
import 'package:fb_mobile/features/workouts/application/workout_actions.dart';
import 'package:fb_mobile/features/workouts/data/workout_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/workout_harness.dart';

void main() {
  test('WO-020 a storage failure in Save or Delete keeps the inputs and lets '
      'the user retry', () async {
    final h = WorkoutHarness();
    await h.apply([
      CreateCustomExercise(wid(1), benchDraft()),
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
    ]);
    final undo = UndoStack(revert: h.applier.revert, clock: h.clock);
    addTearDown(undo.dispose);
    final container = ProviderContainer(
      overrides: [
        workoutRepositoryProvider.overrideWithValue(h.repository),
        idGeneratorProvider.overrideWithValue(SequenceIdGenerator()),
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
        workoutActionsProvider.overrideWithValue(
          WorkoutActions(
            apply: (_) async => throw Exception('disk full'),
            undoStack: undo,
            ids: SequenceIdGenerator(),
            repository: h.repository,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final key = TemplateEditorKey(visitId: 'v1', templateId: wid(70));
    final provider = templateEditorProvider(key);
    container.listen(provider, (_, _) {});
    await container.read(provider.future);
    final editor = container.read(provider.notifier)..setName('Push day');

    expect(
      await editor.save(),
      isA<WorkoutActionFailed>().having(
        (f) => f.reason,
        'reason',
        WorkoutActionFailure.invalid,
      ),
    );
    var state = container.read(provider).requireValue;
    expect(state.saving, isFalse);
    expect(state.name, 'Push day');
    expect(state.lines, hasLength(1));

    expect(await editor.delete(), isA<WorkoutActionFailed>());
    state = container.read(provider).requireValue;
    expect(state.saving, isFalse);
    // Nothing was written.
    final stored = (await h.repository.watchTemplates().first).single;
    expect(stored.draft.name, 'Push');
  });
}
