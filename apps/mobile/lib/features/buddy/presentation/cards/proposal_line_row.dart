import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/amount_text.dart';
import 'package:fb_mobile/core/l10n/assumption_labels.dart';
import 'package:fb_mobile/core/l10n/domain_labels.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/buddy/application/food_card_view.dart';
import 'package:fb_mobile/features/buddy/presentation/cards/proposal_labels.dart';
import 'package:material_ui/material_ui.dart';

/// One item of a food card (AI-031): name, amount + unit, kcal and its
/// source badge, or `~` with the range and reason (AI-032).
class ProposalLineRow extends StatelessWidget {
  /// The row for [line], amounts in [system].
  const new({required this.line, required this.system, super.key});

  /// The item.
  final FoodLineView line;

  /// The display unit system.
  final UnitSystem system;

  String? _note(AppLocalizations l10n) {
    final notes = [
      for (final raw in line.assumptions)
        if (isCardAssumption(raw)) assumptionText(l10n, raw, system: system),
    ];
    return notes.isEmpty ? null : notes.reduce(l10n.proposalNoteJoin);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final amount = line.amount;
    final range = line.line.range ?? line.food.provenance.range;
    final reason = line.reason;
    final Widget marker = line.isEstimate
        ? FbEstimateMarker(
            rangeText: range == null
                ? kcalText(l10n, line.line.snapshot.kcal)
                : l10n.proposalEstimateRange(
                    kcalText(l10n, range.lowKcal),
                    kcalText(l10n, range.highKcal),
                  ),
            reason: reason == null ? '' : estimateReasonText(l10n, reason),
          )
        : FbSourceBadge(source: fbSourceOf(line.food.provenance.source));
    return FbProposalLine(
      name: line.food.names.en,
      amount: foodAmountText(
        l10n,
        input: amount.input,
        amount: amount.amount,
        basis: amount.basis,
        system: system,
      ),
      kcal: l10n.proposalItemKcal(kcalText(l10n, line.line.snapshot.kcal)),
      marker: marker,
      // What the number rests on (a yield conversion, a share, the oil).
      note: _note(l10n),
    );
  }
}
