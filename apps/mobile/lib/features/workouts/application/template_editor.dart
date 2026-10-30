import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/ids/id_generator.dart';
import 'package:fb_mobile/features/workouts/application/exercise_library.dart';
import 'package:fb_mobile/features/workouts/application/workout_actions.dart';
import 'package:fb_mobile/features/workouts/data/workout_repository.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'template_editor.g.dart';

/// A template editor's starting content from "Save as template" (WO-020):
/// a name and the session's targets.
typedef TemplatePrefill = ({String name, List<TemplateTarget> targets});

/// Which template editor: template [templateId] (edit), or a new one,
/// optionally [prefill]ed. [visitId] makes each opening its own form.
@immutable
final class TemplateEditorKey {
  /// The key of one editor visit.
  const new({required this.visitId, this.templateId, this.prefill});

  /// Unique per visit.
  final String visitId;

  /// The template to edit, or `null` for a new one.
  final String? templateId;

  /// A new template's content, or `null` for an empty one.
  final TemplatePrefill? prefill;

  @override
  bool operator ==(Object other) =>
      other is TemplateEditorKey &&
      other.visitId == visitId &&
      other.templateId == templateId;

  @override
  int get hashCode => Object.hash(visitId, templateId);
}

/// One line of the editor: an exercise with target sets × reps (WO-020).
@immutable
final class TemplateLine {
  /// A line; [id] is the item row's ID.
  const new({
    required this.id,
    required this.exerciseId,
    required this.sets,
    required this.reps,
  });

  /// The item row's ID (kept across edits).
  final String id;

  /// The exercise.
  final String exerciseId;

  /// Target sets (1–20).
  final int sets;

  /// Target reps (1–1000).
  final int reps;

  /// This line with some fields changed.
  TemplateLine copyWith({int? sets, int? reps}) => TemplateLine(
    id: id,
    exerciseId: exerciseId,
    sets: sets ?? this.sets,
    reps: reps ?? this.reps,
  );
}

/// The template editor's state (A37 D17).
@immutable
final class TemplateEditorState {
  /// A state.
  new({
    required this.name,
    required Iterable<TemplateLine> lines,
    this.template,
    this.submitted = false,
    this.saving = false,
  }) : lines = List.unmodifiable(lines);

  /// The template's name. User content: never logged.
  final String name;

  /// The lines, in order.
  final List<TemplateLine> lines;

  /// The stored template being edited, or `null` for a new one.
  final Stored<WorkoutTemplateDraft>? template;

  /// Whether Save was tapped (errors show from then on).
  final bool submitted;

  /// Whether a write is running.
  final bool saving;

  /// Whether the name is blank.
  bool get nameMissing => name.trim().isEmpty;

  /// Whether there's no line.
  bool get empty => lines.isEmpty;

  /// The draft to save, or `null` when the form isn't valid.
  WorkoutTemplateDraft? get draft {
    if (nameMissing || empty) return null;
    final trimmed = name.trim();
    if (trimmed.runes.length > WorkoutLimits.nameMax) return null;
    return WorkoutTemplateDraft(
      name: trimmed,
      items: [
        for (final l in lines)
          TemplateItemDraft(
            id: l.id,
            exerciseId: l.exerciseId,
            sets: l.sets,
            reps: l.reps,
          ),
      ],
    );
  }

  /// This state with some fields changed.
  TemplateEditorState copyWith({
    String? name,
    Iterable<TemplateLine>? lines,
    bool? submitted,
    bool? saving,
  }) => TemplateEditorState(
    name: name ?? this.name,
    lines: lines ?? this.lines,
    template: template,
    submitted: submitted ?? this.submitted,
    saving: saving ?? this.saving,
  );
}

/// Target reps a new line starts with.
const int defaultTemplateReps = 10;

/// Target sets a new line starts with.
const int defaultTemplateSets = 3;

/// The template editor (WO-020, A37 D17): name, lines of sets × reps
/// exercises (time and cardio can't be lines), Save and Delete as direct
/// actions with undo.
@riverpod
class TemplateEditor extends _$TemplateEditor {
  @override
  Future<TemplateEditorState> build(TemplateEditorKey key) async {
    final ids = ref.read(idGeneratorProvider);
    if (key.templateId case final id?) {
      // A one-off read: the editor keeps its own edits from here on.
      final templates = await ref
          .read(workoutRepositoryProvider)
          .watchTemplates()
          .first;
      final template = templates.where((t) => t.ref.id == id).firstOrNull;
      if (template == null) throw StateError('the template is gone');
      return TemplateEditorState(
        name: template.draft.name,
        template: template,
        lines: [
          for (final i in template.draft.items)
            TemplateLine(
              id: i.id,
              exerciseId: i.exerciseId,
              sets: i.sets,
              reps: i.reps,
            ),
        ],
      );
    }
    final prefill = key.prefill;
    final library = await ref.read(exerciseLibraryProvider.future);
    return TemplateEditorState(
      name: prefill?.name ?? '',
      lines: [
        for (final t in prefill?.targets ?? const <TemplateTarget>[])
          // Time and cardio exercises can't be template lines (D17).
          if (library.typeOf(t.exerciseId)?.hasReps ?? false)
            TemplateLine(
              id: ids.next(),
              exerciseId: t.exerciseId,
              sets: t.sets.clamp(1, WorkoutSetBounds.maxSets),
              reps: t.reps.clamp(
                WorkoutSetBounds.minReps,
                WorkoutSetBounds.maxReps,
              ),
            ),
      ].take(WorkoutLimits.exercisesMax),
    );
  }

  TemplateEditorState get _state => state.requireValue;

  /// The name changed.
  void setName(String name) => state = AsyncData(_state.copyWith(name: name));

  /// Adds [exerciseIds] (the picker's selection) as lines of 3 × 10,
  /// skipping time and cardio exercises.
  Future<void> addExercises(List<String> exerciseIds) async {
    final library = await ref.read(exerciseLibraryProvider.future);
    if (!ref.mounted) return;
    final ids = ref.read(idGeneratorProvider);
    final lines = [
      ..._state.lines,
      for (final id in exerciseIds)
        if (library.typeOf(id)?.hasReps ?? false)
          TemplateLine(
            id: ids.next(),
            exerciseId: id,
            sets: defaultTemplateSets,
            reps: defaultTemplateReps,
          ),
    ].take(WorkoutLimits.exercisesMax);
    state = AsyncData(_state.copyWith(lines: lines));
  }

  /// Removes line [lineId].
  void removeLine(String lineId) => state = AsyncData(
    _state.copyWith(lines: _state.lines.where((l) => l.id != lineId)),
  );

  /// Moves line [lineId] by [delta] places.
  void moveLine(String lineId, int delta) {
    final lines = [..._state.lines];
    final from = lines.indexWhere((l) => l.id == lineId);
    final to = from + delta;
    if (from < 0 || to < 0 || to >= lines.length) return;
    lines.insert(to, lines.removeAt(from));
    state = AsyncData(_state.copyWith(lines: lines));
  }

  /// Sets line [lineId]'s target sets (kept within 1–20).
  void setSets(String lineId, int sets) => _line(
    lineId,
    (l) => l.copyWith(sets: sets.clamp(1, WorkoutSetBounds.maxSets)),
  );

  /// Sets line [lineId]'s target reps (kept within 1–1000).
  void setReps(String lineId, int reps) => _line(
    lineId,
    (l) => l.copyWith(
      reps: reps.clamp(WorkoutSetBounds.minReps, WorkoutSetBounds.maxReps),
    ),
  );

  void _line(String lineId, TemplateLine Function(TemplateLine l) change) =>
      state = AsyncData(
        _state.copyWith(
          lines: [
            for (final l in _state.lines)
              if (l.id == lineId) change(l) else l,
          ],
        ),
      );

  /// Saves (create or edit); `null` while invalid or already saving.
  Future<WorkoutActionOutcome?> save() async {
    final current = _state;
    final draft = current.draft;
    if (draft == null || current.saving) {
      state = AsyncData(current.copyWith(submitted: true));
      return null;
    }
    state = AsyncData(current.copyWith(submitted: true, saving: true));
    try {
      return await ref
          .read(workoutActionsProvider)
          .saveTemplate(current.template, draft);
    } on Exception {
      // Storage failed: nothing written; the inputs stay for a retry.
      return const WorkoutActionFailed(WorkoutActionFailure.invalid);
    } finally {
      if (ref.mounted) state = AsyncData(_state.copyWith(saving: false));
    }
  }

  /// Deletes the template being edited (plan days using it rest); `null`
  /// for a new one.
  Future<WorkoutActionOutcome?> delete() async {
    final template = _state.template;
    if (template == null || _state.saving) return null;
    state = AsyncData(_state.copyWith(saving: true));
    try {
      return await ref.read(workoutActionsProvider).deleteTemplate(template);
    } on Exception {
      return const WorkoutActionFailed(WorkoutActionFailure.invalid);
    } finally {
      if (ref.mounted) state = AsyncData(_state.copyWith(saving: false));
    }
  }
}
