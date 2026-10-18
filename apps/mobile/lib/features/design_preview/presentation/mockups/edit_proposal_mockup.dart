import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/design_preview/application/fake_data.dart';
import 'package:fb_mobile/features/design_preview/presentation/mockups/mockup_layout.dart';
import 'package:fb_mobile/features/design_preview/presentation/mockups/proposal_actions.dart';
import 'package:material_ui/material_ui.dart';

/// An edit proposal (UX-026, AI-050): the affected diary entry as
/// before → after rows, and what the day's remaining calories become.
class EditProposalMockup extends StatelessWidget {
  /// Creates the mockup.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return MockupPage(
      children: [
        FbCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: FbSpace.s2,
            children: [
              Text(
                l10n.proposalEditLabel,
                style: FbType.label.copyWith(color: scheme.onSurfaceVariant),
              ),
              Text(
                l10n.proposalSlotAtTime(
                  l10n.todaySlotLunch,
                  FakeData.editSlotTime,
                ),
                style: FbType.bodySmall.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              Text(
                FakeData.editEntry,
                style: FbType.title.copyWith(color: scheme.onSurface),
              ),
              const SizedBox(height: FbSpace.s1),
              _Row(
                label: l10n.proposalFieldAmount,
                before: FakeData.editAmountBefore,
                after: FakeData.editAmountAfter,
              ),
              _Row(
                label: l10n.proposalFieldCalories,
                before: l10n.proposalItemKcal(FakeData.editKcalBefore),
                after: l10n.proposalItemKcal(FakeData.editKcalAfter),
              ),
              _Row(
                label: l10n.proposalFieldProtein,
                before: FakeData.editProteinBefore,
                after: FakeData.editProteinAfter,
              ),
              _Row(
                label: l10n.proposalFieldLeftToday,
                before: l10n.proposalItemKcal(FakeData.editDayBefore),
                after: l10n.proposalItemKcal(FakeData.editDayAfter),
              ),
              ProposalActionRow(
                discardLabel: l10n.proposalDiscard,
                confirmLabel: l10n.proposalApplyChange,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One changed value: the label, then the old value, an arrow and the new.
class _Row extends StatelessWidget {
  const new({required this.label, required this.before, required this.after});

  final String label;
  final String before;
  final String after;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: context.l10n.proposalChangeSemantics(label, before, after),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(vertical: FbSpace.s1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant),
            ),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: FbSpace.s2,
              children: [
                Text(
                  before,
                  style: FbType.numeric(FbType.body)
                      .copyWith(color: scheme.onSurfaceVariant),
                ),
                const Icon(FbIcons.next, size: 20),
                Text(
                  after,
                  style: FbType.numeric(FbType.label)
                      .copyWith(color: scheme.onSurface),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
