import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

import '../proposals/proposal_fixtures.dart';
import '../proposals/proposal_recompute_test.dart' show update;

void main() {
  test("AI-065 AI-081 only the user's own state and fat choices are "
      "learned, keyed as the engine's question kinds", () {
    final s = session(
      message([
        intent([
          riceItem(),
          item(dimensions: [fatDimension()]),
        ]),
      ]),
    );
    // Nothing chosen yet: fallbacks are never learned.
    expect(learnedHabitsOf(s.cards.single), isEmpty);
    final rice = s.cards.single.lines.first.dimensions.single;
    final cooked = update(
      s,
      ProposalSelect(rice.id, rice.options.last.id),
    ).session;
    final egg = cooked.cards.single.lines
        .firstWhere((l) => l.dimensions.any((d) => d.kind.name == 'fat'))
        .dimensions
        .single;
    final both = update(
      cooked,
      ProposalSelect(egg.id, egg.options[1].id),
    ).session;
    final habits = learnedHabitsOf(both.cards.single);
    expect(habits.map((h) => (h.key, h.value, h.dimension)), [
      ('state:rice', 'cooked', 'state'),
      ('fat:usda:egg', 'oil:1.0:tsp', 'fat'),
    ]);
    expect(habits.first.subject, 'Synthetic food');
  });
}
