import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

import 'proposal_fixtures.dart';

void main() {
  final policy = ProposalPolicy.fromThresholds({});
  test('AI-060 both strict thresholds must be exceeded', () {
    expect(policy.asks(250, 300), isFalse);
    expect(policy.asks(300, 360), isFalse);
    expect(policy.asks(100, 151), isTrue);
    expect(policy.asks(100, 150), isFalse);
    expect(policy.asks(-1, 100), isFalse);
    expect(policy.asks(200, 100), isFalse);
    expect(policy.asks(double.nan, 100), isFalse);
    expect(policy.asks(1, double.infinity), isFalse);
  });
  test('AI-060 zero kcal option has defined relative impact', () {
    expect(policy.asks(0, 51), isTrue);
    expect(policy.asks(0, 0), isFalse);
    expect(ProposalPolicyConstants.relativeDelta(0, 0), 0);
  });
  test('AI-060 invalid config uses built in defaults', () {
    for (final v in [double.nan, double.infinity, -1.0, 10001.0]) {
      expect(
        ProposalPolicy.fromThresholds({
          'proposalQuestionRelativeDelta': v,
          'proposalQuestionKcalDelta': v,
        }),
        policy,
      );
    }
    final tuned = ProposalPolicy.fromThresholds({
      'proposalQuestionRelativeDelta': 0,
      'proposalQuestionKcalDelta': 10,
    });
    expect(tuned.relativeDelta, 0);
    expect(tuned.kcalDelta, 10);
    expect(tuned.hashCode, isNot(policy.hashCode));
    expect(
      ProposalPolicy.fromThresholds({
        'proposalQuestionRelativeDelta': 1,
        'proposalQuestionKcalDelta': 10000,
      }).kcalDelta,
      10000,
    );
  });
  ProposalQuestion q(int i, double impact) => ProposalQuestion(
    dimensionId: 'd$i',
    kind: 'fat',
    impact: impact,
    optionIds: ['none', 'oil'],
  );
  test('AQ-08 config and public constructors cannot raise question budget', () {
    final budget = QuestionBudget.select([
      q(0, 100),
      q(0, 100),
      q(1, 200),
      q(2, 200),
      q(3, 300),
    ]);
    expect(budget.questions.map((q) => q.dimensionId), ['d3', 'd1']);
    expect(() => budget.questions.add(q(4, 500)), throwsUnsupportedError);
    expect(QuestionBudget.select([]).questions, isEmpty);
    expect(ProposalPolicy.fromThresholds({'questionCap': 100}), policy);
  });
  test('AI-063 questions expose two to four options plus other', () {
    for (final ids in [
      <String>[],
      ['a'],
      ['a', 'a'],
      ['a', 'b', 'c', 'd', 'e'],
    ]) {
      expect(
        () => ProposalQuestion(
          dimensionId: 'd',
          kind: 'fat',
          impact: 100,
          optionIds: ids,
        ),
        throwsException,
      );
    }
    for (final v in [-1.0, double.infinity]) {
      expect(
        () => ProposalQuestion(
          dimensionId: 'd',
          kind: 'fat',
          impact: v,
          optionIds: ['a', 'b'],
        ),
        throwsException,
      );
    }
    expect(
      ProposalQuestion(
        dimensionId: 'd',
        kind: 'fat',
        impact: 1,
        optionIds: ['a', 'b', 'c', 'd'],
      ).optionIds.length,
      4,
    );
  });
  // rule: A21 question-kind
  test('A21 questionKind uses stable subject or wildcard', () {
    expect(q(0, 100).questionKind, 'fat:*');
    expect(
      ProposalQuestion(
        dimensionId: 'd',
        kind: 'state',
        subject: 'rice',
        impact: 100,
        optionIds: ['raw', 'cooked'],
      ).questionKind,
      'state:rice',
    );
  });
  // rule: A21 policy-constants
  test(
    'A21 policy constants pin reduced oil lower denominator and input limits',
    () {
      expect(
        [
          ProposalPolicyConstants.questionCap,
          ProposalPolicyConstants.mostOilLeft,
          ProposalPolicyConstants.maxIntents,
          ProposalPolicyConstants.maxItems,
          ProposalPolicyConstants.maxDimensions,
          ProposalPolicyConstants.maxOptions,
          ProposalPolicyConstants.maxCandidates,
          ProposalPolicyConstants.maxInputBytes,
        ],
        [2, .25, 20, 50, 8, 32, 4, 524288],
      );
      expect(ProposalPolicyConstants.relativeDelta(100, 150), .5);
    },
  );
  // rule: A21 immutable-values
  test(
    'A21 normalized values have equality hash and content free diagnostics',
    () {
      final values = <ProposalValue>[
        const ProposalResult<int>.success(123),
        const ProposalResult<int>.failure(ProposalIssue.invalidInput),
        ProposalRange(nutrients(100), nutrients(200)),
        const ProposalServing('private', 10, NutrientBasis.per100ml, 8, 12),
        localFood(),
        ProposalFoodEffect(localFood()),
        ProposalQuantityEffect(Quantity(1, 'g')),
        ProposalComponentEffect(localFood(), Quantity(1, 'g')),
        const ProposalRetentionEffect(.25),
        const ProposalShareEffect(.5),
        ProposalOption(
          'id',
          'private',
          ProposalQuantityEffect(Quantity(1, 'g')),
        ),
        ProposalDimension(
          'id',
          ProposalDimensionKind.state,
          [],
          stated: 'private',
        ),
        const ProposalChip('id', 'o', ProposalChoiceOrigin.savedDefault),
        ProposalItem(
          id: 'i',
          displayName: 'private',
          match: localFood(),
          quantity: null,
          explicit: false,
          alternatives: [],
          dimensions: [],
        ),
        ProposalIntent(
          index: 0,
          kind: 'foodLog',
          items: [],
          dishGroup: 'private',
        ),
        ProposalInterpretation([]),
        policy,
        q(0, 100),
        QuestionBudget.select([q(0, 100)]),
      ];
      for (final v in values) {
        expect(v, v);
        expect(v.hashCode, isA<int>());
        expect(v.toString(), isNot(contains('private')));
        expect(v == Object(), isFalse);
      }
      expect(
        ProposalInterpretation([]),
        isNot(
          ProposalInterpretation([
            ProposalIntent(index: 0, kind: 'foodLog', items: []),
          ]),
        ),
      );
      expect(localFood(), localFood());
      expect(localFood().hashCode, localFood().hashCode);
    },
  );
  // rule: A21 id-source
  test(
    'A21 ID source allocates at build add and unmatched rebuild lines only',
    () {
      final ids = FixedIds();
      final initial = session(message(), ids: ids);
      expect(ids.calls, 3);
      final itemValue = InterpretationDecoder.decode(
        message(),
        ProposalFacts(),
      ).value!.intents.single.items.single;
      final add = ProposalAdd(initial.cards.single.id, 'token', itemValue, ids);
      final added = ProposalEngine.recompute(initial, add).value!.session;
      expect(ids.calls, 5);
      expect(ProposalEngine.recompute(added, add).value!.diff.isEmpty, isTrue);
      expect(ids.calls, 5);
      final rebuilt = ProposalEngine.rebuild(
        added.cards.single,
        ProposalRequest(
          interpretation: message([
            intent([item(), item(), item(match: oilFood())]),
          ]),
          messageId: '019a1b2c-0000-7000-8000-000000008888',
          idSource: ids,
          context: context(),
          facts: ProposalFacts(),
        ),
      ).value!.session;
      expect(ids.calls, 7);
      expect(
        ProposalDraftCodec.restore(
          ProposalDraftCodec.encodeMessageBudget(rebuilt),
          [ProposalDraftCodec.encodeCard(rebuilt, rebuilt.cards.single.id)],
          context: context(),
        ).issue,
        isNull,
      );
      expect(ids.calls, 7);
    },
  );
}
