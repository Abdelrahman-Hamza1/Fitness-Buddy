import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/workouts/application/exercise_library.dart';
import 'package:fb_mobile/features/workouts/application/workout_log_controller.dart';
import 'package:fb_mobile/features/workouts/application/workout_log_state.dart';
import 'package:fb_mobile/features/workouts/presentation/set_row.dart';
import 'package:fb_mobile/features/workouts/presentation/workout_text.dart';
import 'package:material_ui/material_ui.dart';

enum _CardAction { up, down, remove }

/// One exercise of the log form (A37 D7): name, main muscle group, PR
/// marker and ⋮ (move up/down, remove), the "kg per dumbbell" note, the set
/// rows and "+ Add set".
class ExerciseLogCard extends StatelessWidget {
  /// The card [card] at [index] of [count], edited through [controller].
  const new({
    required this.card,
    required this.index,
    required this.count,
    required this.library,
    required this.controller,
    required this.prs,
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

  Future<void> _menu(BuildContext context) async {
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
    final exercise = library.byId[card.exerciseId];
    final type = exercise?.type;
    final primary = exercise?.primary;
    final isPr = prs?.ofExercise(card.id).isNotEmpty ?? false;
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: FbDensity.cardGap),
      child: FbCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.exerciseName(library, card.exerciseId),
                        style: theme.textTheme.titleMedium,
                      ),
                      if (primary != null)
                        Text(
                          l10n.muscleGroup(primary.group),
                          style: theme.textTheme.bodySmall,
                        ),
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
                FbIconButton(
                  key: ValueKey('workout-card-menu-${card.id}'),
                  icon: FbIcons.more,
                  tooltip: l10n.workoutExerciseMenu,
                  onPressed: () => _menu(context),
                ),
              ],
            ),
            if (exercise?.equipment.weightIsPerImplement ?? false)
              Text(l10n.workoutPerDumbbell, style: theme.textTheme.bodySmall),
            for (final (i, row) in card.sets.indexed)
              SetRow(
                key: ValueKey(row.id),
                row: row,
                number: i + 1,
                type: type,
                isPr: prs?.ofSet(row.id).isNotEmpty ?? false,
                onChanged: (input) =>
                    controller.editSet(card.id, row.id, input),
                onToggle: () => controller.toggleSet(card.id, row.id),
                onRemove: () => controller.removeSet(card.id, row.id),
              ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FbButton.text(
                key: ValueKey('workout-add-set-${card.id}'),
                label: l10n.workoutLogAddSet,
                icon: FbIcons.add,
                onPressed: type == null
                    ? null
                    : () => controller.addSet(card.id),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
