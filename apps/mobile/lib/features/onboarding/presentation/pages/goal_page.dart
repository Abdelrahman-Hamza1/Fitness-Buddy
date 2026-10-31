import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/onboarding/application/setup_flow.dart';
import 'package:fb_mobile/features/onboarding/presentation/pages/page_parts.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:flutter/widgets.dart';

/// "What brings you here?" (D-088): lose, keep, gain (each with the
/// default pace, D9) or just see what I eat (no calorie target).
class GoalPage extends StatelessWidget {
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
    final type = draft.justTrack ? null : draft.goal.type;
    FbChoiceCard card(
      GoalType goal,
      String title,
      String hint,
      IconData icon,
    ) => FbChoiceCard(
      title: title,
      subtitle: hint,
      icon: icon,
      selected: type == goal,
      onTap: () => flow.chooseGoal(goal),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FbSpace.s3,
      children: [
        SetupHeader(title: l10n.setupGoalTitle, hint: l10n.setupGoalHint),
        const SizedBox(height: FbSpace.s1),
        if (draft.showErrors && draft.firstProblem == SetupField.goal)
          ChoiceError(l10n.targetsChooseOne),
        KeyedSubtree(
          key: fieldKeys[SetupField.goal],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: FbSpace.s3,
            children: [
              card(
                GoalType.lose,
                l10n.setupGoalLose,
                l10n.setupGoalLoseHint,
                FbIcons.goalLose,
              ),
              card(
                GoalType.maintain,
                l10n.setupGoalKeep,
                l10n.setupGoalKeepHint,
                FbIcons.goalKeep,
              ),
              card(
                GoalType.gain,
                l10n.setupGoalGain,
                l10n.setupGoalGainHint,
                FbIcons.goalGain,
              ),
              FbChoiceCard(
                title: l10n.setupGoalTrack,
                subtitle: l10n.setupGoalTrackHint,
                icon: FbIcons.goalTrack,
                selected: draft.justTrack,
                onTap: flow.chooseJustTrack,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
