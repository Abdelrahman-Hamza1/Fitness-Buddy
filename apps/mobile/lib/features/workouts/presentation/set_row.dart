import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/workouts/application/set_input.dart';
import 'package:fb_mobile/features/workouts/application/workout_log_state.dart';
import 'package:fb_mobile/features/workouts/presentation/workout_text.dart';
import 'package:material_ui/material_ui.dart';

/// One set row of the log form (A37 D7): `# · last time · inputs · ✓`.
/// The fields show last time's numbers as hints; ✓ with empty fields
/// accepts them. Fields by type (WO-004).
class SetRow extends StatefulWidget {
  /// Row [row] (set [number]) of an exercise of [type] (`null`: unknown,
  /// read-only).
  const new({
    required this.row,
    required this.number,
    required this.type,
    required this.isPr,
    required this.onChanged,
    required this.onToggle,
    required this.onRemove,
    super.key,
  });

  /// The row.
  final LogSetRow row;

  /// Its 1-based number.
  final int number;

  /// The exercise type, or `null` for an unknown exercise.
  final ExerciseType? type;

  /// Whether the saved set is a PR (WO-042: a plain marker).
  final bool isPr;

  /// The inputs changed.
  final ValueChanged<SetInput> onChanged;

  /// ✓ was tapped.
  final VoidCallback onToggle;

  /// The set was removed (its number's menu).
  final VoidCallback onRemove;

  @override
  State<SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<SetRow> {
  late final TextEditingController _first;
  late final TextEditingController _second;

  @override
  void initState() {
    super.initState();
    final (first, second) = _texts(widget.row.input);
    _first = TextEditingController(text: first);
    _second = TextEditingController(text: second);
  }

  @override
  void didUpdateWidget(SetRow old) {
    super.didUpdateWidget(old);
    // The controller filled the fields (✓ on a hint, Reload): show it.
    if (widget.row.input != _input()) {
      final (first, second) = _texts(widget.row.input);
      _first.text = first;
      _second.text = second;
    }
  }

  @override
  void dispose() {
    _first.dispose();
    _second.dispose();
    super.dispose();
  }

  /// The two field texts of [input] for this type: (first, second).
  (String, String) _texts(SetInput input) => switch (widget.type) {
    ExerciseType.weightReps ||
    ExerciseType.assisted ||
    ExerciseType.bodyweightReps => (input.weight, input.reps),
    ExerciseType.repsOnly => (input.reps, ''),
    ExerciseType.duration => (input.duration, ''),
    ExerciseType.distanceDuration => (input.duration, input.distance),
    null => ('', ''),
  };

  SetInput _input() => switch (widget.type) {
    ExerciseType.weightReps ||
    ExerciseType.assisted ||
    ExerciseType.bodyweightReps => SetInput(
      weight: _first.text,
      reps: _second.text,
    ),
    ExerciseType.repsOnly => SetInput(reps: _first.text),
    ExerciseType.duration => SetInput(duration: _first.text),
    ExerciseType.distanceDuration => SetInput(
      duration: _first.text,
      distance: _second.text,
    ),
    null => const SetInput(),
  };

  void _changed(String _) => widget.onChanged(_input());

  Future<void> _menu(BuildContext context) async {
    final l10n = context.l10n;
    final remove = await showFbSheet<bool>(
      context,
      builder: (sheet) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FbListRow(
            key: const ValueKey('workout-set-remove'),
            leading: const Icon(FbIcons.delete),
            title: l10n.workoutSetRemove,
            onTap: () => Navigator.of(sheet).pop(true),
          ),
        ],
      ),
    );
    if (remove ?? false) widget.onRemove();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final type = widget.type;
    final row = widget.row;
    final hint = row.hint;
    final hints = hint == null || type == null
        ? ('', '')
        : _texts(SetInput.of(type, hint));
    final lastTime = hint == null ? '' : l10n.setValues(type, hint);
    Widget field(
      TextEditingController controller,
      String label,
      String hintText, {
      int decimals = 2,
      bool clock = false,
    }) => Expanded(
      child: clock
          ? FbTextField(
              controller: controller,
              label: label,
              hint: hintText,
              keyboardType: TextInputType.datetime,
              textInputAction: TextInputAction.next,
              enabled: type != null,
              onChanged: _changed,
            )
          : FbNumberField(
              controller: controller,
              label: label,
              hint: hintText,
              maxDecimals: decimals,
              textInputAction: TextInputAction.next,
              enabled: type != null,
              onChanged: _changed,
            ),
    );
    final fields = switch (type) {
      ExerciseType.weightReps => [
        field(_first, l10n.workoutFieldKg, hints.$1),
        field(_second, l10n.workoutFieldReps, hints.$2, decimals: 0),
      ],
      ExerciseType.bodyweightReps => [
        field(_first, l10n.workoutFieldAddedKg, hints.$1),
        field(_second, l10n.workoutFieldReps, hints.$2, decimals: 0),
      ],
      ExerciseType.assisted => [
        field(_first, l10n.workoutFieldAssistKg, hints.$1),
        field(_second, l10n.workoutFieldReps, hints.$2, decimals: 0),
      ],
      ExerciseType.repsOnly => [
        field(_first, l10n.workoutFieldReps, hints.$1, decimals: 0),
      ],
      ExerciseType.duration => [
        field(_first, l10n.workoutFieldTime, hints.$1, clock: true),
      ],
      ExerciseType.distanceDuration => [
        field(_first, l10n.workoutFieldMinutes, hints.$1),
        field(_second, l10n.workoutFieldKm, hints.$2),
      ],
      null => <Widget>[],
    };
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: FbSpace.s1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // The set's number opens its menu (remove): a labelled
              // 48 × 48 target.
              Semantics(
                button: true,
                label: l10n.workoutSetMenu(widget.number),
                excludeSemantics: true,
                child: Tooltip(
                  message: l10n.workoutSetMenu(widget.number),
                  child: InkResponse(
                    key: ValueKey('workout-set-menu-${row.id}'),
                    onTap: () => unawaited(_menu(context)),
                    child: SizedBox.square(
                      dimension: FbSpace.s7,
                      child: Center(
                        child: Text(
                          l10n.workoutSetNumber(widget.number),
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: FbSpace.s7 + FbSpace.s2,
                child: Semantics(
                  label: lastTime.isEmpty
                      ? null
                      : l10n.workoutLastTime(lastTime),
                  child: ExcludeSemantics(
                    child: Text(
                      lastTime,
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                    ),
                  ),
                ),
              ),
              for (final (i, f) in fields.indexed) ...[
                if (i > 0) const SizedBox(width: FbSpace.s2),
                f,
              ],
              if (widget.isPr && row.checked)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: FbSpace.s1),
                  child: Text(
                    l10n.workoutPr,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              Checkbox(
                key: ValueKey('workout-set-done-${row.id}'),
                value: row.checked,
                semanticLabel: l10n.workoutSetDone(widget.number),
                onChanged: type == null && !row.checked
                    ? null
                    : (_) => widget.onToggle(),
              ),
            ],
          ),
          if (row.issue != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: FbSpace.s5),
              child: Text(
                l10n.workoutSetInvalid,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
