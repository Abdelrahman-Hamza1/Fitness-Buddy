import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/ids/id_generator.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/undo/undo_snack_bar.dart';
import 'package:fb_mobile/features/workouts/application/exercise_library.dart';
import 'package:fb_mobile/features/workouts/application/template_editor.dart';
import 'package:fb_mobile/features/workouts/application/workout_actions.dart';
import 'package:fb_mobile/features/workouts/presentation/exercise_picker_screen.dart';
import 'package:fb_mobile/features/workouts/presentation/workout_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Opens the template editor on the current tab's navigator: template
/// [id], or a new one ([prefill]ed by "Save as template"). A page that
/// returns a result, like the custom exercise form (A37 D13 deviation:
/// a prefill doesn't fit a URL). Resolves with the saved template's ID.
Future<String?> openTemplateEditor(
  BuildContext context, {
  String? id,
  TemplatePrefill? prefill,
}) => Navigator.of(context).push<String>(
  MaterialPageRoute(
    builder: (_) => TemplateEditorScreen(id: id, prefill: prefill),
  ),
);

/// The template editor (WO-020, A37 D17): a name and lines of exercise ×
/// target sets × reps, reorderable; Save (explicit) and Delete are direct
/// actions with undo.
class TemplateEditorScreen extends ConsumerStatefulWidget {
  /// The editor of template [id], or of a new ([prefill]ed) one.
  const new({this.id, this.prefill, super.key});

  /// The template to edit.
  final String? id;

  /// A new template's content.
  final TemplatePrefill? prefill;

  @override
  ConsumerState<TemplateEditorScreen> createState() => _EditorState();
}

class _EditorState extends ConsumerState<TemplateEditorScreen> {
  late final TemplateEditorKey _key = TemplateEditorKey(
    visitId: ref.read(idGeneratorProvider).next(),
    templateId: widget.id,
    prefill: widget.prefill,
  );
  final TextEditingController _name = TextEditingController();
  bool _filled = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  TemplateEditor get _editor => ref.read(templateEditorProvider(_key).notifier);

  Future<void> _add() async {
    final picked = await pickExercises(context, setsAndRepsOnly: true);
    if (!mounted || picked.isEmpty) return;
    await _editor.addExercises(picked);
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final outcome = await _editor.save();
    if (!mounted || outcome == null) return;
    switch (outcome) {
      case WorkoutActionDone(:final undoId, :final id):
        showUndoFeedback(
          context,
          message: widget.id == null
              ? l10n.workoutTemplateCreated
              : l10n.workoutTemplateUpdated,
          undoEntryId: undoId,
        );
        Navigator.of(context).pop(id);
      case WorkoutActionUnchanged():
        Navigator.of(context).pop(widget.id);
      case WorkoutActionFailed(:final reason):
        showFbSnackBar(context, _failure(l10n, reason));
    }
  }

  static String _failure(AppLocalizations l10n, WorkoutActionFailure r) =>
      r == WorkoutActionFailure.invalid
      ? l10n.workoutActionRefused
      : l10n.workoutActionChanged;

  Future<void> _delete() async {
    final l10n = context.l10n;
    final outcome = await _editor.delete();
    if (!mounted || outcome == null) return;
    switch (outcome) {
      case WorkoutActionDone(:final undoId):
        showUndoFeedback(
          context,
          message: l10n.workoutTemplateDeleted,
          undoEntryId: undoId,
        );
        Navigator.of(context).pop();
      case WorkoutActionUnchanged():
        Navigator.of(context).pop();
      case WorkoutActionFailed(:final reason):
        showFbSnackBar(context, _failure(l10n, reason));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final form = ref.watch(templateEditorProvider(_key)).value;
    final library =
        ref.watch(exerciseLibraryProvider).value ?? ExerciseLibrary.empty;
    if (form != null && !_filled) {
      _filled = true;
      _name.text = form.name;
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.id == null
              ? l10n.workoutTemplateNewTitle
              : l10n.workoutTemplateEditTitle,
        ),
      ),
      body: form == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsetsDirectional.all(FbSpace.s4),
              children: [
                FbTextField(
                  key: const ValueKey('workout-template-name'),
                  controller: _name,
                  label: l10n.workoutTemplateName,
                  hint: l10n.workoutTemplateNameHint,
                  maxLength: 80,
                  errorText: form.submitted && form.nameMissing
                      ? l10n.workoutTemplateNameError
                      : null,
                  onChanged: _editor.setName,
                ),
                FbSectionHeader(title: l10n.workoutTemplateExercises),
                for (final (i, line) in form.lines.indexed)
                  _LineRow(
                    key: ValueKey('workout-template-line-${line.id}'),
                    name: l10n.exerciseName(library, line.exerciseId),
                    line: line,
                    first: i == 0,
                    last: i == form.lines.length - 1,
                    editor: _editor,
                  ),
                if (form.submitted && form.empty)
                  Text(
                    l10n.workoutTemplateEmptyError,
                    style: FbType.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                FbButton.text(
                  key: const ValueKey('workout-template-add'),
                  label: l10n.workoutLogAddExercises,
                  icon: FbIcons.add,
                  onPressed: _add,
                ),
                const SizedBox(height: FbSpace.s5),
                FbButton.primary(
                  key: const ValueKey('workout-template-save'),
                  label: l10n.workoutCustomSave,
                  expand: true,
                  onPressed: form.saving ? null : _save,
                ),
                if (widget.id != null) ...[
                  const SizedBox(height: FbSpace.s2),
                  FbButton.text(
                    key: const ValueKey('workout-template-delete'),
                    label: l10n.workoutTemplateDelete,
                    icon: FbIcons.delete,
                    expand: true,
                    onPressed: form.saving ? null : _delete,
                  ),
                ],
              ],
            ),
    );
  }
}

/// One line: the exercise, its sets and reps steppers, and a menu.
class _LineRow extends StatelessWidget {
  const new({
    required this.name,
    required this.line,
    required this.first,
    required this.last,
    required this.editor,
    super.key,
  });

  final String name;
  final TemplateLine line;
  final bool first;
  final bool last;
  final TemplateEditor editor;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(name, style: FbType.title)),
              FbIconButton(
                icon: FbIcons.more,
                tooltip: l10n.workoutExerciseMenu,
                onPressed: () => _menu(context),
              ),
            ],
          ),
          Wrap(
            spacing: FbSpace.s4,
            runSpacing: FbSpace.s2,
            children: [
              TemplateStepper(
                key: ValueKey('workout-template-sets-${line.id}'),
                label: l10n.workoutTemplateSets,
                value: line.sets,
                onChanged: (v) => editor.setSets(line.id, v),
              ),
              TemplateStepper(
                key: ValueKey('workout-template-reps-${line.id}'),
                label: l10n.workoutFieldReps,
                value: line.reps,
                onChanged: (v) => editor.setReps(line.id, v),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _menu(BuildContext context) async {
    final l10n = context.l10n;
    final choice = await showFbSheet<String>(
      context,
      builder: (sheet) => FbOptionList<String>(
        options: [
          if (!first) FbOption(value: 'up', label: l10n.workoutExerciseMoveUp),
          if (!last)
            FbOption(value: 'down', label: l10n.workoutExerciseMoveDown),
          FbOption(value: 'remove', label: l10n.workoutExerciseRemove),
        ],
        selected: null,
        onSelected: (value) => Navigator.of(sheet).pop(value),
      ),
    );
    switch (choice) {
      case 'up':
        editor.moveLine(line.id, -1);
      case 'down':
        editor.moveLine(line.id, 1);
      case 'remove':
        editor.removeLine(line.id);
    }
  }
}

/// A labelled − value + stepper (48 dp buttons): template targets.
class TemplateStepper extends StatelessWidget {
  /// A stepper of [value] named [label].
  const new({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  /// What it counts ("Sets").
  final String label;

  /// The value.
  final int value;

  /// − or + was tapped.
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Semantics(
      label: label,
      value: '$value',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: FbType.bodySmall),
          FbIconButton(
            icon: FbIcons.remove,
            tooltip: l10n.workoutTemplateLess(label),
            onPressed: () => onChanged(value - 1),
          ),
          ExcludeSemantics(child: Text('$value', style: FbType.title)),
          FbIconButton(
            icon: FbIcons.add,
            tooltip: l10n.workoutTemplateMore(label),
            onPressed: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }
}
