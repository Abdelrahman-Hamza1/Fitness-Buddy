import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/undo/undo_snack_bar.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/progress/application/graph_window.dart';
import 'package:fb_mobile/features/progress/application/weight_graph_providers.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// The weight graph (WB-020–023, IN-004): weigh-ins as faint dots, the
/// trend line, the goal line, the projection cone, goal phases; ranges,
/// pan, tap a point for its details with Edit and Use for trend, and the
/// summary numbers. Opened from Today's weight card and the Progress tab.
class WeightGraphScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  ConsumerState<WeightGraphScreen> createState() => _WeightGraphScreenState();
}

class _WeightGraphScreenState extends ConsumerState<WeightGraphScreen> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Back from the background the day (or the zone) may have changed.
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.invalidate(todayProvider),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final model = ref.watch(weightGraphProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.weightGraphTitle)),
      body: switch (model) {
        AsyncData(:final value) when value.weighIns.isEmpty => FbEmptyState(
          icon: FbIcons.chart,
          title: l10n.weightGraphEmptyTitle,
          message: l10n.weightGraphEmptyMessage,
          action: FbButton.primary(
            label: l10n.weightGraphLog,
            onPressed: () => showWeighInSheet(context),
          ),
        ),
        AsyncData(:final value) => _Graph(model: value),
        AsyncError() => FbEmptyState(
          icon: FbIcons.chart,
          title: l10n.weightGraphTitle,
          message: l10n.weightGraphError,
          action: FbButton.secondary(
            label: l10n.weightGraphTryAgain,
            onPressed: () => ref.invalidate(weightGraphProvider),
          ),
        ),
        _ => const Padding(
          padding: EdgeInsetsDirectional.all(FbSpace.s4),
          child: FbSkeleton.box(width: double.infinity, height: 240),
        ),
      },
    );
  }
}

class _Graph extends ConsumerWidget {
  const new({required this.model});

  final WeightGraphModel model;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final window = ref.watch(weightGraphWindowControllerProvider);
    final controller = ref.read(weightGraphWindowControllerProvider.notifier);
    final selectedId = ref.watch(selectedWeighInProvider);
    final projection = model.projection;
    final shown = projection is WeightProjection ? projection : null;
    final chartWindow = ChartWindow.of(
      window.range,
      model.today,
      firstDate: model.weighIns.first.localDate,
      panStart: window.panStart,
      futureDays: shown == null
          ? 0
          : _futureDays(window.range, model.today, model.weighIns.first),
    );
    final unit = model.unit;
    String value(double kg) => weightText(l10n, kg, unit);
    WeighIn? selected;
    for (final w in model.weighIns) {
      if (w.id == selectedId) selected = w;
    }
    final highlights = ref.watch(chartHighlightPeriodsProvider);
    final latest = model.trend.latest;
    return ListView(
      padding: const EdgeInsetsDirectional.all(FbSpace.s4),
      children: [
        Wrap(
          spacing: FbSpace.s2,
          runSpacing: FbSpace.s2,
          children: [
            for (final range in GraphRange.values)
              FbChoiceChip(
                label: _rangeLabel(l10n, range),
                selected: range == window.range,
                dropdown: false,
                onTap: () => controller.setRange(range),
              ),
            if (window.panStart != null)
              FbChoiceChip(
                label: l10n.weightGraphToday,
                dropdown: false,
                onTap: controller.reset,
              ),
          ],
        ),
        const SizedBox(height: FbSpace.s3),
        FbTimeSeriesChart(
          aspectRatio: 1.2,
          range: FbChartRange(start: chartWindow.start, end: chartWindow.end),
          panBounds: chartWindow.pans
              ? FbChartRange(start: chartWindow.panMin, end: chartWindow.panMax)
              : null,
          onRangeChanged: (r) => controller.setPanStart(r.start),
          series: [
            FbSeries(
              style: FbSeriesStyle.points,
              tone: FbSeriesTone.muted,
              selectable: true,
              semanticLabel: l10n.weightGraphLegendRaw,
              points: [
                for (final w in model.weighIns)
                  FbPoint(chartTimeOf(w), weightIn(w.kg, unit), key: w.id),
              ],
            ),
            FbSeries(
              style: FbSeriesStyle.line,
              semanticLabel: l10n.weightGraphLegendTrend,
              points: [
                for (final p in model.trend.points)
                  FbPoint(chartDay(p.localDate), weightIn(p.trendKg, unit)),
              ],
            ),
            if (shown != null)
              FbSeries(
                style: FbSeriesStyle.dashedLine,
                points: [
                  for (final d in _projectionDays(shown))
                    FbPoint(chartDay(d), weightIn(shown.at(d).centre, unit)),
                ],
              ),
          ],
          bands: [
            if (shown != null)
              FbBand(
                points: [
                  for (final d in _projectionDays(shown))
                    FbBandPoint(
                      chartDay(d),
                      lower: weightIn(shown.at(d).lower, unit),
                      upper: weightIn(shown.at(d).upper, unit),
                    ),
                ],
              ),
          ],
          goal: model.goalKg == null
              ? null
              : FbGoalLine(
                  value: weightIn(model.goalKg!, unit),
                  label: l10n.weightGraphGoal(value(model.goalKg!)),
                ),
          periods: [
            ...phasePeriods(
              model.phases,
              GoalHistory([for (final r in model.phases) r.value.toPhase()]),
              model.today.plusDays(800),
              (record) => goalPhaseLabel(l10n, record),
            ),
            for (final h in highlights)
              FbPeriod(
                start: chartDay(h.start),
                end: chartDay(h.end.plusDays(1)),
                tone: FbPeriodTone.highlight,
                label: l10n.weightGraphRamadan,
              ),
          ],
          selected: selected == null
              ? null
              : FbPointRef(series: 0, key: selected.id),
          onSelect: (p) => ref
              .read(selectedWeighInProvider.notifier)
              .select(p?.key as String?),
          formatValue: (v) => weightNumber(l10n, v),
          formatDate: (at, step) => _date(l10n, at, step),
          semanticLabel: l10n.weightGraphSemantics(
            '${model.weighIns.length}',
            latest == null ? '' : value(latest.trendKg),
          ),
        ),
        const SizedBox(height: FbSpace.s2),
        Text(
          l10n.weightGraphLegendProjection,
          style: FbType.caption.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: FbSpace.s3),
        if (selected == null)
          Text(l10n.weightGraphTapHint, style: FbType.bodySmall)
        else
          _Details(weighIn: selected, model: model),
        const SizedBox(height: FbSpace.s3),
        _Stats(model: model),
      ],
    );
  }

  static int _futureDays(GraphRange range, LocalDate today, WeighIn first) {
    final months = range.months;
    final days = months == null
        ? first.localDate.daysUntil(today)
        : months * 30;
    return (days / 4).clamp(7, 183).round();
  }

  static List<LocalDate> _projectionDays(WeightProjection p) {
    final total = p.anchorDate.daysUntil(p.drawUntil);
    final step = total > 120 ? 7 : 1;
    return [
      for (var d = 0; d < total; d += step) p.anchorDate.plusDays(d),
      p.drawUntil,
    ];
  }

  static String _rangeLabel(AppLocalizations l10n, GraphRange range) =>
      switch (range) {
        GraphRange.m1 => l10n.weightGraphRange1M,
        GraphRange.m3 => l10n.weightGraphRange3M,
        GraphRange.m6 => l10n.weightGraphRange6M,
        GraphRange.y1 => l10n.weightGraphRange1Y,
        GraphRange.all => l10n.weightGraphRangeAll,
      };

  static String _date(AppLocalizations l10n, DateTime at, FbTimeStep step) {
    final local = DateTime(at.year, at.month, at.day);
    return switch (step) {
      FbTimeStep.day => DateFormat.MMMd(l10n.localeName).format(local),
      FbTimeStep.month => DateFormat.MMM(l10n.localeName).format(local),
      FbTimeStep.year => DateFormat.y(l10n.localeName).format(local),
    };
  }
}

/// The selected weigh-in (WB-022): value as typed, date and time, note,
/// the trend that day, Edit and, when another weigh-in feeds the day's
/// trend, Use for trend.
class _Details extends ConsumerWidget {
  const new({required this.weighIn, required this.model});

  final WeighIn weighIn;
  final WeightGraphModel model;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final trendPoint = model.trend.pointOn(weighIn.localDate);
    final trendKg = trendPoint?.trendKg;
    final usedForTrend = trendPoint?.weighInId == weighIn.id;
    final local = weighIn.time.localDateTime;
    final when = DateFormat.yMMMd(l10n.localeName).add_jm().format(
      DateTime(
        weighIn.localDate.year,
        weighIn.localDate.month,
        weighIn.localDate.day,
        local.hour,
        local.minute,
      ),
    );
    return FbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: FbSpace.s1,
        children: [
          Text(weighInInputText(l10n, weighIn.input), style: FbType.title),
          Text(
            when,
            style: FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant),
          ),
          if (weighIn.note case final note?) Text(note, style: FbType.body),
          if (trendKg != null)
            Text(
              l10n.weightGraphTrendThatDay(
                weightText(l10n, trendKg, model.unit),
              ),
              style: FbType.body,
            ),
          if (!usedForTrend)
            Text(
              l10n.weightGraphNotUsed,
              style: FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant),
            ),
          Wrap(
            spacing: FbSpace.s2,
            children: [
              FbButton.secondary(
                label: l10n.weightGraphEdit,
                onPressed: () => showWeighInSheet(context, edit: weighIn),
              ),
              if (!usedForTrend)
                FbButton.text(
                  label: l10n.weightGraphUseForTrend,
                  onPressed: () => _useForTrend(context, ref),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _useForTrend(BuildContext context, WidgetRef ref) async {
    final message = context.l10n.weighInTrendChosen;
    final outcome = await ref
        .read(weighInActionsProvider.notifier)
        .update(
          weighIn,
          weighIn.draft,
          trend: WeighInTrendPick(
            useThis: true,
            dayOthers: [
              for (final w in model.weighIns)
                if (w.localDate == weighIn.localDate && w.id != weighIn.id) w,
            ],
          ),
        );
    if (!context.mounted) return;
    final l10n = context.l10n;
    switch (outcome) {
      case WeighInDone(:final undoId):
        showUndoFeedback(context, message: message, undoEntryId: undoId);
      case WeighInFailed(:final reason):
        showFbSnackBar(context, switch (reason) {
          WeighInFailure.removed => l10n.weighInRemoved,
          WeighInFailure.changed => l10n.weightGraphUseForTrendChanged,
          WeighInFailure.invalid ||
          WeighInFailure.future => l10n.weightGraphUseForTrendFailed,
        });
      default:
        break;
    }
  }
}

/// The summary numbers (WB-023).
class _Stats extends StatelessWidget {
  const new({required this.model});

  final WeightGraphModel model;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stats = model.stats;
    final unit = model.unit;
    final projection = model.projection;
    String change(double kg) => weightDiffText(l10n, kg, unit);
    String date(LocalDate d) => shortDate(l10n, d);
    final month = stats.monthChangeKg == null
        ? l10n.weightGraphNone
        : stats.monthTargetKg == null
        ? change(stats.monthChangeKg!)
        : l10n.weightGraphMonthValue(
            change(stats.monthChangeKg!),
            change(stats.monthTargetKg!),
          );
    return FbCard(
      padding: EdgeInsetsDirectional.zero,
      child: Column(
        children: [
          FbSectionHeader(title: l10n.weightGraphStatsTitle),
          if (stats.startDate case final start?)
            FbListRow(
              title: l10n.weightGraphChangeSince(date(start)),
              trailing: Text(
                stats.changeKg == null
                    ? l10n.weightGraphNone
                    : change(stats.changeKg!),
              ),
            ),
          FbListRow(
            title: stats.monthFrom != null && stats.monthFrom!.day != 1
                ? l10n.weightGraphThisMonthSince(date(stats.monthFrom!))
                : l10n.weightGraphThisMonth,
            subtitle: switch (model.monthlyRate) {
              MonthlyRateUnavailable(gap: MonthlyRateGap.goalNeedsUpdate) =>
                l10n.weightGraphGoalNeedsUpdate,
              MonthlyRateUnavailable(gap: MonthlyRateGap.manualNeedsReview) =>
                l10n.weightGraphManualNeedsReview,
              _ when stats.monthTargetKg == null =>
                l10n.weightGraphNoMonthTarget,
              _ => null,
            },
            trailing: Text(month),
          ),
          FbListRow(
            title: stats.averageSince == null
                ? l10n.weightGraphPerWeek(l10n.weightGraphNone)
                : l10n.weightGraphAverageSince(date(stats.averageSince!)),
            subtitle: stats.averageSince == null
                ? l10n.weightGraphAfterTwoWeeks
                : null,
            trailing: Text(
              stats.averageWeeklyKg == null
                  ? l10n.weightGraphNone
                  : l10n.weightGraphPerWeek(change(stats.averageWeeklyKg!)),
            ),
          ),
          if (projection is WeightProjection && projection.reachDate != null)
            FbListRow(
              title: l10n.weightGraphGoalAround(
                monthYear(l10n, projection.reachDate!),
              ),
            ),
        ],
      ),
    );
  }
}
