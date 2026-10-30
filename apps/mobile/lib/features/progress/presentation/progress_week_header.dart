import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/progress/application/progress_providers.dart';
import 'package:fb_mobile/features/progress/presentation/progress_retry.dart';
import 'package:fb_mobile/features/progress/presentation/progress_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The current-week card at the top of Progress (A16 D10, SC-5): this
/// week's dates, how the week stands against its budget (the line Today
/// shows, HM-002), days counted and the trend change. Always this week,
/// whatever the period below. A39a replaces it with the weekly summary.
class ProgressWeekHeader extends ConsumerWidget {
  /// Creates the card.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final WeekGlance glance;
    switch (ref.watch(weekGlanceProvider)) {
      case AsyncData(:final value):
        glance = value;
      case AsyncError():
        return FbInlineBanner(
          key: const ValueKey('progress-week-error'),
          kind: FbInlineBannerKind.error,
          message: l10n.progressLoadFailed,
          actionLabel: l10n.weightGraphTryAgain,
          onAction: () => retryProgress(ref),
        );
      case _:
        return const FbSkeleton.card();
    }
    final onTint = scheme.onPrimaryContainer;
    final position = glance.position;
    final budget = switch (position) {
      _ when glance.elapsedDays == 0 => l10n.progressWeekNoDays,
      final p? when p.kcal.round() == 0 => l10n.progressWeekOnBudget,
      final p? when p.kcal > 0 => l10n.progressWeekOver(
        kcalNumber(l10n, p.kcal.abs()),
      ),
      final p? => l10n.progressWeekUnder(kcalNumber(l10n, p.kcal.abs())),
      null when glance.averageEaten != null => l10n.progressWeekAverage(
        kcalNumber(l10n, glance.averageEaten!),
        kcalNumber(l10n, glance.averageTarget!),
      ),
      null => null,
    };
    final change = glance.trendChangeKg;
    return Semantics(
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: FbRadius.lgAll,
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.all(FbSpace.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: FbSpace.s1,
            children: [
              Semantics(
                header: true,
                child: Text(
                  l10n.progressWeekHeader(
                    dayRange(l10n, glance.start, glance.end),
                  ),
                  style: FbType.label.copyWith(color: onTint),
                ),
              ),
              if (budget != null)
                Text(budget, style: FbType.title.copyWith(color: onTint)),
              Text(
                [
                  if (glance.elapsedDays > 0)
                    l10n.progressWeekCounted(
                      glance.countedDays,
                      glance.elapsedDays,
                    ),
                  if (change != null)
                    l10n.progressWeekTrend(
                      weightDiffText(l10n, change, glance.unit),
                    ),
                ].join(' · '),
                style: FbType.bodySmall.copyWith(color: onTint),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
