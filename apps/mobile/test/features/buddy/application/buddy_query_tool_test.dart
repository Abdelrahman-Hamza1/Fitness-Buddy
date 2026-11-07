import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/buddy/application/buddy_thread_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/buddy_harness.dart';

/// `queryData` (A68 WP2, AQ-09): the phone answers a QueryPlan with
/// code-computed aggregates and keeps the answer's link; an invalid plan is
/// `unsupportedPlan`. Through the real providers over an empty profile.

Map<String, Object?> _call(String id, Map<String, Object?> plan) => {
  'name': 'queryData',
  'callId': id,
  'args': plan,
};

Map<String, Object?> _plan(String metric, String op, String period) => {
  'metric': metric,
  'measurementType': null,
  'op': op,
  'period': {
    'kind': period,
    'days': period == 'lastNDays' ? 7 : null,
    'since': null,
    'from': null,
    'to': null,
  },
  'filters': null,
};

void main() {
  test('AQ-09 AI-112 queryData answers with claims, coverage and a link; '
      'an invalid combination is unsupportedPlan', () async {
    final h = BuddyHarness();
    final continues = <Map<String, Object?>>[];
    h.adapter.respond = (request) {
      final body = request.data! as Map<String, Object?>;
      final round = body['round'] as int? ?? 0;
      if (round == 1) continues.add(body);
      return turnEvents(
        (_, round) => round == 0
            ? [
                {
                  'type': 'phoneTools',
                  'round': 1,
                  'continuation': 'sealed',
                  'calls': [
                    _call(
                      '11111111-1111-4111-8111-111111111111',
                      _plan('loggedDays', 'count', 'lastNDays'),
                    ),
                    _call(
                      '22222222-2222-4222-8222-222222222222',
                      _plan('weight', 'remaining', 'today'),
                    ),
                  ],
                },
              ]
            : [
                {'type': 'text', 'text': 'No days logged yet.'},
                {
                  'type': 'done',
                  'reason': 'answered',
                  'usage': {'sends': 2, 'inputTokens': 0, 'outputTokens': 0},
                },
              ],
      )(request);
    };
    await h.thread.send('how many days did I log this week', texts);
    final results = continues.single['results']! as List<Object?>;
    final counted = results.first! as Map<String, Object?>;
    expect(counted['ok'], isTrue);
    final data = counted['data']! as Map<String, Object?>;
    final claim =
        (data['claims']! as List<Object?>).single! as Map<String, Object?>;
    expect(claim['metric'], 'loggedDays');
    expect(claim['value'], 0);
    expect(claim['unit'], 'count');
    expect(data['coverage'], {'days': 7, 'loggedDays': 0});
    final invalid = results.last! as Map<String, Object?>;
    expect(invalid['ok'], isFalse);
    expect(invalid['error'], 'unsupportedPlan');
    final turn = h.state.turns.single;
    expect(turn.phase, BuddyTurnPhase.replied);
    expect(turn.links.single.screen, QueryLinkScreen.progress);
    // The link is kept with the reply (restored after a restart).
    h.restart();
    await h.thread.ensureRestored(0);
    expect(h.state.turns.single.links, turn.links);
  });
}
