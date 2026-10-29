/// One template line: an exercise with its target sets × reps (WO-020).
typedef TemplateTarget = ({String exerciseId, int sets, int reps});

/// One exercise as done in a session: its sets' reps in order (`null` for a
/// set without reps, like a timed set).
typedef SessionExerciseDone = ({String exerciseId, List<int?> reps});

/// Whether a session differs from the template it was started from (WO-022,
/// A36 D4). A session matches a template only when it was started from it
/// (`template_id`); there's no fuzzy matching.
///
/// It differs when the ordered exercise list differs, an exercise's set count
/// differs, or any set's reps differ from the target, with one narrow
/// fatigue exception: the trailing sets may fall short of the target by at
/// most [fatigueReps] (`8, 8, 7` against `3×8`). So `10, 10, 9` against
/// `3×8` differs (propose an update); `8, 7, 8` differs too (the short set
/// isn't trailing). Sets without reps (timed) are skipped. Weights never
/// count: they change every week.
abstract final class TemplateMatch {
  /// Whether [done] differs from [targets].
  static bool differs(
    List<TemplateTarget> targets,
    List<SessionExerciseDone> done,
  ) {
    if (targets.length != done.length) return true;
    for (var i = 0; i < targets.length; i++) {
      final target = targets[i];
      final exercise = done[i];
      if (target.exerciseId != exercise.exerciseId) return true;
      if (target.sets != exercise.reps.length) return true;
      if (_repsDiffer(target.reps, exercise.reps.whereType<int>().toList())) {
        return true;
      }
    }
    return false;
  }

  /// How far below target a trailing set may fall and still be fatigue.
  static const int fatigueReps = 2;

  static bool _repsDiffer(int target, List<int> reps) {
    final first = reps.indexWhere((r) => r != target);
    if (first < 0) return false;
    // From the first deviation on, every set must be a small shortfall.
    return reps.skip(first).any((r) => r >= target || r < target - fatigueReps);
  }

  /// The template lines a "save as template" / "update the template" makes
  /// from [done] (WO-020, WO-022): the set count, and the most common reps
  /// (the highest on a tie) as the target.
  static List<TemplateTarget> targetsFrom(List<SessionExerciseDone> done) => [
    for (final exercise in done)
      if (exercise.reps.isNotEmpty)
        (
          exerciseId: exercise.exerciseId,
          sets: exercise.reps.length,
          reps: _mode(exercise.reps.whereType<int>()),
        ),
  ];

  static int _mode(Iterable<int> reps) {
    final counts = <int, int>{};
    for (final r in reps) {
      counts[r] = (counts[r] ?? 0) + 1;
    }
    if (counts.isEmpty) return 1;
    return counts.entries
        .reduce(
          (a, b) => b.value > a.value || (b.value == a.value && b.key > a.key)
              ? b
              : a,
        )
        .key;
  }
}
