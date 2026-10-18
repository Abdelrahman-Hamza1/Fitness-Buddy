import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/design_preview/application/fake_data.dart';
import 'package:fb_mobile/features/design_preview/presentation/mockups/mockup_layout.dart';
import 'package:fb_mobile/features/design_preview/presentation/mockups/proposal_actions.dart';
import 'package:material_ui/material_ui.dart';

/// The food proposal card of `spec/10` §4.1 (AI-031 to AI-034): slot and time,
/// the dish with one row per item and source badge, an assumption chip, a
/// question with answer chips (the default labelled), the totals, "Today
/// after this", Discard and Log it. Tapping the assumption chip, an answer
/// chip, the `~` marker or a badge works; Log it and Discard do nothing.
class FoodProposalMockup extends StatefulWidget {
  /// Creates the mockup.
  const new({super.key});

  @override
  State<FoodProposalMockup> createState() => _FoodProposalMockupState();
}

class _FoodProposalMockupState extends State<FoodProposalMockup> {
  // The default answer stays selected until the user picks another one.
  int _answer = FakeData.defaultAnswer;

  Future<void> _openAssumption() {
    final l10n = context.l10n;
    return showFbSheet<void>(
      context,
      title: l10n.proposalAssumptionTitle,
      builder: (sheet) => Column(
        children: [
          for (final option in FakeData.assumptionAlternatives)
            FbListRow(
              title: option,
              trailing: option == FakeData.proposalAssumption
                  ? const Icon(FbIcons.check)
                  : null,
              onTap: () => Navigator.of(sheet).pop(),
            ),
        ],
      ),
    );
  }

  /// The inline-adjust pattern, static: the amount, a unit picker and the pad.
  Future<void> _adjust(FakeItem item) => showFbSheet<void>(
    context,
    title: item.name,
    builder: (sheet) {
      final scheme = Theme.of(sheet).colorScheme;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FbSpace.s3,
        children: [
          Text(
            item.amount,
            textAlign: TextAlign.center,
            style: FbType.numeric(FbType.headline)
                .copyWith(color: scheme.onSurface),
          ),
          FbUnitPicker(
            units: FakeData.adjustUnits,
            selected: item.unitId,
            onSelected: (_) {},
          ),
          FbNumberPad(onKey: (_) {}, onDone: () => Navigator.of(sheet).pop()),
        ],
      );
    },
  );

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
                l10n.proposalSlotAtTime(
                  l10n.todaySlotBreakfast,
                  FakeData.proposalTime,
                ),
                style: FbType.label.copyWith(color: scheme.onSurfaceVariant),
              ),
              Text(
                FakeData.proposalDish,
                style: FbType.title.copyWith(color: scheme.onSurface),
              ),
              Column(
                children: [
                  for (final item in FakeData.proposalItems)
                    _ItemRow(item: item, onTap: () => _adjust(item)),
                ],
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: FbAssumptionChip(
                  label: FakeData.proposalAssumption,
                  onTap: _openAssumption,
                ),
              ),
              Text(
                FakeData.proposalQuestion,
                style: FbType.label.copyWith(color: scheme.onSurface),
              ),
              Wrap(
                spacing: FbSpace.s2,
                runSpacing: FbSpace.s2,
                children: [
                  for (var i = 0; i < FakeData.answerOptions.length; i++)
                    FbAnswerChip(
                      label: FakeData.answerOptions[i],
                      selected: i == _answer,
                      isDefault: i == FakeData.defaultAnswer,
                      onTap: () => setState(() => _answer = i),
                    ),
                ],
              ),
              Divider(color: scheme.outlineVariant),
              Text(
                l10n.proposalTotalKcal(FakeData.proposalKcal),
                style: FbType.numeric(FbType.headline)
                    .copyWith(color: scheme.onSurface),
              ),
              Text(
                l10n.proposalMacrosShort(
                  FakeData.proposalProtein,
                  FakeData.proposalCarbs,
                  FakeData.proposalFat,
                  FakeData.proposalFiber,
                ),
                style: FbType.numeric(FbType.bodySmall)
                    .copyWith(color: scheme.onSurfaceVariant),
              ),
              Text(
                l10n.proposalTodayAfter(FakeData.todayAfterLeft),
                style: FbType.body.copyWith(color: scheme.onSurface),
              ),
              ProposalActionRow(
                discardLabel: l10n.proposalDiscard,
                confirmLabel: l10n.proposalLogIt,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One item row: name, amount, kcal, the source marker and a chevron.
/// Tapping it opens the adjust sheet.
class _ItemRow extends StatelessWidget {
  const new({required this.item, required this.onTap});

  final FakeItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: FbType.body.copyWith(color: scheme.onSurface),
                ),
                Text(
                  item.amount,
                  style: FbType.numeric(FbType.bodySmall)
                      .copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: FbSpace.s2),
          Text(
            l10n.proposalItemKcal(item.kcal),
            style: FbType.numeric(FbType.body)
                .copyWith(color: scheme.onSurface),
          ),
          if (item.source == FbSource.estimate)
            const FbEstimateMarker(
              rangeText: FakeData.estimateRange,
              reason: FakeData.estimateReason,
            )
          else
            FbSourceBadge(source: item.source),
          Icon(FbIcons.next, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
