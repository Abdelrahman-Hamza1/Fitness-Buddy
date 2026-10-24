import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

import 'proposal_fixtures.dart';
import 'proposal_recompute_test.dart' show BadIds, update;

ProposalRequest follow(Map<String, Object?> json, FixedIds ids) =>
    ProposalRequest(
      interpretation: json,
      messageId: '019a1b2c-0000-7000-8000-000000008888',
      idSource: ids,
      context: context(),
      facts: ProposalFacts(),
    );

void main() {
  test(
    'AI-044 follow-up rebuild keeps line IDs and diffs only the changed amount',
    () {
      final ids = FixedIds();
      final s = session(message(), ids: ids);
      final r = ProposalEngine.rebuild(
        s.cards.single,
        follow(
          message([
            intent([item(amount: 2)]),
          ]),
          ids,
        ),
      );
      expect(r.issue, isNull);
      final u = r.value!;
      expect(ids.calls, 3);
      expect(u.session.cards.single.id, s.cards.single.id);
      expect(
        u.session.cards.single.originMessageId,
        s.cards.single.originMessageId,
      );
      expect(u.session.cards.single.budgetMessageId, endsWith('8888'));
      expect(u.diff.lineFields.values.single, {
        ProposalField.amount,
        ProposalField.nutrients,
      });
      expect(u.diff.addedLineIds, isEmpty);
      expect(u.diff.removedLineIds, isEmpty);
    },
  );
  test('AQ-08 follow-up open questions consume the new message budget', () {
    final ids = FixedIds();
    final s = session(
      message([
        intent([riceItem(), riceItem()]),
      ]),
      ids: ids,
    );
    final r = ProposalEngine.rebuild(
      s.cards.single,
      follow(
        message([
          intent([riceItem(), riceItem(), riceItem()]),
        ]),
        ids,
      ),
    );
    expect(r.issue, isNull);
    expect(
      r.value!.session.budget.questions.map((q) => q.dimensionId),
      s.budget.questions.map((q) => q.dimensionId),
    );
    expect(ids.calls, 7);
  });
  // rule: A21 follow-up-adjustments
  test(
    'A21 follow-up keeps compatible adjustments and clears contradicted fields',
    () {
      final ids = FixedIds();
      final s = session(
        t01(),
        facts: ProposalFacts(cookingFatIds: {'usda:oil'}),
        ids: ids,
      );
      final oil = s.cards.single.lines.last;
      final d = oil.dimensions.single;
      final adjusted = update(
        s,
        ProposalSelect(d.id, d.options.last.id),
      ).session;
      final r = ProposalEngine.rebuild(
        adjusted.cards.single,
        ProposalRequest(
          interpretation: message([
            intent([
              item(amount: 2),
              item(match: oilFood(), unit: 'tbsp'),
            ], group: 'Egg with oil'),
          ]),
          messageId: '019a1b2c-0000-7000-8000-000000008888',
          idSource: ids,
          context: context(),
          facts: ProposalFacts(cookingFatIds: {'usda:oil'}),
        ),
      );
      expect(r.issue, isNull);
      expect(
        r.value!.session.cards.single.lines.last.snapshot,
        adjusted.cards.single.lines.last.snapshot,
      );
      expect(r.value!.session.cards.single.lines.first.snapshot.kcal, 144);
      expect(ids.calls, 6);
    },
  );
  // rule: A21 occurrence-matching
  test(
    'A21 duplicate food keys match by occurrence and order without fresh IDs',
    () {
      final ids = FixedIds();
      final s = session(
        message([
          intent([item(), item(amount: 2)]),
        ]),
        ids: ids,
      );
      final r = ProposalEngine.rebuild(
        s.cards.single,
        follow(
          message([
            intent([item(amount: 3), item(amount: 4)]),
          ]),
          ids,
        ),
      );
      expect(r.issue, isNull);
      expect(
        r.value!.session.cards.single.lines.map((l) => l.entry.id),
        s.cards.single.lines.map((l) => l.entry.id),
      );
      expect(ids.calls, 5);
    },
  );
  // rule: A21 id-source
  test('A21 rebuild allocates IDs only for unmatched new lines', () {
    final ids = FixedIds();
    final s = session(message(), ids: ids);
    final r = ProposalEngine.rebuild(
      s.cards.single,
      follow(
        message([
          intent([item(match: oilFood()), item()]),
        ]),
        ids,
      ),
    );
    expect(r.issue, isNull);
    expect(ids.calls, 5);
    expect(
      r.value!.session.cards.single.lines.last.entry.id,
      s.cards.single.lines.single.entry.id,
    );
  });
  // rule: A21 follow-up-validation
  test(
    'A21 rebuild clears changed choices and accepts new dimension kinds',
    () {
      final ids = FixedIds();
      final s = session(
        message([
          intent([riceItem()]),
        ]),
        ids: ids,
      );
      final d = s.cards.single.lines.single.dimensions.single;
      final adjusted = update(
        s,
        ProposalSelect(d.id, d.options.last.id),
      ).session;
      final r = ProposalEngine.rebuild(
        adjusted.cards.single,
        follow(
          message([
            intent([riceItem(amount: 300)]),
          ]),
          ids,
        ),
      );
      expect(r.issue, isNull);
      expect(r.value!.session.cards.single.totals.kcal, 390);
      final raw = riceItem();
      raw['dimensions'] = [
        dimension('state', [
          option(
            'dry',
            candidate: food(
              key: 'usda:rice_dry',
              kcal: 365,
              state: 'dry',
              group: 'rice',
            ),
          ),
        ], stated: 'dry'),
        fatDimension(),
        fatDimension(),
      ];
      final fresh = ProposalEngine.rebuild(
        r.value!.session.cards.single,
        follow(
          message([
            intent([raw], group: 'dish'),
          ]),
          ids,
        ),
      );
      expect(fresh.issue, isNull);
      expect(
        fresh.value!.session.cards.single.lines.first.dimensions,
        hasLength(3),
      );
      expect(
        ProposalEngine.rebuild(
          s.cards.single,
          follow(message()..['model'] = null, ids),
        ).issue,
        ProposalIssue.invalidInput,
      );
      final closed = update(
        s,
        ProposalSetLifecycle(s.cards.single.id, .discarded),
      ).session;
      expect(
        ProposalEngine.rebuild(
          closed.cards.single,
          follow(message(), ids),
        ).issue,
        ProposalIssue.invalidInput,
      );
    },
  );
  // rule: A21 follow-up-group
  test('A21 follow-up keeps dish identity when intent positions move', () {
    final ids = FixedIds();
    final s = session(
      message([
        {'kind': 'medical', 'language': 'english', 'script': 'latin'},
        intent([
          item(amount: null, unit: null, explicit: false),
        ], group: 'dish'),
      ]),
      ids: ids,
    );
    final r = ProposalEngine.rebuild(
      s.cards.single,
      follow(
        message([
          intent([
            item(amount: null, unit: null, explicit: false),
          ], group: 'dish'),
        ]),
        ids,
      ),
    );
    expect(r.issue, isNull);
    expect(
      r.value!.session.cards.single.draftOps.first,
      s.cards.single.draftOps.first,
    );
    expect(ids.calls, 4);
  });
  // rule: A21 fixed-failures
  test(
    'A21 follow-up invalid allocators and mixed meals fail without content',
    () {
      final s = session(message());
      ProposalRequest request(ProposalIdSource ids) => ProposalRequest(
        interpretation: message([
          intent([item(), item(match: oilFood())]),
        ]),
        messageId: '019a1b2c-0000-7000-8000-000000008888',
        idSource: ids,
        context: context(),
        facts: ProposalFacts(),
      );
      expect(
        ProposalEngine.rebuild(s.cards.single, request(BadIds())).issue,
        ProposalIssue.invalidInput,
      );
      expect(
        ProposalEngine.rebuild(s.cards.single, request(_InvalidIds())).issue,
        ProposalIssue.invalidInput,
      );
      final mixed = ProposalEngine.rebuild(
        s.cards.single,
        follow(
          message([
            intent([item()]),
            intent([item()], slot: 'dinner'),
          ]),
          FixedIds()..calls = 100,
        ),
      );
      expect(mixed.issue, ProposalIssue.invalidInput);
    },
  );
  test(
    'AQ-08 follow-up carried questions survive restore of the new message',
    () {
      final ids = FixedIds();
      final s = session(
        message([
          intent([riceItem(), riceItem()]),
        ]),
        ids: ids,
      );
      final rebuilt = ProposalEngine.rebuild(
        s.cards.single,
        follow(
          message([
            intent([riceItem(), riceItem(), riceItem()]),
          ]),
          ids,
        ),
      ).value!.session;
      final restored = ProposalDraftCodec.restore(
        ProposalDraftCodec.encodeMessageBudget(rebuilt),
        [ProposalDraftCodec.encodeCard(rebuilt, rebuilt.cards.single.id)],
        context: context(),
      ).value!;
      expect(restored, rebuilt);
      expect(
        restored.cards.single.originMessageId,
        s.cards.single.originMessageId,
      );
      expect(
        restored.cards.single.budgetMessageId,
        isNot(s.cards.single.budgetMessageId),
      );
      expect(restored.budget.questions, s.budget.questions);
      expect(ids.calls, 7);
      final oldBudget = ProposalDraftCodec.encodeMessageBudget(
        s,
        movedCardIds: [s.cards.single.id],
      );
      final oldRestored = ProposalDraftCodec.restore(
        oldBudget,
        [],
        context: context(),
      );
      expect(oldRestored.issue, isNull);
      expect(oldRestored.value!.cards, isEmpty);
      expect(
        ProposalDraftCodec.encodeMessageBudget(oldRestored.value!),
        oldBudget,
      );
    },
  );
}

class _InvalidIds implements ProposalIdSource {
  @override
  String next() => 'invalid';
}
