import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/adaptive/adaptive.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/progress/application/weekly_summary_providers.dart';
import 'package:fb_mobile/features/progress/presentation/progress_retry.dart';
import 'package:fb_mobile/features/progress/presentation/progress_text.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The weekly summary at the top of Progress (IN-001, SC-5, A39a D2): this
/// week so far, with this week's check-in (TG-034, A38) under the numbers
/// and a way to past weeks. Replaces A16's current-week card. Local data
/// only; works offline. No streaks, scores or judgement (IN-020, SF-021).
class WeeklySummaryCard extends ConsumerWidget {
  /// The current week's card on the Progress tab.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final start = ref.watch(currentWeekStartProvider).value;
    if (start == null) return const FbSkeleton.card();
    final earliest = ref.watch(summaryEarliestDateProvider).value;
    final hasPast = earliest != null && earliest.isBefore(start);
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WeeklySummaryBlock(weekStart: start, current: true),
        // The check-in belongs to the summary of its week (backlog #231).
        const CheckInCard(),
        if (hasPast)
          FbListRow(
            key: const ValueKey('weekly-summary-past'),
            leading: const Icon(FbIcons.calendar),
            title: l10n.weeklySummaryPastWeeks,
            trailing: const Icon(FbIcons.next),
            onTap: () => ref
                .read(appNavigatorProvider)
                .push(WeeklySummaryRoute(start: start.plusDays(-7))),
          ),
      ],
    );
  }
}

/// One week's summary (IN-001): average calories vs target, days within
/// target, protein days, fiber, the trend change and the workouts. Shown
/// on the Progress card ([current]) and the past-weeks screen.
class WeeklySummaryBlock extends ConsumerWidget {
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
        return const FbSkeleton.card();
    }
    if (summary == null) return const SizedBox.shrink();
    final unit =
        (ref.watch(unitSystemProvider).value ?? UnitSystem.defaultSystem)
            .bodyMass;
    final onTint = scheme.onPrimaryContainer;
    final range = dayRange(l10n, summary.start, summary.end);
    final headline = switch (summary) {
      WeeklySummary(:final averageKcal?, :final averageTargetKcal?) =>
        l10n.progressWeekAverage(
          kcalNumber(l10n, averageKcal),
          kcalNumber(l10n, averageTargetKcal),
        ),
      WeeklySummary(elapsedDays: 0) => l10n.progressWeekNoDays,
      _ => l10n.weeklySummaryNothingCounted,
    };
    final lines = _lines(l10n, summary, unit);
    final body = FbType.bodySmall.copyWith(color: onTint);
    return Semantics(
      key: ValueKey('weekly-summary-$weekStart'),
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
                  current ? l10n.progressWeekHeader(range) : range,
                  style: FbType.label.copyWith(color: onTint),
                ),
              ),
              Text(headline, style: FbType.title.copyWith(color: onTint)),
              for (final line in lines) Text(line, style: body),
              if (summary.elapsedDays > 0)
                Text(
                  l10n.progressWeekCounted(
                    summary.countedDays,
                    summary.elapsedDays,
                  ),
                  style: body,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// The summary's lines in words; a number without data is left out.
  static List<String> _lines(
    AppLocalizations l10n,
    WeeklySummary s,
    MassUnit unit,
  ) => [
    if (s.targetDays > 0)
      l10n.weeklySummaryWithinTarget(s.daysWithinTarget, s.targetDays),
    if (s.proteinTargetDays > 0)
      l10n.weeklySummaryProtein(s.proteinDaysHit, s.proteinTargetDays),
    if (s.averageFiber case final fiber?)
      l10n.weeklySummaryFiber(gramsNumber(l10n, fiber)),
    if (s.trendChangeKg case final change?)
      l10n.weeklySummaryTrend(weightDiffText(l10n, change, unit)),
    if (s.workouts case final w?)
      if (w.planned case final planned?)
        l10n.weeklySummaryWorkoutsPlanned(w.sessions, planned)
      else if (w.sessions > 0)
        l10n.weeklySummaryWorkouts(w.sessions),
    if (s.workouts case final w? when w.prs > 0) l10n.weeklySummaryPrs(w.prs),
  ];
}
