import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

import 'proposal_fixtures.dart';
import 'proposal_recompute_test.dart' show valueChecks;

ProposalRequest request(Map<String, Object?> raw, {ProposalFacts? facts}) =>
    ProposalRequest(
      interpretation: raw,
      messageId: '019a1b2c-0000-7000-8000-000000009999',
      idSource: FixedIds(),
      context: context(),
      facts: facts ?? ProposalFacts(),
    );

void main() {
  // rule: A21 production-eval-parity
  test('A21 eval facade returns exactly the production engine result', () {
    final a = ProposalEvaluation.evaluate(request(t01()));
    final b = ProposalEngine.build(request(t01()));
    expect(a.result, b);
    expect(a.cards, b.value!.cards);
    valueChecks(a, ProposalEvaluation.evaluate(request(t01())));
    final failed = ProposalEvaluation.evaluate(
      request(message()..['model'] = null),
    );
    expect(failed.cards, isEmpty);
    expect(failed.questionCount, 0);
  });
  // rule: A21 production-eval-parity
  test(
    'A21 eval uses recorded local personal pack and embedded fact precedence',
    () {
      final pack = ProposalFacts(
        packAvailable: true,
        catalog: {'usda:egg': localFood()},
      );
      final embedded = ProposalEvaluation.evaluate(request(message()))
          .cards
          .single
          .lines
          .single;
      final local = ProposalEvaluation.evaluate(request(message(), facts: pack))
          .cards
          .single
          .lines
          .single;
      expect(embedded.snapshot.kcal, 72);
      expect(local.snapshot.kcal, 100);
      expect(local.factOrigin, ProposalFactOrigin.localCatalog);
      expect(
        ProposalEvaluation.evaluate(
          request(message(), facts: ProposalFacts(packAvailable: true)),
        ).result.issue,
        ProposalIssue.missingFoodFacts,
      );
      const key = '019a1b2c-0000-7000-8000-000000001234';
      final personal = ProposalEvaluation.evaluate(
        request(
          message([
            intent([
              item(
                match: food(key: key, source: 'personal'),
              ),
            ]),
          ]),
          facts: ProposalFacts(
            personal: {
              key: localFood(key: key, source: .yours, personalVersion: 2),
            },
          ),
        ),
      );
      expect(personal.cards.single.lines.single.snapshot.kcal, 100);
    },
  );
  test('AQ-10 eval projection retains source fact origin ranges and '
      'every estimate flag', () {
    final raw = item(match: food(source: 'reference'), explicit: false);
    final result = ProposalEvaluation.evaluate(
      request(
        message([
          intent([raw]),
        ]),
      ),
    );
    final line = result.cards.single.lines.single;
    expect(line.entry.food.provenance.source, FoodSource.reference);
    expect(line.entry.food.provenance.isEstimate, isTrue);
    expect(line.range, isNotNull);
    expect(line.factOrigin, ProposalFactOrigin.embeddedServer);
  });
  test('AQ-08 eval projection counts questions once per message', () {
    final r = ProposalEvaluation.evaluate(
      request(
        message([
          intent([riceItem(), riceItem()]),
          intent([riceItem()], slot: 'dinner'),
        ]),
      ),
    );
    expect(r.cards, hasLength(2));
    expect(r.questionCount, 2);
  });
}
