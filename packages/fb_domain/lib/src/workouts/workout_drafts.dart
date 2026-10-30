import 'package:fb_domain/src/diary/diary_entry.dart';
import 'package:fb_domain/src/time/local_date.dart';
import 'package:fb_domain/src/time/local_time.dart';
import 'package:fb_domain/src/units/units.dart';
import 'package:fb_domain/src/workouts/exercise_type.dart';
import 'package:fb_domain/src/workouts/muscle.dart';
import 'package:fb_domain/src/workouts/workout_set.dart';
import 'package:fb_domain/src/workouts/workout_wire_rules.dart';

/// Limits of workout drafts (A36), for local writes only.
abstract final class WorkoutLimits {
  /// Longest exercise, session or template name, in code points, trimmed.
  static const int nameMax = 80;

  /// Most aliases on a custom exercise.
  static const int aliasesMax = 10;

  /// Most exercises in one session or template.
  static const int exercisesMax = 30;

  /// Longest session, in minutes.
  static const int durationMinutesMax = 24 * 60;
}

/// Checks [id] is an exercise ID: a built-in catalog ID (`ex:…`) or a custom
/// exercise's UUID (wire rule W4, [WorkoutWireRules.isExerciseRef]). Returns
/// it; throws an `ArgumentError` otherwise.
String checkExerciseId(String id, String name) {
  if (WorkoutWireRules.isExerciseRef(id)) return id;
  throw ArgumentError.value(id, name, 'must be a catalog ID or a UUID');
}

String _checkName(String value, String name) {
  final trimmed = value.trim();
  if (trimmed.isEmpty || trimmed.runes.length > WorkoutLimits.nameMax) {
    throw ArgumentError.value(value, name, 'must be 1 to 80 characters');
  }
  return trimmed;
}

// Child row IDs must be unique within one aggregate (A36 D7): the handler
// addresses rows by them.
void _checkUniqueIds(List<String> ids, String name) {
  if (ids.toSet().length != ids.length) {
    throw ArgumentError.value(ids.length, name, 'has duplicate row IDs');
  }
}

bool _sameList<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// A custom exercise's content (WO-003): name, aliases, type, equipment,
/// and its muscles for the muscle map (WO-007, A37 D6).
final class CustomExerciseDraft {
  /// Throws an `ArgumentError` for a blank or long name or alias, too many
  /// aliases, or [secondaryMuscles] that are more than 4, repeat a muscle or
  /// contain [primaryMuscle]. Names are trimmed; duplicate aliases dropped.
  new({
    required String name,
    required this.type,
    required this.equipment,
    Iterable<String> aliases = const [],
    this.primaryMuscle,
    Iterable<Muscle> secondaryMuscles = const [],
  }) : name = _checkName(name, 'name'),
       aliases = List.unmodifiable({
         for (final a in aliases) _checkName(a, 'aliases'),
       }),
       secondaryMuscles = Muscle.checkSecondaries(
         secondaryMuscles,
         primaryMuscle,
       ) {
    if (this.aliases.length > WorkoutLimits.aliasesMax) {
      throw ArgumentError.value(aliases, 'aliases', 'at most 10');
    }
  }

  /// The display name. User content: never logged.
  final String name;

  /// Search aliases.
  final List<String> aliases;

  /// What a set logs (WO-004).
  final ExerciseType type;

  /// The equipment (WO-002, WO-005).
  final Equipment equipment;

  /// The main muscle (dark on the map), or `null` for a row from before
  /// A37a or synced without one (A37 D2: "no primary muscle"). The form
  /// requires it.
  final Muscle? primaryMuscle;

  /// Secondary muscles (lighter on the map), in order.
  final List<Muscle> secondaryMuscles;

  @override
  bool operator ==(Object other) =>
      other is CustomExerciseDraft &&
      other.name == name &&
      other.type == type &&
      other.equipment == equipment &&
      other.primaryMuscle == primaryMuscle &&
      _sameList(other.aliases, aliases) &&
      _sameList(other.secondaryMuscles, secondaryMuscles);

  @override
  int get hashCode => Object.hash(
    name,
    type,
    equipment,
    Object.hashAll(aliases),
    primaryMuscle,
    Object.hashAll(secondaryMuscles),
  );

  @override
  String toString() => 'CustomExerciseDraft(${type.code}, ${equipment.code})';
}

/// One logged set with the weight as typed (A36 D1): [values] are canonical,
/// [inputValue] and [inputUnit] are the weight as typed (`176` `lb`). [id] is
/// the set row's stable ID (A36 D7), so an edit updates it in place.
final class LoggedSet {
  /// Set [id] with [values]; [inputValue] and [inputUnit] only matter when
  /// there's a weight. Throws an `ArgumentError` for a bad ID, or a typed
  /// value without a weight or that isn't finite and ≥ 0.
  new(
    this.id,
    this.values, {
    this.inputValue,
    this.inputUnit = MassUnit.kilogram,
  }) {
    checkUuid(id, 'id');
    if (inputUnit != MassUnit.kilogram && inputUnit != MassUnit.pound) {
      throw ArgumentError.value(inputUnit, 'inputUnit', 'kg or lb only');
    }
    if (inputValue case final v?
        when values.kg == null || !v.isFinite || v < 0) {
      throw ArgumentError.value(v, 'inputValue', 'needs a weight, ≥ 0');
    }
  }

  /// The weight as typed, in [inputUnit]; `null` when it was typed in kg
  /// (then it equals the canonical kg).
  final double? inputValue;

  /// The set row's ID.
  final String id;

  /// Canonical values.
  final SetValues values;

  /// The unit the weight was typed in.
  final MassUnit inputUnit;

  @override
  bool operator ==(Object other) =>
      other is LoggedSet &&
      other.id == id &&
      other.values == values &&
      other.inputValue == inputValue &&
      other.inputUnit == inputUnit;

  @override
  int get hashCode => Object.hash(id, values, inputValue, inputUnit);
}

/// One exercise in a session, with its sets in order (WO-010).
final class SessionExerciseDraft {
  /// [exerciseId] with [sets] (at most [WorkoutSetBounds.maxSets] × 2).
  new({
    required this.id,
    required String exerciseId,
    required Iterable<LoggedSet> sets,
  }) : exerciseId = checkExerciseId(exerciseId, 'exerciseId'),
       sets = List.unmodifiable(sets) {
    checkUuid(id, 'id');
    if (this.sets.length > WorkoutSetBounds.maxSets * 2) {
      throw ArgumentError.value(this.sets.length, 'sets', 'too many sets');
    }
  }

  /// The session-exercise row's ID (stable across edits, so undo and sync
  /// address it).
  final String id;

  /// A catalog ID or a custom exercise's UUID.
  final String exerciseId;

  /// The sets, in order.
  final List<LoggedSet> sets;

  @override
  bool operator ==(Object other) =>
      other is SessionExerciseDraft &&
      other.id == id &&
      other.exerciseId == exerciseId &&
      _sameList(other.sets, sets);

  @override
  int get hashCode => Object.hash(id, exerciseId, Object.hashAll(sets));
}

/// A whole session's content, saved as one aggregate (WO-010, WO-011, A36
/// D7): any past date, optional name, start time, duration and template.
final class WorkoutSessionDraft {
  /// Throws an `ArgumentError` for a blank or long name, a duration outside
  /// 1–1440 minutes, too many exercises, or a bad template ID.
  new({
    required this.date,
    required Iterable<SessionExerciseDraft> exercises,
    String? name,
    this.startTime,
    this.durationMinutes,
    this.templateId,
  }) : name = name == null ? null : _checkName(name, 'name'),
       exercises = List.unmodifiable(exercises) {
    if (this.exercises.length > WorkoutLimits.exercisesMax) {
      throw ArgumentError.value(this.exercises.length, 'exercises', 'too many');
    }
    if (durationMinutes case final d?
        when d < 1 || d > WorkoutLimits.durationMinutesMax) {
      throw ArgumentError.value(d, 'durationMinutes', 'must be 1 to 1440');
    }
    if (templateId case final t?) checkUuid(t, 'templateId');
    _checkUniqueIds([
      for (final e in this.exercises) ...[e.id, for (final s in e.sets) s.id],
    ], 'exercises');
  }

  /// The training day.
  final LocalDate date;

  /// "Push", or `null`.
  final String? name;

  /// When it started, if known.
  final LocalTime? startTime;

  /// How long it took, if known.
  final int? durationMinutes;

  /// The template it was started from (WO-022, A36 D4).
  final String? templateId;

  /// The exercises, in order.
  final List<SessionExerciseDraft> exercises;

  /// Whether the draft logs on a date after [today] (rejected by the
  /// handler: sessions are for today or the past, WO-011).
  bool isAfter(LocalDate today) => date.isAfter(today);

  @override
  bool operator ==(Object other) =>
      other is WorkoutSessionDraft &&
      other.date == date &&
      other.name == name &&
      other.startTime == startTime &&
      other.durationMinutes == durationMinutes &&
      other.templateId == templateId &&
      _sameList(other.exercises, exercises);

  @override
  int get hashCode => Object.hash(
    date,
    name,
    startTime,
    durationMinutes,
    templateId,
    Object.hashAll(exercises),
  );

  @override
  String toString() =>
      'WorkoutSessionDraft($date, ${exercises.length} exercises)';
}

/// One template line: exercise with target sets × reps (WO-020).
final class TemplateItemDraft {
  /// Throws an `ArgumentError` for sets outside 1–20 or reps outside
  /// 1–1000.
  new({
    required this.id,
    required String exerciseId,
    required this.sets,
    required this.reps,
  }) : exerciseId = checkExerciseId(exerciseId, 'exerciseId') {
    checkUuid(id, 'id');
    if (sets < 1 || sets > WorkoutSetBounds.maxSets) {
      throw ArgumentError.value(sets, 'sets', 'must be 1 to 20');
    }
    if (reps < WorkoutSetBounds.minReps || reps > WorkoutSetBounds.maxReps) {
      throw ArgumentError.value(reps, 'reps', 'out of range');
    }
  }

  /// The item row's ID.
  final String id;

  /// The exercise.
  final String exerciseId;

  /// Target sets.
  final int sets;

  /// Target reps.
  final int reps;

  @override
  bool operator ==(Object other) =>
      other is TemplateItemDraft &&
      other.id == id &&
      other.exerciseId == exerciseId &&
      other.sets == sets &&
      other.reps == reps;

  @override
  int get hashCode => Object.hash(id, exerciseId, sets, reps);
}

/// A template's content, saved as one aggregate (WO-020, A36 D7).
final class WorkoutTemplateDraft {
  /// Throws an `ArgumentError` for a blank or long name or too many items.
  new({required String name, required Iterable<TemplateItemDraft> items})
    : name = _checkName(name, 'name'),
      items = List.unmodifiable(items) {
    if (this.items.length > WorkoutLimits.exercisesMax) {
      throw ArgumentError.value(this.items.length, 'items', 'too many');
    }
    _checkUniqueIds([for (final i in this.items) i.id], 'items');
  }

  /// "Push". User content: never logged.
  final String name;

  /// The lines, in order.
  final List<TemplateItemDraft> items;

  @override
  bool operator ==(Object other) =>
      other is WorkoutTemplateDraft &&
      other.name == name &&
      _sameList(other.items, items);

  @override
  int get hashCode => Object.hash(name, Object.hashAll(items));

  @override
  String toString() => 'WorkoutTemplateDraft(${items.length} items)';
}
