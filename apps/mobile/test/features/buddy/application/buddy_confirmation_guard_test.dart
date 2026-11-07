import 'dart:async';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/buddy/application/buddy_thread_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/buddy_harness.dart';

/// The one automated Buddy check (TD-128, AI-178, AQ-01): whatever a turn
/// streams, nothing reaches the diary without the user's tap, and Apply all
/// logs only what the reply still shows as open.

Map<String, Object?> _meal(String slot, {double amount = 1}) =>
    (message([
                  intent([item(amount: amount)], slot: slot),
                ])['intents']!
                as List<Object?>)
            .single!
        as Map<String, Object?>;

Map<String, Object?> _proposal(
  String id,
  Map<String, Object?> intent, {
  int revision = 1,
  Map<String, Object?>? replaces,
}) => {
  'type': 'proposal',
  'proposalId': id,
  'revision': revision,
  'replaces': replaces,
  'intent': intent,
};

const Map<String, Object?> _done = {
  'type': 'done',
  'reason': 'answered',
  'usage': {'sends': 2, 'inputTokens': 0, 'outputTokens': 0},
};

/// What the applier committed, by origin and entities (from the bus).
final class _Writes {
  new(BuddyHarness h) {
    final sub = h.bus.on<ChangeSetApplied>().listen(all.add);
    addTearDown(sub.cancel);
  }

  final List<ChangeSetApplied> all = [];

  /// The committed change sets that touched the diary.
  List<ChangeSetApplied> get diary => [
    for (final e in all)
      if (e.entities.contains('diaryEntry') || e.entities.contains('dishGroup'))
        e,
  ];

  /// The committed change sets made by confirming a card.
  List<ChangeSetApplied> get confirms => [
    for (final e in all)
      if (e.origin is OriginProposal) e,
  ];
}

void main() {
  test(
    'AQ-01 AI-161 proposal events never reach the diary without a '
    'user tap: new cards, updates, replays, phone rounds and a retry',
    () async {
      final h = BuddyHarness();
      final writes = _Writes(h);
      var posts = 0;
      h.adapter.respond = (request) {
        posts++;
        final body = request.data! as Map<String, Object?>;
        final turnId = body['turnId']! as String;
        final round = body['round'] as int? ?? 0;
        return turnEvents(
          (_, _) => switch ((posts, round)) {
            // Round 0, attempt 1: a card, then the stream breaks (no
            // terminal event): the one retry follows.
            (1, _) => [_proposal('$turnId-a', _meal('breakfast'))],
            // Round 0, attempt 2: the card again under a new ID, then a
            // phone round.
            (2, _) => [
              _proposal('$turnId-b', _meal('breakfast')),
              {
                'type': 'phoneTools',
                'round': 1,
                'continuation': 'sealed',
                'calls': [
                  {
                    'name': 'readDiary',
                    'callId': 'c1',
                    'args': {
                      'dateHint': 'yesterday',
                      'range': null,
                      'slotHint': null,
                      'query': null,
                    },
                  },
                ],
              },
            ],
            // Round 1: a new card, an update of the first, a replay of the
            // new card, a stale update, then done.
            _ => [
              _proposal('$turnId-c', _meal('lunch')),
              _proposal(
                '$turnId-b',
                _meal('breakfast', amount: 2),
                revision: 2,
                replaces: {'proposalId': '$turnId-b', 'expectedRevision': 1},
              ),
              _proposal('$turnId-c', _meal('lunch')),
              _proposal(
                '$turnId-c',
                _meal('lunch', amount: 3),
                revision: 2,
                replaces: {'proposalId': '$turnId-c', 'expectedRevision': 7},
              ),
              _done,
            ],
          },
        )(request);
      };
      await h.thread.send('eggs for breakfast and lunch like yesterday', texts);
      final turn = h.state.turns.single;
      expect(turn.phase, BuddyTurnPhase.replied);
      expect(posts, 3, reason: 'start, its one retry, continue');
      // The retry's own card replaced the first attempt's still-open one.
      expect(turn.cards, hasLength(2));
      expect(
        turn.cards.map((c) => c.resolution),
        everyElement(CardResolution.open),
      );
      expect(turn.cards.first.revision, 2);
      expect(turn.cards.last.revision, 1);
      // Nothing logged, nothing confirmed: only pending cards and the chat.
      expect(await h.entries(), isEmpty);
      expect(writes.diary, isEmpty);
      expect(writes.confirms, isEmpty);
      final pending = await h.proposals();
      expect(
        pending.where((p) => p.status == 'pending').map((p) => p.id).toSet(),
        {for (final c in turn.cards) c.id},
      );
      // The phone answered the phone round with the scoped read.
      final resume = h.adapter.requests.last;
      expect(resume.path, '/v1/buddy/turns/continue');
      final results = (resume.data! as Map)['results']! as List<Object?>;
      expect((results.single! as Map)['callId'], 'c1');
    },
  );

  test('AQ-01 AI-171 a retry keeps the earlier card it updates and tells '
      'the server what it holds', () async {
    final h = BuddyHarness();
    final writes = _Writes(h);
    var posts = 0;
    h.adapter.respond = (request) {
      posts++;
      final turnId = (request.data! as Map)['turnId']! as String;
      return turnEvents(
        (_, _) => posts == 1
            ? [_proposal('$turnId-a', _meal('breakfast'))]
            : [
                _proposal('$turnId-b', _meal('lunch')),
                _proposal(
                  '$turnId-a',
                  _meal('breakfast', amount: 2),
                  revision: 2,
                  replaces: {'proposalId': '$turnId-a', 'expectedRevision': 1},
                ),
                _done,
              ],
      )(request);
    };
    await h.thread.send('eggs', texts);
    final turn = h.state.turns.single;
    expect(turn.cards.map((c) => c.revision), [2, 1]);
    expect(
      turn.cards.map((c) => c.resolution),
      everyElement(CardResolution.open),
    );
    final retry = h.adapter.requests[1].data! as Map;
    final prior = retry['priorAttempt']! as Map;
    expect(prior['attempt'], 1);
    final card = (prior['cards']! as List).single! as Map;
    expect(card['proposalId'], '${turn.userMessageId}-a');
    expect(card['status'], 'pending');
    expect(card['revision'], 1);
    expect(writes.diary, isEmpty);
  });

  test('AQ-01 AI-171 a stopped turn applies nothing and never posts its '
      'pending continue', () async {
    final h = BuddyHarness();
    final writes = _Writes(h);
    final gate = Completer<void>();
    h.adapter.respond = (request) async {
      final body = request.data! as Map<String, Object?>;
      final turnId = body['turnId']! as String;
      await gate.future;
      return await turnEvents(
        (_, _) => [
          _proposal('$turnId-a', _meal('breakfast')),
          {
            'type': 'phoneTools',
            'round': 1,
            'continuation': 'sealed',
            'calls': <Object?>[],
          },
        ],
      )(request);
    };
    final sent = h.thread.send('eggs', texts);
    await pumpEventQueue();
    h.thread.stop(h.state.turns.single.userMessageId);
    gate.complete();
    await sent;
    expect(h.adapter.requests.map((r) => r.path), ['/v1/buddy/turns']);
    expect(writes.diary, isEmpty);
    expect(writes.confirms, isEmpty);
    expect(h.state.turns.single.phase, BuddyTurnPhase.replied);
  });

  test("AI-162 Apply all logs only the reply's still-pending cards at their "
      'current revision, in one change set with one Undo', () async {
    final h = BuddyHarness();
    final writes = _Writes(h);
    h.adapter.respond = turnEvents(
      (turnId, _) => [
        _proposal('$turnId-a', _meal('breakfast')),
        _proposal('$turnId-b', _meal('lunch')),
        _proposal('$turnId-c', _meal('dinner')),
        _done,
      ],
    );
    await h.thread.send('eggs three times', texts);
    final [breakfast, lunch, dinner] = h.state.turns.single.cards;
    // One discarded, one adjusted here (its current revision moves on).
    await h.thread.discard(dinner.id);
    final line = lunch.card.lines.single.entry.id;
    h.thread.setAmount(lunch.id, line, Quantity(3, 'piece'));
    expect(h.state.turns.single.cards[1].revision, 2);
    expect(writes.confirms, isEmpty);
    expect(await h.entries(), isEmpty);

    await h.thread.applyAll(h.state.turns.single.userMessageId);

    // One change set confirmed both open cards, nothing else.
    expect(writes.confirms, hasLength(1));
    final entries = await h.entries();
    expect(entries, hasLength(2));
    final bySlot = {for (final e in entries) e.slotId: e};
    expect(bySlot.keys.toSet(), {
      breakfast.card.lines.single.entry.slotId,
      lunch.card.lines.single.entry.slotId,
    });
    // The adjusted card logged as shown (3 pieces), not as proposed.
    expect(bySlot[lunch.card.lines.single.entry.slotId]!.inputAmount, 3);
    final cards = h.state.turns.single.cards;
    expect(cards.map((c) => c.resolution), [
      CardResolution.logged,
      CardResolution.logged,
      CardResolution.discarded,
    ]);
    // One Undo reverts the whole Apply all.
    expect(cards[0].undoEntryId, isNotNull);
    expect(cards[0].undoEntryId, cards[1].undoEntryId);
    await h.thread.undo(cards[0].id);
    final live = [
      for (final e in await h.entries())
        if (e.deletedAt == null) e,
    ];
    expect(live, isEmpty);
    expect(
      h.state.turns.single.cards.take(2).map((c) => c.resolution),
      everyElement(CardResolution.open),
    ); // Log all again after that Undo: fresh entry IDs, still one change set.
    await h.thread.applyAll(h.state.turns.single.userMessageId);
    expect(writes.confirms, hasLength(2));
    expect([
      for (final e in await h.entries())
        if (e.deletedAt == null) e,
    ], hasLength(2));
  });

  test('AQ-01 a dropped connection before any event leaves the message '
      'waiting, never failed or logged', () async {
    final h = BuddyHarness(); // Offline by default.
    final writes = _Writes(h);
    await h.thread.send('2 eggs', texts);
    expect(h.state.turns.single.phase, BuddyTurnPhase.pending);
    expect(writes.diary, isEmpty);
    final row = await h.row(h.state.turns.single.userMessageId);
    expect(row.status, ChatMessageStatus.pendingOffline.code);
    expect(row.requestJson, isNotNull, reason: 'the checkpoint is kept');
    h.container.dispose();
  });
}
