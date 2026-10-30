import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/buddy/application/proposal_outcomes.dart';
import 'package:fb_mobile/features/buddy/application/session_membership.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../../packages/fb_domain/test/proposals/proposal_fixtures.dart';

ProposalSession _change(ProposalSession s, ProposalAdjustment a) =>
    ProposalEngine.recompute(s, a).value!.session;

void main() {
  // rule: A23 outcome-rule
  test('A23 a card counts as adjusted after any user change or follow-up', () {
    final ids = FixedIds();
    final s = session(
      message([
        intent([item()], slot: 'breakfast'),
      ]),
      ids: ids,
    );
    final card = s.cards.single;
    const none = SessionMembership();
    expect(
      ProposalOutcomes.confirmed(s, card, none),
      ProposalOutcome.unchanged,
    );
    // A user change.
    final changed = _change(
      s,
      ProposalSetAmount(card.lines.single.entry.id, Quantity(2, 'piece')),
    );
    expect(
      ProposalOutcomes.confirmed(changed, changed.cards.single, none),
      ProposalOutcome.adjusted,
    );
    // A rebuild into another message: a follow-up counts, a fact rebuild
    // (no follow-up reply) alone doesn't (rec R3).
    final rebuilt = ProposalEngine.rebuild(
      card,
      ProposalRequest(
        interpretation: message([
          intent([item()], slot: 'breakfast'),
        ]),
        messageId: '019a1b2c-0000-7000-8000-000000008888',
        idSource: ids,
        context: context(),
        facts: ProposalFacts(),
      ),
    ).value!.session;
    final moved = rebuilt.cards.single;
    expect(moved.budgetMessageId, isNot(moved.originMessageId));
    expect(
      ProposalOutcomes.confirmed(
        rebuilt,
        moved,
        none.rebuilt(moved.id, moved.originMessageId),
      ),
      ProposalOutcome.unchanged,
    );
    expect(
      ProposalOutcomes.confirmed(
        rebuilt,
        moved,
        none.followedUp(moved.id, moved.originMessageId, moved.budgetMessageId),
      ),
      ProposalOutcome.adjusted,
    );
    // A context refresh or a lifecycle change isn't an adjustment.
    final refreshed = ProposalEngine.recompute(
      s,
      ProposalSetLifecycle(card.id, ProposalLifecycle.active),
      context: context(),
    ).value!.session;
    expect(
      ProposalOutcomes.confirmed(refreshed, refreshed.cards.single, none),
      ProposalOutcome.unchanged,
    );
    expect(ProposalOutcomes.discarded, ProposalOutcome.discarded);
  });
}
