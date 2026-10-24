import 'package:fb_domain/fb_domain.dart';
import 'package:glados/glados.dart';

import '../helpers/property.dart';
import 'proposal_codec_test.dart' show roundTrip;
import 'proposal_fixtures.dart';
import 'proposal_recompute_test.dart' show decodedItem, update;

Map<String, Object?> sharedRice(double amount) => item(
  match: food(key: 'usda:rice_cooked', kcal: 130, group: 'rice'),
  amount: amount,
  unit: 'g',
  explicit: false,
  share: {'fraction': .5, 'people': 6},
  dimensions: [
    dimension('state', [
      option(
        'cooked',
        candidate: food(key: 'usda:rice_cooked', kcal: 130, group: 'rice'),
      ),
    ], stated: 'dry'),
    fatDimension()..['statedValue'] = 'oil',
  ],
);
ProposalContext sharedContext() => context(
  yields: [YieldFactor(group: 'rice', from: .dry, to: .cooked, factor: 2.8)],
);

void main() {
  // WP2 build path; WP3/4 add reducer and restore coverage to the shared
  // budget.
  Glados(any.intInRange(1, 30), propertyRuns).test(
    'AQ-08 every build recompute and restore has at most two questions per '
    'message',
    (count) {
      final s = session(
        message([intent(List.generate(count, (_) => riceItem()))]),
      );
      expect(s.budget.questions.length, lessThanOrEqualTo(2));
      final changed = update(
        s,
        ProposalSetAmount(
          s.cards.single.lines.first.entry.id,
          Quantity(100, 'g'),
        ),
      ).session;
      expect(changed.budget.questions.length, lessThanOrEqualTo(2));
      expect(roundTrip(changed).budget.questions.length, lessThanOrEqualTo(2));
    },
  );
  Glados(any.intInRange(1, 50000), propertyRuns).test(
    'AI-031 totals equal sum of active rounded line snapshots',
    (hundredths) {
      final s = session(
        message([
          intent([
            riceItem(amount: hundredths / 100),
            item(amount: 3),
            item(match: oilFood(), unit: 'tsp'),
          ]),
        ]),
      );
      final lines = s.cards.single.lines;
      for (final field in <double Function(Nutrients)>[
        (n) => n.kcal,
        (n) => n.protein,
        (n) => n.carbs,
        (n) => n.fat,
        (n) => n.fiber,
      ]) {
        final expected =
            lines.fold<int>(
              0,
              (sum, l) => sum + (field(l.snapshot) * 100).round(),
            ) /
            100;
        expect(field(s.cards.single.totals), expected);
      }
    },
  );
  // rule: A21 determinism
  Glados(any.intInRange(1, 5000), propertyRuns).test(
    'A21 equal inputs and ID source sequence produce equal drafts ops and '
    'question order',
    (amount) {
      final json = message([
        intent([riceItem(amount: amount.toDouble())]),
      ]);
      final a = session(json);
      final b = session(json);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    },
  );
  Glados(any.intInRange(1, 5000), propertyRuns).test(
    'AI-040 recomputing the same absolute adjustment is idempotent',
    (amount) {
      final s = session(
        message([
          intent([riceItem()]),
        ]),
      );
      final edit = ProposalSetAmount(
        s.cards.single.lines.first.entry.id,
        Quantity(amount.toDouble(), 'g'),
      );
      final once = update(s, edit).session;
      final twice = update(once, edit);
      expect(twice.session, once);
      expect(twice.diff.isEmpty, isTrue);
    },
  );
  Glados(any.intInRange(1, 5000), propertyRuns).test(
    'AI-042 remove then restore preserves original totals and identities',
    (amount) {
      final s = session(
        message([
          intent([sharedRice(amount.toDouble())]),
        ]),
        ctx: sharedContext(),
      );
      final id = s.cards.single.lines.first.entry.id;
      final gone = update(s, ProposalSetRemoved(id, removed: true)).session;
      expect(update(gone, ProposalSetRemoved(id, removed: false)).session, s);
    },
  );
  Glados(any.intInRange(1, 5000), propertyRuns).test(
    'AI-042 remove then add same food with new ID restores equal totals',
    (amount) {
      final raw = sharedRice(amount.toDouble());
      final s = session(
        message([
          intent([raw]),
        ]),
        ctx: sharedContext(),
      );
      final gone = update(
        s,
        ProposalSetRemoved(s.cards.single.lines.first.entry.id, removed: true),
      ).session;
      final restored = update(
        gone,
        ProposalAdd(
          s.cards.single.id,
          'new',
          decodedItem(raw),
          FixedIds()..calls = 100,
        ),
      ).session;
      expect(restored.cards.single.totals, s.cards.single.totals);
      expect(
        restored.cards.single.lines.first.entry.id,
        isNot(s.cards.single.lines.first.entry.id),
      );
    },
  );
  Glados(any.intInRange(3, 12), propertyRuns).test(
    'AQ-08 answered questions never free issued slots across adjustments',
    (count) {
      var s = session(
        message([intent(List.generate(count, (_) => riceItem()))]),
      );
      final original = s.budget.questions;
      for (final q in original) {
        s = update(s, ProposalSelect(q.dimensionId, q.optionIds.first)).session;
      }
      expect(s.budget.questions, isEmpty);
    },
  );
  // rule: A21 privacy
  test('A21 proposal diagnostics contain no user content', () {
    final s = session(t01(), facts: ProposalFacts(cookingFatIds: {'usda:oil'}));
    for (final v in [
      s,
      ...s.cards,
      ...s.cards.single.lines,
      s.budget,
      ...s.budget.questions,
      build(message()..['model'] = 'secret').issue,
    ]) {
      expect(v.toString(), isNot(contains('Synthetic')));
      expect(v.toString(), isNot(contains('884')));
      expect(v.toString(), isNot(contains('طعام')));
    }
  });
}
