import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/workouts/application/template_editor.dart'
    show defaultTemplateReps, defaultTemplateSets;
import 'package:flutter/foundation.dart' show immutable;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'plan_setup.g.dart';

/// Which plan setup: [plan], one form per [visitId] (D-089).
@immutable
final class PlanSetupKey {
  /// The setup of [plan] for one visit.
  const new({required this.visitId, required this.plan});

  /// Unique per visit.
  final String visitId;

  /// The starter plan being set up.
  final StarterPlan plan;

  @override
  bool operator ==(Object other) =>
      other is PlanSetupKey && other.visitId == visitId && other.plan == plan;

  @override
  int get hashCode => Object.hash(visitId, plan);
}

/// A plan being set up (D-089, A52 D5): each workout day's chosen
/// exercises. Every day starts empty; the starter template's lines are only
/// suggestions. Nothing is written until the user finishes.
@immutable
final class PlanSetupState {
  /// [plan] with [chosen] lines per day.
  new({
    required this.plan,
    Map<StarterTemplate, List<TemplateTarget>> chosen = const {},
  }) : chosen = Map.unmodifiable({
         for (final MapEntry(:key, :value) in chosen.entries)
           key: List<TemplateTarget>.unmodifiable(value),
       });

  /// The starter plan.
  final StarterPlan plan;

  /// The chosen lines of each day, in the order added.
  final Map<StarterTemplate, List<TemplateTarget>> chosen;

  /// [day]'s chosen lines.
  List<TemplateTarget> chosenOf(StarterTemplate day) => chosen[day] ?? const [];

  /// [day]'s suggestions not chosen yet ("Suggested for Push").
  List<TemplateTarget> suggestionsOf(StarterTemplate day) {
    final ids = {for (final t in chosenOf(day)) t.exerciseId};
    return [
      for (final t in day.items)
        if (!ids.contains(t.exerciseId)) t,
    ];
  }

  /// Whether every day has at least one exercise: the plan can be saved.
  bool get complete => plan.templates.every((t) => chosenOf(t).isNotEmpty);

  /// This state with [day]'s lines replaced.
  PlanSetupState withDay(StarterTemplate day, List<TemplateTarget> lines) =>
      PlanSetupState(plan: plan, chosen: {...chosen, day: lines});
}

/// The plan setup form's view model (D-089, A52 D5).
@riverpod
class PlanSetup extends _$PlanSetup {
  @override
  PlanSetupState build(PlanSetupKey key) => PlanSetupState(plan: key.plan);

  /// Adds [exerciseIds] to [day] (a suggestion keeps its sets × reps, any
  /// other exercise gets 3 × 10), skipping ones already there; at most
  /// [WorkoutLimits.exercisesMax] lines.
  void add(StarterTemplate day, Iterable<String> exerciseIds) {
    final lines = [...state.chosenOf(day)];
    for (final id in exerciseIds) {
      if (lines.length >= WorkoutLimits.exercisesMax) break;
      if (lines.any((l) => l.exerciseId == id)) continue;
      lines.add(
        day.items.where((t) => t.exerciseId == id).firstOrNull ??
            (
              exerciseId: id,
              sets: defaultTemplateSets,
              reps: defaultTemplateReps,
            ),
      );
    }
    state = state.withDay(day, lines);
  }

  /// Adds every remaining suggestion of [day] ("Add all 3").
  void addAll(StarterTemplate day) =>
      add(day, [for (final t in state.suggestionsOf(day)) t.exerciseId]);

  /// Removes [exerciseId] from [day].
  void remove(StarterTemplate day, String exerciseId) =>
      state = state.withDay(day, [
        for (final l in state.chosenOf(day))
          if (l.exerciseId != exerciseId) l,
      ]);

  /// Sets [exerciseId]'s target on [day] (clamped to the set bounds).
  void setTarget(
    StarterTemplate day,
    String exerciseId, {
    required int sets,
    required int reps,
  }) => state = state.withDay(day, [
    for (final l in state.chosenOf(day))
      if (l.exerciseId == exerciseId)
        (
          exerciseId: exerciseId,
          sets: sets.clamp(1, WorkoutSetBounds.maxSets),
          reps: reps.clamp(WorkoutSetBounds.minReps, WorkoutSetBounds.maxReps),
        )
      else
        l,
  ]);
}
