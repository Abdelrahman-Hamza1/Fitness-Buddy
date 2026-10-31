import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/workouts/application/workout_views.dart';
import 'package:fb_mobile/features/workouts/presentation/exercise_muscle_map.dart';
import 'package:fb_mobile/features/workouts/presentation/workout_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The day's session, plan, or a neutral invitation to log (HM-006).
class WorkoutSlide extends ConsumerWidget {
  /// Creates the component with localized labels and session state.
  const new({required this.date, super.key});

  /// The viewed day.
  final LocalDate date;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(todayWorkoutProvider(date));
    final row = value.value;
    final l10n = context.l10n;
    final navigator = ref.read(appNavigatorProvider);
    if (row == null) {
      if (value.hasError) {
        return FbInlineBanner(
          kind: FbInlineBannerKind.error,
          message: l10n.workoutSlideLoadFailed,
          actionLabel: l10n.weightCardTryAgain,
          onAction: () => ref.invalidate(todayWorkoutProvider(date)),
        );
      }
      return const FbSkeleton.card(height: 72);
    }
    final summary = switch (row) {
      TodayWorkoutLogged(:final summary) => summary,
      TodayWorkoutLast(:final summary) => summary,
      _ => null,
    };
    final text = switch (row) {
      TodayWorkoutLogged(:final summary, :final more) => [
        l10n.workoutTodayRow(
          l10n.sessionTitle(summary.title),
          summary.exerciseCount,
        ),
        if (summary.prCount > 0) l10n.workoutPrCount(summary.prCount),
        if (more > 0) l10n.workoutTodayMore(more),
      ].join(' · '),
      TodayWorkoutPlanned(:final template) =>
        date == ref.watch(workoutTodayProvider)
            ? l10n.workoutTodayPlanned(template.draft.name)
            : l10n.workoutDayPlanned(template.draft.name),
      TodayWorkoutLast(:final summary, :final daysAgo) => l10n.workoutSlideLast(
        l10n.sessionTitle(summary.title),
        daysAgo,
      ),
      TodayWorkoutNone() => l10n.workoutSlideNone,
    };
    void log() => navigator.push(
      TodayWorkoutLogRoute(
        date: date,
        template: row is TodayWorkoutPlanned ? row.template.ref.id : null,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FbSpace.s3,
      children: [
        Text(l10n.todaySlideWorkout, style: FbType.label),
        Row(
          children: [
            Expanded(
              child: Semantics(
                label: summary == null
                    ? null
                    : l10n.workoutSlideOpenSemantics(text),
                child: InkWell(
                  key: const ValueKey('workout-today-row'),
                  onTap: summary == null
                      ? null
                      : () => navigator.push(
                          TodayWorkoutSessionRoute(id: summary.id),
                        ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(text, style: FbType.title),
                    ),
                  ),
                ),
              ),
            ),
            if (summary != null &&
                MediaQuery.textScalerOf(context).scale(1) <= 1.3)
              ExerciseMuscleMap.union(summary.muscles, height: 64),
          ],
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FbButton.primary(
            key: const ValueKey('today-workout-log'),
            label: row is TodayWorkoutPlanned
                ? l10n.workoutSlideLog
                : l10n.workoutSlideLogNew,
            onPressed: log,
          ),
        ),
      ],
    );
  }
}
