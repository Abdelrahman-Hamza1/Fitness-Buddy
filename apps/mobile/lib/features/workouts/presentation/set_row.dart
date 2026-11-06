import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/workouts/application/set_input.dart';
import 'package:fb_mobile/features/workouts/application/workout_log_state.dart';
import 'package:fb_mobile/features/workouts/presentation/workout_text.dart';
import 'package:material_ui/material_ui.dart';

/// One set row of the log form (A37 D7, A63 D15): `# · last time · inputs ·
/// status`. A set counts as soon as it has valid numbers; last time's
/// numbers show as dashed hints that don't count (D-097). Fields by type
/// (WO-004). In the normal layout the card's [SetHeaderRow] names the
/// columns; the compact layout keeps each field's label.
class SetRow extends StatefulWidget {
  /// Row [row] (set [number]) of an exercise of [type] (`null`: unknown,
  /// read-only).
  const new({
    required this.row,
    required this.number,
    required this.type,
    required this.isPr,
    required this.onChanged,
    required this.onRemove,
    super.key,
  });

  /// Whether rows stack (A57 D20): a narrow phone or large text. The card's
  /// header row shows only when they don't.
  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 360 ||
      MediaQuery.textScalerOf(context).scale(1) >= 1.3;

  /// The width of the set number column.
  static const double numberWidth = FbSpace.s7;

  /// The width of the "last time" column.
  static const double lastWidth = FbSpace.s7 + FbSpace.s2;

  /// The width of the PR / error status slot.
  static const double statusWidth = FbSpace.s6;

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

  /// Whether one of the row's fields has focus: the issue mark waits until
  /// focus leaves, so a half-typed set doesn't flash an error (A63 D14).
  bool _editing = false;

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
    // The controller filled the fields (Same as last time, Reload): show
    // it.
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
    final compact = SetRow.isCompact(context);
    final labels = setFieldLabels(l10n, type);
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
              hideLabel: !compact,
              dashedWhenEmpty: hintText.isNotEmpty,
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
              hideLabel: !compact,
              dashedWhenEmpty: hintText.isNotEmpty,
              onChanged: _changed,
            ),
    );
    final fields = switch (type) {
      ExerciseType.weightReps ||
      ExerciseType.bodyweightReps ||
      ExerciseType.assisted => [
        field(_first, labels[0], hints.$1),
        field(_second, labels[1], hints.$2, decimals: 0),
      ],
      ExerciseType.repsOnly => [
        field(_first, labels[0], hints.$1, decimals: 0),
      ],
      ExerciseType.duration => [
        field(_first, labels[0], hints.$1, clock: true),
      ],
      ExerciseType.distanceDuration => [
        field(_first, labels[0], hints.$1),
        field(_second, labels[1], hints.$2),
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
            dimension: SetRow.numberWidth,
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
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
    // PR only on a set that counts; the issue only once focus left the row.
    final pr = widget.isPr && row.counts;
    final invalid = row.issue != null && !_editing;
    final inputs = Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (focused) => setState(() => _editing = focused),
      child: Row(
        children: [
          for (final (i, f) in fields.indexed) ...[
            if (i > 0) const SizedBox(width: FbSpace.s2),
            f,
          ],
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: FbSpace.s1),
      // C1 A (A57 D20, A05, A51): at large text or on a narrow phone "last
      // time" goes above the inputs and PR or the invalid note get their
      // own reserved line; otherwise one row with a fixed status slot.
      // Either way nothing moves when a set turns PR or invalid.
      child: compact
          ? Column(
              key: ValueKey('workout-set-compact-${row.id}'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    number,
                    Expanded(child: last()),
                  ],
                ),
                inputs,
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: SetRow.numberWidth,
                  ),
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
            )
          : Row(
              children: [
                number,
                SizedBox(width: SetRow.lastWidth, child: last()),
                Expanded(child: inputs),
                // A fixed status slot (A05): PR, or an error mark for
                // numbers that can't be saved.
                SizedBox(
                  key: ValueKey('workout-set-status-${row.id}'),
                  width: SetRow.statusWidth,
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
              ],
            ),
    );
  }
}

/// The field names of an exercise [type], in field order (WO-004).
List<String> setFieldLabels(AppLocalizations l10n, ExerciseType? type) =>
    switch (type) {
      ExerciseType.weightReps => [l10n.workoutFieldKg, l10n.workoutFieldReps],
      ExerciseType.bodyweightReps => [
        l10n.workoutFieldAddedKg,
        l10n.workoutFieldReps,
      ],
      ExerciseType.assisted => [
        l10n.workoutFieldAssistKg,
        l10n.workoutFieldReps,
      ],
      ExerciseType.repsOnly => [l10n.workoutFieldReps],
      ExerciseType.duration => [l10n.workoutFieldTime],
      ExerciseType.distanceDuration => [
        l10n.workoutFieldMinutes,
        l10n.workoutFieldKm,
      ],
      null => const [],
    };

/// The column names above a card's set rows in the normal layout (A63
/// D15): Set · Last · the type's fields. Hidden from screen readers (each
/// field keeps its spoken name). Columns line up with [SetRow]'s.
class SetHeaderRow extends StatelessWidget {
  /// The header of an exercise of [type].
  const new({required this.type, super.key});

  /// The exercise type.
  final ExerciseType type;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final style = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    Text label(String text, {TextAlign align = TextAlign.start}) => Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: align,
      style: style,
    );
    final names = setFieldLabels(l10n, type);
    return ExcludeSemantics(
      child: Row(
        children: [
          SizedBox(
            width: SetRow.numberWidth,
            child: label(l10n.workoutSetHeader, align: TextAlign.center),
          ),
          SizedBox(
            width: SetRow.lastWidth,
            child: label(l10n.workoutLastHeader),
          ),
          for (final (i, name) in names.indexed) ...[
            if (i > 0) const SizedBox(width: FbSpace.s2),
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: FbSpace.s4),
                child: label(name),
              ),
            ),
          ],
          const SizedBox(width: SetRow.statusWidth),
        ],
      ),
    );
  }
}
