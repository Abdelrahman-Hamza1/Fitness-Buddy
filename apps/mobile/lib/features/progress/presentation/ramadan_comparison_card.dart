import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/progress/application/ramadan_comparison_provider.dart';
import 'package:fb_mobile/features/progress/presentation/progress_text.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// Ramadan vs the month before (IN-008, D-052, A41a D9): average intake on
/// logged complete days, the trend weight's change and workouts per week,
/// side by side. Shown during Ramadan and for 30 days after. Neutral: no
/// judgement, a missing number is a dash.
class RamadanComparisonCard extends ConsumerWidget {
  /// The card (nothing outside its window).
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(ramadanComparisonProvider).value;
    if (c == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final unit =
        (ref.watch(unitSystemProvider).value ?? UnitSystem.defaultSystem)
            .bodyMass;
    String kcal(ComparisonSide s) => switch (s.averageKcal) {
      final v? => l10n.ramadanCompareKcal(kcalNumber(l10n, v)),
      null => l10n.ramadanCompareNone,
    };
    String trend(ComparisonSide s) => switch (s.trendChangeKg) {
      final v? => weightDiffText(l10n, v, unit),
      null => l10n.ramadanCompareNone,
    };
    String workouts(ComparisonSide s) => NumberFormat.decimalPatternDigits(
      locale: l10n.localeName,
      decimalDigits: 1,
    ).format(s.workoutsPerWeek);
    final scheme = Theme.of(context).colorScheme;
    TableRow row(String label, String ramadan, String before) => TableRow(
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(vertical: FbSpace.s1),
          child: Text(label, style: FbType.body),
        ),
        Text(ramadan, style: FbType.numeric(FbType.body)),
        Text(before, style: FbType.numeric(FbType.body)),
      ],
    );
    final caption = FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant);
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: FbDensity.cardGap),
      child: FbCard(
        key: const ValueKey('ramadan-comparison'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: FbSpace.s2,
          children: [
            Text(l10n.ramadanCompareTitle, style: FbType.title),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(1.4),
                1: FlexColumnWidth(),
                2: FlexColumnWidth(),
              },
              children: [
                TableRow(
                  children: [
                    const SizedBox.shrink(),
                    Text(
                      c.inProgress
                          ? l10n.ramadanCompareSoFar(c.ramadan.days)
                          : l10n.ramadanCompareRamadan,
                      style: caption,
                    ),
                    Text(l10n.ramadanCompareBefore, style: caption),
                  ],
                ),
                row(l10n.ramadanCompareIntake, kcal(c.ramadan), kcal(c.before)),
                row(
                  l10n.ramadanCompareTrend,
                  trend(c.ramadan),
                  trend(c.before),
                ),
                row(
                  l10n.ramadanCompareWorkouts,
                  workouts(c.ramadan),
                  workouts(c.before),
                ),
              ],
            ),
            Text(
              l10n.ramadanCompareNote(
                c.ramadan.loggedDays,
                c.before.loggedDays,
              ),
              style: caption,
            ),
          ],
        ),
      ),
    );
  }
}
