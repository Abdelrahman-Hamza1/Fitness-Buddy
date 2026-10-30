import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/day_label.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/workouts/application/workout_views.dart';
import 'package:fb_mobile/features/workouts/presentation/exercise_picker_screen.dart';
import 'package:fb_mobile/features/workouts/presentation/template_editor_screen.dart';
import 'package:fb_mobile/features/workouts/presentation/workout_session_tile.dart';
import 'package:fb_mobile/features/workouts/presentation/workout_week_strip.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The Workouts tab (UX-010, A37a, A37c): the first visit offers "Pick
/// exercises" (no plan needed, WO-024) and "Start from a plan" (WO-023);
/// afterwards the week strip (trained days, plan hints), today's planned
/// workout card ("Log Push"), "Log a workout", recent sessions with Repeat,
/// the history, All exercises, and the plan and templates. A re-tap of the
/// tab scrolls the list to the top (A45 D13).
class WorkoutsScreen extends ConsumerWidget {
  /// Creates the screen.
  const new({super.key});

  /// Picks exercises, then opens the log form with them (WO-034).
  static Future<void> _start(
    BuildContext context,
    AppNavigator navigator,
    LocalDate today,
  ) async {
    final picked = await pickExercises(context);
    if (picked.isEmpty) return;
    navigator.push(WorkoutLogRoute(date: today, exercises: picked));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final navigator = ref.read(appNavigatorProvider);
    final today = ref.watch(workoutTodayProvider);
    final recent = ref.watch(recentWorkoutsProvider);
    final todayRow = ref.watch(todayWorkoutProvider(today)).value;
    final templates = ref.watch(workoutTemplatesProvider).value ?? const [];
    final plan = ref.watch(workoutPlanProvider).value ?? const {};
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabWorkouts)),
      body: switch (recent.value) {
        // Local data: no spinner, the list shows as soon as it's read.
        null => const SizedBox.shrink(),
        // First visit: nothing logged and no templates (a starter plan
        // copied before the first log shows the list with its plan card).
        [] when templates.isEmpty => FbEmptyState(
          icon: FbIcons.navWorkouts,
          title: l10n.workoutsEmptyTitle,
          message: l10n.workoutsFirstVisitMessage,
          action: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: FbSpace.s2,
            children: [
              FbButton.primary(
                key: const ValueKey('workouts-pick'),
                label: l10n.workoutsPickExercises,
                onPressed: () => unawaited(_start(context, navigator, today)),
              ),
              // Optional, never required (WO-023, D-085).
              FbButton.text(
                key: const ValueKey('workouts-start-plan'),
                label: l10n.workoutsStartFromPlan,
                onPressed: () =>
                    navigator.push(const WorkoutStarterPlansRoute()),
              ),
            ],
          ),
        ),
        final sessions => ScrollToTopOnTabReselect(
          tab: AppTab.workouts,
          child: ListView(
            padding: const EdgeInsetsDirectional.symmetric(
              vertical: FbSpace.s2,
            ),
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: FbSpace.s4,
                  vertical: FbSpace.s2,
                ),
                child: WorkoutWeekStrip(today: today),
              ),
              if (todayRow case TodayWorkoutPlanned(:final template))
                _PlanCard(
                  template: template,
                  onLog: () => navigator.push(
                    WorkoutLogRoute(template: template.ref.id),
                  ),
                ),
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: FbSpace.s4,
                  vertical: FbSpace.s2,
                ),
                child: FbButton.primary(
                  key: const ValueKey('workouts-log'),
                  label: l10n.workoutsLogWorkout,
                  icon: FbIcons.add,
                  expand: true,
                  onPressed: () => unawaited(_start(context, navigator, today)),
                ),
              ),
              if (sessions.isNotEmpty)
                Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: FbSpace.s4,
                  ),
                  child: FbSectionHeader(title: l10n.workoutsRecent),
                ),
              for (final summary in sessions)
                WorkoutSessionTile(
                  key: ValueKey('workouts-recent-${summary.id}'),
                  summary: summary,
                  subtitlePrefix: dayLabel(context, summary.date, today),
                  onTap: () =>
                      navigator.push(WorkoutSessionRoute(id: summary.id)),
                  trailing: FbButton.text(
                    key: ValueKey('workouts-repeat-${summary.id}'),
                    label: l10n.workoutsRepeat,
                    onPressed: () =>
                        navigator.push(WorkoutLogRoute(repeat: summary.id)),
                  ),
                ),
              FbListRow(
                key: const ValueKey('workouts-history'),
                title: l10n.workoutsHistory,
                trailing: const Icon(FbIcons.next),
                onTap: () => navigator.push(const WorkoutHistoryRoute()),
              ),
              FbListRow(
                key: const ValueKey('workouts-exercises'),
                title: l10n.workoutsAllExercises,
                trailing: const Icon(FbIcons.next),
                onTap: () => navigator.push(const WorkoutExercisesRoute()),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: FbSpace.s4,
                ),
                child: FbSectionHeader(title: l10n.workoutsPlanSection),
              ),
              FbListRow(
                key: const ValueKey('workouts-plan'),
                title: l10n.workoutsWeeklyPlanRow,
                subtitle: l10n.workoutsWeeklyPlanDays(plan.length),
                trailing: const Icon(FbIcons.next),
                onTap: () => navigator.push(const WorkoutPlanRoute()),
              ),
              FbListRow(
                key: const ValueKey('workouts-starter-plans'),
                title: l10n.workoutsStarterPlansRow,
                trailing: const Icon(FbIcons.next),
                onTap: () => navigator.push(const WorkoutStarterPlansRoute()),
              ),
              for (final t in templates)
                FbListRow(
                  key: ValueKey('workouts-template-${t.ref.id}'),
                  title: t.draft.name,
                  subtitle: l10n.workoutsTemplateSummary(t.draft.items.length),
                  onTap: () =>
                      unawaited(openTemplateEditor(context, id: t.ref.id)),
                  trailing: FbButton.text(
                    key: ValueKey('workouts-template-log-${t.ref.id}'),
                    label: l10n.workoutsTemplateLog,
                    onPressed: () =>
                        navigator.push(WorkoutLogRoute(template: t.ref.id)),
                  ),
                ),
              FbListRow(
                key: const ValueKey('workouts-new-template'),
                leading: const Icon(FbIcons.add),
                title: l10n.workoutsNewTemplate,
                onTap: () => unawaited(openTemplateEditor(context)),
              ),
            ],
          ),
        ),
      },
    );
  }
}

/// Today's planned workout (WO-021, A37c D20): "Push day today" with
/// "Log Push", shown until a session is logged today.
class _PlanCard extends StatelessWidget {
  const new({required this.template, required this.onLog});

  final Stored<WorkoutTemplateDraft> template;
  final VoidCallback onLog;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final name = template.draft.name;
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: FbSpace.s4,
        vertical: FbSpace.s2,
      ),
      child: FbCard(
        key: const ValueKey('workouts-plan-card'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: FbSpace.s2,
          children: [
            Text(l10n.workoutTodayPlanned(name), style: FbType.title),
            Text(
              l10n.workoutsTemplateSummary(template.draft.items.length),
              style: FbType.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            FbButton.secondary(
              key: const ValueKey('workouts-plan-log'),
              label: l10n.workoutsPlanCardLog(name),
              expand: true,
              onPressed: onLog,
            ),
          ],
        ),
      ),
    );
  }
}
