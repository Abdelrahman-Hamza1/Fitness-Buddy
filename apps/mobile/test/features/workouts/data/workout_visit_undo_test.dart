import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/workouts/application/workout_actions.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/workout_harness.dart';

Matcher _invalid(String code) =>
    isA<InvalidOp>().having((f) => f.code, 'code', code);

/// A custom exercise with muscles.
CustomExerciseDraft _flyDraft({
  Muscle? primary = Muscle.chest,
  List<Muscle> secondaries = const [Muscle.shoulders],
}) => CustomExerciseDraft(
  name: 'Cable fly',
  type: ExerciseType.weightReps,
  equipment: Equipment.cable,
  primaryMuscle: primary,
  secondaryMuscles: secondaries,
);

/// Applies [ops] like an autosave and returns the session's version after.
Future<int> _save(WorkoutHarness h, List<ChangeOp> ops) async {
  final applied = await h.apply(ops);
  return applied.versionAfter('workout_sessions', wid(10))!;
}

void main() {
  test(
    'WO-003 custom exercise muscles round-trip and undo restores them',
    () async {
      final h = WorkoutHarness();
      await h.apply([CreateCustomExercise(wid(1), _flyDraft())]);
      final row = await h.db.select(h.db.customExercises).getSingle();
      expect(row.primaryMuscle, 'chest');
      expect(row.secondaryMusclesJson, '["shoulders"]');
      final stored = (await h.repository.watchCustomExercises().first).single;
      expect(stored.draft, _flyDraft());

      final edited = _flyDraft(
        primary: Muscle.triceps,
        secondaries: [Muscle.chest, Muscle.shoulders],
      );
      final edit = await h.apply([
        UpdateCustomExercise(VersionedId(wid(1), 1), edited),
      ]);
      expect(
        (await h.repository.watchCustomExercises().first).single.draft,
        edited,
      );
      // The same muscles again write nothing.
      expect(
        (await h.apply([UpdateCustomExercise(VersionedId(wid(1), 2), edited)]))
            .inverse
            .isEmpty,
        isTrue,
      );
      expect(await h.undo(edit), isA<Applied>());
      expect(
        (await h.repository.watchCustomExercises().first).single.draft,
        _flyDraft(),
      );
    },
  );

  test('WO-034 update revives an owned tombstoned set and exercise with the '
      'same IDs', () async {
    final h = WorkoutHarness();
    await h.seedExercise();
    await h.apply([LogWorkoutSession(wid(10), sessionDraft())]);
    // Uncheck set 32 (autosave drops it), then remove the whole exercise.
    var version = await _save(h, [
      UpdateWorkoutSession(
        VersionedId(wid(10), 1),
        sessionDraft(sets: [lifted(30, 8, 80), lifted(31, 8, 80)]),
      ),
    ]);
    expect(await h.isTombstone('workout_sets', wid(32)), isTrue);
    version = await _save(h, [
      UpdateWorkoutSession(
        VersionedId(wid(10), version),
        WorkoutSessionDraft(date: today, name: 'Push', exercises: const []),
      ),
    ]);
    expect(await h.isTombstone('session_exercises', wid(20)), isTrue);

    // Re-check: the same IDs come back, with the draft's values.
    final revive = await h.apply([
      UpdateWorkoutSession(
        VersionedId(wid(10), version),
        sessionDraft(
          sets: [lifted(30, 8, 80), lifted(31, 8, 80), lifted(32, 6, 85)],
        ),
      ),
    ]);
    for (final set in [30, 31, 32]) {
      expect(await h.isTombstone('workout_sets', wid(set)), isFalse);
    }
    expect(await h.isTombstone('session_exercises', wid(20)), isFalse);
    final session = (await h.repository.session(wid(10)))!;
    expect(session.draft.exercises.single.id, wid(20));
    expect(
      session.draft.exercises.single.sets.last.values,
      const SetValues(reps: 6, kg: 85),
    );
    // Its undo puts the tombstones back.
    expect(await h.undo(revive), isA<Applied>());
    expect(await h.isTombstone('workout_sets', wid(32)), isTrue);
    expect(await h.isTombstone('session_exercises', wid(20)), isTrue);
  });

  test(
    'WO-034 a tombstone of another session is still childOwnership',
    () async {
      final h = WorkoutHarness();
      await h.seedExercise();
      await h.apply([
        LogWorkoutSession(wid(10), sessionDraft()),
        LogWorkoutSession(
          wid(11),
          sessionDraft(exerciseRow: 21, sets: [lifted(40, 5, 100)]),
        ),
      ]);
      // Session 10 loses set 32, then exercise 20 entirely.
      await h.apply([
        UpdateWorkoutSession(
          VersionedId(wid(10), 1),
          sessionDraft(sets: [lifted(30, 8, 80), lifted(31, 8, 80)]),
        ),
      ]);
      await h.apply([
        UpdateWorkoutSession(
          VersionedId(wid(10), 2),
          WorkoutSessionDraft(date: today, exercises: const []),
        ),
      ]);
      // Session 11 can't take session 10's tombstoned set or exercise.
      expect(
        await h.reject([
          UpdateWorkoutSession(
            VersionedId(wid(11), 1),
            sessionDraft(
              exerciseRow: 21,
              sets: [lifted(40, 5, 100), lifted(32, 5, 100)],
            ),
          ),
        ]),
        _invalid('childOwnership'),
      );
      expect(
        await h.reject([
          UpdateWorkoutSession(
            VersionedId(wid(11), 1),
            sessionDraft(sets: [lifted(41, 5, 100)]),
          ),
        ]),
        _invalid('childOwnership'),
      );
    },
  );

  test('Applied.versionAfter reads the session version after insert and '
      'update', () async {
    final h = WorkoutHarness();
    await h.seedExercise();
    final logged = await h.apply([LogWorkoutSession(wid(10), sessionDraft())]);
    expect(logged.versionAfter('workout_sessions', wid(10)), 1);
    expect(logged.versionAfter('workout_sets', wid(30)), 1);
    expect(logged.versionAfter('workout_sessions', wid(99)), isNull);
    final updated = await h.apply([
      UpdateWorkoutSession(
        VersionedId(wid(10), 1),
        sessionDraft(sets: [lifted(30, 9, 80)]),
      ),
    ]);
    expect(updated.versionAfter('workout_sessions', wid(10)), 2);
    expect(
      updated.versionAfter('workout_sessions', wid(10)),
      await h.version('workout_sessions', wid(10)),
    );
  });

  group('one Undo per visit (A37 D9)', () {
    late WorkoutHarness h;
    late UndoStack stack;
    setUp(() {
      h = WorkoutHarness();
      stack = UndoStack(
        revert: h.applier.revert,
        apply: h.applier.apply,
        clock: h.clock,
      );
      addTearDown(stack.dispose);
    });

    ChangeSet compensation(String visitId, ChangeOp op) =>
        ChangeSet([op], origin: Origin.undo(visitId));

    test('UX-030 compensation undo deletes a session created in the '
        'visit', () async {
      await h.seedExercise();
      final before = await h.state();
      final first = await h.apply([
        LogWorkoutSession(wid(10), sessionDraft(sets: [lifted(30, 8, 80)])),
      ]);
      var version = first.versionAfter('workout_sessions', wid(10))!;
      version = await _save(h, [
        UpdateWorkoutSession(
          VersionedId(wid(10), version),
          sessionDraft(sets: [lifted(30, 8, 80), lifted(31, 8, 80)]),
        ),
      ]);
      final entry = stack.recordCompensation(
        first.changeSetId,
        UndoLabel('workoutSaved'),
        compensation(
          first.changeSetId,
          DeleteWorkoutSession(VersionedId(wid(10), version)),
        ),
      );
      expect(await stack.undo(entry.id), UndoOutcome.undone);
      expect(await h.state(), before);
      expect(await h.repository.session(wid(10)), isNull);
    });

    test('UX-030 compensation undo restores an edited session including '
        'children removed in the visit', () async {
      await h.seedExercise();
      await h.apply([LogWorkoutSession(wid(10), sessionDraft())]);
      final baseline = (await h.repository.session(wid(10)))!;
      final before = await h.state();
      // The visit: remove set 32 (autosave), add set 33, edit set 30.
      final first = await h.apply([
        UpdateWorkoutSession(
          baseline.ref,
          sessionDraft(sets: [lifted(30, 8, 80), lifted(31, 8, 80)]),
        ),
      ]);
      var version = first.versionAfter('workout_sessions', wid(10))!;
      version = await _save(h, [
        UpdateWorkoutSession(
          VersionedId(wid(10), version),
          sessionDraft(
            sets: [lifted(30, 9, 82.5), lifted(31, 8, 80), lifted(33, 6, 80)],
          ),
        ),
      ]);
      final entry = stack.recordCompensation(
        first.changeSetId,
        UndoLabel('workoutUpdated'),
        compensation(
          first.changeSetId,
          UpdateWorkoutSession(VersionedId(wid(10), version), baseline.draft),
        ),
      );
      expect(await stack.undo(entry.id), UndoOutcome.undone);
      // Same content and the same child IDs as before the visit.
      expect(await h.state(), before);
      expect((await h.repository.session(wid(10)))!.draft, baseline.draft);
      expect(await h.isTombstone('workout_sets', wid(33)), isTrue);
    });

    test('UX-030 compensation after a later change is a conflict and writes '
        'nothing', () async {
      await h.seedExercise();
      final first = await h.apply([
        LogWorkoutSession(wid(10), sessionDraft(sets: [lifted(30, 8, 80)])),
      ]);
      final frozen = first.versionAfter('workout_sessions', wid(10))!;
      final entry = stack.recordCompensation(
        first.changeSetId,
        UndoLabel('workoutSaved'),
        compensation(
          first.changeSetId,
          DeleteWorkoutSession(VersionedId(wid(10), frozen)),
        ),
      );
      // Another editor changes the session after the visit.
      await h.apply([
        UpdateWorkoutSession(
          VersionedId(wid(10), frozen),
          sessionDraft(sets: [lifted(30, 10, 80)]),
        ),
      ]);
      final before = await h.raw();
      expect(await stack.undo(entry.id), UndoOutcome.conflict);
      expect(await h.raw(), before);
    });
  });

  test('WO-003 D15 a session logged after the app-level "unused" check '
      'still blocks the delete, inside the write transaction', () async {
    final h = WorkoutHarness();
    await h.seedExercise();
    final stack = UndoStack(revert: h.applier.revert, clock: h.clock);
    addTearDown(stack.dispose);
    final actions = WorkoutActions(
      // The session lands between the check and the delete's write.
      apply: (set) async {
        if (set.ops.any((op) => op is DeleteCustomExercise)) {
          await h.apply([LogWorkoutSession(wid(10), sessionDraft())]);
        }
        return await h.applier.apply(set);
      },
      undoStack: stack,
      ids: SequenceIdGenerator(startMs: 0x0199e3c30000),
      repository: h.repository,
    );
    final stored = (await h.repository.watchCustomExercises().first).single;
    final outcome = await actions.deleteExercise(stored);
    expect(
      outcome,
      isA<WorkoutActionFailed>().having(
        (f) => f.reason,
        'reason',
        WorkoutActionFailure.inUse,
      ),
    );
    expect(await h.isTombstone('custom_exercises', wid(1)), isFalse);
    // And the handler refuses it outright.
    expect(
      await h.reject([DeleteCustomExercise(stored.ref)]),
      _invalid('exerciseInUse'),
    );
  });
}
