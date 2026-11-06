import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/approx_text.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/progress/application/weekly_summary_providers.dart';
import 'package:fb_mobile/features/progress/presentation/progress_retry.dart';
import 'package:fb_mobile/features/progress/presentation/progress_text.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// One week's full summary as numbers (IN-001, D-097, A63 D3): the big
/// average vs target, then tiles (in target, protein days, fiber a day,
/// trend, workouts, PRs; a tile without data is left out) and one quiet
/// "5 of 5 days counted". Shown on the weekly summary screen, which the
/// Progress calories header and the weekly notification open. Local data
/// only; no streaks, scores or judgement (IN-020, SF-021).
class WeekSummaryTiles extends ConsumerWidget {
  /// The summary of the week from [weekStart].
  const new({required this.weekStart, this.current = false, super.key});

  /// The week's first day.
  final LocalDate weekStart;

  /// Whether it is the week containing today.
  final bool current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final WeeklySummary? summary;
    switch (ref.watch(weeklySummaryProvider(weekStart))) {
      case AsyncData(:final value):
        summary = value;
      case AsyncError():
        return FbInlineBanner(
          key: const ValueKey('weekly-summary-error'),
          kind: FbInlineBannerKind.error,
          message: l10n.progressLoadFailed,
          actionLabel: l10n.weightGraphTryAgain,
          onAction: () => retryProgress(ref),
        );
      case _:
        return const FbSkeleton.card(height: 200);
    }
    if (summary == null) return const SizedBox.shrink();
    final unit =
        (ref.watch(unitSystemProvider).value ?? UnitSystem.defaultSystem)
            .bodyMass;
    final range = dayRange(l10n, summary.start, summary.end);
    final headline = switch (summary) {
      WeeklySummary(:final averageKcal?, :final averageTargetKcal?) =>
        l10n.progressWeekAverageBig(
          approxText(
            l10n,
            kcalNumber(l10n, averageKcal),
            approximate: summary.estimated,
          ),
          kcalNumber(l10n, averageTargetKcal),
        ),
      WeeklySummary(elapsedDays: 0) => l10n.progressWeekNoDays,
      _ => l10n.weeklySummaryNothingCounted,
    };
    final count = NumberFormat.decimalPattern(l10n.localeName);
    final tiles = <(String, String)>[
      if (summary.targetDays > 0)
        (
          l10n.progressTileFraction(
            summary.daysWithinTarget,
            summary.targetDays,
          ),
          l10n.progressTileInTarget,
        ),
      if (summary.proteinTargetDays > 0)
        (
          l10n.progressTileFraction(
            summary.proteinDaysHit,
            summary.proteinTargetDays,
          ),
          l10n.progressTileProtein,
        ),
      if (summary.averageFiber case final fiber?)
        (
          l10n.progressTileGrams(gramsNumber(l10n, fiber)),
          l10n.progressTileFiber,
        ),
      if (summary.trendChangeKg case final change?)
        (weightDiffText(l10n, change, unit), l10n.progressTileTrend),
      if (summary.workouts case final w?)
        if (w.planned case final planned?)
          (
            l10n.progressTileOfPlanned(w.sessions, planned),
            l10n.progressTileWorkouts,
          )
        else if (w.sessions > 0)
          (count.format(w.sessions), l10n.progressTileWorkouts),
      if (summary.workouts case final w? when w.prs > 0)
        (count.format(w.prs), l10n.progressTilePrs),
    ];
    return Semantics(
      key: ValueKey('weekly-summary-$weekStart'),
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FbSpace.s3,
        children: [
          Semantics(
            header: true,
            child: Text(
              current ? l10n.progressWeekHeader(range) : range,
              style: FbType.label.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          Text(
            headline,
            key: const ValueKey('weekly-summary-average'),
            style: FbType.numeric(FbType.headline),
          ),
          if (tiles.isNotEmpty)
            LayoutBuilder(
              builder: (context, constraints) {
                // Two tiles a row (one at large text on a narrow phone).
                final columns =
                    constraints.maxWidth <
                        MediaQuery.textScalerOf(context).scale(260)
                    ? 1
                    : 2;
                final width =
                    (constraints.maxWidth - FbSpace.s2 * (columns - 1)) /
                    columns;
                return Wrap(
                  spacing: FbSpace.s2,
                  runSpacing: FbSpace.s2,
                  children: [
                    for (final (value, caption) in tiles)
                      SizedBox(
                        width: width,
                        child: _Tile(value: value, caption: caption),
                      ),
                  ],
                );
              },
            ),
          if (summary.elapsedDays > 0)
            Text(
              l10n.progressWeekCounted(
                summary.countedDays,
                summary.elapsedDays,
              ),
              style: FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}

/// One number with its caption under it.
class _Tile extends StatelessWidget {
  const new({required this.value, required this.caption});

  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: FbRadius.mdAll,
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.all(FbSpace.s3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: FbType.numeric(FbType.title),
              ),
              Text(
                caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: FbType.bodySmall.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
