import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/workouts/application/workout_views.dart';
import 'package:fb_mobile/features/workouts/presentation/workout_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Today's workout row (HM-006, A37 D20; A37a: the logged branch): "Push ✓ ·
/// 5 exercises · 1 PR" when [date] has a session, nothing otherwise (no-plan
/// users see nothing until they log). Tap opens the session.
class WorkoutTodayRow extends ConsumerWidget {
  /// The row of [date].
  const new({required this.date, super.key});

  /// The day shown.
  final LocalDate date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final row = ref.watch(todayWorkoutProvider(date)).value;
    if (row == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final summary = row.summary;
    final text = [
      l10n.workoutTodayRow(
        l10n.sessionTitle(summary.title),
        summary.exerciseCount,
      ),
      if (summary.prCount > 0) l10n.workoutPrCount(summary.prCount),
    ].join(' · ');
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        FbSpace.s4,
        0,
        FbSpace.s4,
        FbDensity.cardGap,
      ),
      child: FbCard(
        key: const ValueKey('workout-today-row'),
        onTap: () => ref
            .read(appNavigatorProvider)
            .push(TodayWorkoutSessionRoute(id: summary.id)),
        child: Row(
          children: [
            const Icon(FbIcons.navWorkouts),
            const SizedBox(width: FbSpace.s2),
            Expanded(child: Text(text)),
            if (row.more > 0) Text(l10n.workoutTodayMore(row.more)),
          ],
        ),
      ),
    );
  }
}
