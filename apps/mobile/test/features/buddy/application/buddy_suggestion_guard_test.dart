import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/buddy/application/buddy_thread_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/buddy_harness.dart';

/// The confirmation guard for suggestions (TD-128, AQ-01, AI-121): a
/// streamed `suggestion` writes nothing; a tap writes one pending card and
/// no diary row; only that card's Confirm logs.

List<Object?> _items() {
  final intents =
      message([
            intent([item()], slot: 'lunch'),
          ])['intents']!
          as List<Object?>;
  return (intents.single! as Map<String, Object?>)['items']! as List<Object?>;
}

void main() {
  test('AQ-01 AI-121 a suggestion is never logged without the user: the '
      'tap makes a pending card, its Confirm logs it once', () async {
    final h = BuddyHarness();
    final writes = <ChangeSetApplied>[];
    final sub = h.bus.on<ChangeSetApplied>().listen(writes.add);
    addTearDown(sub.cancel);
    h.adapter.respond = turnEvents(
      (turnId, _) => [
        {
          'type': 'proposal',
          'proposalId': '$turnId-s',
          'revision': 1,
          'replaces': null,
          'intent': {
            'kind': 'suggestion',
            'language': 'english',
            'script': 'latin',
            'options': [
              {'label': 'Eggs', 'slotHint': 'lunch', 'items': _items()},
              {'label': 'More eggs', 'slotHint': null, 'items': _items()},
            ],
          },
        },
        {'type': 'text', 'text': 'A couple of ideas.'},
        {
          'type': 'done',
          'reason': 'answered',
          'usage': {'sends': 3, 'inputTokens': 0, 'outputTokens': 0},
        },
      ],
    );
    bool diary(ChangeSetApplied e) =>
        e.entities.contains('diaryEntry') || e.entities.contains('dishGroup');

    await h.thread.send('what can I eat with 600 kcal left', texts);
    var turn = h.state.turns.single;
    expect(turn.phase, BuddyTurnPhase.replied);
    expect(turn.suggestion!.options, hasLength(2));
    expect(turn.cards, isEmpty);
    expect(await h.proposals(), isEmpty, reason: 'no card from the event');
    expect(writes.where(diary), isEmpty);

    await h.thread.pickSuggestion(turn.userMessageId, 0);
    // A second tap on the same option does nothing.
    await h.thread.pickSuggestion(turn.userMessageId, 0);
    turn = h.state.turns.single;
    expect(turn.cards, hasLength(1));
    expect(turn.cards.single.resolution, CardResolution.open);
    expect(turn.suggestion!.options.first.picked, isTrue);
    final rows = await h.proposals();
    expect(rows, hasLength(1));
    expect(rows.single.status, 'pending');
    expect(await h.entries(), isEmpty);
    expect(writes.where(diary), isEmpty);
    expect(writes.where((e) => e.origin is OriginProposal), isEmpty);

    await h.thread.confirm(turn.cards.single.id);
    expect(await h.entries(), hasLength(1));
    expect(writes.where(diary), hasLength(1));
    expect(writes.where(diary).single.origin, isA<OriginProposal>());

    // The options survive a restart with the reply.
    h.restart();
    await h.thread.ensureRestored(0);
    expect(h.state.turns.single.suggestion!.options, hasLength(2));
  });
}
