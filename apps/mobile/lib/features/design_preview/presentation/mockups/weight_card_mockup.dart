import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/design_preview/application/fake_data.dart';
import 'package:fb_mobile/features/design_preview/presentation/mockups/mockup_layout.dart';
import 'package:material_ui/material_ui.dart';

/// The weight card (HM-005): trend, weekly rate, the chart placeholder and
/// the way to log a weigh-in. Neutral wording about the goal.
class WeightCardMockup extends StatelessWidget {
  /// Creates the mockup.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final muted = FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant);
    return MockupPage(
      children: [
        FbCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: FbSpace.s3,
            children: [
              Text(
                l10n.weightTitle,
                style: FbType.title.copyWith(color: scheme.onSurface),
              ),
              FbBigNumber(
                value: FakeData.weightTrend,
                caption: l10n.weightTrendCaption,
              ),
              Text(l10n.weightRatePerWeek(FakeData.weightRate), style: muted),
              Text(l10n.weightRange, style: muted),
              FbTimeSeriesChart(series: const [], range: FakeData.chartRange),
              Text(
                l10n.weightLastWeighIn(
                  FakeData.weightLast,
                  FakeData.weightLastDate,
                ),
                style: muted,
              ),
              Text(l10n.weightToGoal(FakeData.weightGoalToGo), style: muted),
              FbButton.primary(
                label: l10n.weightLog,
                icon: FbIcons.add,
                onPressed: mockupNoop,
                expand: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
