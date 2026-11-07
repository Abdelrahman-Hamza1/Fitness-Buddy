import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/progress/application/progress_providers.dart';
import 'package:fb_mobile/features/progress/application/weight_chart_parts.dart';
import 'package:fb_mobile/features/progress/application/weight_graph_providers.dart';
import 'package:fb_mobile/features/progress/presentation/graph_range_chips.dart';
import 'package:fb_mobile/features/progress/presentation/progress_retry.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The weight number (WB-011) and the weight chart for the selected period
/// (IN-004, A16 D8): weigh-ins as
/// dots, the trend line, the goal line of the period's phase (PA4) and the
/// phases shaded. No pan or selection here: the card and "Full graph" open
/// the full weight graph. Under the chart, at most one quiet note about the
/// weigh-ins (D-093, A57 D8): the "weigh in 2–3 times a week" tip (at most
/// once in 30 days, dismissible, WB-012), else the sparse-history note,
/// else "Weekly rate after 2 weeks".
class WeightSection extends ConsumerWidget {
  /// Creates the section.
  const new({super.key});

  void _open(WidgetRef ref) =>
      ref.read(appNavigatorProvider).push(const WeightGraphRoute());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final weight = ref.watch(progressWeightProvider);
    return FbCard(
      onTap: () => _open(ref),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FbSpace.s2,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(l10n.progressWeightTitle, style: FbType.title),
                ),
              ),
              FbButton.text(
                key: const ValueKey('progress-full-graph'),
                label: l10n.progressFullGraph,
                onPressed: () => _open(ref),
              ),
            ],
          ),
          const _Reading(),
          switch (weight) {
            AsyncData(:final value) => _Chart(view: value),
            AsyncError() => FbInlineBanner(
              kind: FbInlineBannerKind.error,
              message: l10n.progressLoadFailed,
              actionLabel: l10n.weightGraphTryAgain,
              onAction: () => retryProgress(ref),
            ),
            _ => const FbSkeleton.box(width: double.infinity, height: 160),
          },
          const _WeightNote(),
        ],
      ),
    );
  }
}

class _Chart extends ConsumerWidget {
  const new({required this.view});

  final ProgressWeightView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final graph = view.graph;
    final unit = graph.unit;
    final goal = view.goalKg;
    final start = view.start;
    final end = view.end;
    final inWindow = [
      for (final w in graph.weighIns)
        if (!chartTimeOf(w).isBefore(start) && chartTimeOf(w).isBefore(end)) w,
    ];
    return FbTimeSeriesChart(
      key: const ValueKey('progress-weight-chart'),
      aspectRatio: 2,
      range: FbChartRange(start: start, end: end),
      series: [
        weighInSeries(
          inWindow,
          unit,
          semanticLabel: l10n.weightGraphLegendRaw,
          selectable: false,
        ),
        trendSeries(
          graph.trend,
          unit,
          semanticLabel: l10n.weightGraphLegendTrend,
        ),
      ],
      goal: goal == null
          ? null
          : FbGoalLine(
              value: weightIn(goal, unit),
              label: l10n.weightGraphGoal(weightText(l10n, goal, unit)),
            ),
      periods: [
        ...phasePeriods(
          graph.phases,
          GoalHistory([for (final r in graph.phases) r.value.toPhase()]),
          graph.today,
          (record) => goalPhaseLabel(l10n, record),
        ),
        // WB-021: Ramadans with the mode on (A41a D9).
        for (final h in ref.watch(chartHighlightPeriodsProvider))
          FbPeriod(
            start: chartDay(h.start),
            end: chartDay(h.end.plusDays(1)),
            tone: FbPeriodTone.highlight,
            label: l10n.weightGraphRamadan,
          ),
      ],
      formatValue: (v) => weightNumber(l10n, v),
      formatDate: (at, step) => graphTickLabel(l10n, at, step),
      semanticLabel: l10n.weightGraphSemantics(
        '${inWindow.length}',
        graph.trend.latest == null
            ? ''
            : weightText(l10n, graph.trend.latest!.trendKg, unit),
      ),
      emptyLabel: l10n.progressWeightEmpty,
    );
  }
}

/// The weight number above the chart (WB-011, D-102), as of today: the
/// latest weigh-in as entered or the trend. Nothing before the first
/// weigh-in (the chart says so) or while loading (the chart's skeleton
/// holds the card).
class _Reading extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = EntryTime.now(ref.read(clockProvider)).localDate;
    final state = ref.watch(weightCardProvider(today, isToday: true)).value;
    final reading = state?.reading;
    if (state == null || reading == null) return const SizedBox.shrink();
    return WeightReadingHeader(
      reading: reading,
      unit: state.units.bodyMass,
      today: today,
    );
  }
}

/// The one quiet weigh-in note under the chart (A57 D8), as of today.
class _WeightNote extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final today = EntryTime.now(ref.read(clockProvider)).localDate;
    final state = ref.watch(weightCardProvider(today, isToday: true)).value;
    if (state == null || state.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final style = FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant);
    if (state.showTip) {
      _markTipShown(context, ref, today);
      return Semantics(
        button: true,
        label: l10n.weightCardTipDismiss,
        child: InkWell(
          key: const ValueKey('progress-weight-tip'),
          onTap: () => unawaited(
            ref.read(weightTipControllerProvider.notifier).dismiss(),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(l10n.weightCardTip, style: style),
            ),
          ),
        ),
      );
    }
    final String? note;
    if (state.cadence case final cadence?
        when cadence.kind == CadenceKind.sparse) {
      note = l10n.weightCardSparse(cadence.countLast28);
    } else if (!state.asOf.isStale && state.asOf.weeklyRateKg == null) {
      note = l10n.weightCardRateLater;
    } else {
      note = null;
    }
    if (note == null) return const SizedBox.shrink();
    return Text(
      note,
      key: const ValueKey('progress-weight-note'),
      style: style,
    );
  }

  /// The tip counts as shown once it is on screen (WB-012).
  void _markTipShown(BuildContext context, WidgetRef ref, LocalDate today) {
    if (ref.read(weightTipControllerProvider).value?.shownOn == today) return;
    final controller = ref.read(weightTipControllerProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) unawaited(controller.markShown(today));
    });
  }
}
