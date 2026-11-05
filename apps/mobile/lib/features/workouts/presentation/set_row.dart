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
  /// Keeps the reserved status line one line tall when empty.
  static const _blank = '\u00a0';

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
              // Dense inline inputs: the row reserves its own status
              // (A57 A02, D20).
              supportingLines: 0,
              keyboardType: TextInputType.datetime,
              textInputAction: TextInputAction.next,
              enabled: type != null,
              onChanged: _changed,
            )
          : FbNumberField(
              controller: controller,
              label: label,
              hint: hintText,
              supportingLines: 0,
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
    // The set's number opens its menu (remove): a labelled 48 × 48 target.
    final number = Semantics(
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
    );
    Widget last({int maxLines = 2}) => Semantics(
      label: lastTime.isEmpty ? null : l10n.workoutLastTime(lastTime),
      child: ExcludeSemantics(
        child: Text(
          lastTime,
          key: ValueKey('workout-set-last-${row.id}'),
          style: theme.textTheme.bodySmall,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
    final checkbox = Checkbox(
      key: ValueKey('workout-set-done-${row.id}'),
      value: row.checked,
      semanticLabel: l10n.workoutSetDone(widget.number),
      onChanged: type == null && !row.checked ? null : (_) => widget.onToggle(),
    );
    final pr = widget.isPr && row.checked;
    final invalid = row.issue != null;
    final inputs = [
      for (final (i, f) in fields.indexed) ...[
        if (i > 0) const SizedBox(width: FbSpace.s2),
        f,
      ],
    ];
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: FbSpace.s1),
      // C1 A (A57 D20, A05, A51): at large text or on a narrow phone "last
      // time" goes above the inputs and PR or the invalid note get their
      // own reserved line; otherwise one row with a fixed status slot.
      // Either way nothing moves when a set turns PR or invalid.
      child: Builder(
        builder: (context) {
          final compact =
              MediaQuery.sizeOf(context).width < 360 ||
              MediaQuery.textScalerOf(context).scale(1) >= 1.3;
          if (compact) {
            return Column(
              key: ValueKey('workout-set-compact-${row.id}'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    number,
                    Expanded(child: last()),
                  ],
                ),
                Row(children: [...inputs, checkbox]),
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: FbSpace.s7),
                  child: Text(
                    pr
                        ? l10n.workoutPr
                        : invalid
                        ? l10n.workoutSetInvalid
                        : _blank,
                    key: ValueKey('workout-set-status-${row.id}'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: invalid && !pr
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            );
          }
          return Row(
            children: [
              number,
              SizedBox(width: FbSpace.s7 + FbSpace.s2, child: last()),
              ...inputs,
              // A fixed status slot before the checkbox (A05): PR, or an
              // error mark for numbers that can't be saved.
              SizedBox(
                key: ValueKey('workout-set-status-${row.id}'),
                width: FbSpace.s6,
                child: Center(
                  child: pr
                      ? Text(
                          l10n.workoutPr,
                          maxLines: 1,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        )
                      : invalid
                      ? Tooltip(
                          message: l10n.workoutSetInvalid,
                          child: Semantics(
                            label: l10n.workoutSetInvalid,
                            child: Icon(
                              FbIcons.error,
                              size: 20,
                              color: theme.colorScheme.error,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
              checkbox,
            ],
          );
        },
      ),
    );
  }
}
