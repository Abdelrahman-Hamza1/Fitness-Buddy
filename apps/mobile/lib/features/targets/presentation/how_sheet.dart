import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/targets/application/targets_actions.dart';
import 'package:fb_mobile/features/targets/application/targets_screens.dart';
import 'package:fb_mobile/features/targets/presentation/goal_form.dart'
    show capMessage;
import 'package:fb_mobile/features/targets/presentation/manual_target_sheet.dart';
import 'package:fb_mobile/features/targets/presentation/target_explanation.dart';
import 'package:fb_mobile/features/targets/presentation/targets_feedback.dart';
import 'package:fb_mobile/features/targets/presentation/targets_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Opens "How your target is worked out" (D-090, sketch `TgWhy`, TG-021):
/// the calculation as plain steps (resting energy → × activity → goal →
/// the daily number, which the app adapts after 2–3 weeks of weigh-ins),
/// or the note for the user's own number; "Recalculate with today's
/// weight" when offered, "Set my own number instead" and, for an own
/// number, "Use the calculated target".
Future<void> showHowSheet(BuildContext context, {required TargetsView view}) =>
    showFbSheet<void>(context, builder: (_) => HowSheet(view: view));

/// The body of the how sheet.
class HowSheet extends ConsumerWidget {
  /// Explains [view]'s version.
  const new({required this.view, super.key});

  /// What Targets showed.
  final TargetsView view;

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    Future<TargetsOutcome> Function(TargetsActions a) command,
  ) async {
    final host = Navigator.of(context, rootNavigator: true).context;
    Navigator.of(context).pop();
    final outcome = await command(ref.read(targetsActionsProvider));
    if (!host.mounted) return;
    showTargetsFeedback(host, outcome, done: (_) => host.l10n.targetsUpdated);
  }

  void _setOwn(BuildContext context) {
    final host = Navigator.of(context, rootNavigator: true).context;
    Navigator.of(context).pop();
    unawaited(showManualTargetSheet(host, view: view));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final version = view.version;
    final explanation = view.explanation;
    final calc = explanation?.calculated;
    final unit = view.units.bodyMass;
    const kcal = DisplayRounding.kcal;
    final muted = FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant);
    final body = FbType.body.copyWith(color: scheme.onSurface);
    return FbSheet(
      title: l10n.targetsHowTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FbSpace.s4,
        children: [
          if (version.manual && calc != null)
            Text(
              l10n.targetsManualNote(kcal(version.baseKcal), kcal(calc.kcal)),
              style: body,
            )
          else if (calc != null) ...[
            if (view.adapted)
              Text(
                l10n.targetsAdjustedNote(
                  kcal(version.baseKcal),
                  kcal(calc.kcal),
                ),
                key: const ValueKey('targets-adapted'),
                style: body,
              ),
            _Step(
              number: 1,
              title: l10n.targetsHowRestingTitle(kcal(calc.restingKcal)),
              body: l10n.targetsHowRestingBody,
            ),
            _Step(
              number: 2,
              title: l10n.targetsHowActivityTitle(
                calc.activityFactor,
                kcal(calc.expenditureKcal),
              ),
              body: l10n.targetsHowActivityBody(
                activityLabel(l10n, view.profile.activity),
              ),
            ),
            if (explanation!.goal != null)
              _Step(
                number: 3,
                title: l10n.targetsHowGoalTitle,
                body: explanationGoalLine(l10n, calc, unit),
              ),
            if (calc.warnings.contains(TargetWarning.lossRateCapped))
              Text(capMessage(l10n, calc, unit), style: muted),
            if (calc.warnings.contains(TargetWarning.calorieFloorApplied))
              Text(
                l10n.targetsExplainFloor(kcal(calc.floorKcal)),
                style: muted,
              ),
            _Step(
              number: explanation.goal != null ? 4 : 3,
              title: l10n.targetsHowResultTitle(kcal(view.suggestionKcal)),
              body: l10n.targetsHowResultBody,
              last: true,
            ),
          ],
          if (view.recalculateOffered) ...[
            Text(
              l10n.targetsRecalculateHint(
                massText(l10n, version.basisWeightKg, unit),
                massText(l10n, view.trendKg!, unit),
              ),
              style: muted,
            ),
            FbButton.secondary(
              label: l10n.targetsHowRecalculate,
              expand: true,
              onPressed: () => unawaited(
                _run(context, ref, (a) => a.recalculate(view.shown)),
              ),
            ),
          ],
          if (version.manual)
            FbButton.secondary(
              label: l10n.targetsUseCalculated,
              expand: true,
              onPressed: () => unawaited(
                _run(context, ref, (a) => a.useCalculatedTarget(view.shown)),
              ),
            ),
          FbButton.text(
            label: l10n.targetsHowSetOwn,
            expand: true,
            onPressed: () => _setOwn(context),
          ),
        ],
      ),
    );
  }
}

/// One numbered step: a value line and its plain explanation.
class _Step extends StatelessWidget {
  const new({
    required this.number,
    required this.title,
    required this.body,
    this.last = false,
  });

  final int number;
  final String title;
  final String body;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: FbSpace.s3,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: last ? scheme.primary : scheme.primaryContainer,
          child: Text(
            '$number',
            style: FbType.label.copyWith(
              color: last ? scheme.onPrimary : scheme.onPrimaryContainer,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: FbSpace.s1,
            children: [
              Text(
                title,
                style: FbType.numeric(FbType.title)
                    .copyWith(color: scheme.onSurface),
              ),
              Text(
                body,
                style: FbType.bodySmall.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
