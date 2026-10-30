import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/progress/application/progress_providers.dart';
import 'package:fb_mobile/features/progress/presentation/progress_retry.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Goal progress (IN-007, A16 D9): the phase's name, start → now → goal,
/// a calm progress bar with the share of the way (never negative), and for
/// the current phase this month against the monthly target. Rate-only
/// goals show the change since the start and the weekly average. Nothing
/// without a phase.
class GoalProgressCard extends ConsumerWidget {
  /// Creates the card.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final GoalProgressView? view;
    switch (ref.watch(goalProgressCardProvider)) {
      case AsyncData(:final value):
        // No phase to show: no card (and no gap).
        if (value == null) return const SizedBox.shrink();
        view = value;
      case AsyncError():
        return FbInlineBanner(
          key: const ValueKey('progress-goal-error'),
          kind: FbInlineBannerKind.error,
          message: l10n.progressLoadFailed,
          actionLabel: l10n.weightGraphTryAgain,
          onAction: () => retryProgress(ref),
        );
      case _:
        return const FbSkeleton.card();
    }
    final progress = view.progress;
    final unit = view.unit;
    String kg(double value) => weightText(l10n, value, unit);
    String change(double value) => weightDiffText(l10n, value, unit);
    final muted = FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant);
    final start = progress.startKg;
    final latest = progress.latestKg;
    final target = progress.targetKg;
    final fraction = progress.fraction;
    final stats = view.stats;
    final end = view.phase.end;
    return FbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: FbSpace.s1,
        children: [
          Semantics(
            header: true,
            child: Text(l10n.progressGoalCardTitle, style: FbType.title),
          ),
          Text(
            view.record == null
                ? goalTypeLabel(l10n, view.phase.type)
                : goalPhaseLabel(l10n, view.record!),
            style: FbType.label,
          ),
          if (!view.current && end != null)
            Text(l10n.progressGoalEnded(shortDate(l10n, end)), style: muted),
          if (start == null || latest == null)
            Text(l10n.progressGoalNoTrend, style: FbType.body)
          else ...[
            Text(
              target == null
                  ? l10n.progressGoalPathNoTarget(kg(start), kg(latest))
                  : l10n.progressGoalPath(kg(start), kg(latest), kg(target)),
              style: FbType.body,
            ),
            if (fraction != null) ...[
              FbProgressBar(
                value: fraction,
                target: 1,
                semanticsLabel: l10n.progressGoalPercent(
                  '${(fraction * 100).round()}',
                ),
              ),
              Text(
                progress.reached
                    ? l10n.progressGoalReached
                    : l10n.progressGoalPercent('${(fraction * 100).round()}'),
                style: muted,
              ),
            ] else if (progress.changeKg != null) ...[
              Text(
                l10n.progressGoalChange(
                  change(progress.changeKg!),
                  shortDate(l10n, progress.startDate!),
                ),
                style: muted,
              ),
              if (progress.weeklyKg != null)
                Text(
                  l10n.progressGoalRate(change(progress.weeklyKg!)),
                  style: muted,
                ),
            ],
          ],
          if (stats != null && stats.monthChangeKg != null)
            Text(
              stats.monthTargetKg == null
                  ? l10n.progressGoalThisMonthNoTarget(
                      change(stats.monthChangeKg!),
                    )
                  : l10n.progressGoalThisMonth(
                      change(stats.monthChangeKg!),
                      change(stats.monthTargetKg!),
                    ),
              style: muted,
            ),
        ],
      ),
    );
  }
}
