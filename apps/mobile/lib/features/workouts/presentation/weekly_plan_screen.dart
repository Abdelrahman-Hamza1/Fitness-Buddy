import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/core/undo/undo_snack_bar.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_mobile/features/workouts/application/exercise_library.dart';
import 'package:fb_mobile/features/workouts/application/workout_actions.dart';
import 'package:fb_mobile/features/workouts/application/workout_views.dart';
import 'package:fb_mobile/features/workouts/presentation/exercise_muscle_map.dart';
import 'package:fb_mobile/features/workouts/presentation/template_editor_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// A weekday's full name ("Monday") in [locale].
String weekdayName(String locale, DayOfWeek day) =>
    // 2024-01-01 was a Monday, so day N of that week is ISO weekday N.
    DateFormat.EEEE(locale).format(DateTime(2024, 1, day.isoNumber));

/// "Your plan" (WO-021, D-085, D-089): which workout each weekday trains,
/// in the user's week order (a tap picks a workout or Rest, a direct action
/// with undo); the workouts (templates) to edit or log; a new workout; and
/// "Choose a different plan".
class WeeklyPlanScreen extends ConsumerWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final weekStart = ref.watch(weekStartProvider).value ?? DayOfWeek.saturday;
    final plan = ref.watch(workoutPlanProvider).value ?? const {};
    final templates = ref.watch(workoutTemplatesProvider).value ?? const [];
    final library =
        ref.watch(exerciseLibraryProvider).value ?? ExerciseLibrary.empty;
    final navigator = ref.read(appNavigatorProvider);
    String? nameOf(String? id) =>
        templates.where((t) => t.ref.id == id).firstOrNull?.draft.name;
    Widget section(String title) => Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: FbSpace.s4),
      child: FbSectionHeader(title: title),
    );
    return Scaffold(
      appBar: AppBar(title: Text(l10n.workoutsYourPlan)),
      body: ListView(
        padding: const EdgeInsetsDirectional.symmetric(vertical: FbSpace.s2),
        children: [
          section(l10n.workoutPlanTitle),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: FbSpace.s4,
            ),
            child: Text(
              l10n.workoutPlanIntro,
              style: FbType.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          for (final day in WeekCalendar(weekStart: weekStart).daysInOrder)
            FbListRow(
              key: ValueKey('workout-plan-day-${day.name}'),
              title: weekdayName(locale, day),
              subtitle: nameOf(plan[day]) ?? l10n.workoutPlanRest,
              trailing: const Icon(FbIcons.expand),
              onTap: () => unawaited(
                _choose(context, ref, day, plan[day], templates, locale),
              ),
            ),
          section(l10n.workoutPlanWorkoutsSection),
          for (final t in templates)
            FbListRow(
              key: ValueKey('workouts-template-${t.ref.id}'),
              leading: ExerciseMuscleMap.union(
                library.musclesOf([
                  for (final i in t.draft.items) i.exerciseId,
                ]),
                height: ExerciseMuscleMap.rowHeight,
              ),
              title: t.draft.name,
              subtitle: l10n.workoutsTemplateSummary(t.draft.items.length),
              onTap: () => unawaited(openTemplateEditor(context, id: t.ref.id)),
              trailing: FbButton.text(
                key: ValueKey('workouts-template-log-${t.ref.id}'),
                label: l10n.workoutsTemplateLog,
                onPressed: () =>
                    navigator.push(WorkoutLogRoute(template: t.ref.id)),
              ),
            ),
          FbListRow(
            key: const ValueKey('workout-plan-new-template'),
            leading: const Icon(FbIcons.add),
            title: l10n.workoutsNewTemplate,
            onTap: () => unawaited(openTemplateEditor(context)),
          ),
          const SizedBox(height: FbSpace.s4),
          FbListRow(
            key: const ValueKey('workout-plan-starter'),
            title: l10n.workoutPlanChooseAnother,
            trailing: const Icon(FbIcons.next),
            onTap: () => navigator.push(const WorkoutStarterPlansRoute()),
          ),
        ],
      ),
    );
  }

  /// Picks [day]'s template, or Rest.
  Future<void> _choose(
    BuildContext context,
    WidgetRef ref,
    DayOfWeek day,
    String? current,
    List<Stored<WorkoutTemplateDraft>> templates,
    String locale,
  ) async {
    final l10n = context.l10n;
    // The empty string stands for Rest.
    final choice = await showFbSheet<String>(
      context,
      title: weekdayName(locale, day),
      builder: (sheet) => FbOptionList<String>(
        options: [
          FbOption(value: '', label: l10n.workoutPlanRest),
          for (final t in templates)
            FbOption(value: t.ref.id, label: t.draft.name),
        ],
        selected: current ?? '',
        onSelected: (value) => Navigator.of(sheet).pop(value),
      ),
    );
    if (choice == null || choice == (current ?? '') || !context.mounted) {
      return;
    }
    final outcome = await ref
        .read(workoutActionsProvider)
        .setPlanDay(day, choice.isEmpty ? null : choice);
    if (!context.mounted) return;
    switch (outcome) {
      case WorkoutActionDone(:final undoId):
        showUndoFeedback(
          context,
          message: l10n.workoutPlanUpdated,
          undoEntryId: undoId,
        );
      case WorkoutActionFailed():
        showFbSnackBar(context, l10n.workoutActionChanged);
      case WorkoutActionUnchanged():
        break;
    }
  }
}
