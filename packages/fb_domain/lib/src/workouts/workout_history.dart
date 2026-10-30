import 'package:fb_domain/src/time/local_date.dart';
import 'package:fb_domain/src/workouts/exercise_type.dart';
import 'package:fb_domain/src/workouts/personal_records.dart';
import 'package:fb_domain/src/workouts/workout_drafts.dart';
import 'package:fb_domain/src/workouts/workout_set.dart';

/// A stored session as history sees it: its row ID and content.
typedef SessionEntry = ({String id, WorkoutSessionDraft draft});

/// Orders sessions in history (A37 D11): by date, then by ID (UUIDv7 IDs
/// are time-ordered, so same-day sessions keep the order they were logged).
int compareSessions(SessionEntry a, SessionEntry b) {
  final byDate = a.draft.date.compareTo(b.draft.date);
  return byDate != 0 ? byDate : a.id.compareTo(b.id);
}

/// The set [values] of an exercise of [type] as a record set (WO-042, A37
/// D11), or `null` when the type keeps no records or the set lacks reps:
/// weight × reps uses its weight; bodyweight and reps-only use the added
/// load, or 0 ("most reps"). Assisted, time and cardio sets keep none.
LiftedSet? liftedSetOf(ExerciseType type, SetValues values) {
  final reps = values.reps;
  if (reps == null || reps < 1) return null;
  return switch (type) {
    ExerciseType.weightReps => switch (values.kg) {
      final kg? when kg.isFinite && kg >= 0 => (kg: kg, reps: reps),
      _ => null,
    },
    ExerciseType.bodyweightReps || ExerciseType.repsOnly => (
      kg: switch (values.kg) {
        final kg? when kg.isFinite && kg >= 0 => kg,
        _ => 0.0,
      },
      reps: reps,
    ),
    ExerciseType.assisted ||
    ExerciseType.duration ||
    ExerciseType.distanceDuration => null,
  };
}

/// Last session's numbers (WO-034, A37 D7).
abstract final class LastPerformance {
  /// The sets of [exerciseId] in the latest session before the one at
  /// [date] with ID [sessionId] (history order, [compareSessions]), or an
  /// empty list when there's none. The session itself and later ones are
  /// ignored, so editing an old session shows what came before it. Set `i`
  /// of the result is the hint for set `i` of the form.
  static List<SetValues> of(
    Iterable<SessionEntry> sessions,
    String exerciseId, {
    required LocalDate date,
    required String sessionId,
  }) {
    final current = (id: sessionId, date: date);
    SessionEntry? best;
    SessionExerciseDraft? bestExercise;
    for (final session in sessions) {
      if (!_before(session, current)) continue;
      if (best != null && compareSessions(session, best) <= 0) continue;
      final exercise = session.draft.exercises
          .where((e) => e.exerciseId == exerciseId && e.sets.isNotEmpty)
          .firstOrNull;
      if (exercise == null) continue;
      best = session;
      bestExercise = exercise;
    }
    return List.unmodifiable([
      for (final set in bestExercise?.sets ?? const <LoggedSet>[]) set.values,
    ]);
  }

  static bool _before(
    SessionEntry session,
    ({String id, LocalDate date}) current,
  ) {
    final byDate = session.draft.date.compareTo(current.date);
    return byDate < 0 || (byDate == 0 && session.id.compareTo(current.id) < 0);
  }
}

/// Plain PR markers over a history (WO-042, A37 D11), derived on read and
/// never stored (A36 D3).
///
/// A set is marked when it beats the records of every **earlier** session
/// of its exercise (history order) by heaviest weight or e1RM, or beats an
/// **existing** most-reps-at-that-weight record; sets of the same session
/// don't compete with each other, and an exercise's first session never
/// marks. Bodyweight and reps-only exercises keep only most-reps records;
/// assisted, time and cardio keep none.
final class SessionPrs {
  new _(this._bySet, this._byExercise, this._countBySession);

  /// The markers of [sessions], typing each exercise through [typeOf]
  /// (`null` for an unknown exercise: no records).
  factory of(
    Iterable<SessionEntry> sessions,
    ExerciseType? Function(String exerciseId) typeOf,
  ) {
    final ordered = sessions.toList()..sort(compareSessions);
    final records = <String, PersonalRecords>{};
    final types = <String, ExerciseType?>{};
    final bySet = <String, Set<PrKind>>{};
    final byExercise = <String, Set<PrKind>>{};
    final countBySession = <String, int>{};
    for (final session in ordered) {
      final before = Map.of(records);
      final marked = <String>{};
      for (final exercise in session.draft.exercises) {
        final type = types.putIfAbsent(
          exercise.exerciseId,
          () => typeOf(exercise.exerciseId),
        );
        if (type == null) continue;
        final earlier = before[exercise.exerciseId];
        final kinds = <PrKind>{};
        for (final set in exercise.sets) {
          final lifted = liftedSetOf(type, set.values);
          if (lifted == null) continue;
          records[exercise.exerciseId] =
              (records[exercise.exerciseId] ?? PersonalRecords.none).add(
                lifted,
              );
          if (earlier == null) continue;
          final beaten = _beaten(type, earlier, lifted);
          if (beaten.isEmpty) continue;
          bySet[set.id] = Set.unmodifiable(beaten);
          kinds.addAll(beaten);
        }
        if (kinds.isEmpty) continue;
        byExercise[exercise.id] = Set.unmodifiable(kinds);
        marked.add(exercise.exerciseId);
      }
      if (marked.isNotEmpty) countBySession[session.id] = marked.length;
    }
    return SessionPrs._(bySet, byExercise, countBySession);
  }

  static Set<PrKind> _beaten(
    ExerciseType type,
    PersonalRecords earlier,
    LiftedSet set,
  ) {
    final repsRecord = earlier.mostRepsByKg.containsKey(
      PersonalRecords.keyOf(set.kg),
    );
    return {
      for (final kind in earlier.newRecords(set))
        if (switch (kind) {
          // A first set at a new weight isn't a reps record (A37 D11).
          PrKind.repsAtWeight => repsRecord,
          PrKind.heaviest || PrKind.e1rm => type == ExerciseType.weightReps,
        })
          kind,
    };
  }

  final Map<String, Set<PrKind>> _bySet;
  final Map<String, Set<PrKind>> _byExercise;
  final Map<String, int> _countBySession;

  /// The records set [setId] beat; empty for none.
  Set<PrKind> ofSet(String setId) => _bySet[setId] ?? const {};

  /// The records any set of session exercise [sessionExerciseId] beat.
  Set<PrKind> ofExercise(String sessionExerciseId) =>
      _byExercise[sessionExerciseId] ?? const {};

  /// How many exercises of session [sessionId] have a PR ("1 PR").
  int countOf(String sessionId) => _countBySession[sessionId] ?? 0;
}
