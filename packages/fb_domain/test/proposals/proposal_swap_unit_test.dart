import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

import 'proposal_fixtures.dart';
import 'proposal_recompute_test.dart' show update;

void main() {
  // rule: A22b swap-incompatible-unit
  test('AI-041 swapping 1 piece to a food without a piece serving keeps the '
      'row with grams or a serving and the stepper', () {
    final s = session(message());
    final line = s.cards.single.lines.single;
    expect(line.entry.amount.input, Quantity(1, 'piece'));
    expect(line.amountAssumed, isFalse);
    // A food with no servings at all: "piece" can't be resolved for it.
    final noPiece = ProposalFood(
      key: 'usda:yogurt',
      names: FoodNames('Yogurt'),
      state: .asSold,
      source: .database,
      per100: nutrients(60),
      version: '1',
    );
    final swapped = update(s, ProposalSwap(line.entry.id, noPiece)).session;
    final card = swapped.cards.single;
    expect(card.issues, isEmpty);
    expect(card.canConfirm, isTrue);
    final row = card.lines.single;
    expect(row.entry.id, line.entry.id);
    expect(row.selectedFood?.key, 'usda:yogurt');
    expect(row.entry.amount.input.unitCode, isNot('piece'));
    expect(noPiece.measures.resolve(row.entry.amount.input), isA<Resolved>());
    expect(row.amountAssumed, isTrue);

    // A compatible unit carries over unchanged and stays stated.
    final egg2 = localFood(key: 'usda:duck_egg', kcal: 185);
    final kept = update(
      s,
      ProposalSwap(line.entry.id, egg2),
    ).session.cards.single.lines.single;
    expect(kept.entry.amount.input, Quantity(1, 'piece'));
    expect(kept.amountAssumed, isFalse);
  });
}
