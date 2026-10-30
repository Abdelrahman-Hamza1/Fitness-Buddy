import 'dart:async';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/buddy/application/buddy_thread_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/buddy_harness.dart';

Map<String, Object?> _activeCard(Map<String, Object?> body) =>
    (body['context']! as Map<String, Object?>)['activeCard']
        as Map<String, Object?>? ??
    const {};

void main() {
  // rule: A22 follow-up-updates-card
  test('AI-044 follow-up updates existing card and highlights changed '
      'amount', () async {
    final h = BuddyHarness()..answer(twoMeals());
    await h.thread.send('an egg for breakfast and one for lunch', texts);
    final first = h.state.turns.single;
    final lunch = first.cards.last;
    final lineId = lunch.card.lines.single.entry.id;
    expect(h.state.followUpCard?.id, lunch.id);

    h.answer(
      message([
        intent([item(amount: 2)], slot: 'lunch'),
      ]),
    );
    await h.thread.send('make it 2 eggs', texts);

    // The request named the open card and carried its summary.
    final body = h.adapter.requests.last.data as Map<String, Object?>;
    expect(body['activeProposal'], lunch.id);
    expect(_activeCard(body)['lines'], hasLength(1));

    // Same card, same line, new amount, highlighted.
    final turns = h.state.turns;
    expect(turns, hasLength(2));
    expect(turns.last.cards, isEmpty);
    expect(turns.last.phase, BuddyTurnPhase.replied);
    final updated = turns.first.cards.last;
    expect(updated.id, lunch.id);
    expect(updated.resolution, CardResolution.open);
    final line = updated.card.lines.single;
    expect(line.entry.id, lineId);
    expect(line.entry.amount.input, Quantity(2, 'piece'));
    expect(updated.diff?.lineFields[lineId], isNotEmpty);
    expect(updated.changeToken, isNotNull);
    // Breakfast is untouched.
    expect(turns.first.cards.first.card, first.cards.first.card);

    // Origin stays M1; the budget moves to the follow-up's assistant row.
    final m2 = turns.last.assistantMessageId!;
    expect(updated.card.originMessageId, first.assistantMessageId);
    expect(updated.card.budgetMessageId, m2);
    final rows = await h.chat();
    final assistant = rows.singleWhere((r) => r.id == m2);
    expect(assistant.messageText, texts.updated);
    expect(assistant.codecVersion, 1);
    expect(assistant.budgetJson, isNotNull);
    expect(rows.where((r) => r.role == 'user').map((r) => r.status).toSet(), {
      'done',
    });
    // Nothing reached the diary (AI-036).
    expect(h.applied.expand((s) => s.ops).whereType<DiaryOp>(), isEmpty);
  });

  // rule: A22 follow-up-other-slot
  test('A22 follow-up naming another slot starts a new card', () async {
    final h = BuddyHarness()..answer(twoMeals());
    await h.thread.send('an egg for breakfast and one for lunch', texts);
    final lunch = h.state.turns.single.cards.last;
    h.answer(
      message([
        intent([item(amount: 3)], slot: 'dinner'),
      ]),
    );
    await h.thread.send('and 3 eggs for dinner', texts);
    final turns = h.state.turns;
    expect(turns.last.cards, hasLength(1));
    expect(turns.last.cards.single.id, isNot(lunch.id));
    expect(turns.first.cards.last.card, lunch.card);
  });

  // rule: A22 follow-up-escape
  test('A22 clearing the follow-up chip sends a new message', () async {
    final h = BuddyHarness()..answer(twoMeals());
    await h.thread.send('an egg for breakfast and one for lunch', texts);
    h.thread.clearFollowUp();
    expect(h.state.followUpCard, isNull);
    h.answer(
      message([
        intent([item(amount: 2)], slot: 'lunch'),
      ]),
    );
    await h.thread.send('2 eggs for lunch', texts);
    final body = h.adapter.requests.last.data as Map<String, Object?>;
    expect(body['activeProposal'], isNull);
    expect(h.state.turns.last.cards, hasLength(1));
  });

  // rule: A22b follow-up-in-flight
  test('A22 a card is read-only while its follow-up is in flight so the '
      'answer never overwrites an edit', () async {
    final h = BuddyHarness()..answer(twoMeals());
    await h.thread.send('an egg for breakfast and one for lunch', texts);
    final lunch = h.state.turns.single.cards.last;
    final lineId = lunch.card.lines.single.entry.id;
    final gate = Completer<void>();
    final answer = json(
      message([
        intent([item(amount: 2)], slot: 'lunch'),
      ]),
    );
    h.adapter.respond = (request) async {
      await gate.future;
      return await answer(request);
    };
    final sending = h.thread.send('make it 2 eggs', texts);
    await pumpEventQueue();
    expect(h.state.isUpdating(lunch.id), isTrue);
    expect(h.state.isUpdating(h.state.turns.first.cards.first.id), isFalse);
    // Edits, Log it and Discard on that card do nothing meanwhile.
    h.thread
      ..stepAmount(lunch.id, lineId, up: true)
      ..removeLine(lunch.id, lineId)
      ..setSlot(lunch.id, DefaultSlots.dinner.id);
    await h.thread.confirm(lunch.id);
    await h.thread.discard(lunch.id);
    final during = h.state.turns.first.cards.last;
    expect(during.card, lunch.card);
    expect(during.resolution, CardResolution.open);
    expect(during.removed, isEmpty);
    gate.complete();
    await sending;
    expect(h.state.isUpdating(lunch.id), isFalse);
    final after = h.state.turns.first.cards.last;
    expect(after.card.lines.single.entry.amount.input, Quantity(2, 'piece'));
    expect(after.card.lines.single.entry.slotId, DefaultSlots.lunch.id);
  });

  // rule: A22b follow-up-closed
  test('A22 a follow-up whose card was logged meanwhile leaves it alone and '
      'never says updated', () async {
    final h = BuddyHarness()..answer(twoMeals());
    await h.thread.send('an egg for breakfast and one for lunch', texts);
    final lunch = h.state.turns.single.cards.last;
    h.adapter.respond = offline;
    await h.thread.send('make it 2 eggs', texts);
    final followUp = h.state.turns.last;
    expect(followUp.followUpCardId, lunch.id);
    expect(followUp.canRetry, isTrue);
    await h.thread.confirm(lunch.id);
    expect(h.state.turns.first.cards.last.resolution, CardResolution.logged);
    h.answer(
      message([
        intent([item(amount: 2)], slot: 'lunch'),
      ]),
    );
    await h.thread.retry(followUp.userMessageId, texts);
    final turns = h.state.turns;
    expect(turns.last.phase, BuddyTurnPhase.replied);
    expect(turns.last.cards, isEmpty);
    expect(turns.first.cards.last.resolution, CardResolution.logged);
    final reply = (await h.chat()).singleWhere(
      (r) => r.id == turns.last.assistantMessageId,
    );
    expect(reply.messageText, texts.cardClosed);
    expect(reply.messageText, isNot(texts.updated));
  });

  // rule: A22b follow-up-older-day
  test('A22 a follow-up on a card for an older day keeps that day in its '
      'preview', () async {
    final h = BuddyHarness()
      ..answer(
        message([
          intent([item()], date: 'daysAgo:3'),
        ]),
      );
    // An egg logged three days ago.
    await h.thread.send('an egg 3 days ago', texts);
    final first = h.state.turns.single.cards.single;
    await h.thread.confirm(first.id);
    expect(h.state.turns.single.cards.single.resolution, CardResolution.logged);
    // Another card for that day counts it once.
    await h.thread.send('and another egg that day', texts);
    final card = h.state.turns.last.cards.single;
    final day = card.card.preview.date;
    expect(day, first.card.preview.date);
    expect(card.card.preview.eaten?.kcal, 144);
    // The follow-up names no day: still that day, still counted.
    h.answer(
      message([
        intent([item(amount: 2)]),
      ]),
    );
    await h.thread.send('make it 2', texts);
    final after = h.state.turns[1].cards.single.card;
    expect(after.id, card.id);
    expect(after.preview.date, day);
    expect(after.preview.eaten?.kcal, 216);
  });
}
