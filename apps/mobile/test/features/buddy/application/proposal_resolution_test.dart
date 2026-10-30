import 'dart:async';
import 'dart:convert';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/account/profile_generation.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/buddy/application/buddy_issues.dart';
import 'package:fb_mobile/features/buddy/application/buddy_reply_texts.dart';
import 'package:fb_mobile/features/buddy/application/buddy_thread_controller.dart';
import 'package:fb_mobile/features/buddy/application/proposal_resolution.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/buddy_harness.dart';

PersonalFoodDraft _food(double kcal) => PersonalFoodDraft(
  names: FoodNames('Private'),
  per100: Nutrients(kcal: kcal, protein: 1, carbs: 1, fat: 1, fiber: 0),
);

/// A harness with a two-card reply (breakfast, lunch) in its thread.
Future<BuddyHarness> twoCards() async {
  final h = BuddyHarness()..answer(twoMeals());
  await h.thread.send('2 eggs', texts);
  expect(h.state.turns.single.cards, hasLength(2));
  return h;
}

/// A harness with a two-card reply of a personal food (breakfast, lunch):
/// its cards restore confirmable from the database.
Future<BuddyHarness> twoPersonalCards() async {
  final h = BuddyHarness();
  h.answer(BuddyHarness.personalMeals(await h.personalFood()));
  await h.thread.send('my food twice', texts);
  expect(h.state.turns.single.cards, hasLength(2));
  return h;
}

void main() {
  // rule: A22 confirm-composition
  test(
    'A22 confirm use case composes only selected card ops and origin',
    () async {
      final h = await twoCards();
      final [a, b] = h.state.turns.single.cards;
      final before = h.applied.length;
      await h.thread.confirm(a.id);
      expect(h.applied.length, before + 1);
      final set = h.applied.last;
      expect(set.origin, Origin.proposal(a.id));
      // This card's draft ops, then only the durable proposal bookkeeping
      // (A23): its resolve, its sibling's row and the message budget.
      expect(set.ops.take(a.card.draftOps.length), a.card.draftOps);
      expect(
        set.ops
            .skip(a.card.draftOps.length)
            .every((o) => o is ProposalOp || o is SetChatMessageBudget),
        isTrue,
      );
      for (final op in b.card.draftOps) {
        expect(set.ops, isNot(contains(op)));
      }
      final stored = await h.entries();
      expect(stored, hasLength(a.card.lines.length));
      expect(stored.every((e) => e.origin == 'proposal:${a.id}'), isTrue);
      final cards = h.state.turns.single.cards;
      expect(cards[0].resolution, CardResolution.logged);
      expect(cards[0].card.lifecycle, ProposalLifecycle.confirmed);
      expect(cards[1].resolution, CardResolution.open);
      expect(cards[1].card.lifecycle, ProposalLifecycle.active);
    },
  );

  // rule: A22 single-flight-confirm
  test('A22 concurrent confirm applies once', () async {
    final h = await twoCards();
    final card = h.state.turns.single.cards.first;
    final before = h.applied.length;
    final first = h.thread.confirm(card.id);
    expect(
      h.state.turns.single.cards.first.resolution,
      CardResolution.confirming,
    );
    final second = h.thread.confirm(card.id);
    await Future.wait([first, second]);
    await h.thread.confirm(card.id);
    expect(h.applied.length, before + 1);
    expect(await h.entries(), hasLength(card.card.lines.length));
  });

  // rule: A22 undo-once
  test('A22 undo reverts the confirm exactly once', () async {
    final h = await twoCards();
    final card = h.state.turns.single.cards.first;
    await h.thread.confirm(card.id);
    final logged = h.state.turns.single.cards.first;
    expect(logged.undoEntryId, isNotNull);
    expect(h.undo.entries.single.label, UndoLabel('proposalLogged'));
    expect(await h.thread.undo(card.id), UndoOutcome.undone);
    final live = (await h.entries()).where((e) => e.deletedAt == null);
    expect(live, isEmpty);
    final undone = h.state.turns.single.cards.first;
    // A23 D10: the card is pending again.
    expect(undone.resolution, CardResolution.open);
    expect(undone.undoEntryId, isNull);
    // A second undo is a no-op; nothing else is reverted.
    expect(await h.thread.undo(card.id), isNull);
    expect(h.undo.entries, isEmpty);
  });

  // rule: A23 undo-reopens
  test(
    'A23 undo of a confirm or discard reopens the card as pending',
    () async {
      final h = await twoPersonalCards();
      final [a, b] = h.state.turns.single.cards;
      final message = h.state.turns.single.assistantMessageId!;

      // Confirm, then Undo: the whole pre-resolution session is back.
      await h.thread.confirm(a.id);
      expect((await h.proposal(a.id)).status, 'confirmed');
      expect(await h.thread.undo(a.id), UndoOutcome.undone);
      expect((await h.entries()).where((e) => e.deletedAt == null), isEmpty);
      final rows = await h.proposals();
      expect(rows.map((r) => r.status), ['pending', 'pending']);
      expect(rows.map((r) => r.outcome), [null, null]);
      // One stored session again, as it was before the confirm.
      final stored = proposalRevisionOf((await h.row(message)).budgetJson);
      for (final r in rows) {
        expect(proposalRevisionOf(r.draftJson), stored);
      }
      // Read back from the database: open, with Log it offered again.
      final reopened = h.state.turns.single.cards.first;
      expect(reopened.resolution, CardResolution.open);
      expect(reopened.card.lifecycle, ProposalLifecycle.active);
      expect(reopened.card.canConfirm, isTrue);
      expect(reopened.card.lines, a.card.lines);
      expect(h.state.turns.single.cards.last.card.lines, b.card.lines);
      await h.thread.confirm(a.id);
      expect(
        h.state.turns.single.cards.first.resolution,
        CardResolution.logged,
      );
      expect(
        (await h.entries()).where((e) => e.deletedAt == null),
        hasLength(a.card.lines.length),
      );
      expect(await h.thread.undo(a.id), UndoOutcome.undone);

      // Discard, then Undo: the same.
      await h.thread.discard(b.id);
      final discarded = h.state.turns.single.cards.last;
      expect(discarded.resolution, CardResolution.discarded);
      expect(discarded.undoEntryId, isNotNull);
      expect((await h.proposal(b.id)).outcome, 'discarded');
      expect(await h.thread.restoreDiscarded(b.id), UndoOutcome.undone);
      final back = h.state.turns.single.cards.last;
      expect(back.resolution, CardResolution.open);
      expect(back.card.canConfirm, isTrue);
      expect((await h.proposal(b.id)).status, 'pending');
      // Pending again everywhere, one consistent stored session; the card
      // logged and undone logs again (its old entry IDs are diary
      // tombstones: the confirm gives it fresh ones in its change set).
      final rows2 = await h.proposals();
      expect(rows2.map((r) => r.status), ['pending', 'pending']);
      final revision = proposalRevisionOf((await h.row(message)).budgetJson);
      for (final r in rows2) {
        expect(proposalRevisionOf(r.draftJson), revision);
      }
      await h.thread.confirm(a.id);
      expect(
        h.state.turns.single.cards.first.resolution,
        CardResolution.logged,
      );
      expect(
        (await h.entries()).where((e) => e.deletedAt == null),
        hasLength(a.card.lines.length),
      );
    },
  );

  // rule: A23 undo-drains
  test('A23 undo after an unflushed sibling edit is refused and keeps the '
      'edit', () async {
    final h = await twoPersonalCards();
    final [a, b] = h.state.turns.single.cards;
    await h.thread.confirm(a.id);
    // Adjusted after the confirm, not flushed yet.
    final line = h.state.turns.single.cards.last.card.lines.single.entry.id;
    h.thread.setAmount(b.id, line, Quantity(321, 'g'));
    expect(await h.thread.undo(a.id), UndoOutcome.conflict);
    final cards = h.state.turns.single.cards;
    expect(cards.first.resolution, CardResolution.logged);
    expect(cards.last.card.lines.single.entry.amount.input, Quantity(321, 'g'));
    expect((await h.proposal(a.id)).status, 'confirmed');
    final stored = (await h.restorer.session(
      h.state.turns.single.assistantMessageId!,
      referenceTime: h.state.turns.single.message.time,
    )).value!;
    expect(
      stored.cards.last.lines.single.entry.amount.input,
      Quantity(321, 'g'),
    );
  });

  // rule: A23 undo-busy
  test(
    'A23 a sibling takes no edit while an undo of its session is pending',
    () async {
      final h = await twoPersonalCards();
      final [a, b] = h.state.turns.single.cards;
      await h.thread.confirm(a.id);
      final line = h.state.turns.single.cards.last.card.lines.single.entry.id;
      h.thread.setAmount(b.id, line, Quantity(150, 'g'));
      // Hold the pending write so the undo waits behind it in the lane.
      final gate = Completer<void>();
      h.beforeApply = (set) => gate.future;
      final flushing = h.thread.flush();
      await pumpEventQueue();
      final undoing = h.thread.undo(a.id);
      await pumpEventQueue();
      // An edit now would be lost to the reopened session: it's not taken.
      h.thread.setAmount(b.id, line, Quantity(999, 'g'));
      expect(
        h.state.turns.single.cards.last.card.lines.single.entry.amount.input,
        Quantity(150, 'g'),
      );
      gate.complete();
      h.beforeApply = null;
      await flushing;
      // The flushed sibling edit makes the undo refuse; the edit is kept.
      expect(await undoing, UndoOutcome.conflict);
      expect(
        h.state.turns.single.cards.first.resolution,
        CardResolution.logged,
      );
      expect(
        h.state.turns.single.cards.last.card.lines.single.entry.amount.input,
        Quantity(150, 'g'),
      );
      // Afterwards the sibling is editable again.
      h.thread.setAmount(b.id, line, Quantity(200, 'g'));
      expect(
        h.state.turns.single.cards.last.card.lines.single.entry.amount.input,
        Quantity(200, 'g'),
      );
    },
  );

  // rule: A23 undo-busy-overlap
  test(
    'A23 overlapping undos keep the session locked until the last one',
    () async {
      final h = BuddyHarness();
      h.answer(
        BuddyHarness.personalMeals(
          await h.personalFood(),
          slots: ['breakfast', 'lunch', 'dinner'],
        ),
      );
      await h.thread.send('my food three times', texts);
      final [a, b, c] = h.state.turns.single.cards;
      await h.thread.confirm(a.id);
      // B's confirm rewrites A's row: A's undo will conflict, B's won't.
      await h.thread.confirm(b.id);
      final line = c.card.lines.single.entry.id;
      Quantity amount() =>
          h.state.turns.single.cards.last.card.lines.single.entry.amount.input;
      final before = amount();
      final undoA = h.thread.undo(a.id);
      final undoB = h.thread.undo(b.id);
      expect(await undoA, UndoOutcome.conflict);
      // B's undo is still pending: C takes no edit it could overwrite.
      h.thread.setAmount(c.id, line, Quantity(999, 'g'));
      expect(amount(), before);
      expect(await undoB, UndoOutcome.undone);
      expect(amount(), before);
      expect(h.state.turns.single.cards[1].resolution, CardResolution.open);
      // Unlocked after the last one.
      h.thread.setAmount(c.id, line, Quantity(250, 'g'));
      expect(amount(), Quantity(250, 'g'));
    },
  );

  // rule: A23 undo-busy-success
  test(
    'A23 a sibling takes no edit while a successful undo is mid-way',
    () async {
      final h = await twoPersonalCards();
      final [a, b] = h.state.turns.single.cards;
      await h.thread.confirm(a.id);
      // Another message's adjustment is pending: the undo's own drain writes
      // it, and is held there (inside the undo, before its revert).
      h.answer(
        BuddyHarness.personalMeals(await h.personalFood(), slots: ['dinner']),
      );
      await h.thread.send('another food', texts);
      final d = h.state.turns.last.cards.single;
      h.thread.setAmount(d.id, d.card.lines.single.entry.id, Quantity(60, 'g'));
      final gate = Completer<void>();
      var held = false;
      h.beforeApply = (set) {
        held = true;
        return gate.future;
      };
      final undoing = h.thread.undo(a.id);
      await pumpEventQueue();
      expect(held, isTrue);
      final line = b.card.lines.single.entry.id;
      h.thread.setAmount(b.id, line, Quantity(999, 'g'));
      gate.complete();
      h.beforeApply = null;
      expect(await undoing, UndoOutcome.undone);
      final cards = h.state.turns.first.cards;
      expect(cards.first.resolution, CardResolution.open);
      expect(
        cards.last.card.lines.single.entry.amount.input,
        b.card.lines.single.entry.amount.input,
      );
      h.thread.setAmount(b.id, line, Quantity(250, 'g'));
      expect(
        h.state.turns.first.cards.last.card.lines.single.entry.amount.input,
        Quantity(250, 'g'),
      );
    },
  );

  // rule: A23 undo-busy-revert
  test(
    'A23 a sibling takes no edit while a successful undo is reverting',
    () async {
      final h = await twoPersonalCards();
      final [a, b] = h.state.turns.single.cards;
      await h.thread.confirm(a.id);
      // Held in the undo's own revert, after its drain.
      final gate = Completer<void>();
      var reverting = false;
      h.beforeRevert = () {
        reverting = true;
        return gate.future;
      };
      final undoing = h.thread.undo(a.id);
      await pumpEventQueue();
      expect(reverting, isTrue);
      final line = b.card.lines.single.entry.id;
      Quantity amountB() =>
          h.state.turns.single.cards.last.card.lines.single.entry.amount.input;
      final before = amountB();
      h.thread.setAmount(b.id, line, Quantity(999, 'g'));
      expect(amountB(), before);
      gate.complete();
      h.beforeRevert = null;
      expect(await undoing, UndoOutcome.undone);
      expect(h.state.turns.single.cards.first.resolution, CardResolution.open);
      // Nothing was taken while it ran; afterwards the edit is accepted.
      expect(amountB(), before);
      h.thread.setAmount(b.id, line, Quantity(250, 'g'));
      expect(amountB(), Quantity(250, 'g'));
    },
  );

  // rule: A23 undo-stale-lane
  test("A23 an older generation's undo never drains the new generation's "
      'edits', () async {
    final h = await twoPersonalCards();
    // Past the first frame: a new generation restores on its own.
    await h.thread.ensureRestored(0);
    final [a, b] = h.state.turns.single.cards;
    await h.thread.confirm(a.id);
    // Block the old lane with another message's pending write, queue the
    // undo behind it.
    h.answer(
      BuddyHarness.personalMeals(await h.personalFood(), slots: ['dinner']),
    );
    await h.thread.send('another food', texts);
    final d = h.state.turns.last.cards.single;
    h.thread.setAmount(d.id, d.card.lines.single.entry.id, Quantity(60, 'g'));
    final gate = Completer<void>();
    var first = true;
    h.beforeApply = (set) async {
      if (first) {
        first = false;
        await gate.future;
      }
    };
    final flushing = h.thread.flush();
    await pumpEventQueue();
    final old = h.thread.undo(a.id);
    await pumpEventQueue();
    // A switch; the new generation edits b (a pending write of its own).
    h.container.read(profileGenerationProvider.notifier).bump();
    expect(h.state.turns, isEmpty);
    await pumpEventQueue();
    final nb = h.state.turns.first.cards.firstWhere((c) => c.id == b.id);
    h.thread.setAmount(b.id, nb.card.lines.single.entry.id, Quantity(77, 'g'));
    gate.complete();
    await flushing;
    expect(await old, isNull);
    // The new generation's edit is still pending and is written by its
    // flush.
    await h.thread.flush();
    final stored = (await h.restorer.session(
      nb.card.budgetMessageId,
      referenceTime: h.state.turns.first.message.time,
    )).value!;
    expect(
      stored.cards
          .firstWhere((c) => c.id == b.id)
          .lines
          .single
          .entry
          .amount
          .input,
      Quantity(77, 'g'),
    );
    h.beforeApply = null;
  });

  // rule: A23 undo-lock-generation
  test(
    'A23 an undo from an older generation never releases a newer lock',
    () async {
      final h = BuddyHarness();
      h.answer(
        BuddyHarness.personalMeals(
          await h.personalFood(),
          slots: ['breakfast', 'lunch', 'dinner'],
        ),
      );
      await h.thread.send('my food three times', texts);
      await h.thread.ensureRestored(0);
      final [a, b, c] = h.state.turns.single.cards;
      final line = b.card.lines.single.entry.id;
      Quantity amountB() =>
          h.state.turns.single.cards[1].card.lines.single.entry.amount.input;
      // Each gate holds the next write that arrives.
      final gates = <Completer<void>>[];
      h.beforeApply = (set) async {
        if (gates.isNotEmpty) await gates.removeAt(0).future;
      };
      await h.thread.confirm(a.id);
      // Generation 0: an undo held in its drain (a pending edit of b).
      h.thread.setAmount(b.id, line, Quantity(150, 'g'));
      final oldGate = Completer<void>();
      gates.add(oldGate);
      final old = h.thread.undo(a.id);
      await pumpEventQueue();
      // A profile switch; the new generation reads the same message back.
      h.container.read(profileGenerationProvider.notifier).bump();
      expect(h.state.turns, isEmpty);
      await pumpEventQueue();
      expect(h.state.turns.single.cards, hasLength(3));
      // Generation 1: discard c, then its undo held in its drain too.
      await h.thread.discard(c.id);
      h.thread.setAmount(b.id, line, Quantity(160, 'g'));
      final newGate = Completer<void>();
      gates.add(newGate);
      final current = h.thread.restoreDiscarded(c.id);
      await pumpEventQueue();
      // The old undo finishes: no throw, and the new lock still holds.
      oldGate.complete();
      expect(await old, isNull);
      h.thread.setAmount(b.id, line, Quantity(999, 'g'));
      expect(amountB(), Quantity(160, 'g'));
      newGate.complete();
      await current;
      expect(amountB(), Quantity(160, 'g'));
      h.beforeApply = null;
    },
  );

  // rule: A23 resolve-rebase
  test(
    'A23 a sibling edited while a confirm is being written keeps both',
    () async {
      final h = await twoPersonalCards();
      final [a, b] = h.state.turns.single.cards;
      final gate = Completer<void>();
      h.beforeApply = (set) async {
        if (set.origin == Origin.proposal(a.id)) await gate.future;
      };
      final confirming = h.thread.confirm(a.id);
      await pumpEventQueue();
      h.thread.setAmount(b.id, b.card.lines.single.entry.id, Quantity(77, 'g'));
      gate.complete();
      await confirming;
      h.beforeApply = null;
      final [ra, rb] = h.state.turns.single.cards;
      expect(ra.resolution, CardResolution.logged);
      expect(ra.card.lifecycle, ProposalLifecycle.confirmed);
      expect(rb.card.lines.single.entry.amount.input, Quantity(77, 'g'));
      await h.thread.flush();
      expect((await h.proposal(a.id)).status, 'confirmed');
      final stored = (await h.restorer.session(
        h.state.turns.single.assistantMessageId!,
        referenceTime: h.state.turns.single.message.time,
      )).value!;
      expect(stored.cards.first.lifecycle, ProposalLifecycle.confirmed);
      expect(
        stored.cards.last.lines.single.entry.amount.input,
        Quantity(77, 'g'),
      );
    },
  );

  // rule: A23 undo-crash-safe
  test('A23 a card undone then reopened after a restart logs again', () async {
    final h = await twoPersonalCards();
    final a = h.state.turns.single.cards.first;
    await h.thread.confirm(a.id);
    expect(await h.thread.undo(a.id), UndoOutcome.undone);
    // Killed right after the undo: nothing else was written.
    h.restart();
    await h.thread.ensureRestored(0);
    final back = h.state.turns.single.cards.first;
    expect(back.card.canConfirm, isTrue);
    expect(
      back.card.lines.map((l) => l.entry.id),
      a.card.lines.map((l) => l.entry.id),
    );
    await h.thread.confirm(a.id);
    expect(h.state.turns.single.cards.first.resolution, CardResolution.logged);
    final live = (await h.entries()).where((e) => e.deletedAt == null);
    expect(live, hasLength(a.card.lines.length));
    expect(
      live.map((e) => e.id).toSet().intersection({
        for (final l in a.card.lines) l.entry.id,
      }),
      isEmpty,
    );
    // A card whose entries are live is never logged twice that way.
    final second = await h.resolution.confirm(
      a.session,
      a.id,
      CardOrigin(
        interpretation: h.state.turns.single.interpretation!,
        messageId: h.state.turns.single.assistantMessageId!,
        referenceTime: h.state.turns.single.message.time,
      ),
    );
    expect(second, isA<CardNotLogged>());
  });

  // rule: A23 restored-ids
  test('A23 confirming a restored card reuses its stored entry IDs', () async {
    final h = await twoPersonalCards();
    final turn = h.state.turns.single;
    final [a, _] = turn.cards;
    final message = turn.assistantMessageId!;
    // Two independent sessions read back from the same rows (a restart, a
    // second phone's copy).
    final one = (await h.restorer.session(
      message,
      referenceTime: turn.message.time,
    )).value!;
    final two = (await h.restorer.session(
      message,
      referenceTime: turn.message.time,
    )).value!;
    final ids = [
      for (final l in one.cards.firstWhere((c) => c.id == a.id).lines)
        l.entry.id,
    ];
    expect(ids, [for (final l in a.card.lines) l.entry.id]);
    final origin = CardOrigin(
      interpretation: turn.interpretation!,
      messageId: message,
      referenceTime: turn.message.time,
    );
    final first = await h.resolution.confirm(one, a.id, origin);
    expect(first, isA<CardLogged>());
    final applied = h.applied.length;
    final second = await h.resolution.confirm(two, a.id, origin);
    expect(second, isA<CardNotLogged>());
    // The second insert of the same entry IDs was rejected, never logged.
    expect(h.applied, hasLength(applied + 1));
    expect(
      (await h.entries()).map((e) => e.id).toList()..sort(),
      [...ids]..sort(),
    );
  });

  // rule: A23 rebuild-new-message
  test('A23 a rejected confirm rebuild moves the card to a new assistant '
      'message', () async {
    final h = BuddyHarness();
    final key = await h.personalFood();
    h.answer(BuddyHarness.personalMeals(key));
    await h.thread.send('my food twice', texts);
    final turn = h.state.turns.single;
    final m = turn.assistantMessageId!;
    final [a, b] = turn.cards;
    // The food changed after the cards were built.
    await h.applier.apply(
      ChangeSet([
        UpdatePersonalFood(key, 1, _food(300)),
      ], origin: Origin.direct),
    );
    await h.thread.confirm(a.id);
    expect(await h.entries(), isEmpty);
    final rebuilt = h.state.turns.single.cards.first;
    expect(rebuilt.resolution, CardResolution.open);
    expect(rebuilt.rebuilt, isTrue);
    final mPrime = rebuilt.card.budgetMessageId;
    expect(mPrime, isNot(m));
    expect(rebuilt.card.originMessageId, m);
    expect(rebuilt.origin!.messageId, mPrime);
    // M′: an assistant row with no reply-to, the fixed text, the answer.
    final row = await h.row(mPrime);
    expect(row.role, 'assistant');
    expect(row.replyToMessageId, isNull);
    expect(row.messageText, BuddyReplyTexts.cardRebuiltRecord);
    expect(row.answerJson, isNotNull);
    expect(row.budgetJson, isNotNull);
    // The card bound to M′; M lists it departed and keeps its sibling, each
    // session at one revision; both restore.
    final card = await h.proposal(a.id);
    expect(card.budgetMessageId, mPrime);
    expect(card.originMessageId, m);
    expect(
      proposalRevisionOf(card.draftJson),
      proposalRevisionOf(row.budgetJson),
    );
    final budget = jsonDecode((await h.row(m)).budgetJson!) as Map;
    expect(budget['cards'], [b.id]);
    expect(budget['departed'], [a.id]);
    expect(
      proposalRevisionOf((await h.proposal(b.id)).draftJson),
      budget['revision'],
    );
    expect(h.state.membership.departedFrom(m), {a.id});
    expect(h.state.membership.isFollowUp(mPrime), isFalse);
    for (final message in [m, mPrime]) {
      final restored = await h.restorer.session(
        message,
        referenceTime: turn.message.time,
      );
      expect(restored.issue, isNull);
    }
    // Logged with the current facts; a fact rebuild alone isn't an
    // adjustment (rec R3).
    await h.thread.confirm(a.id);
    expect((await h.entries()).single.kcal, 300);
    expect((await h.proposal(a.id)).outcome, 'unchanged');
  });

  // rule: A22 pending-not-written
  test('AI-036 nothing from a pending card reaches the diary', () async {
    final h = await twoCards();
    final card = h.state.turns.single.cards.first;
    final dimensions = card.card.lines.expand((l) => l.dimensions);
    for (final d in dimensions) {
      h.thread.adjust(card.id, ProposalSelect(d.id, d.options.last.id));
    }
    expect(await h.entries(), isEmpty);
    // Only the transcript and the pending card rows (A23), never the diary.
    expect(
      (await h.db.select(h.db.syncOutbox).get()).map((r) => r.entity).toSet(),
      {'chatMessage', 'proposal'},
    );
  });

  // rule: A22 discard
  test('AI-037 discard removes the card and logs nothing', () async {
    final h = await twoCards();
    final card = h.state.turns.single.cards.first;
    final before = h.applied.length;
    await h.thread.discard(card.id);
    // One change set: the card's resolution, no diary op (A23).
    expect(h.applied.length, before + 1);
    expect(h.applied.last.ops.whereType<DiaryOp>(), isEmpty);
    expect(await h.entries(), isEmpty);
    final discarded = h.state.turns.single.cards.first;
    expect(discarded.resolution, CardResolution.discarded);
    expect(discarded.card.lifecycle, ProposalLifecycle.discarded);
    await h.thread.confirm(card.id);
    expect(h.applied.length, before + 1);
    // A contributor's discard ops make it one change set.
    final c = await twoCards();
    final contributor = TestContributor(discard: [c.settingOp('discard')]);
    c.contributors.add(contributor);
    await c.thread.discard(c.state.turns.single.cards.first.id);
    expect(contributor.calls, ['discard']);
    expect(await c.db.select(c.db.settingsKv).get(), hasLength(1));
    // A failing one leaves the card open.
    final f = await twoCards();
    f.contributors.add(TestContributor(discard: [BuddyHarness.failingOp()]));
    await f.thread.discard(f.state.turns.single.cards.first.id);
    expect(f.state.turns.single.cards.first.resolution, CardResolution.open);
  });

  // rule: A22 preview-after-confirm
  test('A22 sibling preview counts a confirmed card once through confirmed '
      'intake', () async {
    final h = await twoCards();
    final [a, b] = h.state.turns.single.cards;
    final kcal = a.card.totals.kcal;
    final before = b.card.preview.eaten!.kcal;
    expect(before, closeTo(b.card.totals.kcal, 1e-6));
    await h.thread.confirm(a.id);
    final lunch = h.state.turns.single.cards[1].card;
    expect(lunch.preview.eaten!.kcal, closeTo(before + kcal, 1e-6));
    // Undo takes it out of confirmed intake again.
    await h.thread.undo(a.id);
    expect(
      h.state.turns.single.cards[1].card.preview.eaten!.kcal,
      closeTo(before, 1e-6),
    );
  });

  // rule: A22 rebuild-on-fact-change
  test('A22 rejected confirm rebuilds the card only for fact or slot '
      'changes', () async {
    expect(
      ProposalResolution.isFactChange(
        const VersionConflict(
          entity: 'personalFood',
          id: 'x',
          expected: 1,
          actual: 2,
        ),
      ),
      isTrue,
    );
    for (final failure in <ChangeFailure>[
      const RowNotFound(entity: 'personalFood', id: 'x'),
      const RowNotFound(entity: 'mealSlot', id: 'x'),
      const InvalidOp('unknownSlot'),
      const InvalidOp('inactiveSlot'),
      const InvalidOp('noSlot'),
    ]) {
      expect(
        ProposalResolution.isFactChange(failure),
        isTrue,
        reason: '$failure',
      );
    }
    for (final failure in <ChangeFailure>[
      const ConstraintViolation('duplicateId'),
      const VersionConflict(
        entity: 'diaryEntry',
        id: 'x',
        expected: 1,
        actual: 2,
      ),
      const InvalidOp('futureDate'),
      const RowNotFound(entity: 'dishGroup', id: 'x'),
    ]) {
      expect(
        ProposalResolution.isFactChange(failure),
        isFalse,
        reason: '$failure',
      );
    }

    // A personal food edited after the card was built: rebuilt, nothing
    // written, then the rebuilt card logs.
    final h = BuddyHarness();
    const key = '019a1b2c-0000-7000-8000-000000001234';
    final created = await h.applier.apply(
      ChangeSet([CreatePersonalFood(key, _food(100))], origin: Origin.direct),
    );
    expect(created, isA<Applied>());
    h.answer(
      message([
        intent([
          item(
            match: food(key: key, source: 'personal'),
            amount: 100,
            unit: 'g',
          ),
        ], slot: 'breakfast'),
      ]),
    );
    await h.thread.send('my food', texts);
    final card = h.state.turns.single.cards.single;
    expect(card.card.canConfirm, isTrue);
    await h.applier.apply(
      ChangeSet([
        UpdatePersonalFood(key, 1, _food(300)),
      ], origin: Origin.direct),
    );
    await h.thread.confirm(card.id);
    expect(await h.entries(), isEmpty);
    final rebuilt = h.state.turns.single.cards.single;
    expect(rebuilt.id, card.id);
    expect(rebuilt.resolution, CardResolution.open);
    expect(rebuilt.couldNotLog, isFalse);
    expect(rebuilt.card.lines.single.snapshot.kcal, 300);
    await h.thread.confirm(card.id);
    expect((await h.entries()).single.kcal, 300);

    // A duplicate ID is never rebuilt: fixed copy, nothing written.
    final d = await twoCards();
    final first = d.state.turns.single.cards.first;
    await d.applier.apply(
      ChangeSet(first.card.draftOps, origin: Origin.direct),
    );
    final entries = (await d.entries()).length;
    await d.thread.confirm(first.id);
    expect((await d.entries()).length, entries);
    final failed = d.state.turns.single.cards.first;
    expect(failed.resolution, CardResolution.open);
    expect(failed.couldNotLog, isTrue);
    // Not rebuilt: the same lines (the session itself may have been
    // refreshed for the diary change).
    expect(failed.card.lines, first.card.lines);
  });

  // rule: A22 stale-totals
  test('A22 a diary change made elsewhere refreshes open cards and the '
      'logged summary', () async {
    final h = BuddyHarness()..answer(twoMeals());
    await h.thread.send('2 eggs', texts);
    final [breakfast, lunch] = h.state.turns.single.cards;
    expect(breakfast.card.preview.eaten!.kcal, 72);
    // Elsewhere (the sheet closed): 72 kcal logged by hand, not by Buddy.
    expect(
      await h.applier.apply(
        ChangeSet(lunch.card.draftOps, origin: Origin.direct),
      ),
      isA<Applied>(),
    );
    await pumpEventQueue();
    BuddyCard card() =>
        h.state.turns.single.cards.firstWhere((c) => c.id == breakfast.id);
    expect(card().card.preview.eaten!.kcal, 144);
    // Log it: the one-line summary is the day as it is now.
    await h.thread.confirm(breakfast.id);
    expect(card().resolution, CardResolution.logged);
    expect(card().logged!.preview.eaten!.kcal, 144);
    expect(card().logged!.kcal, 72);
  });

  // rule: A22 logged-despite-refresh
  test('A22 a logged card stays logged with its Undo when the refresh after '
      'the write fails', () async {
    final h = BuddyHarness()..answer(message());
    await h.thread.send('2 eggs', texts);
    final cardId = h.state.turns.single.cards.single.id;
    // The write succeeds; reading the fresh context afterwards throws.
    h.configThrows = true;
    await h.thread.confirm(cardId);
    final card = h.state.turns.single.cards.single;
    expect(await h.entries(), hasLength(1));
    expect(card.resolution, CardResolution.logged);
    expect(card.couldNotLog, isFalse);
    expect(card.undoEntryId, isNotNull);
    expect(h.issues, contains(isA<BuddyRefreshFailed>()));
    // The Undo window starts when the change set was applied.
    expect(card.logged!.loggedAt, h.undo.entries.single.appliedAt);
    // And Undo still works.
    h.configThrows = false;
    expect(await h.thread.undo(cardId), UndoOutcome.undone);
    expect((await h.entries()).where((e) => e.deletedAt == null), isEmpty);
  });
}
