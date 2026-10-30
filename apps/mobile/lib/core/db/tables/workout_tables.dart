// Drift evaluates self-referencing column checks lazily, without recursion.
// ignore_for_file: recursive_getters
import 'package:drift/drift.dart';
import 'package:fb_mobile/core/db/tables/sync_columns.dart';

// Workout tables (A36 D7). The CHECKs are only as strict as a future sync
// wire would be: the local-write bounds live in fb_domain and the handler,
// so synced rows are never rejected (the A12 convention). Sessions and
// templates are aggregates: their children carry the parent ID and a
// position, and are tombstoned with it.

/// Custom exercises (WO-003). Built-in ones are read from the catalog pack.
@DataClassName('CustomExerciseRow')
class CustomExercises extends Table with SyncColumns {
  /// The display name. User content.
  TextColumn get name => text()();

  /// Search aliases, a JSON array of strings. User content.
  TextColumn get aliasesJson => text().withDefault(const Constant('[]'))();

  /// The WO-004 type code.
  TextColumn get exerciseType => text().check(
    exerciseType.isIn(const [
      'weight_reps',
      'bodyweight_reps',
      'assisted',
      'reps_only',
      'duration',
      'distance_duration',
    ]),
  )();

  /// The equipment code (WO-002, WO-005).
  TextColumn get equipment => text().check(
    equipment.isIn(const [
      'barbell',
      'dumbbell',
      'cable',
      'machine',
      'kettlebell',
      'bodyweight',
      'other',
    ]),
  )();

  /// The main muscle code (WO-007, A37 D2, D6), or null: rows from before
  /// v11, or synced without one.
  TextColumn get primaryMuscle => text().nullable().check(
    primaryMuscle.isIn(const [
      'chest',
      'shoulders',
      'biceps',
      'triceps',
      'forearms',
      'traps',
      'upper_back',
      'lower_back',
      'abs',
      'obliques',
      'quadriceps',
      'hamstrings',
      'glutes',
      'calves',
      'adductors',
    ]),
  )();

  /// Secondary muscle codes, a JSON array (at most 4, never the primary).
  TextColumn get secondaryMusclesJson =>
      text().withDefault(const Constant('[]'))();
}

/// Logged sessions (WO-010, WO-011).
@DataClassName('WorkoutSessionRow')
class WorkoutSessions extends Table with SyncColumns {
  /// The training day, `YYYY-MM-DD`.
  TextColumn get localDate => text()();

  /// "Push", or null. User content.
  TextColumn get name => text().nullable()();

  /// Start time, minutes after local midnight.
  IntColumn get startMinute =>
      integer().nullable().check(startMinute.isBetweenValues(0, 1439))();

  /// Duration in minutes.
  IntColumn get durationMinutes =>
      integer().nullable().check(durationMinutes.isBiggerOrEqualValue(0))();

  /// The template it was started from (WO-022, A36 D4).
  TextColumn get templateId => text().nullable()();
}

/// The exercises of a session, in order.
@DataClassName('SessionExerciseRow')
class SessionExercises extends Table with SyncColumns {
  /// The session.
  TextColumn get sessionId => text()();

  /// A catalog ID (`ex:…`) or a custom exercise's ID.
  TextColumn get exerciseId => text()();

  /// Order within the session, from 0.
  IntColumn get position => integer().check(position.isBiggerOrEqualValue(0))();
}

/// The sets of a session exercise, in order. Fields by type (WO-004); `kg`
/// is the weight, added load or assistance, per dumbbell (WO-005).
@DataClassName('WorkoutSetRow')
class WorkoutSets extends Table with SyncColumns {
  /// The session exercise.
  TextColumn get sessionExerciseId => text()();

  /// Order within the exercise, from 0.
  IntColumn get position => integer().check(position.isBiggerOrEqualValue(0))();

  /// Reps.
  IntColumn get reps =>
      integer().nullable().check(reps.isBiggerOrEqualValue(0))();

  /// Load in kg.
  RealColumn get kg => real().nullable().check(kg.isBiggerOrEqualValue(0))();

  /// The weight as typed, in [inputUnit] (A36 D1, TD-017).
  RealColumn get inputValue =>
      real().nullable().check(inputValue.isBiggerOrEqualValue(0))();

  /// The unit the weight was typed in: `kg` or `lb` (A36 D1).
  TextColumn get inputUnit =>
      text().nullable().check(inputUnit.isIn(const ['kg', 'lb']))();

  /// Duration in seconds.
  IntColumn get durationSeconds =>
      integer().nullable().check(durationSeconds.isBiggerOrEqualValue(0))();

  /// Distance in metres.
  RealColumn get distanceMeters =>
      real().nullable().check(distanceMeters.isBiggerOrEqualValue(0))();
}

/// Routine templates (WO-020).
@DataClassName('WorkoutTemplateRow')
class WorkoutTemplates extends Table with SyncColumns {
  /// "Push". User content.
  TextColumn get name => text()();
}

/// A template's lines: exercise with target sets × reps, in order.
@DataClassName('WorkoutTemplateItemRow')
class WorkoutTemplateItems extends Table with SyncColumns {
  /// The template.
  TextColumn get templateId => text()();

  /// The exercise.
  TextColumn get exerciseId => text()();

  /// Order within the template, from 0.
  IntColumn get position => integer().check(position.isBiggerOrEqualValue(0))();

  /// Target sets.
  IntColumn get targetSets =>
      integer().check(targetSets.isBiggerOrEqualValue(1))();

  /// Target reps.
  IntColumn get targetReps =>
      integer().check(targetReps.isBiggerOrEqualValue(1))();
}

/// The weekly plan (WO-021): one row per weekday, a template or rest.
@DataClassName('WeeklyPlanDayRow')
class WeeklyPlanDays extends Table with SyncColumns {
  /// ISO weekday, 1 (Monday) to 7.
  IntColumn get weekday => integer().check(weekday.isBetweenValues(1, 7))();

  /// The template, or null for rest.
  TextColumn get templateId => text().nullable()();
}

/// Sync entity names (A36 D6: not in the sync contract yet).
const customExerciseEntity = 'customExercise';

/// See [customExerciseEntity].
const workoutSessionEntity = 'workoutSession';

/// See [customExerciseEntity].
const sessionExerciseEntity = 'sessionExercise';

/// See [customExerciseEntity].
const workoutSetEntity = 'workoutSet';

/// See [customExerciseEntity].
const workoutTemplateEntity = 'workoutTemplate';

/// See [customExerciseEntity].
const workoutTemplateItemEntity = 'workoutTemplateItem';

/// See [customExerciseEntity].
const weeklyPlanDayEntity = 'weeklyPlanDay';
