import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

import 'proposal_fixtures.dart';
import 'proposal_rebuild_test.dart' show follow;

void main() {
  // rule: A22b follow-up-keeps-when
  test('AI-044 a lunch card made at breakfast time stays lunch after a '
      'follow-up that names no meal', () {
    final ids = FixedIds();
    final s = session(
      message([
        intent([item()], slot: 'lunch'),
      ]),
      ids: ids,
    );
    final before = s.cards.single.lines.single.entry;
    expect(before.slotId, DefaultSlots.lunch.id);
    // Every food changes; no slot, time or day in the answer.
    final r = ProposalEngine.rebuild(
      s.cards.single,
      follow(
        message([
          intent([item(match: food(key: 'usda:rice', kcal: 130))]),
        ]),
        ids,
      ),
    );
    expect(r.issue, isNull);
    final after = r.value!.session.cards.single.lines.single.entry;
    expect(after.slotId, DefaultSlots.lunch.id);
    expect(after.when, before.when);
  });

  test('AI-044 a yesterday card stays yesterday after a follow-up that names '
      'no day', () {
    final ids = FixedIds();
    final s = session(
      message([
        intent([item()], date: 'yesterday'),
      ]),
      ids: ids,
    );
    final before = s.cards.single.lines.single.entry;
    final r = ProposalEngine.rebuild(
      s.cards.single,
      follow(
        message([
          intent([item(match: food(key: 'usda:bread', kcal: 250))]),
        ]),
        ids,
      ),
    );
    expect(r.issue, isNull);
    final after = r.value!.session.cards.single;
    expect(after.lines.single.entry.when, before.when);
    expect(after.lines.single.entry.slotId, before.slotId);
    expect(after.preview.date, s.cards.single.preview.date);
  });

  test('A22 a follow-up that names another meal or day still moves it', () {
    final ids = FixedIds();
    final s = session(message(), ids: ids);
    final r = ProposalEngine.rebuild(
      s.cards.single,
      follow(
        message([
          intent([item()], slot: 'dinner', date: 'yesterday'),
        ]),
        ids,
      ),
    );
    final after = r.value!.session.cards.single;
    expect(after.lines.single.entry.slotId, DefaultSlots.dinner.id);
    expect(after.preview.date, s.cards.single.preview.date.plusDays(-1));
  });
}
