import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/progress/application/progress_providers.dart';
import 'package:fb_mobile/features/progress/application/weight_chart_parts.dart';
import 'package:fb_mobile/features/progress/application/weight_graph_providers.dart';
import 'package:fb_mobile/features/progress/presentation/graph_range_chips.dart';
import 'package:fb_mobile/features/progress/presentation/progress_retry.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The weight chart for the selected period (IN-004, A16 D8): weigh-ins as
/// dots, the trend line, the goal line of the period's phase (PA4) and the
/// phases shaded. No pan or selection here: the card and "Full graph" open
/// the full weight graph.
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
        ],
      ),
    );
  }
}

class _Chart extends StatelessWidget {
  const new({required this.view});

  final ProgressWeightView view;

  @override
  Widget build(BuildContext context) {
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
      periods: phasePeriods(
        graph.phases,
        GoalHistory([for (final r in graph.phases) r.value.toPhase()]),
        graph.today,
        (record) => goalPhaseLabel(l10n, record),
      ),
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
