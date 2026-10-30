import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/progress/application/progress_providers.dart';
import 'package:fb_mobile/features/progress/application/weight_graph_providers.dart';
import 'package:fb_mobile/features/progress/presentation/progress_day_details.dart';
import 'package:fb_mobile/features/progress/presentation/progress_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The calories chart (IN-002, A16 D5): one bar per day (or week, month)
/// in the brand colour, a dark target mark across each, the part above the
/// target in neutral grey (never red), days marked incomplete hatched,
/// today lighter, days without food a baseline tick. A tap opens the bar's
/// details with Mark day incomplete / Count this day again (DY-004).
class CaloriesSection extends ConsumerWidget {
  /// Creates the section for [view].
  const new({required this.view, super.key});

  /// What is shown.
  final ProgressView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final selected = ref.watch(selectedProgressBarProvider);
    final buckets = view.buckets;
    final shown = selected != null && selected < buckets.length
        ? selected
        : null;
    final count = buckets.length + view.futureSlots;
    return FbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FbSpace.s2,
        children: [
          Semantics(
            header: true,
            child: Text(l10n.progressCaloriesTitle, style: FbType.title),
          ),
          FbBarChart(
            key: const ValueKey('progress-calories-chart'),
            bars: caloriesBars(view),
            selected: shown,
            onSelect: ref.read(selectedProgressBarProvider.notifier).select,
            formatValue: (v) => kcalNumber(l10n, v),
            formatLabel: (i) => i < buckets.length
                ? barLabel(l10n, buckets[i].start, buckets[i].size, count)
                : barLabel(
                    l10n,
                    view.today.plusDays(i - buckets.length + 1),
                    ProgressBucketSize.day,
                    count,
                  ),
            describeBar: (i) => caloriesBarWords(l10n, buckets[i]),
            semanticLabel: l10n.progressCaloriesSemantics(
              periodLabel(l10n, view),
            ),
            emptyLabel: l10n.progressPlaceholder,
            aspectRatio: 1.7,
          ),
          FbBarLegend(
            entries: [
              (FbBarLegendKind.target, l10n.progressLegendTarget),
              (FbBarLegendKind.over, l10n.progressLegendOver),
              (FbBarLegendKind.notCounted, l10n.progressLegendNotCounted),
              (FbBarLegendKind.inProgress, l10n.progressLegendToday),
            ],
          ),
          if (shown != null) ProgressDayDetails(bucket: buckets[shown]),
        ],
      ),
    );
  }
}

/// The calories chart's bars for [view]: one per bucket, then empty slots
/// for the period's days still to come.
List<FbBar> caloriesBars(ProgressView view) => [
  for (final bucket in view.buckets)
    FbBar(
      at: chartDay(bucket.start),
      value: bucket.avgKcal,
      target: bucket.avgTargetKcal,
      style: switch (bucket.status) {
        DayStatus.incomplete => FbBarStyle.hatched,
        DayStatus.inProgress => FbBarStyle.faint,
        _ => FbBarStyle.solid,
      },
    ),
  for (var i = 1; i <= view.futureSlots; i++)
    FbBar(at: chartDay(view.today.plusDays(i)), placeholder: true),
];
