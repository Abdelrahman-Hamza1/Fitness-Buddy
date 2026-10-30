import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/l10n/day_label.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/workouts/application/workout_views.dart';
import 'package:fb_mobile/features/workouts/presentation/workout_session_tile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Every logged session by date, newest first, with its summary and PR
/// count (WO-040, WO-042).
class WorkoutHistoryScreen extends ConsumerWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final history = ref.watch(workoutHistoryProvider).value ?? const [];
    final today = ref.watch(workoutTodayProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.workoutHistoryTitle)),
      body: history.isEmpty
          ? FbEmptyState(
              icon: FbIcons.navWorkouts,
              title: l10n.workoutsEmptyTitle,
              message: l10n.workoutsFirstVisitMessage,
            )
          : ListView(
              padding: const EdgeInsetsDirectional.symmetric(
                vertical: FbSpace.s2,
              ),
              children: [
                for (final (i, summary) in history.indexed) ...[
                  if (i == 0 || history[i - 1].date != summary.date)
                    Padding(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: FbSpace.s4,
                      ),
                      child: FbSectionHeader(
                        title: dayLabel(context, summary.date, today),
                      ),
                    ),
                  WorkoutSessionTile(
                    key: ValueKey('workout-history-${summary.id}'),
                    summary: summary,
                    onTap: () => ref
                        .read(appNavigatorProvider)
                        .push(WorkoutSessionRoute(id: summary.id)),
                  ),
                ],
              ],
            ),
    );
  }
}
