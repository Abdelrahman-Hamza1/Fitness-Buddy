import 'package:fb_domain/src/ids/uuid_v7.dart';
import 'package:fb_domain/src/workouts/exercise_type.dart';
import 'package:fb_domain/src/workouts/starter_plans.dart';
import 'package:fb_domain/src/workouts/template_match.dart';
import 'package:fb_domain/src/workouts/workout_drafts.dart';
import 'package:fb_domain/src/workouts/workout_set.dart';

/// The template-update offer's content (WO-022, A37 D21): the lines
/// [session] suggests for [template], or `null` when it doesn't differ
/// ([TemplateMatch.differs]). Time, cardio and unknown exercises
/// ([typeOf] without reps) are left out on both sides: they can't be
/// template lines (A37 D17), so adding a plank to a Push day never asks.
List<TemplateTarget>? templateUpdateFor(
  WorkoutTemplateDraft template,
  WorkoutSessionDraft session,
  ExerciseType? Function(String exerciseId) typeOf,
) {
  bool lines(String id) => typeOf(id)?.hasReps ?? false;
  final targets = [
    for (final t in templateTargetsOf(template))
      if (lines(t.exerciseId)) t,
  ];
  final done = [
    for (final d in sessionDoneOf(session))
      if (lines(d.exerciseId) && d.reps.isNotEmpty) d,
  ];
  if (done.isEmpty || !TemplateMatch.differs(targets, done)) return null;
  return TemplateMatch.targetsFrom(done);
}

/// [template] with its lines replaced by [targets] (WO-022): same name;
/// an item keeps its row ID when its exercise stays (the first unused item
/// of that exercise), new lines get IDs from [ids], dropped ones go.
WorkoutTemplateDraft templateWithTargets(
  WorkoutTemplateDraft template,
  List<TemplateTarget> targets,
  IdGenerator ids,
) {
  final unused = [...template.items];
  return WorkoutTemplateDraft(
    name: template.name,
    items: [
      for (final t in targets.take(WorkoutLimits.exercisesMax))
        TemplateItemDraft(
          id: switch (unused.indexWhere((i) => i.exerciseId == t.exerciseId)) {
            -1 => ids.next(),
            final i => unused.removeAt(i).id,
          },
          exerciseId: t.exerciseId,
          sets: t.sets.clamp(1, WorkoutSetBounds.maxSets),
          reps: t.reps.clamp(
            WorkoutSetBounds.minReps,
            WorkoutSetBounds.maxReps,
          ),
        ),
    ],
  );
}
