import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/day_label.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/workouts/application/exercise_library.dart';
import 'package:fb_mobile/features/workouts/application/workout_views.dart';
import 'package:fb_mobile/features/workouts/presentation/exercise_muscle_map.dart';
import 'package:fb_mobile/features/workouts/presentation/exercise_picker_screen.dart';
import 'package:fb_mobile/features/workouts/presentation/workout_session_tile.dart';
import 'package:fb_mobile/features/workouts/presentation/workout_text.dart';
import 'package:fb_mobile/features/workouts/presentation/workout_week_strip.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// The Workouts tab (UX-010, D-089): today's action first. This week's
/// strip; today's plan card ("Log Push", "Something else") or one "Log a
/// workout" card; recent sessions with their muscle maps and Repeat; one
/// "Your plan" row. The exercise library opens from the search icon;
/// templates and the weekly plan live on the "Your plan" page. With nothing
/// logged and no plan the tab is the setup point (WO-024: "Log a workout"
/// or "Choose a plan"). A re-tap of the tab scrolls to the top (A45 D13).
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
    final templates = ref.watch(workoutTemplatesProvider).value;
    final plan = ref.watch(workoutPlanOverviewProvider);
    void start() => unawaited(_start(context, navigator, today));
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tabWorkouts),
        actions: [
          FbIconButton(
            key: const ValueKey('workouts-exercises'),
            icon: FbIcons.search,
            tooltip: l10n.workoutsAllExercises,
            onPressed: () => navigator.push(const WorkoutExercisesRoute()),
          ),
        ],
      ),
      body: switch ((recent.value, templates, plan)) {
        // Local data: no spinner, the list shows as soon as it's read.
        (null, _, _) ||
        (_, null, _) ||
        (_, _, AsyncLoading()) => const SizedBox.shrink(),
        // The setup point: nothing logged, no plan, no templates.
        ([], [], AsyncData(value: null)) => FbEmptyState(
          icon: FbIcons.navWorkouts,
          title: l10n.workoutsEmptyTitle,
          message: l10n.workoutsFirstVisitMessage,
          action: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: FbSpace.s2,
            children: [
              FbButton.primary(
                key: const ValueKey('workouts-pick'),
                label: l10n.workoutsLogWorkout,
                icon: FbIcons.add,
                onPressed: start,
              ),
              // Optional, never required (WO-023, D-085).
              FbButton.secondary(
                key: const ValueKey('workouts-start-plan'),
                label: l10n.workoutsChoosePlan,
                onPressed: () =>
                    navigator.push(const WorkoutStarterPlansRoute()),
              ),
            ],
          ),
        ),
        (final sessions?, _, _) => ScrollToTopOnTabReselect(
          tab: AppTab.workouts,
          child: ListView(
            padding: const EdgeInsetsDirectional.all(FbSpace.s4),
            children: [
              FbCard(
                key: const ValueKey('workouts-week'),
                child: WorkoutWeekStrip(today: today),
              ),
              const SizedBox(height: FbDensity.cardGap),
              if (todayRow case TodayWorkoutPlanned(:final template))
                _PlanCard(
                  template: template,
                  onLog: () => navigator.push(
                    WorkoutLogRoute(template: template.ref.id),
                  ),
                  onOther: start,
                )
              else
                _LogCard(onLog: start),
              if (sessions.isNotEmpty) ...[
                FbSectionHeader(
                  title: l10n.workoutsRecent,
                  trailing: FbButton.text(
                    key: const ValueKey('workouts-history'),
                    label: l10n.workoutsSeeAll,
                    onPressed: () =>
                        navigator.push(const WorkoutHistoryRoute()),
                  ),
                ),
                FbCard(
                  padding: EdgeInsetsDirectional.zero,
                  child: Column(
                    children: [
                      for (final (i, summary) in sessions.indexed) ...[
                        if (i > 0) const Divider(height: 1),
                        WorkoutSessionTile(
                          key: ValueKey('workouts-recent-${summary.id}'),
                          summary: summary,
                          subtitlePrefix: _weekday(
                            context,
                            summary.date,
                            today,
                          ),
                          onTap: () => navigator.push(
                            WorkoutSessionRoute(id: summary.id),
                          ),
                          trailing: FbButton.secondary(
                            key: ValueKey('workouts-repeat-${summary.id}'),
                            label: l10n.workoutsRepeat,
                            onPressed: () => navigator.push(
                              WorkoutLogRoute(repeat: summary.id),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: FbSpace.s5),
              _PlanRow(
                overview: plan.value,
                // Without a plan but with templates, "Your plan" still
                // holds them; with nothing, the chooser.
                onTap: () => navigator.push(
                  plan.value == null && (templates?.isEmpty ?? true)
                      ? const WorkoutStarterPlansRoute()
                      : const WorkoutPlanRoute(),
                ),
              ),
            ],
          ),
        ),
      },
    );
  }

  /// "Today", "Yesterday", else the short weekday within the week ("Wed"),
  /// else the date ("Oct 12").
  static String _weekday(
    BuildContext context,
    LocalDate date,
    LocalDate today,
  ) {
    final daysAgo = date.daysUntil(today);
    if (daysAgo < 2) return dayLabel(context, date, today);
    final locale = Localizations.localeOf(context).toString();
    final at = DateTime(date.year, date.month, date.day);
    return (daysAgo < 7 ? DateFormat.E(locale) : DateFormat.MMMd(locale))
        .format(at);
  }
}

/// Today's planned workout (WO-021, A37c D20, D-089): its name, first
/// exercises and muscle map, with "Log Push" and "Something else".
class _PlanCard extends ConsumerWidget {
  const new({
    required this.template,
    required this.onLog,
    required this.onOther,
  });

  final Stored<WorkoutTemplateDraft> template;
  final VoidCallback onLog;
  final VoidCallback onOther;

  /// How many exercise names the card lists before "+2".
  static const int _shown = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final library =
        ref.watch(exerciseLibraryProvider).value ?? ExerciseLibrary.empty;
    final name = template.draft.name;
    final ids = [for (final i in template.draft.items) i.exerciseId];
    final names = ids.take(_shown).map((id) => l10n.exerciseName(library, id));
    final more = ids.length - _shown;
    return FbCard(
      key: const ValueKey('workouts-plan-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FbSpace.s3,
        children: [
          Row(
            spacing: FbSpace.s3,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: FbSpace.s1,
                  children: [
                    Text(
                      l10n.workoutsTodaysPlan,
                      style: FbType.label.copyWith(color: scheme.primary),
                    ),
                    Text(name, style: FbType.headline),
                    if (ids.isNotEmpty)
                      Text(
                        [
                          names.join(', '),
                          if (more > 0) l10n.workoutsMoreCount(more),
                        ].join(' '),
                        style: FbType.bodySmall.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              ExerciseMuscleMap.union(
                library.musclesOf(ids),
                height: _planMapHeight,
              ),
            ],
          ),
          _Actions(
            primary: FbButton.primary(
              key: const ValueKey('workouts-plan-log'),
              label: l10n.workoutsPlanCardLog(name),
              expand: true,
              onPressed: onLog,
            ),
            secondary: FbButton.secondary(
              key: const ValueKey('workouts-log'),
              label: l10n.workoutsSomethingElse,
              expand: true,
              onPressed: onOther,
            ),
          ),
        ],
      ),
    );
  }
}

/// Two buttons side by side, stacked when large text wouldn't fit them.
class _Actions extends StatelessWidget {
  const new({required this.primary, required this.secondary});

  final Widget primary;
  final Widget secondary;

  /// Above this text scale the buttons stack.
  static const double _stackScale = 1.3;

  @override
  Widget build(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(1) > _stackScale
      ? Column(spacing: FbSpace.s2, children: [primary, secondary])
      : Row(
          spacing: FbSpace.s2,
          children: [
            Expanded(child: primary),
            Expanded(child: secondary),
          ],
        );
}

/// The plan card's map: big enough to read the muscles.
const double _planMapHeight = 88;

/// "Log a workout" when there's no plan for today (WO-024).
class _LogCard extends StatelessWidget {
  const new({required this.onLog});

  final VoidCallback onLog;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FbCard(
      key: const ValueKey('workouts-log-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FbSpace.s2,
        children: [
          Text(l10n.workoutsLogWorkout, style: FbType.title),
          Text(
            l10n.workoutsLogCardMessage,
            style: FbType.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          FbButton.primary(
            key: const ValueKey('workouts-log'),
            label: l10n.workoutsLogWorkout,
            icon: FbIcons.add,
            expand: true,
            onPressed: onLog,
          ),
        ],
      ),
    );
  }
}

/// "Your plan · Push / Pull / Legs · Mon, Wed, Fri", or "No plan".
class _PlanRow extends StatelessWidget {
  const new({required this.overview, required this.onTap});

  final PlanOverview? overview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final short = DateFormat.E(locale);
    final overview = this.overview;
    return FbCard(
      padding: EdgeInsetsDirectional.zero,
      child: FbListRow(
        key: const ValueKey('workouts-plan'),
        title: l10n.workoutsYourPlan,
        subtitle: overview == null
            ? l10n.workoutsNoPlan
            : [
                overview.names.join(' / '),
                overview.days
                    // 2024-01-01 was a Monday: day N is ISO weekday N.
                    .map((d) => short.format(DateTime(2024, 1, d.isoNumber)))
                    .join(', '),
              ].join(' · '),
        trailing: const Icon(FbIcons.next),
        onTap: onTap,
      ),
    );
  }
}
