import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/onboarding/application/setup_flow.dart';
import 'package:fb_mobile/features/onboarding/presentation/pages/page_parts.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Theme;

/// Page 5, "Your targets" (D9, TG-021): the daily and weekly numbers from
/// the A12 engine, the plain-language explanation (with any floor or cap
/// line), the macros and how the targets apply. Save is below.
class TargetsPage extends StatelessWidget {
  /// Creates the page.
  const new({required this.draft, super.key});

  /// What setup holds.
  final SetupDraft draft;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final preview = draft.preview;
    final calculation = preview?.calculation;
    final activity = draft.activity;
    if (preview == null || calculation == null || activity == null) {
      return const SizedBox.shrink();
    }
    final weekly = preview.weeklyKcal!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FbSpace.s4,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.setupTargetsDaily(DisplayRounding.kcal(calculation.kcal)),
              style: FbType.numeric(FbType.headline)
                  .copyWith(color: scheme.onSurface),
            ),
            Text(
              l10n.setupTargetsWeekly(DisplayRounding.kcal(weekly)),
              style: FbType.numeric(FbType.body)
                  .copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
        SetupLabel(l10n.setupTargetsHow),
        TargetExplanationView(
          calculation: calculation,
          activity: activity,
          units: draft.units,
          weeklyKcal: weekly,
        ),
        if (preview.macros case final macros?) ...[
          SetupLabel(l10n.setupTargetsMacros),
          MacroSummary(macros: macros),
        ],
        SetupHint(l10n.setupTargetsMode),
      ],
    );
  }
}
