import 'dart:convert';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/buddy/application/proposal_session_writer.dart';
import 'package:fb_mobile/features/buddy/application/session_membership.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../../packages/fb_domain/test/proposals/proposal_fixtures.dart'
    as fixtures;

void main() {
  // rule: A23 budget-bound
  test('A23 the budget of a reply with the most cards stays far below the '
      'sync bound', () {
    // Twenty meals (the intent cap), each its own card, with questions.
    final slots = ['breakfast', 'lunch', 'dinner', 'snacks'];
    final s = fixtures.session(
      fixtures.message([
        for (var i = 0; i < ProposalPolicyConstants.maxIntents; i++)
          fixtures.intent(
            [fixtures.riceItem(), fixtures.riceItem()],
            slot: slots[i % 4],
            date: 'daysAgo:${i + 2}',
          ),
      ]),
    );
    expect(s.cards.length, ProposalPolicyConstants.maxIntents);
    expect(s.budget.questions, isNotEmpty);
    final budget = ProposalSessionWriter.budget(s);
    expect(budget.length, lessThan(ChatProposalSyncBounds.json ~/ 8));
    // Even with every card departed and listed twice over.
    final all = {for (final c in s.cards) c.id};
    expect(
      ProposalSessionWriter.budget(s, departed: all).length,
      lessThan(ChatProposalSyncBounds.json ~/ 8),
    );
    expect(ProposalSessionWriter.budgetFits(s), isTrue);
  });

  // rule: A23 membership
  test('A23 session membership leaves departed cards out of a write', () {
    final s = fixtures.session(
      fixtures.message([
        fixtures.intent([fixtures.item()], slot: 'breakfast'),
        fixtures.intent([fixtures.item()], slot: 'lunch'),
      ]),
    );
    final [a, b] = s.cards;
    final m = a.budgetMessageId;
    final moved = const SessionMembership().followedUp(a.id, m, 'm2');
    expect(moved.members(s).map((c) => c.id), [b.id]);
    expect(moved.isFollowUp('m2'), isTrue);
    final ops = ProposalSessionWriter.write(s, moved);
    expect(ops.whereType<SaveProposalDraft>().map((o) => o.id), [b.id]);
    final budget = jsonDecode(
      ops.whereType<SetChatMessageBudget>().single.budgetJson,
    ) as Map<String, Object?>;
    expect(budget['cards'], [b.id]);
    expect(budget['departed'], [a.id]);
    expect('$moved', isNot(contains(a.id)));
  });
}
