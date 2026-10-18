import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/design_preview/application/fake_data.dart';
import 'package:fb_mobile/features/design_preview/presentation/mockups/mockup_layout.dart';
import 'package:material_ui/material_ui.dart';

/// The Progress overview (IN-001, IN-007): the weekly summary with Buddy's
/// review, the calories, macros and weight charts as placeholders, and goal
/// progress. No streaks, scores or badges (IN-020).
class ProgressMockup extends StatelessWidget {
  /// Creates the mockup.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final chart = FbTimeSeriesChart(
      series: const [],
      range: FakeData.chartRange,
      aspectRatio: 2.4,
    );
    return MockupPage(
      children: [
        const FbDateHeader(label: FakeData.weekRange, onPrevious: mockupNoop),
        FbCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: FbSpace.s2,
            children: [
              Text(
                l10n.progressReviewTitle,
                style: FbType.label.copyWith(color: scheme.onSurfaceVariant),
              ),
              Text(
                FakeData.weekReview,
                style: FbType.body.copyWith(color: scheme.onSurface),
              ),
            ],
          ),
        ),
        FbCard(
          padding: EdgeInsetsDirectional.zero,
          child: Column(
            children: [
              FbSectionHeader(title: l10n.progressWeekTitle),
              _SummaryRow(
                label: l10n.progressAvgCalories,
                value: l10n.progressAvgCaloriesValue(
                  FakeData.weekAvgKcal,
                  FakeData.weekBudgetKcal,
                ),
              ),
              _SummaryRow(
                label: l10n.progressDaysWithin,
                value: l10n.progressOutOf(
                  FakeData.weekDaysWithin,
                  FakeData.weekDaysLogged,
                ),
              ),
              _SummaryRow(
                label: l10n.progressProteinDays,
                value: l10n.progressOutOf(
                  FakeData.weekProteinDays,
                  FakeData.weekDaysLogged,
                ),
              ),
              _SummaryRow(
                label: l10n.progressFiberAvg,
                value: l10n.progressGrams(FakeData.weekFiberAvg),
              ),
              _SummaryRow(
                label: l10n.progressWeightChange,
                value: l10n.progressKg(FakeData.weekWeightChange),
              ),
              _SummaryRow(
                label: l10n.progressWorkouts,
                value: l10n.progressOutOf(
                  FakeData.weekWorkoutsDone,
                  FakeData.weekWorkoutsPlanned,
                ),
              ),
            ],
          ),
        ),
        FbCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: FbSpace.s2,
            children: [
              Text(
                l10n.progressChartCalories,
                style: FbType.title.copyWith(color: scheme.onSurface),
              ),
              chart,
              const SizedBox(height: FbSpace.s2),
              Text(
                l10n.progressChartMacros,
                style: FbType.title.copyWith(color: scheme.onSurface),
              ),
              chart,
              const SizedBox(height: FbSpace.s2),
              Text(
                l10n.progressChartWeight,
                style: FbType.title.copyWith(color: scheme.onSurface),
              ),
              chart,
            ],
          ),
        ),
        FbCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: FbSpace.s2,
            children: [
              Text(
                l10n.progressGoalTitle,
                style: FbType.title.copyWith(color: scheme.onSurface),
              ),
              Text(
                l10n.progressGoalPhase(FakeData.goalPhase),
                style: FbType.bodySmall.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const FbProgressBar(
                value: FakeData.goalStartKg - FakeData.goalNowKg,
                target: FakeData.goalStartKg - FakeData.goalTargetKg,
              ),
              Text(
                l10n.progressGoalNowTarget(
                  FakeData.goalNowText,
                  FakeData.goalTargetText,
                ),
                style: FbType.numeric(FbType.body)
                    .copyWith(color: scheme.onSurface),
              ),
              Text(
                l10n.progressGoalMonth(
                  FakeData.goalMonthDone,
                  FakeData.goalMonthTarget,
                ),
                style: FbType.numeric(FbType.bodySmall)
                    .copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One summary row: the label and its value, which wraps at large text.
class _SummaryRow extends StatelessWidget {
  const new({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: FbSpace.s4,
        vertical: FbSpace.s2,
      ),
      child: Row(
        spacing: FbSpace.s3,
        children: [
          Expanded(
            child: Text(
              label,
              style: FbType.body.copyWith(color: scheme.onSurface),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: FbType.numeric(FbType.body)
                  .copyWith(color: scheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
