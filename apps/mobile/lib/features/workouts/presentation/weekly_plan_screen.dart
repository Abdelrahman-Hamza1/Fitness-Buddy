import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/core/undo/undo_snack_bar.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_mobile/features/workouts/application/workout_actions.dart';
import 'package:fb_mobile/features/workouts/application/workout_views.dart';
import 'package:fb_mobile/features/workouts/presentation/template_editor_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// A weekday's full name ("Monday") in [locale].
String weekdayName(String locale, DayOfWeek day) =>
    // 2024-01-01 was a Monday, so day N of that week is ISO weekday N.
    DateFormat.EEEE(locale).format(DateTime(2024, 1, day.isoNumber));

/// The optional weekly plan (WO-021, D-085): which template each weekday
/// trains, in the user's week order; a tap picks a template or Rest
/// (a direct action with undo). Links to the starter plans and a new
/// template.
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
    final navigator = ref.read(appNavigatorProvider);
    String? nameOf(String? id) =>
        templates.where((t) => t.ref.id == id).firstOrNull?.draft.name;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.workoutPlanTitle)),
      body: ListView(
        padding: const EdgeInsetsDirectional.symmetric(vertical: FbSpace.s2),
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: FbSpace.s4,
              vertical: FbSpace.s2,
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
          const SizedBox(height: FbSpace.s2),
          FbListRow(
            key: const ValueKey('workout-plan-starter'),
            title: l10n.workoutsStarterPlansRow,
            trailing: const Icon(FbIcons.next),
            onTap: () => navigator.push(const WorkoutStarterPlansRoute()),
          ),
          FbListRow(
            key: const ValueKey('workout-plan-new-template'),
            leading: const Icon(FbIcons.add),
            title: l10n.workoutsNewTemplate,
            onTap: () => unawaited(openTemplateEditor(context)),
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
