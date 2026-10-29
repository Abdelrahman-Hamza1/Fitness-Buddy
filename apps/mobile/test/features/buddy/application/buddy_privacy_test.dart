import 'dart:async';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/buddy/application/buddy_thread_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/buddy_harness.dart';

const _canaries = [
  'CANARY-A22-EN shawarma',
  'كناري-A22 شاورما',
  'CANARY-A22-ARABIZI kalet shawerma',
];

/// Runs [body] capturing every `print` and `debugPrint` line.
Future<List<String>> _captured(Future<void> Function() body) async {
  final lines = <String>[];
  final previous = debugPrint;
  debugPrint = (message, {wrapWidth}) => lines.add('$message');
  try {
    await runZoned(
      body,
      zoneSpecification: ZoneSpecification(
        print: (_, _, _, line) => lines.add(line),
      ),
    );
  } finally {
    debugPrint = previous;
  }
  return lines;
}

/// Every string form the send path exposes for [h]'s thread.
List<String> _strings(BuddyHarness h) => [
  '${h.state}',
  for (final t in h.state.turns) ...[
    '$t',
    '${t.message}',
    '${t.request}',
    for (final c in t.cards) '$c',
  ],
  for (final i in h.issues) '$i',
  for (final s in h.applied) '$s',
  for (final s in h.applied) ...s.ops.map((o) => '$o'),
];

void main() {
  // rule: A22 privacy-canaries
  test('A22 send path never logs message text replies or proposal '
      'results', () async {
    for (final canary in _canaries) {
      final reply = {
        ...message([
          intent([
            {...item(), 'mention': canary},
          ], slot: 'breakfast'),
        ]),
        'model': canary,
      };
      final scenarios = <String, Future<BuddyHarness> Function()>{
        'success': () async {
          final h = BuddyHarness()..answer(reply);
          await h.thread.send(canary, texts);
          expect(h.state.turns.single.cards, hasLength(1));
          return h;
        },
        'rejected 400': () async {
          final h = BuddyHarness();
          h.adapter.respond = json({
            'type': 'https://api.test/errors/validation-failed',
            'status': 400,
            'errors': {
              'text': [canary],
            },
          }, status: 400);
          await h.thread.send(canary, texts);
          return h;
        },
        'offline': () async {
          final h = BuddyHarness();
          await h.thread.send(canary, texts);
          return h;
        },
        'malformed 200': () async {
          final h = BuddyHarness()
            ..answer({'promptVersion': canary, 'intents': canary});
          await h.thread.send(canary, texts);
          expect(h.issues, isNotEmpty);
          return h;
        },
        'rejected confirm': () async {
          final h = BuddyHarness()..answer(reply);
          await h.thread.send(canary, texts);
          final card = h.state.turns.single.cards.single;
          // Its rows already exist: the confirm is rejected (duplicateId).
          await h.applier.apply(
            ChangeSet(card.card.draftOps, origin: Origin.direct),
          );
          await h.thread.confirm(card.id);
          expect(
            h.state.turns.single.cards.single.resolution,
            CardResolution.open,
          );
          return h;
        },
      };
      for (final MapEntry(key: name, value: run) in scenarios.entries) {
        late BuddyHarness h;
        final lines = await _captured(() async => h = await run());
        for (final text in [...lines, ..._strings(h)]) {
          expect(
            text,
            isNot(contains(canary)),
            reason: '$name leaked into "$text"',
          );
        }
        for (final issue in h.issues) {
          expect('$issue', isNot(contains('Exception:')), reason: name);
        }
      }
    }
  });
}
