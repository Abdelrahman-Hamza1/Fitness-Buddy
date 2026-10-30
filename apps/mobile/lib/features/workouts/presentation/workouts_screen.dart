import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/day_label.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/workouts/application/workout_views.dart';
import 'package:fb_mobile/features/workouts/presentation/exercise_picker_screen.dart';
import 'package:fb_mobile/features/workouts/presentation/workout_session_tile.dart';
import 'package:fb_mobile/features/workouts/presentation/workout_week_strip.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The Workouts tab (UX-010, A37a): the first visit offers "Pick
/// exercises" (no plan needed, WO-024); afterwards the week strip of trained
/// days, "Log a workout", recent sessions with Repeat, and the history. A
/// re-tap of the tab scrolls the list to the top (A45 D13).
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
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabWorkouts)),
      body: switch (recent.value) {
        // Local data: no spinner, the list shows as soon as it's read.
        null => const SizedBox.shrink(),
        [] => FbEmptyState(
          icon: FbIcons.navWorkouts,
          title: l10n.workoutsEmptyTitle,
          message: l10n.workoutsFirstVisitMessage,
          action: FbButton.primary(
            key: const ValueKey('workouts-pick'),
            label: l10n.workoutsPickExercises,
            onPressed: () => unawaited(_start(context, navigator, today)),
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
            ],
          ),
        ),
      },
    );
  }
}
