import 'dart:convert';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/features/buddy/application/buddy_issues.dart';
import 'package:fb_mobile/features/buddy/application/buddy_thread_controller.dart';
import 'package:fb_mobile/features/buddy/application/send_buddy_message.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/buddy_harness.dart';

void main() {
  // rule: A22 save-before-dispatch
  test('A22 message is saved before interpret dispatch', () async {
    final h = BuddyHarness()..answer(twoMeals());
    final seen = <ChatMessageRow>[];
    h.adapter.onRequest = (request) async {
      // The committed row, read outside the change set.
      seen.addAll(await h.chat());
    };
    await h.thread.send('  2 eggs for breakfast and lunch ', texts);
    await pumpEventQueue();
    expect(h.adapter.requests, hasLength(1));
    final request = h.adapter.requests.single;
    final body = request.data as Map<String, Object?>;
    final user = (await h.chat()).first;
    expect(seen.single.id, user.id);
    expect(seen.single.status, 'queued');
    expect(seen.single.role, 'user');
    expect(seen.single.messageText, '  2 eggs for breakfast and lunch ');
    expect(body['requestId'], user.id);
    expect(request.headers['Idempotency-Key'], user.id);
    expect(isUuidV7(user.id), isTrue);
    // The save is its own direct change set; the reply is a second one.
    expect(h.applied.first.origin, Origin.direct);
    expect(h.applied.first.ops.single, isA<CreateChatMessage>());
    expect(h.applied[1].origin, Origin.system);
    expect(user.status, 'done');
    expect(user.language, 'en');
  });

  // rule: A22 assistant-budget-owner
  test(
    'A22 assistant message alone stores the shared question budget',
    () async {
      final h = BuddyHarness()..answer(twoMeals(language: 'arabic'));
      await h.thread.send('بيضتين', texts);
      final turn = h.state.turns.single;
      final session = turn.cards.first.session;
      final rows = await h.chat();
      expect(rows, hasLength(2));
      final user = rows.singleWhere((r) => r.role == 'user');
      final assistant = rows.singleWhere((r) => r.role == 'assistant');
      expect(user.codecVersion, isNull);
      expect(user.budgetJson, isNull);
      expect(assistant.id, turn.assistantMessageId);
      expect(assistant.codecVersion, 1);
      expect(
        assistant.budgetJson,
        jsonEncode(ProposalDraftCodec.encodeMessageBudget(session)),
      );
      expect(assistant.replyToMessageId, user.id);
      expect(assistant.language, 'en');
      expect(assistant.messageText, texts.cards);
      // No language from the model's raw value: arabic + latin is Arabizi.
      expect(user.language, 'ar-Latn');
      for (final card in session.cards) {
        expect(card.originMessageId, assistant.id);
        expect(card.budgetMessageId, assistant.id);
      }
      expect(turn.cards, hasLength(2));
    },
  );

  // rule: A22 retry-same-request
  test(
    'A22 retryable failures offer try again with the same request',
    () async {
      for (final responder in <FakeResponder>[
        offline,
        timeout,
        json({'type': 'about:blank', 'status': 500}, status: 500),
        json({'type': 'about:blank', 'status': 503}, status: 503),
      ]) {
        final h = BuddyHarness();
        h.adapter.respond = responder;
        await h.thread.send('2 eggs', texts);
        final failed = h.state.turns.single;
        expect(failed.phase, BuddyTurnPhase.failed);
        expect(failed.failure!.retryable, isTrue);
        expect(failed.canRetry, isTrue);
        expect((await h.chat()).single.status, 'failed');
        h.answer(twoMeals());
        await h.thread.retry(failed.userMessageId, texts);
        expect(h.bodies, hasLength(2));
        expect(h.bodies[1], h.bodies[0]);
        expect(h.keys[1], h.keys[0]);
        expect(h.keys[0], failed.userMessageId);
        final done = h.state.turns.single;
        expect(done.phase, BuddyTurnPhase.replied);
        expect(done.cards, hasLength(2));
        expect((await h.chat()).first.status, 'done');
        expect(h.issues, isEmpty);
      }
    },
  );

  // rule: A22 second-503
  test(
    'A22 second 503 stops retry and returns the text to the composer',
    () async {
      final h = BuddyHarness();
      h.adapter.respond = json({'status': 503}, status: 503);
      await h.thread.send('2 eggs', texts);
      expect(h.state.turns.single.canRetry, isTrue);
      expect(h.state.composerRestore, isNull);
      await h.thread.retry(h.state.turns.single.userMessageId, texts);
      final turn = h.state.turns.single;
      expect(turn.unavailableCount, 2);
      expect(turn.canRetry, isFalse);
      expect(h.state.composerRestore, '2 eggs');
      expect(h.thread.takeComposerRestore(), '2 eggs');
      expect(h.state.composerRestore, isNull);
      expect(h.thread.takeComposerRestore(), isNull);
      // No third attempt with that key.
      await h.thread.retry(turn.userMessageId, texts);
      expect(h.adapter.requests, hasLength(2));
      // The next send is a new message with a new key.
      h.answer(twoMeals());
      await h.thread.send('2 eggs', texts);
      expect(h.adapter.requests, hasLength(3));
      expect(h.keys[2], isNot(h.keys[0]));
      expect(h.state.turns, hasLength(2));
    },
  );

  // rule: A22 no-retry-classes
  test('A22 rejected or rate limited sends are not retried', () async {
    for (final (status, failure, reported) in [
      (400, BuddySendFailure.rejected, true),
      (409, BuddySendFailure.rejected, true),
      (429, BuddySendFailure.rateLimited, false),
    ]) {
      final h = BuddyHarness();
      h.adapter.respond = json({'status': status}, status: status);
      await h.thread.send('2 eggs', texts);
      final turn = h.state.turns.single;
      expect(turn.failure, failure, reason: '$status');
      expect(turn.canRetry, isFalse);
      await h.thread.retry(turn.userMessageId, texts);
      expect(h.adapter.requests, hasLength(1));
      expect((await h.chat()).single.status, 'failed');
      expect(
        h.issues,
        reported ? [isA<BuddyRequestRejected>()] : isEmpty,
        reason: '$status',
      );
    }
  });

  // rule: A22 unusable-reply
  test('A22 a reply that cannot become a card is saved with the fallback '
      'template', () async {
    for (final body in <Map<String, Object?>>[
      {'promptVersion': 'interpret-v1'}, // Not contract-valid.
      {...message(), 'promptVersion': 'v2'}, // Loader rejects it.
    ]) {
      final h = BuddyHarness()..answer(body);
      await h.thread.send('2 eggs', texts);
      final rows = await h.chat();
      expect(rows.first.status, 'done');
      final assistant = rows.singleWhere((r) => r.role == 'assistant');
      expect(assistant.messageText, texts.noCard);
      expect(assistant.budgetJson, isNull);
      expect(assistant.codecVersion, isNull);
      expect(h.state.turns.single.phase, BuddyTurnPhase.replied);
      expect(h.state.turns.single.cards, isEmpty);
      expect(h.issues, [isA<BuddyReplyUnusable>()]);
    }
  });

  // rule: A22 fixed-templates
  test('A22 non-food replies use fixed templates', () async {
    for (final (kind, template) in [
      ('medical', texts.medical),
      ('outOfScope', texts.notFood),
      ('clarify', texts.notFood),
    ]) {
      final h = BuddyHarness()
        ..answer({
          ...message([
            {
              'kind': kind,
              'language': 'english',
              'script': 'latin',
              'reason': kind == 'clarify' ? 'unclear' : 'offTopic',
            },
          ]),
        });
      await h.thread.send('is it ok?', texts);
      final assistant = (await h.chat()).singleWhere(
        (r) => r.role == 'assistant',
      );
      expect(assistant.messageText, template, reason: kind);
      expect(assistant.budgetJson, isNull);
      expect(h.state.turns.single.cards, isEmpty);
    }
  });

  // rule: A22 unrecognized-routing
  test('A22 an intent this version cannot handle gets the unsupported '
      'template', () async {
    for (final intent in <Map<String, Object?>>[
      {'kind': 'somethingNewer'},
      {
        'kind': 'diaryDelete',
        'language': 'english',
        'script': 'latin',
        'targets': <Object?>[],
        'reference': {
          'mention': 'lunch',
          'dateHint': null,
          'slotHint': null,
          'scope': 'one',
        },
      },
      {
        'kind': 'foodLog',
        'language': 'english',
        'script': 'latin',
        'timeHint': null,
        'slotHint': null,
        'dateHint': 'date:2999-01-01',
        'dishGroup': null,
        'items': <Object?>[],
      },
    ]) {
      final h = BuddyHarness()..answer(message([intent]));
      await h.thread.send('change lunch', texts);
      final assistant = (await h.chat()).singleWhere(
        (r) => r.role == 'assistant',
      );
      expect(assistant.messageText, texts.unsupported, reason: '$intent');
      expect(h.state.turns.single.cards, isEmpty);
    }
  });

  // rule: A22 contributors-same-transaction
  test('A22 persistence contributors land in the same transaction for reply '
      'and confirm', () async {
    // Reply: the contributor's op commits with the reply.
    final h = BuddyHarness()..answer(twoMeals());
    final ok = TestContributor(
      reply: [h.settingOp('reply')],
      confirm: [h.settingOp('confirm')],
    );
    h.contributors.add(ok);
    await h.thread.send('2 eggs', texts);
    expect(ok.calls, ['reply']);
    expect(h.applied[1].ops.last, isA<ScriptOp>());
    expect(await h.db.select(h.db.settingsKv).get(), hasLength(1));
    final card = h.state.turns.single.cards.first;
    await h.thread.confirm(card.id);
    expect(ok.calls, ['reply', 'confirm']);
    final confirmSet = h.applied.last;
    expect(confirmSet.origin, Origin.proposal(card.id));
    expect(confirmSet.ops.last, isA<ScriptOp>());
    expect(await h.db.select(h.db.settingsKv).get(), hasLength(2));

    // A failing contributor rolls the whole reply back.
    final f = BuddyHarness()..answer(twoMeals());
    f.contributors.add(TestContributor(reply: [BuddyHarness.failingOp()]));
    await f.thread.send('2 eggs', texts);
    final rows = await f.chat();
    expect(rows, hasLength(1));
    expect(rows.single.status, 'queued');
    expect(f.state.turns.single.phase, BuddyTurnPhase.failed);

    // ...and a failing confirm contributor rolls the confirm back.
    final c = BuddyHarness()..answer(twoMeals());
    c.contributors.add(TestContributor(confirm: [BuddyHarness.failingOp()]));
    await c.thread.send('2 eggs', texts);
    await c.thread.confirm(c.state.turns.single.cards.first.id);
    expect(await c.entries(), isEmpty);
    expect(c.state.turns.single.cards.first.resolution, CardResolution.open);
    expect(c.state.turns.single.cards.first.couldNotLog, isTrue);
  });

  test(
    'A22 blank text saves nothing and a send in flight blocks another',
    () async {
      final h = BuddyHarness()..answer(twoMeals());
      expect(await h.send.save('   '), isNull);
      expect(await h.send.save('\u0000'), isNull);
      await h.thread.send(' \n ', texts);
      expect(await h.chat(), isEmpty);
      expect(h.state.turns, isEmpty);
      final first = h.thread.send('2 eggs', texts);
      final second = h.thread.send('3 eggs', texts);
      await Future.wait([first, second]);
      expect(h.adapter.requests, hasLength(1));
      // The composer cap: 1000 UTF-16 units without splitting a pair.
      final saved = await h.send.save('x' * 999 + '🍎');
      expect(saved!.text, 'x' * 999);
      expect(SendBuddyMessage.languageOf({'intents': 'nope'}), isNull);
      expect(
        SendBuddyMessage.languageOf({
          'intents': [
            {'language': 1},
          ],
        }),
        isNull,
      );
    },
  );

  // rule: A22 unexpected-throws
  test('A22 unexpected throws never wedge the thread', () async {
    // The loader throws an Error: the reply is the fixed template.
    final h = BuddyHarness()
      ..answer(message())
      ..configThrows = true;
    await h.thread.send('2 eggs', texts);
    expect(h.state.turns.single.phase, BuddyTurnPhase.replied);
    expect(
      (await h.chat()).singleWhere((r) => r.role == 'assistant').messageText,
      texts.noCard,
    );
    expect(h.issues, [isA<BuddyReplyUnusable>()]);

    // The applier throws on the reply: the turn fails (retryable), Send is
    // free again, and Try again works.
    final g = BuddyHarness()..answer(message());
    var replies = 0;
    g.throwOnApply = (set) =>
        set.ops.length > 1 && replies++ == 0; // The first reply only.
    await g.thread.send('2 eggs', texts);
    final turn = g.state.turns.single;
    expect(turn.phase, BuddyTurnPhase.failed);
    expect(turn.failure, BuddySendFailure.server);
    expect(turn.canRetry, isTrue);
    expect(g.state.sending, isFalse);
    await g.thread.retry(turn.userMessageId, texts);
    expect(g.state.turns.single.phase, BuddyTurnPhase.replied);

    // The applier throws on Log it: the card is open again, "couldn't log".
    final c = BuddyHarness()..answer(message());
    await c.thread.send('2 eggs', texts);
    final cardId = c.state.turns.single.cards.single.id;
    c.throwOnApply = (set) => set.origin is OriginProposal;
    await c.thread.confirm(cardId);
    final card = c.state.turns.single.cards.single;
    expect(card.resolution, CardResolution.open);
    expect(card.couldNotLog, isTrue);
    expect(await c.entries(), isEmpty);
  });

  // rule: A22 fixed-templates
  test(
    'A22 cards with a medical or unsupported part keep both sentences',
    () async {
      for (final (kind, template) in [
        ('medical', texts.medical),
        ('somethingNewer', texts.unsupported),
      ]) {
        final h = BuddyHarness()
          ..answer({
            ...message([
              intent([item()]),
              {'kind': kind, 'language': 'english', 'script': 'latin'},
            ]),
          });
        await h.thread.send('eggs and a question', texts);
        expect(h.state.turns.single.cards, hasLength(1), reason: kind);
        final assistant = (await h.chat()).singleWhere(
          (r) => r.role == 'assistant',
        );
        expect(assistant.messageText, '${texts.cards} $template', reason: kind);
      }
    },
  );
}
