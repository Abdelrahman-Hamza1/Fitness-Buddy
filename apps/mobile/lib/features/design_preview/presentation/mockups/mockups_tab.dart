import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/design_preview/application/mockup_entry.dart';
import 'package:fb_mobile/features/design_preview/presentation/mockups/edit_proposal_mockup.dart';
import 'package:fb_mobile/features/design_preview/presentation/mockups/food_proposal_mockup.dart';
import 'package:fb_mobile/features/design_preview/presentation/mockups/progress_mockup.dart';
import 'package:fb_mobile/features/design_preview/presentation/mockups/today_mockup.dart';
import 'package:fb_mobile/features/design_preview/presentation/mockups/weight_card_mockup.dart';
import 'package:material_ui/material_ui.dart';

/// The Mockups tab: one section per [MockupEntry]. The
/// mockups carry their own screen padding.
class MockupsTab extends StatelessWidget {
  /// Creates the tab.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.only(bottom: FbSpace.s6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final entry in MockupEntry.values)
            Column(
              key: ValueKey('mockup.${entry.name}'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FbSectionHeader(title: mockupTitle(context, entry)),
                mockupBody(context, entry),
              ],
            ),
        ],
      ),
    );
  }
}

/// The localized name of [entry].
String mockupTitle(BuildContext context, MockupEntry entry) {
  final l10n = context.l10n;
  return switch (entry) {
    MockupEntry.today => l10n.previewMockupToday,
    MockupEntry.foodProposal => l10n.previewMockupFoodProposal,
    MockupEntry.editProposal => l10n.previewMockupEditProposal,
    MockupEntry.weightCard => l10n.previewMockupWeightCard,
    MockupEntry.progress => l10n.previewMockupProgress,
  };
}

/// The mockup of [entry].
Widget mockupBody(BuildContext context, MockupEntry entry) => switch (entry) {
  MockupEntry.today => const TodayMockup(),
  MockupEntry.foodProposal => const FoodProposalMockup(),
  MockupEntry.editProposal => const EditProposalMockup(),
  MockupEntry.weightCard => const WeightCardMockup(),
  MockupEntry.progress => const ProgressMockup(),
};
