import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/write_guard.dart';
import 'package:fb_mobile/features/buddy/application/buddy_thread_controller.dart';
import 'package:fb_mobile/features/buddy/application/proposal_resolution.dart';
import 'package:fb_mobile/features/buddy/buddy.dart';
import 'package:fb_mobile/features/buddy/data/proposal_mappers.dart';
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

  // rule: A23 privacy-canaries
  test(
    'A23 proposal persistence never logs drafts answers or results',
    () async {
      for (final canary in _canaries) {
        final reply = {
          ...message([
            intent([
              {...item(), 'mention': canary},
            ], slot: 'breakfast'),
            intent([
              {...item(), 'mention': canary},
            ], slot: 'lunch'),
          ]),
          'model': canary,
        };
        final scenarios = <String, Future<BuddyHarness> Function()>{
          'reply, confirm, discard, undo, restore': () async {
            final h = BuddyHarness()..answer(reply);
            await h.thread.send(canary, texts);
            final [a, b] = h.state.turns.single.cards;
            await h.thread.confirm(a.id);
            await h.thread.undo(a.id);
            await h.thread.discard(b.id);
            await h.thread.restoreDiscarded(b.id);
            h.restart();
            await h.thread.ensureRestored(0);
            expect(h.state.turns.single.cards, hasLength(2));
            return h;
          },
          'rejected resolve': () async {
            final h = BuddyHarness()..answer(reply);
            await h.thread.send(canary, texts);
            final a = h.state.turns.single.cards.first;
            await h.thread.discard(a.id);
            // A stale copy of the card confirms against a resolved row.
            await h.resolution.confirm(
              a.session,
              a.id,
              CardOrigin(
                interpretation: h.state.turns.single.interpretation!,
                messageId: h.state.turns.single.assistantMessageId!,
                referenceTime: h.state.turns.single.message.time,
              ),
            );
            return h;
          },
          'unrestorable and mapper errors': () async {
            final h = BuddyHarness()..answer(reply);
            await h.thread.send(canary, texts);
            final m = h.state.turns.single.assistantMessageId!;
            await runAuthorizedWrite(
              () => h.db.customStatement(
                'UPDATE chat_messages SET budget_json = ? WHERE id = ?',
                ['{"x":"$canary"}', m],
              ),
            );
            h.restart();
            await h.thread.ensureRestored(0);
            expect(h.state.turns.single.unrestorable, hasLength(2));
            for (final row in await h.proposals()) {
              final tomb = row.copyWith(deletedAt: const Value(1));
              expect(
                () => proposalToSync(tomb),
                throwsA(
                  isA<ProposalMappingError>().having(
                    (e) => '$e',
                    'text',
                    isNot(contains(canary)),
                  ),
                ),
              );
            }
            return h;
          },
        };
        for (final MapEntry(key: name, value: run) in scenarios.entries) {
          late BuddyHarness h;
          final lines = await _captured(() async => h = await run());
          for (final text in [
            ...lines,
            ..._strings(h),
            for (final t in h.state.turns) ...t.unrestorable.map((u) => '$u'),
            for (final r in await ProposalRepository(h.db).pending()) '$r',
          ]) {
            expect(
              text,
              isNot(contains(canary)),
              reason: '$name leaked into "$text"',
            );
          }
        }
      }
    },
  );
}
