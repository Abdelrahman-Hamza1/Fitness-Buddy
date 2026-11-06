import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/api/client_config_repository.dart';
import 'package:fb_mobile/core/catalog/catalog.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/features/buddy/data/proposal_input_loader.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../packages/fb_domain/test/proposals/proposal_fixtures.dart';
import '../diary/support/diary_harness.dart';

// A62b review fix (A62 D12, D15): a Buddy card for a day whose intake is a
// day estimate previews what confirming gives, its food alone, because the
// confirm replaces the estimate.

const String _key = '019a1b2c-0000-7000-8000-000000001234';

void main() {
  test('DY-006 AI-031 a card on an estimated day previews the food alone '
      '(macros known); confirm gives exactly that; Undo brings the '
      'estimate back', () async {
    final h = DiaryHarness();
    final yesterday = today.plusDays(-1);
    await h.apply([
      CreatePersonalFood(
        _key,
        PersonalFoodDraft(
          names: FoodNames('Private'),
          per100: Nutrients(
            kcal: 230,
            protein: 20,
            carbs: 10,
            fat: 12,
            fiber: 2,
          ),
        ),
      ),
      SetDayEstimate(
        yesterday,
        kcal: 2300,
        expectedVersion: null,
        expectEstimate: false,
      ),
    ]);
    final catalog = OfflineCatalog(h.db);
    addTearDown(catalog.dispose);
    final loader = ProposalInputLoader(
      h.db,
      catalog: catalog,
      config: () => ClientConfigRepository.defaults,
    );
    final request = (await loader.load(
      interpretation: message([
        intent([
          item(
            match: food(key: _key, source: 'personal'),
            amount: 100,
            unit: 'g',
          ),
        ], time: 'yesterday'),
      ]),
      messageId: '019a1b2c-0000-7000-8000-000000009999',
      idSource: FixedIds(),
      referenceTime: context().referenceTime,
    )).value!;
    final card = ProposalEngine.build(request).value!.cards.single;
    expect(card.canConfirm, isTrue);
    final preview = card.preview;
    expect(preview.date, yesterday);
    final after = preview.intake!;
    // Not 2,300 + the card: the estimate goes away on confirm.
    expect(after.sum.kcal, closeTo(230, 0.5));
    expect(after.dayEstimate, isFalse);
    expect(after.estimated, isFalse);
    expect(after.coverage(NutrientField.protein), NutrientCoverage.full);

    final applied = await h.applier.apply(
      ChangeSet(card.draftOps, origin: Origin.proposal(card.id)),
    );
    expect(applied, isA<Applied>());
    final day = (await h.reads.dailyTotals(yesterday, yesterday)).single;
    expect(day.dayEstimate, isFalse);
    expect(day.hasDayEstimate, isFalse);
    expect(day.intake.sum.kcal, closeTo(after.sum.kcal, 0.5));
    expect(
      day.intake.coverage(NutrientField.protein),
      after.coverage(NutrientField.protein),
    );
    // The estimate-only mark is gone with it (back to no mark).
    expect(await h.reads.markOn(yesterday), isNull);

    await h.undo(applied as Applied);
    final undone = (await h.reads.dailyTotals(yesterday, yesterday)).single;
    expect((undone.dayEstimate, undone.intake.sum.kcal), (true, 2300.0));
    expect((await h.reads.markOn(yesterday))!.estimateOnly, isTrue);
  });
}
