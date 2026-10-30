import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

import 'proposal_fixtures.dart';
import 'proposal_recompute_test.dart' show update;

void main() {
  // rule: A22b component-remove
  test('AI-042 generated oil is removed on its own and its item stays', () {
    final s = session(
      message([
        intent([
          item(dimensions: [fatDimension()]),
        ]),
      ]),
    );
    final d = s.cards.single.lines.first.dimensions.first;
    final withOil = update(s, ProposalSelect(d.id, d.options.last.id)).session;
    final lines = withOil.cards.single.lines;
    expect(lines, hasLength(2));
    final egg = lines.first;
    final oil = lines.last;
    expect(egg.componentOf, isNull);
    expect(oil.componentOf, egg.entry.id);

    final noOil = update(
      withOil,
      ProposalSetRemoved(oil.entry.id, removed: true),
    ).session;
    expect(noOil.cards.single.lines.single.entry.id, egg.entry.id);
    expect(
      noOil.cards.single.totals.kcal,
      lessThan(withOil.cards.single.totals.kcal),
    );

    final back = update(
      noOil,
      ProposalSetRemoved(oil.entry.id, removed: false),
    ).session;
    expect(back, withOil);

    // Removing the item takes its oil with it.
    final none = update(
      withOil,
      ProposalSetRemoved(egg.entry.id, removed: true),
    ).session;
    expect(none.cards.single.lines, isEmpty);
  });

  test('A22 an oil the user named is an item of its own', () {
    final s = session(
      message([
        intent([item(), item(match: oilFood(), unit: 'tbsp')]),
      ]),
    );
    expect(s.cards.single.lines, hasLength(2));
    final oil = s.cards.single.lines.last;
    expect(oil.entry.food.ref.id, 'usda:oil');
    expect(oil.componentOf, isNull);
    final u = update(s, ProposalSetRemoved(oil.entry.id, removed: true));
    expect(u.session.cards.single.lines, hasLength(1));
  });
}
