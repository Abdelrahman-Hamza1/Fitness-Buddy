import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/undo/undo_snack_bar.dart';
import 'package:fb_mobile/features/workouts/application/custom_exercise_form.dart';
import 'package:fb_mobile/features/workouts/application/workout_actions.dart';
import 'package:fb_mobile/features/workouts/presentation/exercise_muscle_map.dart';
import 'package:fb_mobile/features/workouts/presentation/workout_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Opens the custom exercise form (new, named [initialName], or exercise
/// [id]) on the current tab's navigator; resolves with the saved
/// exercise's ID, or `null` when closed or deleted.
Future<String?> openCustomExercise(
  BuildContext context, {
  String? id,
  String initialName = '',
}) => Navigator.of(context).push<String>(
  MaterialPageRoute(
    builder: (_) => CustomExerciseScreen(
      formKey: CustomExerciseKey(id: id, initialName: initialName),
    ),
  ),
);

/// The custom exercise form (WO-003, WO-007, A37 D6, D15): name, aliases,
/// type (locked once used), equipment, main and secondary muscles. Save and
/// Delete are direct actions with undo.
class CustomExerciseScreen extends ConsumerStatefulWidget {
  /// The form for [formKey].
  const new({required this.formKey, super.key});

  /// Which exercise.
  final CustomExerciseKey formKey;

  @override
  ConsumerState<CustomExerciseScreen> createState() => _CustomState();
}

class _CustomState extends ConsumerState<CustomExerciseScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _aliases = TextEditingController();
  bool _filled = false;

  @override
  void dispose() {
    _name.dispose();
    _aliases.dispose();
    super.dispose();
  }

  CustomExerciseForm get _form =>
      ref.read(customExerciseFormProvider(widget.formKey).notifier);

  Future<void> _save() async {
    final l10n = context.l10n;
    final outcome = await _form.save();
    if (!mounted || outcome == null) return;
    switch (outcome) {
      case WorkoutActionDone(:final undoId, :final id):
        showUndoFeedback(
          context,
          message: widget.formKey.id == null
              ? l10n.workoutCustomCreated
              : l10n.workoutCustomUpdated,
          undoEntryId: undoId,
        );
        Navigator.of(context).pop(id);
      case WorkoutActionUnchanged():
        Navigator.of(context).pop(widget.formKey.id);
      case WorkoutActionFailed(:final reason):
        showFbSnackBar(context, _failure(l10n, reason));
    }
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final outcome = await _form.delete();
    if (!mounted || outcome == null) return;
    switch (outcome) {
      case WorkoutActionDone(:final undoId):
        showUndoFeedback(
          context,
          message: l10n.workoutCustomDeleted,
          undoEntryId: undoId,
        );
        Navigator.of(context).pop();
      case WorkoutActionUnchanged():
        Navigator.of(context).pop();
      case WorkoutActionFailed(:final reason):
        showFbSnackBar(context, _failure(l10n, reason));
    }
  }

  static String _failure(AppLocalizations l10n, WorkoutActionFailure reason) =>
      switch (reason) {
        WorkoutActionFailure.changed ||
        WorkoutActionFailure.removed => l10n.workoutActionChanged,
        WorkoutActionFailure.inUse => l10n.workoutCustomInUse,
        WorkoutActionFailure.invalid => l10n.workoutActionRefused,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final editing = widget.formKey.id != null;
    final form = ref.watch(customExerciseFormProvider(widget.formKey)).value;
    if (form != null && !_filled) {
      _filled = true;
      _name.text = form.name;
      _aliases.text = form.aliases;
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          editing ? l10n.workoutCustomEditTitle : l10n.workoutCustomNewTitle,
        ),
      ),
      body: form == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsetsDirectional.all(FbSpace.s4),
              children: [
                FbTextField(
                  key: const ValueKey('workout-custom-name'),
                  controller: _name,
                  label: l10n.workoutCustomName,
                  maxLength: WorkoutLimits.nameMax,
                  errorText: form.submitted && form.nameMissing
                      ? l10n.workoutCustomNameError
                      : null,
                  textInputAction: TextInputAction.next,
                  onChanged: _form.setName,
                ),
                const SizedBox(height: FbSpace.s2),
                FbTextField(
                  key: const ValueKey('workout-custom-aliases'),
                  controller: _aliases,
                  label: l10n.workoutCustomAliases,
                  hint: l10n.workoutCustomAliasesHint,
                  errorText: form.tooManyAliases
                      ? l10n.workoutCustomAliasesTooMany(
                          WorkoutLimits.aliasesMax,
                        )
                      : form.aliasTooLong
                      ? l10n.workoutCustomAliasTooLong(WorkoutLimits.nameMax)
                      : null,
                  onChanged: _form.setAliases,
                ),
                FbSectionHeader(title: l10n.workoutCustomType),
                _Chips<ExerciseType>(
                  values: ExerciseType.values,
                  label: l10n.exerciseType,
                  selected: (t) => t == form.type,
                  onTap: editing && form.inUse ? null : _form.setType,
                ),
                if (editing && form.inUse)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(top: FbSpace.s1),
                    child: Text(
                      l10n.workoutCustomTypeLocked,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                FbSectionHeader(title: l10n.workoutCustomEquipment),
                _Chips<Equipment>(
                  values: Equipment.values,
                  label: l10n.equipment,
                  selected: (e) => e == form.equipment,
                  onTap: _form.setEquipment,
                ),
                const SizedBox(height: FbSpace.s4),
                // Live: redraws as the muscles below change (WO-007).
                Center(
                  child: ExerciseMuscleMap(
                    key: const ValueKey('workout-custom-map'),
                    primary: form.primary,
                    secondaries: form.secondaries,
                  ),
                ),
                FbSectionHeader(title: l10n.workoutCustomPrimary),
                _Chips<Muscle>(
                  keyPrefix: 'workout-custom-primary',
                  values: Muscle.values,
                  label: l10n.muscle,
                  selected: (m) => m == form.primary,
                  onTap: _form.setPrimary,
                ),
                if (form.submitted && form.primaryMissing)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(top: FbSpace.s1),
                    child: Text(
                      l10n.workoutCustomPrimaryError,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                FbSectionHeader(title: l10n.workoutCustomSecondary),
                _Chips<Muscle>(
                  keyPrefix: 'workout-custom-secondary',
                  values: [
                    for (final m in Muscle.values)
                      if (m != form.primary) m,
                  ],
                  label: l10n.muscle,
                  selected: form.secondaries.contains,
                  onTap: _form.toggleSecondary,
                ),
                const SizedBox(height: FbSpace.s5),
                FbButton.primary(
                  key: const ValueKey('workout-custom-save'),
                  label: l10n.workoutCustomSave,
                  expand: true,
                  onPressed: form.saving ? null : _save,
                ),
                if (editing) ...[
                  const SizedBox(height: FbSpace.s2),
                  if (form.inUse)
                    Text(
                      l10n.workoutCustomInUse,
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  else
                    FbButton.text(
                      label: l10n.workoutCustomDelete,
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

/// A wrap of choice chips, one per value.
class _Chips<T extends Enum> extends StatelessWidget {
  const new({
    required this.values,
    required this.label,
    required this.selected,
    required this.onTap,
    this.keyPrefix,
  });

  final List<T> values;
  final String Function(T value) label;
  final bool Function(T value) selected;
  final void Function(T value)? onTap;
  final String? keyPrefix;

  @override
  Widget build(BuildContext context) {
    final onTap = this.onTap;
    return Wrap(
      spacing: FbSpace.s2,
      runSpacing: FbSpace.s2,
      children: [
        for (final value in values)
          FbChoiceChip(
            key: keyPrefix == null
                ? null
                : ValueKey('$keyPrefix-${value.name}'),
            label: label(value),
            dropdown: false,
            selected: selected(value),
            onTap: onTap == null ? null : () => onTap(value),
          ),
      ],
    );
  }
}
