import 'dart:convert';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/write_guard.dart';
import 'package:fb_mobile/features/buddy/application/buddy_issues.dart';
import 'package:fb_mobile/features/buddy/application/buddy_thread_controller.dart';
import 'package:fb_mobile/features/buddy/application/food_card_view.dart';
import 'package:fb_mobile/features/buddy/data/proposal_mappers.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/buddy_harness.dart';

/// A reply of personal-food cards (restore trusts them), then a restart.
Future<(BuddyHarness, String)> _personal({
  List<String> slots = const ['breakfast', 'lunch'],
}) async {
  final h = BuddyHarness();
  final key = await h.personalFood();
  h.answer(BuddyHarness.personalMeals(key, slots: slots));
  await h.thread.send('my food', texts);
  return (h, key);
}

/// Restarts [h] and reads its thread back.
Future<BuddyThread> _restart(BuddyHarness h) async {
  h.restart();
  expect(h.state.turns, isEmpty);
  await h.thread.ensureRestored(0);
  return h.state;
}

Future<double> _todayKcal(BuddyHarness h) async {
  final totals = await DiaryReads(h.db).dailyTotals(
    h.state.turns.first.message.time.localDate,
    h.state.turns.first.message.time.localDate,
  );
  return totals.fold<double>(0, (n, t) => n + t.totals.kcal);
}

void main() {
  // rule: A23 restore-pending
  test('AI-045 pending cards restore after restart without entering '
      'totals', () async {
    final (h, _) = await _personal();
    final before = h.state.turns.single;
    final restored = await _restart(h);
    final turn = restored.turns.single;
    expect(turn.userMessageId, before.userMessageId);
    expect(turn.assistantMessageId, before.assistantMessageId);
    expect(turn.message.text, before.message.text);
    expect(turn.phase, BuddyTurnPhase.replied);
    expect(turn.interpretation, before.interpretation);
    expect(turn.cards.map((c) => c.id), before.cards.map((c) => c.id));
    for (final (i, card) in turn.cards.indexed) {
      expect(card.resolution, CardResolution.open);
      expect(card.card.canConfirm, isTrue);
      expect(card.card.lines, before.cards[i].card.lines);
    }
    expect(await h.entries(), isEmpty);
    expect(await _todayKcal(h), 0);
    // Once per generation: a second call adds nothing.
    await h.thread.ensureRestored(0);
    expect(h.state.turns, hasLength(1));
    // A restored card logs as usual.
    await h.thread.confirm(turn.cards.first.id);
    expect(h.state.turns.single.cards.first.resolution, CardResolution.logged);
  });

  // rule: A23 restore-no-expiry
  test('AI-046 pending cards stay until handled', () async {
    final (h, _) = await _personal();
    h.clock.advance(const Duration(days: 5));
    final restored = await _restart(h);
    expect(restored.turns.single.cards.map((c) => c.resolution), [
      CardResolution.open,
      CardResolution.open,
    ]);
    expect((await h.proposals()).map((r) => r.status), ['pending', 'pending']);
  });

  // rule: A23 restore-not-diary
  test('DY-025 restored pending cards never appear as diary entries', () async {
    final (h, _) = await _personal();
    await _restart(h);
    expect(await h.entries(), isEmpty);
    final day = h.state.turns.single.message.time.localDate;
    expect(await DiaryReads(h.db).dailyTotals(day, day), isEmpty);
    expect(
      (await h.db.select(h.db.syncOutbox).get()).map((r) => r.entity).toSet(),
      isNot(contains('diaryEntry')),
    );
  });

  // rule: A23 restore-question-cap
  test('A23 assistant row budget and current message cards restore at most '
      'two issued question IDs', () async {
    final h = BuddyHarness()
      ..answer(
        message([
          intent([riceItem(), riceItem(), riceItem()], slot: 'lunch'),
        ]),
      );
    await h.thread.send('rice three ways', texts);
    final m = h.state.turns.single.assistantMessageId!;
    final budget = jsonDecode((await h.row(m)).budgetJson!) as Map;
    expect((budget['issued']! as Map).length, lessThanOrEqualTo(2));
    final restored = await _restart(h);
    final session = restored.turns.single.cards.single.session;
    expect(session.budget.questions.length, lessThanOrEqualTo(2));
    expect(
      session.budget.questions.map((q) => q.dimensionId).toList(),
      budget['open'],
    );
  });

  // rule: A23 restore-sibling-intake
  test(
    'A23 confirmed sibling is counted only through confirmed intake',
    () async {
      final (h, _) = await _personal();
      final [a, b] = h.state.turns.single.cards;
      await h.thread.confirm(a.id);
      final kcal = a.card.totals.kcal;
      final restored = await _restart(h);
      final [ra, rb] = restored.turns.single.cards;
      expect(ra.resolution, CardResolution.logged);
      expect(ra.card.canConfirm, isFalse);
      expect(rb.resolution, CardResolution.open);
      // The sibling's day preview counts the logged card once, from the
      // diary, plus itself.
      expect(
        rb.card.preview.eaten!.kcal,
        closeTo(kcal + rb.card.totals.kcal, 1e-6),
      );
      expect(await _todayKcal(h), closeTo(kcal, 1e-6));
      expect(b.id, rb.id);
    },
  );

  // rule: A23 restore-status-map
  test('A23 stored pending maps to active and superseded stays '
      'nonconfirmable', () async {
    final (h, _) = await _personal();
    final [a, b] = h.state.turns.single.cards;
    // Another phone marked one historical (a synced row).
    await runAuthorizedWrite(
      () => h.db.customStatement(
        "UPDATE proposals SET status = 'superseded' WHERE id = ?",
        [b.id],
      ),
    );
    final restored = await _restart(h);
    final [ra, rb] = restored.turns.single.cards;
    expect(ra.card.lifecycle, ProposalLifecycle.active);
    expect(ra.resolution, CardResolution.open);
    expect(rb.card.lifecycle, ProposalLifecycle.superseded);
    expect(rb.resolution, CardResolution.superseded);
    expect(rb.card.canConfirm, isFalse);
    await h.thread.confirm(b.id);
    expect(await h.entries(), isEmpty);
    expect(a.id, ra.id);
  });

  // rule: A23 oversized-local
  test('A23 oversized proposal remains local pending with recoverable sync '
      'size issue', () async {
    final h = BuddyHarness()
      ..answer(
        message([
          intent([
            item(match: food()..['nameEn'] = '😀' * 17000),
          ], slot: 'lunch'),
        ]),
      );
    await h.thread.send('a huge name', texts);
    final card = h.state.turns.single.cards.single;
    final row = await h.proposal(card.id);
    expect(row.status, 'pending');
    expect(row.draftJson.length, greaterThan(ChatProposalSyncBounds.json));
    expect(() => proposalToSync(row), throwsA(ProposalMappingError.tooLarge));
    expect(proposalTooLargeToSync(proposalRecordOf(row)), isTrue);
    expect(FoodCardView.of(card).tooLargeToSync, isTrue);
    expect(card.card.canConfirm, isTrue);
    // It survives a restart as a local pending card with the same note.
    final restored = await _restart(h);
    final again = restored.turns.single.cards.single;
    expect(again.id, card.id);
    expect(FoodCardView.of(again).tooLargeToSync, isTrue);
  });

  // rule: A23 unrestorable-discard
  test(
    'A23 a card that cannot be reopened is offered for discard alone',
    () async {
      final (h, _) = await _personal();
      final first = h.state.turns.single;
      // A second reply whose budget is unreadable (an unknown format).
      final key = await h.personalFood();
      h.answer(BuddyHarness.personalMeals(key, slots: ['dinner']));
      await h.thread.send('my other food', texts);
      final broken = h.state.turns.last;
      final budget = jsonDecode(
        (await h.row(broken.assistantMessageId!)).budgetJson!,
      ) as Map<String, Object?>;
      await runAuthorizedWrite(
        () => h.db.customStatement(
          'UPDATE chat_messages SET budget_json = ? WHERE id = ?',
          [
            jsonEncode({...budget, 'codecVersion': 99}),
            broken.assistantMessageId,
          ],
        ),
      );
      final restored = await _restart(h);
      expect(restored.turns, hasLength(2));
      expect(restored.turns.first.cards, hasLength(2));
      final turn = restored.turns.last;
      expect(turn.cards, isEmpty);
      final placeholder = turn.unrestorable.single;
      expect(placeholder.id, broken.cards.single.id);
      expect(placeholder.issue, ProposalIssue.unsupportedCodecVersion);
      expect(
        h.issues,
        contains(
          isA<BuddyRestoreIssue>().having(
            (i) => i.issue,
            'issue',
            ProposalIssue.unsupportedCodecVersion,
          ),
        ),
      );
      await h.thread.discardUnrestorable(placeholder.id);
      final discarded = h.state.turns.last.unrestorable.single;
      expect(discarded.discarded, isTrue);
      final row = await h.proposal(placeholder.id);
      expect(row.status, 'discarded');
      expect(row.outcome, 'discarded');
      // Only that row: the other message's cards stay pending.
      for (final c in first.cards) {
        expect((await h.proposal(c.id)).status, 'pending');
      }
      expect(await h.entries(), isEmpty);
      // Undo puts it back.
      await h.thread.restoreUnrestorable(placeholder.id);
      expect(h.state.turns.last.unrestorable.single.discarded, isFalse);
      expect((await h.proposal(placeholder.id)).status, 'pending');
    },
  );

  // rule: A23 stale-update
  test('A23 a stale restored card updates from the stored answer into a new '
      'message', () async {
    // Answer foods without an attached pack can't be verified on restore.
    final h = BuddyHarness()..answer(twoMeals());
    await h.thread.send('an egg for breakfast and one for lunch', texts);
    final [a, _] = h.state.turns.single.cards;
    final m = h.state.turns.single.assistantMessageId!;
    final restored = await _restart(h);
    final stale = restored.turns.single.cards.first;
    final view = FoodCardView.of(
      stale,
      turnAnswer: restored.turns.single.interpretation,
    );
    expect(view.factsChanged, isTrue);
    expect(view.canLog, isFalse);
    expect(view.canUpdate, isTrue);
    expect(
      h.issues.whereType<BuddyRestoreIssue>().map((i) => i.issue),
      contains(ProposalIssue.staleFacts),
    );
    // Offline: no network call.
    final requests = h.adapter.requests.length;
    await h.thread.updateCard(a.id);
    expect(h.adapter.requests, hasLength(requests));
    final updated = h.state.turns.single.cards.first;
    expect(updated.card.canConfirm, isTrue);
    expect(updated.rebuilt, isTrue);
    final mPrime = updated.card.budgetMessageId;
    expect(mPrime, isNot(m));
    expect((await h.proposal(a.id)).budgetMessageId, mPrime);
    expect((await h.row(mPrime)).replyToMessageId, isNull);
    await h.thread.confirm(a.id);
    expect(h.state.turns.single.cards.first.resolution, CardResolution.logged);
  });

  // rule: A23 follow-up-restore
  test('A23 follow-up restores carried questions by budgetMessageId with '
      'immutable origin', () async {
    final h = BuddyHarness()
      ..answer(
        message([
          intent([riceItem(), riceItem()], slot: 'lunch'),
        ]),
      );
    await h.thread.send('rice twice', texts);
    final m1 = h.state.turns.single.assistantMessageId!;
    final card = h.state.turns.single.cards.single;
    h.answer(
      message([
        intent([riceItem(), riceItem(), riceItem()], slot: 'lunch'),
      ]),
    );
    await h.thread.send('and one more rice', texts);
    final m2 = h.state.turns.last.assistantMessageId!;
    final live = h.state.turns.first.cards.single;
    expect(live.card.budgetMessageId, m2);
    final carried = live.session.budget.questions
        .map((q) => q.dimensionId)
        .toList();
    final restored = await _restart(h);
    // The card is in its origin turn; the follow-up turn shows no card.
    final origin = restored.turns.firstWhere((t) => t.assistantMessageId == m1);
    final back = origin.cards.single;
    expect(back.id, card.id);
    expect(back.card.originMessageId, m1);
    expect(back.card.budgetMessageId, m2);
    expect(
      back.session.budget.questions.map((q) => q.dimensionId).toList(),
      carried,
    );
    expect(h.state.membership.isFollowUp(m2), isTrue);
    expect(back.origin?.messageId, m2);
  });

  // rule: A23 rebuild-note-restore
  test("A23 rebuild note renders in the card's origin turn and restores "
      'without a reply', () async {
    final (h, key) = await _personal();
    final [a, _] = h.state.turns.single.cards;
    await h.applier.apply(
      ChangeSet([
        UpdatePersonalFood(
          key,
          1,
          PersonalFoodDraft(
            names: FoodNames('Private'),
            per100: Nutrients(
              kcal: 250,
              protein: 1,
              carbs: 1,
              fat: 1,
              fiber: 0,
            ),
          ),
        ),
      ], origin: Origin.direct),
    );
    await h.thread.confirm(a.id);
    final mPrime = h.state.turns.single.cards.first.card.budgetMessageId;
    final restored = await _restart(h);
    // M′ is no turn of its own: the card stays in its origin turn.
    expect(restored.turns, hasLength(1));
    final back = restored.turns.single.cards.firstWhere((c) => c.id == a.id);
    expect(back.rebuilt, isTrue);
    expect(back.card.budgetMessageId, mPrime);
    expect(FoodCardView.of(back).rebuilt, isTrue);
    expect(back.card.canConfirm, isTrue);
  });

  // rule: A23 restore-merge
  test('A23 restore runs after catalog install and account recovery once per '
      'generation', () async {
    final (h, _) = await _personal();
    final live = h.state.turns.single;
    // A live turn wins over its stored copy; nothing doubles.
    await h.thread.ensureRestored(0);
    expect(h.state.turns, hasLength(1));
    expect(identical(h.state.turns.single, live), isTrue);
    // Concurrent calls share one restore.
    h.restart();
    await Future.wait([h.thread.ensureRestored(0), h.thread.ensureRestored(0)]);
    expect(h.state.turns, hasLength(1));
    // Another generation's call does nothing.
    h.restart();
    await h.thread.ensureRestored(7);
    expect(h.state.turns, isEmpty);
  });

  // rule: A23 restore-kind
  test('A23 a stored card of another kind restores as a placeholder', () async {
    final (h, _) = await _personal(slots: ['breakfast']);
    final card = h.state.turns.single.cards.single;
    await runAuthorizedWrite(
      () => h.db.customStatement(
        "UPDATE proposals SET kind = 'targetChange' WHERE id = ?",
        [card.id],
      ),
    );
    final restored = await _restart(h);
    final turn = restored.turns.single;
    expect(turn.cards, isEmpty);
    expect(turn.unrestorable.single.id, card.id);
  });

  // rule: A23 restore-orphans
  test(
    'A23 pending cards without a turn are still offered for discard',
    () async {
      final (h, _) = await _personal();
      final [a, b] = h.state.turns.single.cards;
      // A row with no message refs, and one whose origin message is gone.
      await runAuthorizedWrite(() async {
        await h.db.customStatement(
          'UPDATE proposals SET budget_message_id = NULL, '
          'origin_message_id = NULL WHERE id = ?',
          [a.id],
        );
        await h.db.customStatement(
          'UPDATE proposals SET origin_message_id = ? WHERE id = ?',
          ['019a1b2c-0000-7000-8000-00000000dead', b.id],
        );
      });
      final restored = await _restart(h);
      expect(restored.turns, isEmpty);
      expect(restored.orphans.map((o) => o.id).toSet(), {a.id, b.id});
      await h.thread.discardUnrestorable(a.id);
      expect((await h.proposal(a.id)).status, 'discarded');
      expect(
        h.state.orphans.singleWhere((o) => o.id == a.id).discarded,
        isTrue,
      );
      await h.thread.restoreUnrestorable(a.id);
      expect((await h.proposal(a.id)).status, 'pending');
    },
  );

  // rule: A23 placeholder-answer
  test('A23 discarding the last unrestorable card of a message clears its '
      'answer', () async {
    final (h, _) = await _personal(slots: ['breakfast']);
    final m = h.state.turns.single.assistantMessageId!;
    final card = h.state.turns.single.cards.single;
    expect((await h.row(m)).answerJson, isNotNull);
    await runAuthorizedWrite(
      () => h.db.customStatement(
        'UPDATE chat_messages SET budget_json = ? WHERE id = ?',
        ['{"broken":true}', m],
      ),
    );
    final restored = await _restart(h);
    expect(restored.turns.single.unrestorable.single.id, card.id);
    await h.thread.discardUnrestorable(card.id);
    expect((await h.row(m)).answerJson, isNull);
    // Undo brings the answer back with the row.
    await h.thread.restoreUnrestorable(card.id);
    expect((await h.row(m)).answerJson, isNotNull);
    expect((await h.proposal(card.id)).status, 'pending');
  });

  // rule: A23 placeholder-non-object
  test(
    'A23 a placeholder whose draft is not a JSON object can be discarded',
    () async {
      for (final draft in ['[]', 'null', '1', '"x"']) {
        final (h, _) = await _personal(slots: ['breakfast']);
        final m = h.state.turns.single.assistantMessageId!;
        final card = h.state.turns.single.cards.single;
        await runAuthorizedWrite(
          () => h.db.customStatement(
            'UPDATE proposals SET draft_json = ? WHERE id = ?',
            [draft, card.id],
          ),
        );
        final restored = await _restart(h);
        expect(restored.turns.single.unrestorable.single.id, card.id);
        await h.thread.discardUnrestorable(card.id);
        final row = await h.proposal(card.id);
        expect(row.status, 'discarded', reason: draft);
        expect(row.draftJson, '{}', reason: draft);
        expect((await h.row(m)).answerJson, isNull, reason: draft);
        await h.thread.restoreUnrestorable(card.id);
        expect((await h.proposal(card.id)).draftJson, draft, reason: draft);
        expect((await h.row(m)).answerJson, isNotNull, reason: draft);
      }
    },
  );
}
