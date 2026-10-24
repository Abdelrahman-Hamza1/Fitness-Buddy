import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

import 'proposal_codec_test.dart' show copyJson;
import 'proposal_fixtures.dart';
import 'proposal_rebuild_test.dart' show follow;
import 'proposal_recompute_test.dart' show update;

void main() {
  // rule: A21 restore-trust-boundary
  test('A21 catalog forged nutrients measures and yields stay read-only', () {
    final f = localFood(origin: .localCatalog);
    final facts = ProposalFacts(catalog: {f.key: f}, packAvailable: true);
    final ids = FixedIds();
    final s = session(message(), facts: facts, ids: ids);
    final original = ProposalDraftCodec.encodeCard(s, s.cards.single.id);
    final trusted = TrustedFoodFacts(foods: {f.key: f});
    for (final field in [5, 7, 10, 11, 13, -1]) {
      final row = copyJson(original);
      final food = (row['foods']! as List).first as List;
      switch (field) {
        case 5:
          (food[5] as List)[0] = 999.0;
        case 7:
          food[7] = 0;
        case 10:
          food[10] = 2.0;
        case 11:
          food[11] = 'forged';
        case 13:
          food[13] = [
            ['piece', 999.0, 0, null, null],
          ];
        default:
          (row['environment']! as List)[3] = [
            ['forged', 0, 1, 3.0],
          ];
      }
      final restored = ProposalDraftCodec.restore(
        ProposalDraftCodec.encodeMessageBudget(s),
        [row],
        context: context(),
        trustedFacts: trusted,
      );
      expect(restored.issue, isNull);
      final card = restored.value!.cards.single;
      expect(card.issues, contains(ProposalIssue.factsMismatch));
      expect(card.canConfirm, isFalse);
      expect(card.lines, isNotEmpty);
      expect(card.draftOps, isEmpty);
      final adjusted = update(
        restored.value!,
        ProposalSetAmount(card.lines.first.entry.id, Quantity(100, 'g')),
      ).session.cards.single;
      expect(adjusted.canConfirm, isFalse);
      final rebuilt = ProposalEngine.rebuild(
        card,
        follow(message(), ids),
      ).value!;
      expect(rebuilt.session.cards.single.canConfirm, isTrue);
    }
  });
  // rule: A21 restore-trust-boundary
  test(
    'A21 forged cross-source restore identity preserves verified sibling',
    () {
      const key = '019a1b2c-0000-7000-8000-000000001234';
      final f = localFood(origin: .localCatalog);
      final personal = localFood(
        key: key,
        source: .yours,
        personalVersion: 1,
        origin: .localPersonal,
      );
      final s = session(
        message([
          intent([item()], slot: 'breakfast'),
          intent([
            item(
              match: food(key: key, source: 'personal'),
            ),
          ], slot: 'dinner'),
        ]),
        facts: ProposalFacts(
          catalog: {f.key: f},
          personal: {key: personal},
          packAvailable: true,
        ),
      );
      final rows = [
        for (final c in s.cards) ProposalDraftCodec.encodeCard(s, c.id),
      ];
      ((rows.first['foods']! as List).first as List)[0] = key;
      final restored = ProposalDraftCodec.restore(
        ProposalDraftCodec.encodeMessageBudget(s),
        rows,
        context: context(),
        trustedFacts: TrustedFoodFacts(foods: {f.key: f, key: personal}),
      ).value!;
      expect(restored.cards.first.issues, contains(ProposalIssue.staleFacts));
      expect(restored.cards.first.canConfirm, isFalse);
      expect(restored.cards.first.lines, isNotEmpty);
      expect(restored.cards.last.canConfirm, isTrue);
    },
  );
  // rule: A21 restore-trust-boundary
  test(
    'A21 fact mismatch blocks only its card and rebuild drops forged overrides',
    () {
      final f = localFood(origin: .localCatalog);
      final other = localFood(key: 'usda:other', origin: .localCatalog);
      final facts = ProposalFacts(
        catalog: {f.key: f, other.key: other},
        packAvailable: true,
      );
      final ids = FixedIds();
      var s = session(
        message([
          intent([item()], slot: 'breakfast'),
          intent([item(match: food(key: other.key))], slot: 'dinner'),
        ]),
        facts: facts,
        ids: ids,
      );
      s = update(
        s,
        ProposalSwap(s.cards.first.lines.single.entry.id, f),
      ).session;
      final rows = [
        for (final c in s.cards) ProposalDraftCodec.encodeCard(s, c.id),
      ];
      (((rows.first['foods']! as List).first as List)[5] as List)[0] = 999.0;
      final restored = ProposalDraftCodec.restore(
        ProposalDraftCodec.encodeMessageBudget(s),
        rows,
        context: context(),
        trustedFacts: TrustedFoodFacts(foods: {f.key: f, other.key: other}),
      ).value!;
      expect(restored.cards.first.canConfirm, isFalse);
      expect(restored.cards.last.canConfirm, isTrue);
      final rebuilt = ProposalEngine.rebuild(
        restored.cards.first,
        ProposalRequest(
          interpretation: message(),
          messageId: '019a1b2c-0000-7000-8000-000000008888',
          idSource: ids,
          context: context(),
          facts: facts,
        ),
      ).value!.session.cards.single;
      expect(rebuilt.canConfirm, isTrue);
      expect(rebuilt.lines.single.selectedFood, f);
    },
  );
  // rule: A21 restore-trust-boundary
  test(
    'A21 changed pack version missing food and source mismatch are stale',
    () {
      final f = localFood(origin: .localCatalog);
      final s = session(
        message(),
        facts: ProposalFacts(catalog: {f.key: f}, packAvailable: true),
      );
      for (final trusted in [
        TrustedFoodFacts(),
        TrustedFoodFacts(
          foods: {f.key: localFood(key: f.key, version: 'new-pack')},
        ),
        TrustedFoodFacts(
          foods: {f.key: localFood(key: f.key, source: .reference)},
        ),
      ]) {
        final result = ProposalDraftCodec.restore(
          ProposalDraftCodec.encodeMessageBudget(s),
          [ProposalDraftCodec.encodeCard(s, s.cards.single.id)],
          context: context(),
          trustedFacts: trusted,
        );
        final card = result.value!.cards.single;
        expect(card.issues, contains(ProposalIssue.staleFacts));
        expect(card.canConfirm, isFalse);
        expect(card.lines, isNotEmpty);
      }
    },
  );
}
