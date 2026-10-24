import 'package:fb_domain/fb_domain.dart';
import 'package:glados/glados.dart';

import '../helpers/property.dart';
import 'proposal_fixtures.dart';

void main() {
  // WP2 build path; WP3/4 add reducer and restore coverage to the shared budget.
  Glados(any.intInRange(1, 30), propertyRuns).test(
    'AQ-08 build never exceeds two questions per message',
    (count) {
      final s = session(
        message([intent(List.generate(count, (_) => riceItem()))]),
      );
      expect(s.budget.questions.length, lessThanOrEqualTo(2));
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
