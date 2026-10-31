import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/onboarding/application/setup_flow.dart';
import 'package:fb_mobile/features/onboarding/presentation/pages/page_parts.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:flutter/widgets.dart';

/// "Do you work out?" (D-088): not right now, I mix it up, or I want a plan
/// (the starter plans open when the flow ends). Nothing is stored.
class TrainingPage extends StatelessWidget {
  /// Creates the page.
  const new({
    required this.draft,
    required this.flow,
    this.fieldKeys = const {},
    super.key,
  });

  /// What the flow holds.
  final SetupDraft draft;

  /// The view model.
  final SetupFlow flow;

  /// Keys of the required inputs, so a refused Continue can scroll there.
  final Map<SetupField, GlobalKey> fieldKeys;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    FbChoiceCard card(TrainingChoice choice, String title, String hint) =>
        FbChoiceCard(
          title: title,
          subtitle: hint,
          selected: draft.training == choice,
          onTap: () => flow.setTraining(choice),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FbSpace.s3,
      children: [
        SetupHeader(
          title: l10n.setupTrainingTitle,
          hint: l10n.setupTrainingHint,
        ),
        const SizedBox(height: FbSpace.s1),
        if (draft.showErrors && draft.training == null)
          ChoiceError(l10n.targetsChooseOne),
        KeyedSubtree(
          key: fieldKeys[SetupField.training],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: FbSpace.s3,
            children: [
              card(
                TrainingChoice.notNow,
                l10n.setupTrainingNotNow,
                l10n.setupTrainingNotNowHint,
              ),
              card(
                TrainingChoice.mixItUp,
                l10n.setupTrainingMix,
                l10n.setupTrainingMixHint,
              ),
              card(
                TrainingChoice.wantPlan,
                l10n.setupTrainingPlan,
                l10n.setupTrainingPlanHint,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
