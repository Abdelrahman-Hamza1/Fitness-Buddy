import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

/// The day's numbers at the top (HM-001): the calories eaten as the big
/// number, then the four macros of the day. Targets, remaining calories and
/// the bars replace the caption in A13.
class TodayNumbers extends StatelessWidget {
  /// Creates the block for the day's [totals].
  const new({required this.totals, super.key});

  /// The sum of the day's stored snapshots.
  final Nutrients totals;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    String macro(String label, double grams) =>
        l10n.diaryMacroItem(label, DisplayRounding.nutrientGrams(grams));
    final style = FbType.numeric(FbType.bodySmall)
        .copyWith(color: scheme.onSurfaceVariant);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        FbSpace.s4,
        FbSpace.s3,
        FbSpace.s4,
        FbSpace.s4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FbBigNumber(
            value: l10n.diaryBigKcal(DisplayRounding.kcal(totals.kcal)),
            caption: l10n.diaryKcalEaten,
          ),
          const SizedBox(height: FbSpace.s3),
          Wrap(
            spacing: FbSpace.s3,
            runSpacing: FbSpace.s1,
            children: [
              Text(macro(l10n.todayMacroProtein, totals.protein), style: style),
              Text(macro(l10n.todayMacroCarbs, totals.carbs), style: style),
              Text(macro(l10n.todayMacroFat, totals.fat), style: style),
              Text(macro(l10n.todayMacroFiber, totals.fiber), style: style),
            ],
          ),
        ],
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
