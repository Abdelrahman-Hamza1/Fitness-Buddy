import 'dart:convert';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/features/buddy/application/buddy_thread_controller.dart';
import 'package:fb_mobile/features/buddy/application/proposal_resolution.dart';
import 'package:fb_mobile/features/buddy/application/proposal_session_writer.dart';
import 'package:fb_mobile/features/buddy/application/session_membership.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../../packages/fb_domain/test/proposals/proposal_fixtures.dart'
    as fixtures;
import '../support/buddy_harness.dart';

/// A harness with a two-card reply (breakfast, lunch).
Future<BuddyHarness> _twoCards() async {
  final h = BuddyHarness()..answer(twoMeals());
  await h.thread.send('an egg for breakfast and one for lunch', texts);
  expect(h.state.turns.single.cards, hasLength(2));
  return h;
}

int? _revision(String? json) => proposalRevisionOf(json);

/// The outbox rows as data, to compare before and after.
Future<String> _outbox(BuddyHarness h) async => jsonEncode([
  for (final r in await h.db.select(h.db.syncOutbox).get())
    [r.entity, r.rowId, r.hlc],
]);

void main() {
  // rule: A23 reply-rows
  test('AI-045 a reply creates one pending proposal row per card in its '
      'change set', () async {
    final h = await _twoCards();
    final turn = h.state.turns.single;
    final m = turn.assistantMessageId!;
    final session = turn.cards.first.session;
    // One change set: the user row done, the assistant row, its budget and
    // a row per card.
    final reply = h.applied[1];
    expect(reply.origin, Origin.system);
    expect(reply.ops.whereType<CreateProposal>(), hasLength(2));
    expect(reply.ops.whereType<SetChatMessageBudget>().single.id, m);
    final rows = await h.proposals();
    expect(rows.map((r) => r.id), [for (final c in turn.cards) c.id]);
    for (final row in rows) {
      final card = session.cards.firstWhere((c) => c.id == row.id);
      expect(row.status, 'pending');
      expect(row.outcome, isNull);
      expect(row.resolvedAt, isNull);
      expect(row.kind, 'foodLog');
      expect(row.originMessageId, m);
      expect(row.budgetMessageId, m);
      expect(row.codecVersion, ProposalDraftCodec.version);
      final (interpretation, draft) = ProposalSessionWriter.fields(
        session,
        card.id,
      );
      expect(row.interpretationJson, interpretation);
      expect(row.draftJson, draft);
      expect(_revision(row.draftJson), _revision((await h.row(m)).budgetJson));
    }
    // The assistant row keeps the answer locally; the budget is the
    // writer's; nothing reached the diary.
    final assistant = await h.row(m);
    expect(assistant.answerJson, isNotNull);
    expect(jsonDecode(assistant.answerJson!), turn.interpretation);
    expect(
      assistant.budgetJson,
      jsonEncode(ProposalDraftCodec.encodeMessageBudget(session)),
    );
    expect(await h.entries(), isEmpty);
    // Every card restores from the rows (budget + cards, one revision).
    final restored = ProposalDraftCodec.restore(
      ProposalDraftCodec.messageFromSync(assistant.budgetJson).value!,
      [
        for (final r in rows)
          ProposalDraftCodec.cardFromSync(
            interpretationJson: r.interpretationJson,
            draftJson: r.draftJson,
          ).value!,
      ],
      context: fixtures.context(),
      trustedFacts: fixtures.trustedRows([
        for (final r in rows) jsonDecode(r.draftJson) as Map<String, Object?>,
      ]),
    );
    expect(restored.issue, isNull);
    expect(restored.value!.cards.map((c) => c.id), [
      for (final c in session.cards) c.id,
    ]);
  });

  // rule: A23 confirm-atomic
  test('A23 confirm commits diary proposal status outcome and message budget '
      'atomically', () async {
    final h = await _twoCards();
    final turn = h.state.turns.single;
    final [a, b] = turn.cards;
    final m = turn.assistantMessageId!;
    final budgetBefore = (await h.row(m)).budgetJson;
    final count = h.applied.length;
    await h.thread.confirm(a.id);
    // Exactly one change set, from the proposal.
    expect(h.applied, hasLength(count + 1));
    final set = h.applied.last;
    expect(set.origin, Origin.proposal(a.id));
    final ops = set.ops;
    expect(ops.whereType<DiaryOp>(), isNotEmpty);
    final resolve = ops.whereType<ResolveProposal>().single;
    expect(resolve.id, a.id);
    expect(resolve.to, ProposalStatus.confirmed);
    expect(resolve.outcome, ProposalOutcome.unchanged);
    expect(ops.whereType<SaveProposalDraft>().single.id, b.id);
    expect(ops.whereType<SetChatMessageBudget>().single.id, m);
    // Diary, card status, outcome, sibling and budget all committed.
    expect(await h.entries(), hasLength(a.card.lines.length));
    final row = await h.proposal(a.id);
    expect(row.status, 'confirmed');
    expect(row.outcome, 'unchanged');
    expect(row.resolvedAt, h.clock.nowUtc().millisecondsSinceEpoch);
    final sibling = await h.proposal(b.id);
    expect(sibling.status, 'pending');
    final budget = (await h.row(m)).budgetJson;
    expect(budget, isNot(budgetBefore));
    final revision = _revision(budget);
    expect(revision, greaterThan(_revision(budgetBefore)!));
    expect(_revision(row.draftJson), revision);
    expect(_revision(sibling.draftJson), revision);
    // An adjusted card's outcome is `adjusted`.
    final q = b.card.lines.expand((l) => l.dimensions).toList();
    final current = h.state.turns.single.cards.last;
    if (q.isNotEmpty) {
      h.thread.adjust(
        b.id,
        ProposalSelect(q.first.id, q.first.options.last.id),
      );
    } else {
      h.thread.adjust(
        b.id,
        ProposalSetAmount(
          current.card.lines.single.entry.id,
          Quantity(3, 'piece'),
        ),
      );
    }
    await h.thread.confirm(b.id);
    expect((await h.proposal(b.id)).outcome, 'adjusted');
  });

  // rule: A23 resolve-rollback
  test('A23 failing resolve op rolls back diary and outbox', () async {
    final h = await _twoCards();
    final turn = h.state.turns.single;
    final a = turn.cards.first;
    final m = turn.assistantMessageId!;
    // The stored card was rebound elsewhere (another phone's follow-up).
    final other = h.ids.next();
    expect(
      await h.applier.apply(
        ChangeSet([
          CreateChatMessage(
            other,
            const ChatMessageDraft(
              role: ChatMessageRole.assistant,
              text: 'x',
              status: ChatMessageStatus.done,
            ),
          ),
          SaveProposalDraft(
            a.id,
            expectedBudgetMessageId: m,
            budgetMessageId: other,
            codecVersion: ProposalDraftCodec.version,
            interpretationJson: (await h.proposal(a.id)).interpretationJson,
            draftJson: (await h.proposal(a.id)).draftJson,
          ),
        ], origin: Origin.system),
      ),
      isA<Applied>(),
    );
    final outbox = await _outbox(h);
    final rows = jsonEncode([for (final r in await h.proposals()) r.toJson()]);
    await h.thread.confirm(a.id);
    // The diary ops were rolled back with the rejected resolve.
    expect(await h.entries(), isEmpty);
    expect(await _outbox(h), outbox);
    expect(jsonEncode([for (final r in await h.proposals()) r.toJson()]), rows);
    final card = h.state.turns.single.cards.first;
    expect(card.resolution, CardResolution.open);
    expect(card.couldNotLog, isTrue);
    // A resolved card is refused the same way.
    final r = await _twoCards();
    final b = r.state.turns.single.cards.last;
    await r.thread.discard(b.id);
    final before = await _outbox(r);
    final again = await r.resolution.confirm(
      b.session,
      b.id,
      CardOrigin(
        interpretation: r.state.turns.single.interpretation!,
        messageId: r.state.turns.single.assistantMessageId!,
        referenceTime: r.state.turns.single.message.time,
      ),
    );
    expect(again, isA<CardNotLogged>());
    expect(await r.entries(), isEmpty);
    expect(await _outbox(r), before);
  });

  // rule: A23 no-double-log
  test('A23 duplicate or concurrent confirm cannot log twice', () async {
    final h = await _twoCards();
    final turn = h.state.turns.single;
    final a = turn.cards.first;
    final origin = CardOrigin(
      interpretation: turn.interpretation!,
      messageId: turn.assistantMessageId!,
      referenceTime: turn.message.time,
    );
    // Double tap through the thread.
    await Future.wait([h.thread.confirm(a.id), h.thread.confirm(a.id)]);
    expect(await h.entries(), hasLength(a.card.lines.length));
    // Two calls on the same pre-confirm session, in parallel.
    final p = await _twoCards();
    final pa = p.state.turns.single.cards.first;
    final porigin = CardOrigin(
      interpretation: p.state.turns.single.interpretation!,
      messageId: p.state.turns.single.assistantMessageId!,
      referenceTime: p.state.turns.single.message.time,
    );
    final results = await Future.wait([
      p.resolution.confirm(pa.session, pa.id, porigin),
      p.resolution.confirm(pa.session, pa.id, porigin),
    ]);
    expect(results.whereType<CardLogged>(), hasLength(1));
    expect(await p.entries(), hasLength(pa.card.lines.length));
    expect((await p.proposal(pa.id)).status, 'confirmed');
    // A stale copy of the session after the confirm, again.
    expect(
      await h.resolution.confirm(a.session, a.id, origin),
      isA<CardNotLogged>(),
    );
    expect(await h.entries(), hasLength(a.card.lines.length));
  });

  // rule: A23 discard-outcome
  test('A23 discard records outcome without diary writes', () async {
    final h = await _twoCards();
    final turn = h.state.turns.single;
    final [a, b] = turn.cards;
    final m = turn.assistantMessageId!;
    final outbox = (await h.db.select(h.db.syncOutbox).get()).length;
    await h.thread.discard(a.id);
    final set = h.applied.last;
    expect(set.origin, Origin.system);
    expect(set.ops.whereType<DiaryOp>(), isEmpty);
    final row = await h.proposal(a.id);
    expect(row.status, 'discarded');
    expect(row.outcome, 'discarded');
    expect(row.resolvedAt, isNotNull);
    expect((await h.proposal(b.id)).status, 'pending');
    expect(await h.entries(), isEmpty);
    final entities = [
      for (final r in (await h.db.select(h.db.syncOutbox).get()).skip(outbox))
        r.entity,
    ];
    expect(entities.toSet(), {'proposal', 'chatMessage'});
    expect(
      _revision((await h.row(m)).budgetJson),
      _revision((await h.proposal(b.id)).draftJson),
    );
  });

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

  // rule: A23 answer-cleared
  test('A23 stored answer is cleared once no card of its message is '
      'pending', () async {
    final h = await _twoCards();
    final turn = h.state.turns.single;
    final [a, b] = turn.cards;
    final m = turn.assistantMessageId!;
    expect((await h.row(m)).answerJson, isNotNull);
    await h.thread.confirm(a.id);
    // One card still pending: the answer stays.
    expect((await h.row(m)).answerJson, isNotNull);
    await h.thread.discard(b.id);
    expect((await h.row(m)).answerJson, isNull);
    // Undo of the discard brings it back with the rows.
    await h.thread.restoreDiscarded(b.id);
    expect((await h.row(m)).answerJson, isNotNull);
    // A template reply keeps none.
    final t = BuddyHarness()
      ..answer({
        ...message([
          {
            'kind': 'outOfScope',
            'language': 'english',
            'script': 'latin',
            'reason': 'offTopic',
          },
        ]),
      });
    await t.thread.send('hi', texts);
    final assistant = (await t.chat()).singleWhere(
      (r) => r.role == 'assistant',
    );
    expect(assistant.answerJson, isNull);
    expect(assistant.budgetJson, isNull);
    expect(await t.proposals(), isEmpty);
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
