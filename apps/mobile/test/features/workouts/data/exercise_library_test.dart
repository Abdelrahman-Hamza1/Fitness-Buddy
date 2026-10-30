import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/catalog/catalog.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../core/catalog/support/catalog_support.dart';
import '../../../core/db/support/db_support.dart';
import '../support/workout_harness.dart';

const _exercises = '''
INSERT INTO exercises VALUES
  ('ex:barbell_bench_press', 'Barbell bench press', 'weight_reps', 'barbell',
   'chest', 'triceps,shoulders', 1),
  ('ex:dumbbell_bench_press', 'Dumbbell bench press', 'weight_reps',
   'dumbbell', 'chest', '', 1),
  ('ex:plank', 'Plank', 'duration', 'bodyweight', 'abs', 'obliques,neck', 1),
  ('ex:future_thing', 'Future thing', 'rpe_only', 'barbell', 'chest', '', 1);
INSERT INTO names (target_id, lang, name, key, is_display) VALUES
  ('ex:barbell_bench_press', 'en', 'Barbell bench press',
   'barbell bench press', 1),
  ('ex:barbell_bench_press', 'en', 'BB bench', 'b bench', 0),
  ('ex:plank', 'en', 'Plank', 'plank', 1);
''';

/// A genuine pack from before A37a: no `secondary_muscles` column and the
/// legacy primary codes `back`, `core`, `full_body` (PA5).
const _legacyExercises = '''
DROP TABLE exercises;
CREATE TABLE exercises (
  id TEXT PRIMARY KEY,
  name_en TEXT NOT NULL,
  type TEXT NOT NULL,
  equipment TEXT NOT NULL,
  primary_muscle TEXT NOT NULL,
  catalog_version INTEGER NOT NULL
) WITHOUT ROWID;
INSERT INTO exercises VALUES
  ('ex:barbell_bench_press', 'Barbell bench press', 'weight_reps', 'barbell',
   'chest', 1),
  ('ex:barbell_row', 'Barbell row', 'weight_reps', 'barbell', 'back', 1),
  ('ex:plank', 'Plank', 'duration', 'bodyweight', 'core', 1),
  ('ex:burpee', 'Burpee', 'reps_only', 'bodyweight', 'full_body', 1),
  ('ex:neck_curl', 'Neck curl', 'weight_reps', 'machine', 'neck', 1);
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

  test('WO-007 exercises() reads secondary muscles', () async {
    final (db, catalog) = fixtureCatalog(extraSql: _exercises);
    addTearDown(db.close);
    addTearDown(catalog.dispose);
    final byId = {for (final e in await catalog.exercises()) e.id: e};
    expect(byId['ex:barbell_bench_press']!.primary, Muscle.chest);
    expect(byId['ex:barbell_bench_press']!.secondaries, [
      Muscle.triceps,
      Muscle.shoulders,
    ]);
    expect(byId['ex:dumbbell_bench_press']!.secondaries, isEmpty);
    // Unknown codes are dropped, never guessed.
    expect(byId['ex:plank']!.secondaries, [Muscle.obliques]);
    expect(await catalog.exerciseNames(), {
      'ex:barbell_bench_press': ['Barbell bench press', 'BB bench'],
      'ex:plank': ['Plank'],
    });
  });

  test('WO-007 a genuine pre-A37a pack (no secondary_muscles column, legacy '
      'back/core/full_body values) lists every exercise with mapped primaries '
      'and groups', () async {
    final (db, catalog) = fixtureCatalog(extraSql: _legacyExercises);
    addTearDown(db.close);
    addTearDown(catalog.dispose);
    final exercises = await catalog.exercises();
    final byId = {for (final e in exercises) e.id: e};
    expect(byId.keys, hasLength(5));
    expect(byId['ex:barbell_bench_press']!.primary, Muscle.chest);
    expect(byId['ex:barbell_row']!.primary, Muscle.upperBack);
    expect(byId['ex:barbell_row']!.primary!.group, MuscleGroup.back);
    expect(byId['ex:plank']!.primary, Muscle.abs);
    expect(byId['ex:plank']!.primary!.group, MuscleGroup.core);
    expect(byId['ex:burpee']!.primary, isNull);
    expect(byId['ex:neck_curl']!.primary, isNull);
    for (final e in exercises) {
      expect(e.secondaries, isEmpty, reason: e.id);
    }
  });

  test('WO-007 swapping an old pack for a new one reads the new column '
      '(cache cleared)', () async {
    final dir = tempDir().path;
    final old = writeFixturePack(
      '$dir/catalog-1.db',
      extraSql: _legacyExercises,
    );
    final fresh = writeFixturePack('$dir/catalog-2.db', extraSql: _exercises);
    final db = fileDatabase('$dir/user.db', catalog: FixedPack(old));
    final catalog = OfflineCatalog(db);
    addTearDown(db.close);
    addTearDown(catalog.dispose);
    final before = {for (final e in await catalog.exercises()) e.id: e};
    expect(before['ex:barbell_bench_press']!.secondaries, isEmpty);

    await db.reattachCatalog(fresh);
    await pumpEventQueue();
    final after = {for (final e in await catalog.exercises()) e.id: e};
    expect(after['ex:barbell_bench_press']!.secondaries, [
      Muscle.triceps,
      Muscle.shoulders,
    ]);

    // And back: the old pack's missing column is noticed again.
    await db.reattachCatalog(old);
    await pumpEventQueue();
    final back = {for (final e in await catalog.exercises()) e.id: e};
    expect(back['ex:barbell_row']!.primary, Muscle.upperBack);
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
