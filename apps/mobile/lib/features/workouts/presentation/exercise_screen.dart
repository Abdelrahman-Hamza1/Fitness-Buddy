import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/day_label.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/workouts/application/set_input.dart';
import 'package:fb_mobile/features/workouts/application/workout_views.dart';
import 'package:fb_mobile/features/workouts/presentation/custom_exercise_screen.dart';
import 'package:fb_mobile/features/workouts/presentation/exercise_muscle_map.dart';
import 'package:fb_mobile/features/workouts/presentation/workout_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The tab an "All exercises" list and its exercise pages live in (A37
/// D13): the Workouts tab, or the Progress tab (IN-006).
enum ExerciseBrowseTab {
  /// The Workouts tab.
  workouts,

  /// The Progress tab.
  progress;

  /// The page of exercise [id] in this tab.
  AppRoute page(String id) => switch (this) {
    workouts => WorkoutExerciseRoute(id),
    progress => ProgressExerciseRoute(id),
  };
}

/// One exercise's page (WO-041, WO-007, IN-006): its muscle map, records,
/// a graph whose main line is the heaviest set (estimated 1RM a toggle;
/// most reps or longest for other types), and its past sessions, newest
/// first. Sessions open in the Workouts tab only.
class ExerciseScreen extends ConsumerWidget {
  /// The page of exercise [exerciseId] in [tab].
  const new({required this.exerciseId, required this.tab, super.key});

  /// A catalog ID or a custom exercise's UUID.
  final String exerciseId;

  /// The tab it's shown in.
  final ExerciseBrowseTab tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final view = ref.watch(exerciseProgressProvider(exerciseId));
    final shown = view.value;
    return Scaffold(
      appBar: AppBar(
        title: Text(shown?.exercise.name ?? l10n.workoutExercisesTitle),
        actions: [
          if (shown != null && shown.exercise.isCustom)
            FbIconButton(
              icon: FbIcons.edit,
              tooltip: l10n.workoutPickEditCustom,
              onPressed: () => openCustomExercise(context, id: exerciseId),
            ),
        ],
      ),
      body: switch (view) {
        AsyncData(value: final value?) => _Body(view: value, tab: tab),
        AsyncData() => FbEmptyState(
          icon: FbIcons.navWorkouts,
          title: l10n.workoutRemovedExercise,
          message: l10n.workoutExerciseRemovedMessage,
        ),
        // Local data: nothing to wait for that deserves a spinner.
        _ => const SizedBox.shrink(),
      },
    );
  }
}

class _Body extends ConsumerWidget {
  const new({required this.view, required this.tab});

  final ExerciseProgressView view;
  final ExerciseBrowseTab tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final exercise = view.exercise;
    final progress = view.progress;
    final today = ref.watch(workoutTodayProvider);
    final e1rm =
        progress.hasE1rm && ref.watch(exerciseGraphE1rmProvider(exercise.id));
    final metric = e1rm ? ExerciseMetric.e1rm : progress.main;
    final points = progress.series(metric);
    final primary = exercise.primary;
    final secondaries = [
      for (final m in exercise.secondaries)
        if (m != primary) m,
    ];
    return ListView(
      padding: const EdgeInsetsDirectional.all(FbSpace.s4),
      children: [
        Center(
          child: ExerciseMuscleMap(
            primary: primary,
            secondaries: secondaries,
            height: 180,
          ),
        ),
        const SizedBox(height: FbSpace.s2),
        // The muscles in words too: the map never relies on colour alone.
        ExcludeSemantics(
          child: Text(
            [
              if (primary != null)
                l10n.workoutExerciseMain(l10n.muscle(primary)),
              if (secondaries.isNotEmpty)
                l10n.workoutExerciseSecondary(
                  secondaries.map(l10n.muscle).join(', '),
                ),
            ].join(' · '),
            textAlign: TextAlign.center,
            style: FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: FbSpace.s4),
        if (progress.sessions.isEmpty)
          FbEmptyState(
            icon: FbIcons.chart,
            title: l10n.workoutExerciseNoSessions,
            message: l10n.workoutExerciseNoSessionsMessage,
          )
        else ...[
          _Records(view: view),
          const SizedBox(height: FbSpace.s3),
          if (progress.hasE1rm) ...[
            Wrap(
              spacing: FbSpace.s2,
              children: [
                FbChoiceChip(
                  key: const ValueKey('exercise-graph-heaviest'),
                  label: l10n.workoutExerciseHeaviest,
                  dropdown: false,
                  selected: !e1rm,
                  onTap: () => ref
                      .read(exerciseGraphE1rmProvider(exercise.id).notifier)
                      .show(on: false),
                ),
                FbChoiceChip(
                  key: const ValueKey('exercise-graph-e1rm'),
                  label: l10n.workoutExerciseE1rm,
                  dropdown: false,
                  selected: e1rm,
                  onTap: () => ref
                      .read(exerciseGraphE1rmProvider(exercise.id).notifier)
                      .show(on: true),
                ),
              ],
            ),
            const SizedBox(height: FbSpace.s2),
          ],
          _Graph(
            key: ValueKey('exercise-graph-${metric.name}'),
            points: points,
            metric: metric,
            name: exercise.name,
          ),
          const SizedBox(height: FbSpace.s3),
          FbSectionHeader(title: l10n.workoutExerciseHistory),
          for (final session in progress.sessions.reversed)
            FbListRow(
              key: ValueKey('exercise-session-${session.sessionId}'),
              title: dayLabel(context, session.date, today),
              subtitle: [
                for (final set in session.sets)
                  l10n.setValues(exercise.type, set),
              ].where((s) => s.isNotEmpty).join(', '),
              // Sessions live in the Workouts tab (A37 D13).
              onTap: tab == ExerciseBrowseTab.workouts
                  ? () => ref
                        .read(appNavigatorProvider)
                        .push(WorkoutSessionRoute(id: session.sessionId))
                  : null,
            ),
        ],
      ],
    );
  }
}

/// The exercise's bests as small tiles (WO-042): heaviest and estimated
/// 1RM for weight × reps, most reps for bodyweight and reps-only, longest
/// (and farthest) for time and cardio. Assisted keeps no records.
class _Records extends StatelessWidget {
  const new({required this.view});

  final ExerciseProgressView view;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final progress = view.progress;
    String kg(double v) => l10n.workoutExerciseKg(formatNumber(v));
    final tiles = <(String, String)>[
      ...switch (progress.type) {
        ExerciseType.weightReps => [
          if (progress.best(ExerciseMetric.heaviest) case final v?)
            (l10n.workoutExerciseHeaviest, kg(v)),
          if (progress.best(ExerciseMetric.e1rm) case final v?)
            (l10n.workoutExerciseE1rm, kg(v)),
        ],
        ExerciseType.bodyweightReps || ExerciseType.repsOnly => [
          if (progress.best(ExerciseMetric.mostReps) case final v?)
            (l10n.workoutExerciseMostReps, l10n.workoutSetReps(v.round())),
        ],
        ExerciseType.assisted => const <(String, String)>[],
        ExerciseType.duration || ExerciseType.distanceDuration => [
          if (progress.best(ExerciseMetric.longest) case final v?)
            (l10n.workoutExerciseLongest, formatClock(v.round())),
          if (progress.farthestMeters case final m?)
            (
              l10n.workoutExerciseFarthest,
              l10n.workoutExerciseKm(formatNumber(m / 1000)),
            ),
        ],
      },
    ];
    if (tiles.isEmpty) return const SizedBox.shrink();
    return Row(
      spacing: FbDensity.cardGap,
      children: [
        for (final (label, value) in tiles)
          Expanded(
            child: FbCard(
              child: Semantics(
                container: true,
                label: '$label, $value',
                child: ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(value, style: FbType.title),
                      Text(
                        label,
                        style: FbType.caption.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// The per-session graph of [metric] (WO-041).
class _Graph extends StatelessWidget {
  const new({
    required this.points,
    required this.metric,
    required this.name,
    super.key,
  });

  final List<ExercisePoint> points;
  final ExerciseMetric metric;
  final String name;

  static DateTime _at(LocalDate d) => DateTime.utc(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final first = points.isEmpty ? null : _at(points.first.date);
    final last = points.isEmpty ? null : _at(points.last.date);
    // A week either side of a single session, so it isn't a zero range.
    final start = (first ?? DateTime.utc(2026)).subtract(
      const Duration(days: 7),
    );
    final end = (last ?? DateTime.utc(2026)).add(const Duration(days: 7));
    return FbTimeSeriesChart(
      aspectRatio: 1.6,
      range: FbChartRange(start: start, end: end),
      series: [
        FbSeries(
          semanticLabel: l10n.workoutExerciseMetric(metric.name),
          points: [for (final p in points) FbPoint(_at(p.date), p.value)],
        ),
      ],
      formatValue: (v) => switch (metric) {
        ExerciseMetric.heaviest ||
        ExerciseMetric.e1rm => l10n.workoutExerciseKg(formatNumber(v)),
        ExerciseMetric.mostReps => '${v.round()}',
        ExerciseMetric.longest => formatClock(v.round()),
      },
      semanticLabel: l10n.workoutExerciseGraph(
        name,
        l10n.workoutExerciseMetric(metric.name),
        points.length,
      ),
    );
  }
}
