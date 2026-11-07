import 'package:fb_domain/src/chat/memory_item_ops.dart';
import 'package:fb_domain/src/proposals/proposal_input.dart';

/// A choice the user made on a confirmed card (A67 D12, AI-065): the
/// engine's question kind (`key`), the option code (`value`) and the food
/// it was about (`subject`). User content: never logged.
typedef LearnedHabit = ({
  String key,
  String value,
  String subject,
  String dimension,
});

/// The state and fat choices the user made on [card] (a chip they picked
/// or a question they answered): learned only from what is confirmed
/// (AI-081). The keys are the engine's `savedDefaults` keys.
List<LearnedHabit> learnedHabitsOf(ProposalCard card) {
  final out = <LearnedHabit>[];
  final seen = <String>{};
  for (final line in card.lines) {
    final food = line.selectedFood;
    final group = food?.yieldGroup ?? food?.key;
    if (group == null) continue;
    for (final chip in line.chips) {
      if (chip.origin != ProposalChoiceOrigin.userAdjusted) continue;
      final d = line.dimensions
          .where((d) => d.id == chip.dimensionId)
          .firstOrNull;
      if (d == null ||
          (d.kind != ProposalDimensionKind.state &&
              d.kind != ProposalDimensionKind.fat)) {
        continue;
      }
      final o = d.options.where((o) => o.id == chip.optionId).firstOrNull;
      if (o == null) continue;
      final key = '${d.kind.name}:$group';
      if (!seen.add(key)) continue;
      final value = switch (o.effect) {
        ProposalComponentEffect(quantity: final q?) =>
          '${o.value}:${q.amount}:${q.unitCode}',
        _ => o.value,
      };
      if (key.length > MemoryItemOp.maxText ||
          value.isEmpty ||
          value.length > MemoryItemOp.maxText) {
        continue;
      }
      out.add((
        key: key,
        value: value,
        subject: food!.names.en,
        dimension: d.kind.name,
      ));
    }
  }
  return out;
}
