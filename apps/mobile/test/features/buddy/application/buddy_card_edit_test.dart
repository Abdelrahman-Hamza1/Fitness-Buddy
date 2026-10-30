import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/buddy/data/proposal_input_loader.dart';
import 'package:fb_mobile/features/foods/foods.dart' show FoodChoice;
import 'package:flutter_test/flutter_test.dart';

import '../../../../../../packages/fb_domain/test/proposals/proposal_fixtures.dart'
    show localFood;
import '../support/buddy_harness.dart';

void main() {
  // rule: A22b amount-pad
  test('AI-040 amount pad and unit chips update totals live', () async {
    final h = BuddyHarness()..answer(message());
    await h.thread.send('an egg', texts);
    final card = h.state.turns.single.cards.single;
    final line = card.card.lines.single;
    h.thread.setAmount(card.id, line.entry.id, Quantity(150, 'g'));
    final after = h.state.turns.single.cards.single;
    expect(after.card.lines.single.entry.amount.input, Quantity(150, 'g'));
    expect(after.card.totals.kcal, 216);
    expect(after.changeToken, isNotNull);
    // Zero or a missing line changes nothing.
    h.thread
      ..setAmount(card.id, line.entry.id, Quantity(0, 'g'))
      ..setAmount(card.id, 'missing', Quantity(2, 'piece'));
    expect(h.state.turns.single.cards.single.card, after.card);
    expect(h.applied, hasLength(2));
  });

  // rule: A22b search-swap-add
  test('AI-041 AI-042 a food picked in search swaps a line or is added as '
      'a new one', () async {
    final h = BuddyHarness()..answer(message());
    await h.thread.send('an egg', texts);
    final card = h.state.turns.single.cards.single;
    final line = card.card.lines.single;
    final picked = localFood(key: 'usda:labneh', kcal: 160);

    h.thread.swapFood(card.id, line.entry.id, picked);
    var now = h.state.turns.single.cards.single.card;
    expect(now.lines.single.entry.id, line.entry.id);
    expect(now.lines.single.selectedFood?.key, 'usda:labneh');

    h.thread.addFood(
      card.id,
      localFood(key: 'usda:bread'),
      Quantity(1, 'piece'),
    );
    now = h.state.turns.single.cards.single.card;
    expect(now.lines, hasLength(2));
    expect(now.lines.last.selectedFood?.key, 'usda:bread');
    expect(now.lines.last.entry.id, isNot(line.entry.id));
    expect(isUuidV7(now.lines.last.entry.id), isTrue);
    // Nothing was written by either (AI-036).
    expect(h.applied, hasLength(2));
  });

  test('A22 a personal food picked in search keeps its version', () {
    final food = PersonalFood(
      id: '019a1b2c-0000-7000-8000-000000000042',
      version: 3,
      draft: PersonalFoodDraft(
        names: FoodNames('Home maqluba'),
        servings: [PersonalFoodServing('plate', 350)],
        per100: Nutrients(kcal: 180, protein: 6, carbs: 22, fat: 7, fiber: 1),
      ),
    );
    final choice = FoodChoice(
      food: EntryFood(
        ref: FoodRef.personal(food.id),
        names: food.draft.names,
        per100: food.draft.per100,
        provenance: Provenance(source: FoodSource.yours),
      ),
      measures: FoodMeasures(basis: NutrientBasis.per100g),
      personalFood: food,
    );
    final proposal = ProposalInputLoader.proposalFoodOf(choice)!;
    expect(proposal.key, food.id);
    expect(proposal.source, FoodSource.yours);
    expect(proposal.personalVersion, 3);
    expect(proposal.servings.single.code, 'plate');
    // Something search shows that isn't a catalog or personal food can't be
    // swapped in.
    expect(
      ProposalInputLoader.proposalFoodOf(
        FoodChoice(
          food: choice.food,
          measures: FoodMeasures(basis: NutrientBasis.per100g),
        ),
      ),
      isNull,
    );
  });
}
