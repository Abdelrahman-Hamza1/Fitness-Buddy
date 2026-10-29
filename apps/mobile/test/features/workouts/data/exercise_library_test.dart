import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../core/catalog/support/catalog_support.dart';
import '../support/workout_harness.dart';

const _exercises = '''
INSERT INTO exercises VALUES
  ('ex:barbell_bench_press', 'Barbell bench press', 'weight_reps', 'barbell',
   'chest', 1),
  ('ex:dumbbell_bench_press', 'Dumbbell bench press', 'weight_reps',
   'dumbbell', 'chest', 1),
  ('ex:plank', 'Plank', 'duration', 'bodyweight', 'core', 1),
  ('ex:future_thing', 'Future thing', 'rpe_only', 'barbell', 'chest', 1);
''';

void main() {
  test('WO-001 WO-002 built-in exercises come from the pack, equipment '
      'variants separate; unknown types are left out', () async {
    final (db, catalog) = fixtureCatalog(extraSql: _exercises);
    addTearDown(db.close);
    addTearDown(catalog.dispose);
    final exercises = await catalog.exercises();
    expect(
      [for (final e in exercises) e.id],
      ['ex:barbell_bench_press', 'ex:dumbbell_bench_press', 'ex:plank'],
    );
    expect(exercises[1].equipment, Equipment.dumbbell);
    expect(exercises[1].equipment.weightIsPerImplement, isTrue);
    expect(exercises[2].type, ExerciseType.duration);
  });

  test('WO-004 a session of built-in exercises is checked against the '
      "pack's types", () async {
    final (db, catalog) = fixtureCatalog(extraSql: _exercises);
    addTearDown(catalog.dispose);
    final h = WorkoutHarness(database: db);
    WorkoutSessionDraft draft(String exercise, LoggedSet set) =>
        WorkoutSessionDraft(
          date: today,
          exercises: [
            SessionExerciseDraft(
              id: wid(20),
              exerciseId: exercise,
              sets: [set],
            ),
          ],
        );
    await h.apply([
      LogWorkoutSession(
        wid(10),
        draft('ex:barbell_bench_press', lifted(30, 8, 80)),
      ),
    ]);
    final failure = await h.reject([
      LogWorkoutSession(
        wid(11),
        WorkoutSessionDraft(
          date: today,
          exercises: [
            SessionExerciseDraft(
              id: wid(21),
              exerciseId: 'ex:plank',
              sets: [lifted(31, 8, 80)],
            ),
          ],
        ),
      ),
    ]);
    expect(
      failure,
      isA<InvalidOp>().having((f) => f.code, 'code', 'invalidSet'),
    );
  });
}
