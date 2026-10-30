import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/progress/application/progress_period.dart';
import 'package:fb_mobile/features/progress/application/weight_chart_parts.dart';
import 'package:fb_mobile/features/progress/application/weight_graph_providers.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:fb_mobile/features/workouts/workouts.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'progress_providers.g.dart';

/// The diary days [from]–[to] (inclusive) the charts need: each day with
/// entries or a mark, from the indexed per-day totals and the day marks
/// (A16 D2). Days with neither are left out (unknown, TG-032).
@riverpod
Future<List<DayLog>> progressLogs(Ref ref, LocalDate from, LocalDate to) async {
  final totalsFuture = ref.watch(_progressTotalsProvider(from, to).future);
  final marksFuture = ref.watch(_progressMarksProvider(from, to).future);
  final totals = {for (final t in await totalsFuture) t.date: t};
  final marks = {for (final m in await marksFuture) m.localDate: m};
  return [
    for (final date in {...totals.keys, ...marks.keys})
      DayLog(
        date: date,
        totals: totals[date]?.totals ?? Nutrients.zero,
        entryCount: totals[date]?.entryCount ?? 0,
        incomplete: marks[date]?.incomplete ?? false,
      ),
  ];
}

@riverpod
Stream<List<DailyTotals>> _progressTotals(
  Ref ref,
  LocalDate from,
  LocalDate to,
) => ref.watch(diaryRepositoryProvider).watchDailyTotals(from, to);

@riverpod
Stream<List<DayMark>> _progressMarks(Ref ref, LocalDate from, LocalDate to) =>
    ref.watch(diaryRepositoryProvider).watchDayMarks(from, to);

/// Every date from [from] to the earlier of [to] and today with its intake,
/// status and target (A16 D6): [ProgressSeries.build] over the same inputs
/// `dayTargetsProvider` uses (the stored targets, the week start, the
/// trend, the training input), so a day's target equals Today's for it
/// (G10). Follows every source. No automatic retry: the screen shows the
/// error with Try again (UX-052).
@Riverpod(retry: _noAutomaticRetry)
Future<List<ProgressDay>> progressDays(
  Ref ref,
  LocalDate from,
  LocalDate to,
) async {
  final todayFuture = ref.watch(todayProvider.future);
  final dataFuture = ref.watch(targetsDataProvider.future);
  final weekStartFuture = ref.watch(weekStartProvider.future);
  final trendFuture = ref.watch(weightTrendProvider.future);
  final today = await todayFuture;
  final calendar = WeekCalendar(weekStart: await weekStartFuture);
  final last = to.isAfter(today) ? today : to;
  if (last.isBefore(from)) return const [];
  final first = calendar.weekStartOf(from);
  final logsFuture = ref.watch(progressLogsProvider(first, last).future);
  final trainingFuture = ref.watch(trainingShiftProvider(first, last).future);
  final data = await dataFuture;
  final trend = await trendFuture;
  final logs = await logsFuture;
  final training = await trainingFuture;
  return ProgressSeries.build(
    from: from,
    to: last,
    today: today,
    settings: [for (final s in data.settings) s.value],
    profile: data.profile?.value,
    goals: [for (final g in data.phases) g.value],
    trendOn: trend.trendOn,
    logs: logs,
    calendar: calendar,
    training: training,
  );
}

Duration? _noAutomaticRetry(int retryCount, Object error) => null;

/// The earliest date ‹ can reach (A16 D14): the first diary day (a live
/// entry or day mark), settings version, weigh-in or phase start; today
/// without any.
@riverpod
Future<LocalDate> progressEarliestDate(Ref ref) async {
  final todayFuture = ref.watch(todayProvider.future);
  final firstDiaryFuture = ref.watch(_firstDiaryDateProvider.future);
  final dataFuture = ref.watch(targetsDataProvider.future);
  final weighInsFuture = ref.watch(weighInsProvider.future);
  final today = await todayFuture;
  final data = await dataFuture;
  final weighIns = await weighInsFuture;
  var earliest = today;
  void consider(LocalDate? date) {
    if (date != null && date.isBefore(earliest)) earliest = date;
  }

  consider(await firstDiaryFuture);
  for (final s in data.settings) {
    consider(s.value.effectiveFrom);
  }
  for (final w in weighIns) {
    consider(w.localDate);
  }
  for (final p in data.phases) {
    consider(p.value.start);
  }
  return earliest;
}

@riverpod
Stream<LocalDate?> _firstDiaryDate(Ref ref) =>
    ref.watch(diaryRepositoryProvider).watchFirstDiaryDate();

/// The selected period with its dates and bars (A16 D3, D4). Content-free
/// [toString].
final class ProgressView {
  /// The view.
  new({
    required this.period,
    required this.selection,
    required this.today,
    required this.calendar,
    required this.from,
    required this.end,
    required List<ProgressDay> days,
    required List<ProgressBucket> buckets,
    required this.canPrevious,
    required this.canNext,
    required this.hasPhases,
    this.phase,
  }) : days = List.unmodifiable(days),
       buckets = List.unmodifiable(buckets);

  /// The period shown.
  final ProgressPeriod period;

  /// The selector's state behind it.
  final ProgressSelection selection;

  /// Today.
  final LocalDate today;

  /// The week calendar.
  final WeekCalendar calendar;

  /// The period's first day.
  final LocalDate from;

  /// The period's last day (may be after today: later days are empty
  /// slots).
  final LocalDate end;

  /// The days with data reads, [from] to the earlier of [end] and today.
  final List<ProgressDay> days;

  /// The bars.
  final List<ProgressBucket> buckets;

  /// Whether ‹ is enabled.
  final bool canPrevious;

  /// Whether › is enabled (not at the current period).
  final bool canNext;

  /// Whether the Phase choice shows.
  final bool hasPhases;

  /// The stored row of the phase shown by a phase period (its name), or
  /// null.
  final GoalPhaseRecord? phase;

  /// The bar size.
  ProgressBucketSize get bucketSize =>
      buckets.isEmpty ? ProgressBucketSize.day : buckets.first.size;

  /// Later days of the period with daily bars: empty slots after today
  /// (a period never starts after today).
  int get futureSlots =>
      bucketSize == ProgressBucketSize.day && end.isAfter(today)
      ? today.daysUntil(end)
      : 0;

  @override
  String toString() => 'ProgressView(${period.kind.name}, ${days.length} days)';
}

/// The [ProgressView] of the selected period (follows today, the week
/// start, the phases and every diary or targets change).
@Riverpod(retry: _noAutomaticRetry)
Future<ProgressView> progressView(Ref ref) async {
  final selection = ref.watch(progressPeriodControllerProvider);
  final todayFuture = ref.watch(todayProvider.future);
  final weekStartFuture = ref.watch(weekStartProvider.future);
  final phasesFuture = ref.watch(goalHistoryProvider.future);
  final earliestFuture = ref.watch(progressEarliestDateProvider.future);
  final today = await todayFuture;
  final calendar = WeekCalendar(weekStart: await weekStartFuture);
  final phases = await phasesFuture;
  final period = resolvePeriod(
    selection,
    today: today,
    calendar: calendar,
    phases: phases,
  );
  final range = period.range(today, phases);
  final days = await ref.watch(
    progressDaysProvider(range.from, range.end).future,
  );
  final earliest = await earliestFuture;
  return ProgressView(
    period: period,
    selection: selection,
    today: today,
    calendar: calendar,
    from: range.from,
    end: range.end,
    days: days,
    buckets: ProgressBuckets.of(days, calendar: calendar),
    canPrevious: canGoBack(
      selection,
      today: today,
      calendar: calendar,
      phases: phases,
      earliest: earliest,
    ),
    canNext: selection.back > 0,
    hasPhases: selectablePhases(phases, today).isNotEmpty,
    phase: switch (period) {
      PhasePeriod(:final phaseId) => phases.recordOf(phaseId)?.value,
      _ => null,
    },
  );
}

/// The selected bar of the calories chart (its details card), or null.
/// Cleared when the period changes.
@riverpod
class SelectedProgressBar extends _$SelectedProgressBar {
  @override
  int? build() {
    ref.watch(progressPeriodControllerProvider);
    return null;
  }

  /// Selects bar [index] (null clears).
  // A method, not a setter: the chart passes it as a callback.
  // ignore: use_setters_to_change_properties
  void select(int? index) => state = index;
}

/// The current-week header (A16 D10): always this week, whatever the
/// period. Content-free [toString].
final class WeekGlance {
  /// The glance.
  const new({
    required this.start,
    required this.end,
    required this.countedDays,
    required this.elapsedDays,
    required this.unit,
    this.position,
    this.averageEaten,
    this.averageTarget,
    this.trendChangeKg,
  });

  /// The week's first day.
  final LocalDate start;

  /// The week's last day.
  final LocalDate end;

  /// The weekly line Today shows (HM-002): positive over, negative under;
  /// null in fixed mode or before setup.
  final WeekPosition? position;

  /// Fixed mode: the average eaten over the counted earlier days.
  final double? averageEaten;

  /// Fixed mode: the average target over the same days.
  final double? averageTarget;

  /// Earlier days of the week that count.
  final int countedDays;

  /// Earlier days of the week (today not included).
  final int elapsedDays;

  /// The trend change since the day before the week started, or null.
  final double? trendChangeKg;

  /// The weight unit.
  final MassUnit unit;

  @override
  String toString() => 'WeekGlance($start, $countedDays/$elapsedDays)';
}

/// The [WeekGlance] of the week containing today. No automatic retry: the
/// card shows the error with Try again (UX-052).
@Riverpod(retry: _noAutomaticRetry)
Future<WeekGlance> weekGlance(Ref ref) async {
  final today = await ref.watch(todayProvider.future);
  final calendar = WeekCalendar(
    weekStart: await ref.watch(weekStartProvider.future),
  );
  final week = calendar.weekOf(today);
  final targetsFuture = ref.watch(dayTargetsProvider(today).future);
  // The same key as the Week period's view, so the current week is read
  // once.
  final daysFuture = ref.watch(
    progressDaysProvider(week.start, week.end).future,
  );
  final trendFuture = ref.watch(weightTrendProvider.future);
  final unitsFuture = ref.watch(unitSystemProvider.future);
  final targets = await targetsFuture;
  final days = await daysFuture;
  final trend = await trendFuture;
  final units = await unitsFuture;
  final earlier = [
    for (final d in days)
      if (d.date.isBefore(today)) d,
  ];
  final counted = [
    for (final d in earlier)
      if (d.counted) d,
  ];
  final withTarget = [
    for (final d in counted)
      if (d.targetKcal != null) d,
  ];
  final now = trend.trendOn(today);
  final before = trend.trendOn(week.start.plusDays(-1));
  final fixed = targets != null && targets.week == null;
  return WeekGlance(
    start: week.start,
    end: week.end,
    position: targets?.week,
    averageEaten: fixed && withTarget.isNotEmpty
        ? withTarget.fold<double>(0, (s, d) => s + d.eaten.kcal) /
              withTarget.length
        : null,
    averageTarget: fixed && withTarget.isNotEmpty
        ? withTarget.fold<double>(0, (s, d) => s + d.targetKcal!) /
              withTarget.length
        : null,
    countedDays: counted.length,
    elapsedDays: earlier.length,
    trendChangeKg: now == null || before == null ? null : now - before,
    unit: units.bodyMass,
  );
}

/// The goal progress card (IN-007, A16 D9): the current phase for a week or
/// month, the selected phase for a phase period. Content-free [toString].
final class GoalProgressView {
  /// The view.
  const new({
    required this.phase,
    required this.progress,
    required this.current,
    required this.unit,
    this.record,
    this.stats,
    this.monthlyRate,
  });

  /// The projected phase.
  final GoalPhase phase;

  /// Its stored row (name), or null.
  final GoalPhaseRecord? record;

  /// The numbers.
  final GoalProgress progress;

  /// Whether it is the phase in effect today.
  final bool current;

  /// This month vs the monthly target (current phase only).
  final WeightStats? stats;

  /// The rate behind this month's target (current phase only).
  final MonthlyTargetRate? monthlyRate;

  /// The weight unit.
  final MassUnit unit;

  @override
  String toString() => 'GoalProgressView(current: $current)';
}

/// The [GoalProgressView] for the selected period, or null without a phase
/// to show. No automatic retry: the card shows the error with Try again.
@Riverpod(retry: _noAutomaticRetry)
Future<GoalProgressView?> goalProgressCard(Ref ref) async {
  final viewFuture = ref.watch(progressViewProvider.future);
  final graphFuture = ref.watch(weightGraphProvider.future);
  final phasesFuture = ref.watch(goalHistoryProvider.future);
  final view = await viewFuture;
  final graph = await graphFuture;
  final phases = await phasesFuture;
  final phase = switch (view.period) {
    PhasePeriod() => periodPhase(view.period, phases, view.today),
    _ => phases.history.at(view.today),
  };
  if (phase == null) return null;
  final current = phase.contains(view.today);
  return GoalProgressView(
    phase: phase,
    record: phases.recordOf(phase.id)?.value,
    progress: GoalProgress.of(
      phase: phase,
      trend: graph.trend,
      today: view.today,
    ),
    current: current,
    stats: current ? graph.stats : null,
    monthlyRate: current ? graph.monthlyRate : null,
    unit: graph.unit,
  );
}

/// The Progress tab's weight chart (IN-004, A16 D8): the weigh-ins and the
/// trend over the period's window, the goal of the period's phase (PA4).
/// Content-free [toString].
final class ProgressWeightView {
  /// The view.
  const new({
    required this.start,
    required this.end,
    required this.graph,
    this.goalKg,
  });

  /// The window's first moment (naive wall-clock).
  final DateTime start;

  /// The window's end (the day after the period's last day).
  final DateTime end;

  /// The weight graph's model (weigh-ins, trend, phases, unit).
  final WeightGraphModel graph;

  /// The goal weight of the period's phase, or null.
  final double? goalKg;

  @override
  String toString() => 'ProgressWeightView($start)';
}

/// The [ProgressWeightView] of the selected period.
@riverpod
Future<ProgressWeightView> progressWeight(Ref ref) async {
  final viewFuture = ref.watch(progressViewProvider.future);
  final graphFuture = ref.watch(weightGraphProvider.future);
  final phasesFuture = ref.watch(goalHistoryProvider.future);
  final view = await viewFuture;
  final graph = await graphFuture;
  final phases = await phasesFuture;
  return ProgressWeightView(
    start: chartDay(view.from),
    end: chartDay(view.end.plusDays(1)),
    graph: graph,
    goalKg: periodGoalKg(view.period, phases, view.today),
  );
}
