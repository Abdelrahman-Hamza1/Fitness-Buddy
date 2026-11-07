import 'package:fb_domain/src/changes/change_op.dart';
import 'package:fb_domain/src/math/rounding.dart';
import 'package:fb_domain/src/proposals/day_hint.dart';
import 'package:fb_domain/src/proposals/proposal_input.dart'
    show ProposalIdSource;
import 'package:fb_domain/src/records/record_plan.dart';
import 'package:fb_domain/src/records/record_request.dart';
import 'package:fb_domain/src/time/local_date.dart';
import 'package:fb_domain/src/units/units.dart';
import 'package:fb_domain/src/workouts/exercise_type.dart';
import 'package:fb_domain/src/workouts/personal_records.dart';
import 'package:fb_domain/src/workouts/workout_drafts.dart';
import 'package:fb_domain/src/workouts/workout_ops.dart';
import 'package:fb_domain/src/workouts/workout_set.dart';

/// A library exercise as a workout card needs it: built-in or custom.
final class ExerciseFacts {
  /// The exercise.
  const new({
    required this.id,
    required this.name,
    required this.type,
    required this.equipment,
  });

  /// A catalog ID or a custom exercise's UUID.
  final String id;

  /// Its display name. User content for custom exercises.
  final String name;

  /// What a set logs.
  final ExerciseType type;

  /// Its equipment.
  final Equipment equipment;

  @override
  String toString() => 'ExerciseFacts($id)';
}

/// One exercise of a workout card (A69 D3).
final class WorkoutExerciseView {
  /// The exercise.
  const new({
    required this.index,
    required this.mention,
    required this.sets,
    required this.type,
    this.exercise,
    this.candidates = const [],
    this.pick,
    this.created = false,
    this.leftOut = false,
    this.prSets = const {},
    this.splitPerDumbbell = false,
    this.assumptions = const [],
  });

  /// Its position in the intent.
  final int index;

  /// The user's words. User content.
  final String mention;

  /// The matched (or picked) library exercise; `null` while it waits for a
  /// pick, or for a new custom exercise ([created]).
  final ExerciseFacts? exercise;

  /// The sets it logs.
  final List<LoggedSet> sets;

  /// What its sets log: the matched exercise's type, or the one a new
  /// exercise takes from its sets (shown before a pick too).
  final ExerciseType type;

  /// The closest library exercises to pick from (unmatched only).
  final List<ExerciseFacts> candidates;

  /// The user's pick, when one was made.
  final String? pick;

  /// It becomes a new custom exercise named after the mention.
  final bool created;

  /// The user left it out.
  final bool leftOut;

  /// Indices of [sets] that beat the exercise's earlier records (WO-042).
  final Set<int> prSets;

  /// A dumbbell total was split per dumbbell.
  final bool splitPerDumbbell;

  /// The server's assumption lines (English), as sent.
  final List<String> assumptions;

  /// Whether it still waits for a pick.
  bool get needsPick => exercise == null && !created && !leftOut;

  @override
  String toString() => 'WorkoutExerciseView($index)';
}

/// A workout card's figures.
final class WorkoutView {
  /// The figures.
  const new({required this.date, required this.exercises, this.name});

  /// The training day.
  final LocalDate date;

  /// The session's name. User content.
  final String? name;

  /// The exercises, in order.
  final List<WorkoutExerciseView> exercises;

  /// Whether an exercise still waits for a pick.
  bool get needsPick => exercises.any((e) => e.needsPick);

  @override
  String toString() => 'WorkoutView(${exercises.length})';
}

/// Plans a workout card (A69 D3) over [f]: the session the confirm logs
/// (with any new custom exercises in the same change set), or why not.
/// `ArgumentError`s of the drafts reach the planner (issue `invalid`).
RecordPlan planWorkout(
  WorkoutRecord r,
  RecordFacts f,
  ProposalIdSource ids,
  RecordAdjust adjust,
) {
  final today = f.now.localDate;
  final hint = r.when.dateHint;
  final date = hint == null ? today : DayHint.resolve(hint, today);
  if (date == null || date.isAfter(today) || r.exercises.isEmpty) {
    return RecordPlan.failed(r.kind, RecordIssue.invalid);
  }
  final views = <WorkoutExerciseView>[];
  final ops = <ChangeOp>[];
  final drafts = <SessionExerciseDraft>[];
  for (final (i, e) in r.exercises.indexed) {
    final pick = adjust.exercisePicks[i];
    final matched = f.exercises[e.exerciseRef];
    final picked = f.exercises[pick];
    final exercise = matched ?? picked;
    final created = matched == null && pick == RecordAdjust.newExercise;
    final leftOut = pick == RecordAdjust.leaveOut;
    final type = exercise?.type ?? _typeOf(e.sets);
    final dumbbell = exercise?.equipment == Equipment.dumbbell;
    final split =
        dumbbell && e.sets.any((s) => s.weight != null && !s.perDumbbell);
    final sets = [
      for (final s in e.sets) _set(ids.next(), s, type, f.massUnit, dumbbell),
    ];
    if (sets.length > WorkoutSetBounds.maxSets * 2) {
      return RecordPlan.failed(r.kind, RecordIssue.invalid);
    }
    final prs = exercise == null
        ? const <int>{}
        : _prs(sets, f.liftedSets[exercise.id] ?? const [], type);
    views.add(
      WorkoutExerciseView(
        index: i,
        mention: e.mention,
        exercise: leftOut ? null : exercise,
        sets: sets,
        type: type,
        candidates: matched == null
            ? f.exerciseCandidates[i] ?? const []
            : const [],
        pick: pick,
        created: created,
        leftOut: leftOut,
        prSets: prs,
        splitPerDumbbell: split,
        assumptions: e.assumptions,
      ),
    );
    if (leftOut) continue;
    var exerciseId = exercise?.id;
    if (created) {
      exerciseId = ids.next();
      ops.add(
        CreateCustomExercise(
          exerciseId,
          CustomExerciseDraft(
            name: _name(e.mention),
            type: type,
            equipment: Equipment.other,
          ),
        ),
      );
    }
    if (exerciseId == null) continue;
    drafts.add(
      SessionExerciseDraft(id: ids.next(), exerciseId: exerciseId, sets: sets),
    );
  }
  final view = WorkoutView(
    date: date,
    name: r.name == null || r.name!.trim().isEmpty ? null : _name(r.name!),
    exercises: views,
  );
  final notes = {if (r.when.timeHint != null) RecordNote.timeIgnored};
  final recordView = RecordView(
    kind: r.kind,
    date: date,
    title: view.name,
    notes: notes,
    workout: view,
  );
  if (view.needsPick || drafts.isEmpty) return RecordPlan(recordView, const []);
  return RecordPlan(recordView, [
    ...ops,
    LogWorkoutSession(
      ids.next(),
      WorkoutSessionDraft(date: date, exercises: drafts, name: view.name),
    ),
  ]);
}

/// The type a new custom exercise gets from its sets.
ExerciseType _typeOf(List<WorkoutSetInput> sets) {
  if (sets.any((s) => s.durationSeconds != null)) {
    return sets.any((s) => s.distanceMeters != null)
        ? ExerciseType.distanceDuration
        : ExerciseType.duration;
  }
  if (sets.any((s) => s.weight != null && s.weight! > 0)) {
    return ExerciseType.weightReps;
  }
  if (sets.any((s) => s.reps != null)) return ExerciseType.repsOnly;
  return ExerciseType.weightReps;
}

/// A name trimmed to [WorkoutLimits.nameMax] code points.
String _name(String text) {
  final runes = text.trim().runes.toList();
  return String.fromCharCodes(runes.take(WorkoutLimits.nameMax)).trim();
}

/// One set in canonical units (kg; a dumbbell's per dumbbell), the typed
/// weight kept when it was lb. Throws an `ArgumentError` when it doesn't
/// fit [type].
LoggedSet _set(
  String id,
  WorkoutSetInput s,
  ExerciseType type,
  MassUnit fallback,
  bool dumbbell,
) {
  final unit = MassUnit.fromCode(s.unit ?? '') ?? fallback;
  var typed = s.weight;
  if (typed != null && typed <= 0 && type == ExerciseType.bodyweightReps) {
    typed = null;
  }
  if (typed != null && dumbbell && !s.perDumbbell) typed = typed / 2;
  final kg = typed == null
      ? null
      : StoragePrecision.round(
          unit == MassUnit.pound ? typed * MassUnit.pound.grams / 1000 : typed,
        );
  final values = SetValues(
    reps: s.reps,
    kg: kg,
    durationSeconds: s.durationSeconds,
    distanceMeters: s.distanceMeters,
  );
  if (values.issueFor(type) case final issue?) {
    throw ArgumentError.value(issue.name, 'set', 'does not fit the type');
  }
  return LoggedSet(
    id,
    values,
    inputValue: kg != null && unit == MassUnit.pound
        ? StoragePrecision.round(typed!)
        : null,
    inputUnit: kg != null && unit == MassUnit.pound
        ? MassUnit.pound
        : MassUnit.kilogram,
  );
}

/// The sets that beat [earlier]'s heaviest or best e1RM (WO-042); none for
/// an exercise without history (the first session isn't a record hint).
Set<int> _prs(
  List<LoggedSet> sets,
  List<LiftedSet> earlier,
  ExerciseType type,
) {
  if (earlier.isEmpty ||
      (type != ExerciseType.weightReps &&
          type != ExerciseType.bodyweightReps)) {
    return const {};
  }
  var records = PersonalRecords.of(earlier);
  final out = <int>{};
  for (final (i, s) in sets.indexed) {
    final kg = s.values.kg;
    final reps = s.values.reps;
    if (kg == null || kg <= 0 || reps == null) continue;
    final beats = records.newRecords((kg: kg, reps: reps));
    if (beats.contains(PrKind.heaviest) || beats.contains(PrKind.e1rm)) {
      out.add(i);
    }
    records = records.add((kg: kg, reps: reps));
  }
  return out;
}
