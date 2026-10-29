import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:fb_mobile/features/today/application/today_numbers_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:material_ui/material_ui.dart';

/// The day's numbers at the top (HM-001–003, A13 D12).
///
/// With targets on [date]: the calories left today as the big number (or,
/// past the target, how much over in the neutral over tone with no icon,
/// SF-021), a bar of eaten against the target, the weekly line (hidden in
/// fixed mode, TG-044) and the macros against their targets. Without: the
/// calories eaten and the four macros, and on today's page the "Set up your
/// targets" row (D10; "Update the app" for a profile this version can't
/// read). The block is a skeleton until the targets are first loaded
/// (UX-051); a reload keeps the last numbers. A targets read error keeps the
/// eaten numbers and offers Try again (UX-052).
class TodayNumbers extends ConsumerWidget {
  /// Creates the block of [date] for the day's [totals].
  const new({
    required this.date,
    required this.isToday,
    required this.totals,
    super.key,
  });

  /// The day.
  final LocalDate date;

  /// Whether [date] is today (only today offers setup).
  final bool isToday;

  /// The sum of the day's stored snapshots.
  final Nutrients totals;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final targets = ref.watch(dayTargetsProvider(date));
    final List<Widget> children;
    if (targets.hasValue) {
      children = switch (TodayNumbersView.of(totals, targets.value)) {
        final TargetNumbers view => _targetMode(context, view),
        final EatenNumbers view => [
          ..._eatenMode(context, view),
          if (isToday) const _SetupRow(),
        ],
      };
    } else if (targets.hasError) {
      final l10n = context.l10n;
      children = [
        ..._eatenMode(context, EatenNumbers.of(totals)),
        const SizedBox(height: FbSpace.s3),
        FbInlineBanner(
          kind: FbInlineBannerKind.error,
          message: l10n.todayTargetsLoadFailed,
          actionLabel: l10n.todayTargetsTryAgain,
          // The whole chain: the stored targets, the trend weight, the day.
          onAction: () => ref
            ..invalidate(targetsDataProvider)
            ..invalidate(bodyWeightProvider(date))
            ..invalidate(dayTargetsProvider(date)),
        ),
      ];
    } else {
      // Shaped like the target-mode block (number, caption, bar, line,
      // macros), so the targets arriving don't shift the page.
      children = const [
        FbSkeleton.box(width: 160, height: 56),
        SizedBox(height: FbSpace.s1),
        FbSkeleton.line(width: 120),
        SizedBox(height: FbSpace.s3),
        FbSkeleton.line(height: 8),
        SizedBox(height: FbSpace.s2),
        FbSkeleton.line(width: 200),
        SizedBox(height: FbSpace.s4),
        FbSkeleton.line(width: 140),
        SizedBox(height: FbSpace.s3),
        FbSkeleton.line(width: 140),
        SizedBox(height: FbSpace.s3),
        FbSkeleton.line(width: 140),
        SizedBox(height: FbSpace.s3),
        FbSkeleton.line(width: 100),
      ];
    }
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        FbSpace.s4,
        FbSpace.s3,
        FbSpace.s4,
        FbSpace.s4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  List<Widget> _eatenMode(BuildContext context, EatenNumbers eaten) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final style = FbType.numeric(FbType.bodySmall)
        .copyWith(color: scheme.onSurfaceVariant);
    Widget macro(String label, double grams) =>
        Text(l10n.diaryMacroItem(label, grams), style: style);
    return [
      FbBigNumber(
        value: l10n.diaryBigKcal(eaten.eatenKcal),
        caption: l10n.diaryKcalEaten,
      ),
      const SizedBox(height: FbSpace.s3),
      Wrap(
        spacing: FbSpace.s3,
        runSpacing: FbSpace.s1,
        children: [
          macro(l10n.todayMacroProtein, eaten.protein),
          macro(l10n.todayMacroCarbs, eaten.carbs),
          macro(l10n.todayMacroFat, eaten.fat),
          macro(l10n.todayMacroFiber, eaten.fiber),
        ],
      ),
    ];
  }

  List<Widget> _targetMode(BuildContext context, TargetNumbers view) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final number = NumberFormat.decimalPattern(l10n.localeName);
    final eaten = number.format(view.eatenKcal);
    final budget = number.format(view.targetKcal);
    final muted = FbType.numeric(FbType.bodySmall)
        .copyWith(color: scheme.onSurfaceVariant);
    final large = MediaQuery.textScalerOf(context).scale(14) >= 14 * 1.4;
    // The bar already says it to screen readers.
    final budgetText = ExcludeSemantics(
      child: Text(l10n.todayEatenOfBudget(eaten, budget), style: muted),
    );
    FbMacroValue macro(FbMacroKind kind, String label, MacroNumbers m) =>
        FbMacroValue(
          kind: kind,
          label: label,
          value: m.eatenGrams,
          target: m.targetGrams?.toDouble(),
          valueText: switch (m.targetGrams) {
            final target? => l10n.todayMacroOfTarget(m.eatenGrams, target),
            null => l10n.todayMacroEaten(m.eatenGrams),
          },
        );
    return [
      FbBigNumber(
        value: l10n.diaryBigKcal(view.remainingKcal.abs()),
        caption: view.over ? l10n.todayKcalOver : l10n.todayKcalLeft,
        over: view.over,
      ),
      const SizedBox(height: FbSpace.s3),
      FbProgressBar(
        value: view.eatenKcal.toDouble(),
        target: view.targetKcal.toDouble(),
        semanticsLabel: l10n.todayEatenOfBudgetSemantics(eaten, budget),
      ),
      const SizedBox(height: FbSpace.s1),
      // The weekly line at the start, "eaten / target" at the end; at large
      // text sizes the latter goes under it instead of squeezing it.
      switch (view.week) {
        final week? when large => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(weekLineText(context, week), style: muted),
            const SizedBox(height: FbSpace.s1),
            Align(alignment: AlignmentDirectional.centerEnd, child: budgetText),
          ],
        ),
        final week? => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(weekLineText(context, week), style: muted)),
            const SizedBox(width: FbSpace.s2),
            budgetText,
          ],
        ),
        null => Align(
          alignment: AlignmentDirectional.centerEnd,
          child: budgetText,
        ),
      },
      const SizedBox(height: FbSpace.s4),
      FbMacroBars(
        macros: [
          macro(FbMacroKind.protein, l10n.todayMacroProtein, view.protein),
          macro(FbMacroKind.carbs, l10n.todayMacroCarbs, view.carbs),
          macro(FbMacroKind.fat, l10n.todayMacroFat, view.fat),
          macro(FbMacroKind.fiber, l10n.todayMacroFiber, view.fiber),
        ],
      ),
    ];
  }
}

/// "This week: 350 kcal under · 1 day not counted" (A13 D7): under, over or
/// on track (0 after rounding), plus the days not counted, if any.
String weekLineText(BuildContext context, WeekLine week) {
  final l10n = context.l10n;
  final amount = NumberFormat.decimalPattern(l10n.localeName)
      .format(week.kcal.abs());
  final line = switch (week.kcal) {
    0 => l10n.todayWeekOnTrack,
    > 0 => l10n.todayWeekOver(amount),
    _ => l10n.todayWeekUnder(amount),
  };
  return week.uncountedDays == 0
      ? line
      : l10n.todayWeekWithUncounted(
          line,
          l10n.todayWeekUncounted(week.uncountedDays),
        );
}

/// Today's entry to setup while no targets exist (A13 D10): "Set up your
/// targets · About 2 minutes", or "Update the app" when the stored profile
/// was saved by a newer version (both open setup, which explains the
/// latter). Nothing while the status loads or once set up.
class _SetupRow extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final (title, subtitle) = switch (ref.watch(setupStatusProvider).value) {
      SetupStatus.notSetUp => (l10n.todaySetupTitle, l10n.todaySetupTime),
      SetupStatus.profileUnreadable => (
        l10n.setupUpdateTitle,
        l10n.todayUpdateSubtitle,
      ),
      SetupStatus.setUp || null => (null, null),
    };
    if (title == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: FbSpace.s3),
      child: FbCard(
        padding: EdgeInsetsDirectional.zero,
        child: FbListRow(
          title: title,
          subtitle: subtitle,
          trailing: const Icon(FbIcons.next),
          onTap: () => ref.read(appNavigatorProvider).push(const SetupRoute()),
        ),
      ),
    );
  }
}

/// The hint above the meals of an empty day (UX-050): today points at "+" and
/// suggests adding a food; past days offer a reminder to fill gaps.
class EmptyDayHint extends StatelessWidget {
  /// Creates the hint for today or a past day.
  const new({required this.isToday, super.key});

  /// Whether the day is today.
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        FbSpace.s4,
        0,
        FbSpace.s4,
        FbSpace.s3,
      ),
      child: FbCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isToday ? l10n.diaryEmptyTodayHint : l10n.diaryEmptyPastHint,
              style: FbType.body.copyWith(color: scheme.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}
