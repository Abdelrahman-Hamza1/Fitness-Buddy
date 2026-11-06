import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/ui/revealed_column.dart';
import 'package:fb_mobile/features/workouts/application/exercise_library.dart';
import 'package:fb_mobile/features/workouts/application/workout_log_controller.dart';
import 'package:fb_mobile/features/workouts/application/workout_log_state.dart';
import 'package:fb_mobile/features/workouts/presentation/exercise_muscle_map.dart';
import 'package:fb_mobile/features/workouts/presentation/set_row.dart';
import 'package:fb_mobile/features/workouts/presentation/workout_text.dart';
import 'package:material_ui/material_ui.dart';

enum _CardAction { up, down, remove }

/// One exercise of the log form (A37 D7, D-089): its muscle map, name,
/// main muscle group and equipment (with the "kg per dumbbell" note), PR
/// marker, show/hide and ⋮ (move up/down, remove), then one header row
/// (A63 D15), the set rows and "+ Add set" / "Same as last time". A set
/// row swipes away toward the start edge, with Undo (A63 D16). A
/// [collapsed] card shows only its header ("3 sets planned").
class ExerciseLogCard extends StatefulWidget {
  /// The card [card] at [index] of [count], edited through [controller].
  const new({
    required this.card,
    required this.index,
    required this.count,
    required this.library,
    required this.controller,
    required this.prs,
    this.collapsed = false,
    this.onCollapse,
    super.key,
  });

  /// The card.
  final LogExerciseCard card;

  /// Its position.
  final int index;

  /// How many cards the form has.
  final int count;

  /// Names, types and muscles.
  final ExerciseLibrary library;

  /// The form's view model.
  final WorkoutLogController controller;

  /// The history's PR markers, or `null` while they load.
  final SessionPrs? prs;

  /// Whether only the header shows.
  final bool collapsed;

  /// Shows ([collapsed]) or hides the sets; `null`: no toggle.
  final VoidCallback? onCollapse;

  @override
  State<ExerciseLogCard> createState() => _ExerciseLogCardState();
}

class _ExerciseLogCardState extends State<ExerciseLogCard> {
  /// How often each set row came back through Undo: its swipe wrapper gets
  /// a fresh identity, so it never comes back slid out (A63 PA7).
  final Map<String, int> _restores = {};

  LogExerciseCard get card => widget.card;
  WorkoutLogController get controller => widget.controller;

  /// Removes set [row] (number [number]) by swipe or its menu, with an
  /// in-form Undo (A63 D16): the visit keeps its one undo-stack entry.
  void _removeSet(LogSetRow row, int number) {
    final removed = controller.removeSet(card.id, row.id);
    if (removed == null) return;
    final (gone, index) = removed;
    final full = context.l10n.workoutSetRestoreFull(maxSetsPerExercise);
    showFbUndoSnackBar(
      context,
      message: context.l10n.workoutSetRemoved(number),
      onUndo: () {
        switch (controller.restoreSet(card.id, gone, index)) {
          case SetRestore.restored:
            if (mounted) {
              setState(
                () => _restores[gone.id] = (_restores[gone.id] ?? 0) + 1,
              );
            }
          case SetRestore.full:
            if (mounted) showFbSnackBar(context, full);
          case SetRestore.gone:
            break;
        }
      },
    );
  }

  Future<void> _menu(BuildContext context) async {
    final index = widget.index;
    final count = widget.count;
    final l10n = context.l10n;
    final action = await showFbSheet<_CardAction>(
      context,
      builder: (sheet) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (index > 0)
            FbListRow(
              title: l10n.workoutExerciseMoveUp,
              onTap: () => Navigator.of(sheet).pop(_CardAction.up),
            ),
          if (index < count - 1)
            FbListRow(
              title: l10n.workoutExerciseMoveDown,
              onTap: () => Navigator.of(sheet).pop(_CardAction.down),
            ),
          FbListRow(
            title: l10n.workoutExerciseRemove,
            onTap: () => Navigator.of(sheet).pop(_CardAction.remove),
          ),
        ],
      ),
    );
    switch (action) {
      case _CardAction.up:
        controller.moveExercise(card.id, -1);
      case _CardAction.down:
        controller.moveExercise(card.id, 1);
      case _CardAction.remove:
        controller.removeExercise(card.id);
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final library = widget.library;
    final prs = widget.prs;
    final collapsed = widget.collapsed;
    final exercise = library.byId[card.exerciseId];
    final type = exercise?.type;
    final primary = exercise?.primary;
    final isPr = prs?.ofExercise(card.id).isNotEmpty ?? false;
    final name = l10n.exerciseName(library, card.exerciseId);
    final details = [
      if (primary != null) l10n.muscleGroup(primary.group),
      if (exercise != null) l10n.equipment(exercise.equipment),
      if (exercise?.equipment.weightIsPerImplement ?? false)
        l10n.workoutPerDumbbell,
      if (collapsed) l10n.workoutCardPlanned(card.sets.length),
    ].join(' · ');
    final onCollapse = widget.onCollapse;
    final canFill =
        type != null && card.sets.any((s) => s.input.isEmpty && s.hint != null);
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: FbDensity.cardGap),
      child: FbCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              spacing: FbSpace.s3,
              children: [
                ExerciseMuscleMap(
                  primary: primary,
                  secondaries: exercise?.secondaries ?? const [],
                  height: ExerciseMuscleMap.cardHeight,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: theme.textTheme.titleMedium),
                      if (details.isNotEmpty)
                        Text(details, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                if (isPr)
                  Text(
                    l10n.workoutPr,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                if (onCollapse != null)
                  FbIconButton(
                    key: ValueKey('workout-card-collapse-${card.id}'),
                    icon: collapsed ? FbIcons.expand : FbIcons.collapse,
                    tooltip: collapsed
                        ? l10n.workoutCardShow(name)
                        : l10n.workoutCardHide(name),
                    onPressed: onCollapse,
                  ),
                FbIconButton(
                  key: ValueKey('workout-card-menu-${card.id}'),
                  icon: FbIcons.more,
                  tooltip: l10n.workoutExerciseMenu,
                  onPressed: () => _menu(context),
                ),
              ],
            ),
            // Collapsing shrinks the sets under the header; added and
            // removed sets grow in and out (A57 A21/A22).
            FbReveal(
              visible: !collapsed,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (type != null &&
                      card.sets.isNotEmpty &&
                      !SetRow.isCompact(context))
                    SetHeaderRow(
                      key: ValueKey('workout-set-header-${card.id}'),
                      type: type,
                    ),
                  RevealedColumn(
                    children: [
                      for (final (i, row) in card.sets.indexed)
                        KeyedSubtree(
                          key: ValueKey('workout-set-${row.id}'),
                          child: FbSwipeActions(
                            key: ValueKey(_restores[row.id] ?? 0),
                            // The column's removal owns the exit (PA7).
                            collapseOnDismiss: false,
                            dismissAction: type == null
                                ? null
                                : FbSwipeAction(
                                    label: l10n.workoutSetRemove,
                                    icon: FbIcons.delete,
                                    onTriggered: () => _removeSet(row, i + 1),
                                  ),
                            child: SetRow(
                              key: ValueKey(row.id),
                              row: row,
                              number: i + 1,
                              type: type,
                              isPr: prs?.ofSet(row.id).isNotEmpty ?? false,
                              onChanged: (input) =>
                                  controller.editSet(card.id, row.id, input),
                              onRemove: () => _removeSet(row, i + 1),
                            ),
                          ),
                        ),
                    ],
                  ),
                  Wrap(
                    spacing: FbSpace.s2,
                    children: [
                      FbButton.text(
                        key: ValueKey('workout-add-set-${card.id}'),
                        label: l10n.workoutLogAddSet,
                        icon: FbIcons.add,
                        onPressed: type == null
                            ? null
                            : () => controller.addSet(card.id),
                      ),
                      if (canFill)
                        FbButton.text(
                          key: ValueKey('workout-same-as-last-${card.id}'),
                          label: l10n.workoutSameAsLast,
                          icon: FbIcons.sameAsLast,
                          onPressed: () => controller.fillFromLastTime(card.id),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
