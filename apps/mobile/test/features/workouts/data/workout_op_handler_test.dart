import 'package:drift/drift.dart' show OrderingTerm;
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/db/write_guard.dart';
import 'package:fb_mobile/features/workouts/workouts.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/workout_harness.dart';

Matcher _invalid(String code) =>
    isA<InvalidOp>().having((f) => f.code, 'code', code);

void main() {
  group('custom exercises', () {
    test(
      'WO-003 create, edit and delete a custom exercise, each undoable',
      () async {
        final h = WorkoutHarness();
        final created = await h.seedExercise();
        final row = await h.db.select(h.db.customExercises).getSingle();
        expect(row.name, 'Cable fly');
        expect(row.aliasesJson, '["fly"]');
        expect((row.exerciseType, row.equipment), ('weight_reps', 'cable'));

        final edited = await h.apply([
          UpdateCustomExercise(
            VersionedId(wid(1), 1),
            CustomExerciseDraft(
              name: 'Low cable fly',
              type: ExerciseType.weightReps,
              equipment: Equipment.cable,
            ),
          ),
        ]);
        expect(
          (await h.db.select(h.db.customExercises).getSingle()).name,
          'Low cable fly',
        );
        expect(await h.undo(edited), isA<Applied>());
        expect(
          (await h.db.select(h.db.customExercises).getSingle()).name,
          'Cable fly',
        );

        final deleted = await h.apply([
          DeleteCustomExercise(VersionedId(wid(1), 3)),
        ]);
        expect(await h.isTombstone('custom_exercises', wid(1)), isTrue);
        expect(await h.undo(deleted), isA<Applied>());
        expect(await h.isTombstone('custom_exercises', wid(1)), isFalse);
        expect(created.inverse, isNotNull);
      },
    );

    test("WO-004 a custom exercise type can't change while sets use it, and "
        'undoing its creation is refused then', () async {
      final h = WorkoutHarness();
      final created = await h.seedExercise();
      await h.apply([LogWorkoutSession(wid(10), sessionDraft())]);
      expect(
        await h.reject([
          UpdateCustomExercise(
            VersionedId(wid(1), 1),
            benchDraft(type: ExerciseType.repsOnly),
          ),
        ]),
        _invalid('typeInUse'),
      );
      final undo = await h.undo(created);
      expect(undo, isA<Rejected>());
      expect((undo as Rejected).failure, _invalid('exerciseInUse'));
    });

    test('WO-003 undoing a change set that created the exercise and its '
        'session together goes through', () async {
      final h = WorkoutHarness();
      final both = await h.apply([
        CreateCustomExercise(wid(1), benchDraft()),
        LogWorkoutSession(wid(10), sessionDraft()),
      ]);
      expect(await h.undo(both), isA<Applied>());
      expect(await h.isTombstone('custom_exercises', wid(1)), isTrue);
      expect(await h.isTombstone('workout_sessions', wid(10)), isTrue);
    });

    test('WO-003 a template using the exercise also blocks undoing its '
        'creation', () async {
      final h = WorkoutHarness();
      final created = await h.seedExercise();
      await h.apply([
        CreateWorkoutTemplate(
          wid(50),
          WorkoutTemplateDraft(
            name: 'Push',
            items: [
              TemplateItemDraft(
                id: wid(60),
                exerciseId: wid(1),
                sets: 3,
                reps: 8,
              ),
            ],
          ),
        ),
      ]);
      expect(await h.undo(created), isA<Rejected>());
    });

    test('WO-003 the same ID twice is refused', () async {
      final h = WorkoutHarness();
      await h.seedExercise();
      expect(
        await h.reject([CreateCustomExercise(wid(1), benchDraft())]),
        _invalid('duplicateId'),
      );
    });
  });

  group('sessions', () {
    test('WO-010 logging writes the session, its exercises and sets in '
        'order, with the weight as typed', () async {
      final h = WorkoutHarness();
      await h.seedExercise();
      final draft = sessionDraft(
        sets: [
          LoggedSet(
            wid(30),
            const SetValues(reps: 8, kg: 79.83225699),
            inputValue: 176,
            inputUnit: MassUnit.pound,
          ),
          lifted(31, 6, 85),
        ],
      );
      await h.apply([LogWorkoutSession(wid(10), draft)]);
      final session = await h.db.select(h.db.workoutSessions).getSingle();
      expect((session.localDate, session.name), ('2026-10-29', 'Push'));
      final sets = await (h.db.select(
        h.db.workoutSets,
      )..orderBy([(t) => OrderingTerm(expression: t.position)])).get();
      expect(
        [for (final s in sets) (s.position, s.reps, s.inputUnit)],
        [(0, 8, 'lb'), (1, 6, 'kg')],
      );
      expect(sets.first.inputValue, 176);
      expect(sets.last.inputValue, 85);
      final stored = await h.repository.sessions(today, today);
      expect(stored.single.ref, VersionedId(wid(10), 1));
      expect(stored.single.draft, draft);
    });

    test('WO-061 logging emits WorkoutSessionLogged and the logged dates '
        'follow', () async {
      final h = WorkoutHarness();
      await h.seedExercise();
      final logged = h.bus.on<WorkoutSessionLogged>().first;
      final yesterday = today.plusDays(-1);
      await h.apply([
        LogWorkoutSession(wid(10), sessionDraft(date: yesterday)),
      ]);
      expect(await logged, WorkoutSessionLogged(wid(10), yesterday));
      expect(
        await h.repository
            .watchLoggedDates(yesterday.plusDays(-6), today)
            .first,
        {yesterday},
      );
    });

    test('WO-011 a past date is fine, a future one is refused', () async {
      final h = WorkoutHarness();
      await h.seedExercise();
      await h.apply([
        LogWorkoutSession(wid(10), sessionDraft(date: LocalDate(2025, 1, 1))),
      ]);
      expect(
        await h.reject([
          LogWorkoutSession(
            wid(11),
            sessionDraft(
              date: today.plusDays(1),
              exerciseRow: 21,
              sets: [lifted(40, 8, 80)],
            ),
          ),
        ]),
        _invalid('future'),
      );
    });

    test('WO-004 sets must fit the exercise type; unknown exercises and '
        'duplicate IDs are refused', () async {
      final h = WorkoutHarness();
      await h.seedExercise();
      expect(
        await h.reject([
          LogWorkoutSession(
            wid(10),
            sessionDraft(sets: [LoggedSet(wid(30), const SetValues(reps: 8))]),
          ),
        ]),
        _invalid('invalidSet'),
      );
      expect(
        await h.reject([
          LogWorkoutSession(
            wid(10),
            WorkoutSessionDraft(
              date: today,
              exercises: [
                SessionExerciseDraft(
                  id: wid(20),
                  exerciseId: 'ex:barbell_bench_press', // no pack attached
                  sets: [lifted(30, 8, 80)],
                ),
              ],
            ),
          ),
        ]),
        _invalid('unknownExercise'),
      );
      await h.apply([LogWorkoutSession(wid(10), sessionDraft())]);
      expect(
        await h.reject([LogWorkoutSession(wid(11), sessionDraft())]),
        _invalid('duplicateId'),
      );
    });

    test(
      'A36 D7 an edit updates kept children in place, inserts new ones '
      'and tombstones removed ones atomically; undo restores it all',
      () async {
        final h = WorkoutHarness();
        await h.seedExercise();
        await h.apply([LogWorkoutSession(wid(10), sessionDraft())]);
        final before = await h.state();
        final edit = await h.apply([
          UpdateWorkoutSession(
            VersionedId(wid(10), 1),
            sessionDraft(sets: [lifted(30, 8, 82.5), lifted(33, 8, 82.5)]),
          ),
        ]);
        expect(await h.version('workout_sets', wid(30)), 2);
        expect(await h.isTombstone('workout_sets', wid(31)), isTrue);
        expect(await h.isTombstone('workout_sets', wid(32)), isTrue);
        expect(await h.isTombstone('workout_sets', wid(33)), isFalse);
        // The session's content is unchanged, but its version (the
        // aggregate revision) moved with the children.
        expect(await h.version('workout_sessions', wid(10)), 2);
        expect(await h.undo(edit), isA<Applied>());
        expect(await h.state(), before);
      },
    );

    test('A36 D7 removing an exercise tombstones its sets too', () async {
      final h = WorkoutHarness();
      await h.seedExercise();
      await h.apply([LogWorkoutSession(wid(10), sessionDraft())]);
      await h.apply([
        UpdateWorkoutSession(
          VersionedId(wid(10), 1),
          WorkoutSessionDraft(date: today, name: 'Push', exercises: const []),
        ),
      ]);
      for (final set in [30, 31, 32]) {
        expect(await h.isTombstone('workout_sets', wid(set)), isTrue);
      }
      expect(await h.isTombstone('session_exercises', wid(20)), isTrue);
    });

    test('A36 D7 a child ID owned by another session is refused', () async {
      final h = WorkoutHarness();
      await h.seedExercise();
      await h.apply([
        LogWorkoutSession(wid(10), sessionDraft()),
        LogWorkoutSession(
          wid(11),
          sessionDraft(exerciseRow: 21, sets: [lifted(40, 5, 100)]),
        ),
      ]);
      expect(
        await h.reject([
          UpdateWorkoutSession(
            VersionedId(wid(11), 1),
            sessionDraft(exerciseRow: 21, sets: [lifted(30, 5, 100)]),
          ),
        ]),
        _invalid('childOwnership'),
      );
      expect(
        await h.reject([
          UpdateWorkoutSession(
            VersionedId(wid(11), 1),
            sessionDraft(sets: [lifted(40, 5, 100)]),
          ),
        ]),
        _invalid('childOwnership'),
      );
    });

    test('A36 D7 two editors of the same session version conflict even when '
        'they only touch sets', () async {
      final h = WorkoutHarness();
      await h.seedExercise();
      await h.apply([LogWorkoutSession(wid(10), sessionDraft())]);
      await h.apply([
        UpdateWorkoutSession(
          VersionedId(wid(10), 1),
          sessionDraft(
            sets: [lifted(30, 8, 82.5), lifted(31, 8, 80), lifted(32, 7, 80)],
          ),
        ),
      ]);
      expect(
        await h.reject([
          UpdateWorkoutSession(
            VersionedId(wid(10), 1),
            sessionDraft(
              sets: [lifted(30, 8, 80), lifted(31, 9, 80), lifted(32, 7, 80)],
            ),
          ),
        ]),
        isA<VersionConflict>(),
      );
    });

    test('A36 D7 undoing a session log is refused once children were added '
        'later', () async {
      final h = WorkoutHarness();
      await h.seedExercise();
      final logged = await h.apply([
        LogWorkoutSession(wid(10), sessionDraft()),
      ]);
      await h.apply([
        UpdateWorkoutSession(
          VersionedId(wid(10), 1),
          sessionDraft(
            sets: [
              lifted(30, 8, 80),
              lifted(31, 8, 80),
              lifted(32, 7, 80),
              lifted(33, 6, 80),
            ],
          ),
        ),
      ]);
      final before = await h.raw();
      expect(await h.undo(logged), isA<Rejected>());
      expect(await h.raw(), before);
      expect(await h.isTombstone('workout_sets', wid(33)), isFalse);
    });

    test('WO-004 undo that would restore sets the exercise type no longer '
        'fits is refused', () async {
      final h = WorkoutHarness();
      await h.seedExercise();
      await h.apply([LogWorkoutSession(wid(10), sessionDraft())]);
      final deleted = await h.apply([
        DeleteWorkoutSession(VersionedId(wid(10), 1)),
      ]);
      // Nothing uses it any more, so the type may change.
      await h.apply([
        UpdateCustomExercise(
          VersionedId(wid(1), 1),
          benchDraft(type: ExerciseType.duration),
        ),
      ]);
      final before = await h.raw();
      final undo = await h.undo(deleted);
      expect(undo, isA<Rejected>());
      expect(
        (undo as Rejected).failure,
        isA<InvalidOp>().having((f) => f.code, 'code', 'incompatibleSets'),
      );
      expect(await h.raw(), before);
    });

    test('WO-004 undo that restores an exercise reference checks its '
        'unchanged sets against the retyped exercise', () async {
      final h = WorkoutHarness();
      await h.seedExercise(); // A = wid(1), weight × reps
      await h.apply([CreateCustomExercise(wid(2), benchDraft())]); // B
      await h.apply([LogWorkoutSession(wid(10), sessionDraft())]);
      // Same exercise row and sets, now pointing at B.
      final edit = await h.apply([
        UpdateWorkoutSession(
          VersionedId(wid(10), 1),
          WorkoutSessionDraft(
            date: today,
            name: 'Push',
            exercises: [
              SessionExerciseDraft(
                id: wid(20),
                exerciseId: wid(2),
                sets: [lifted(30, 8, 80), lifted(31, 8, 80), lifted(32, 7, 80)],
              ),
            ],
          ),
        ),
      ]);
      expect(await h.version('workout_sets', wid(30)), 1);
      // A is unused now, so it may become a timed exercise.
      await h.apply([
        UpdateCustomExercise(
          VersionedId(wid(1), 1),
          benchDraft(type: ExerciseType.duration),
        ),
      ]);
      final before = await h.raw();
      final undo = await h.undo(edit);
      expect(undo, isA<Rejected>());
      expect(
        (undo as Rejected).failure,
        isA<InvalidOp>().having((f) => f.code, 'code', 'incompatibleSets'),
      );
      expect(await h.raw(), before);
    });

    test(
      'WO-004 undo of a session edit restores sets that still fit',
      () async {
        final h = WorkoutHarness();
        await h.seedExercise();
        await h.apply([LogWorkoutSession(wid(10), sessionDraft())]);
        final edit = await h.apply([
          UpdateWorkoutSession(
            VersionedId(wid(10), 1),
            sessionDraft(sets: [lifted(30, 5, 90)]),
          ),
        ]);
        expect(await h.undo(edit), isA<Applied>());
        expect(await h.isTombstone('workout_sets', wid(31)), isFalse);
      },
    );

    test('UpdateWorkoutSession with a stale version is refused', () async {
      final h = WorkoutHarness();
      await h.seedExercise();
      await h.apply([LogWorkoutSession(wid(10), sessionDraft())]);
      expect(
        await h.reject([
          UpdateWorkoutSession(VersionedId(wid(10), 2), sessionDraft()),
        ]),
        isA<VersionConflict>(),
      );
    });

    test('UX-030 deleting a session tombstones it with every child; undo '
        'revives them', () async {
      final h = WorkoutHarness();
      await h.seedExercise();
      await h.apply([LogWorkoutSession(wid(10), sessionDraft())]);
      final before = await h.state();
      final deleted = await h.apply([
        DeleteWorkoutSession(VersionedId(wid(10), 1)),
      ]);
      expect(await h.isTombstone('workout_sessions', wid(10)), isTrue);
      expect(await h.isTombstone('session_exercises', wid(20)), isTrue);
      expect(await h.isTombstone('workout_sets', wid(32)), isTrue);
      expect(await h.repository.sessions(today, today), isEmpty);
      expect(await h.undo(deleted), isA<Applied>());
      expect(await h.state(), before);
    });
  });

  group('templates and plan', () {
    WorkoutTemplateDraft push({int sets = 3, int reps = 8}) =>
        WorkoutTemplateDraft(
          name: 'Push',
          items: [
            TemplateItemDraft(
              id: wid(60),
              exerciseId: wid(1),
              sets: sets,
              reps: reps,
            ),
          ],
        );

    test('WO-020 create and update a template; items keep their IDs', () async {
      final h = WorkoutHarness();
      await h.seedExercise();
      await h.apply([CreateWorkoutTemplate(wid(50), push())]);
      final edit = await h.apply([
        UpdateWorkoutTemplate(VersionedId(wid(50), 1), push(reps: 10)),
      ]);
      final item = await h.db.select(h.db.workoutTemplateItems).getSingle();
      expect((item.id, item.targetReps, item.version), (wid(60), 10, 2));
      expect(
        (await h.repository.watchTemplates().first).single.draft,
        push(reps: 10),
      );
      expect(await h.undo(edit), isA<Applied>());
      expect(
        (await h.db.select(h.db.workoutTemplateItems).getSingle()).targetReps,
        8,
      );
    });

    test('A36 D7 item-only edits bump the template version, so stale '
        'editors conflict', () async {
      final h = WorkoutHarness();
      await h.seedExercise();
      await h.apply([CreateWorkoutTemplate(wid(50), push())]);
      await h.apply([
        UpdateWorkoutTemplate(VersionedId(wid(50), 1), push(reps: 10)),
      ]);
      expect(await h.version('workout_templates', wid(50)), 2);
      expect(
        await h.reject([
          UpdateWorkoutTemplate(VersionedId(wid(50), 1), push(sets: 4)),
        ]),
        isA<VersionConflict>(),
      );
    });

    test('WO-021 plan days use a deterministic weekday ID and are '
        'idempotent; unknown templates are refused', () async {
      final h = WorkoutHarness();
      await h.seedExercise();
      await h.apply([CreateWorkoutTemplate(wid(50), push())]);
      await h.apply([SetPlanDay(DayOfWeek.saturday, wid(50))]);
      final row = await h.db.select(h.db.weeklyPlanDays).getSingle();
      expect(row.id, planDayId(DayOfWeek.saturday));
      expect(row.weekday, 6);
      final out = await h.raw();
      await h.apply([SetPlanDay(DayOfWeek.saturday, wid(50))]);
      expect(await h.raw(), out, reason: 'same plan day writes nothing');
      expect(await h.repository.watchPlan().first, {
        DayOfWeek.saturday: wid(50),
      });
      expect(
        await h.reject([SetPlanDay(DayOfWeek.sunday, wid(99))]),
        isA<RowNotFound>(),
      );
    });

    test('WO-021 undoing a template creation is refused while plan days '
        'point at it, allowed when the same change set planned it', () async {
      final h = WorkoutHarness();
      await h.seedExercise();
      final created = await h.apply([CreateWorkoutTemplate(wid(50), push())]);
      await h.apply([SetPlanDay(DayOfWeek.saturday, wid(50))]);
      final undo = await h.undo(created);
      expect(undo, isA<Rejected>());
      expect(
        (undo as Rejected).failure,
        isA<InvalidOp>().having((f) => f.code, 'code', 'templateInUse'),
      );

      final both = await h.apply([
        CreateWorkoutTemplate(
          wid(51),
          WorkoutTemplateDraft(name: 'Pull', items: const []),
        ),
        SetPlanDay(DayOfWeek.sunday, wid(51)),
      ]);
      expect(await h.undo(both), isA<Applied>());
      expect(await h.repository.plan(), {DayOfWeek.saturday: wid(50)});
    });

    test('WO-021 the plan ignores days pointing at a template that is no '
        'longer live', () async {
      final h = WorkoutHarness();
      await h.seedExercise();
      await h.apply([
        CreateWorkoutTemplate(wid(50), push()),
        SetPlanDay(DayOfWeek.saturday, wid(50)),
      ]);
      // A tombstone arriving by sync, without the plan day being cleared.
      await runAuthorizedWrite(
        () => h.db.customStatement(
          'UPDATE workout_templates SET deleted_at = 1 WHERE id = ?',
          [wid(50)],
        ),
      );
      expect(await h.repository.watchPlan().first, isEmpty);
    });

    test('WO-021 deleting a template makes its plan days rest days; undo '
        'restores both', () async {
      final h = WorkoutHarness();
      await h.seedExercise();
      await h.apply([
        CreateWorkoutTemplate(wid(50), push()),
        SetPlanDay(DayOfWeek.saturday, wid(50)),
      ]);
      final before = await h.state();
      final deleted = await h.apply([
        DeleteWorkoutTemplate(VersionedId(wid(50), 1)),
      ]);
      expect(await h.repository.watchPlan().first, isEmpty);
      expect(await h.isTombstone('workout_template_items', wid(60)), isTrue);
      expect(await h.undo(deleted), isA<Applied>());
      expect(await h.state(), before);
    });
  });
}
