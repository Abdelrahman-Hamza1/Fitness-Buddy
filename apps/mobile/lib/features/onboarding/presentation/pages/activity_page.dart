import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/onboarding/application/setup_flow.dart';
import 'package:fb_mobile/features/onboarding/presentation/pages/page_parts.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:flutter/widgets.dart';

/// "How active are you?" (D9): the four activity levels with their plain
/// descriptions as answer cards, nothing preselected.
class ActivityPage extends StatelessWidget {
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FbSpace.s3,
      children: [
        SetupHeader(
          title: l10n.setupPageActivity,
          hint: l10n.setupActivityHint,
        ),
        const SizedBox(height: FbSpace.s1),
        if (draft.showErrors && draft.activity == null)
          ChoiceError(l10n.targetsChooseOne),
        KeyedSubtree(
          key: fieldKeys[SetupField.activity],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: FbSpace.s3,
            children: [
              for (final level in ActivityLevel.values)
                FbChoiceCard(
                  title: activityLabel(l10n, level),
                  subtitle: activityDescription(l10n, level),
                  selected: draft.activity == level,
                  onTap: () => flow.setActivity(level),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
