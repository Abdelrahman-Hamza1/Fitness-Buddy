import 'dart:async';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/account/profile_generation.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/buddy/application/buddy_issues.dart';
import 'package:fb_mobile/features/buddy/application/buddy_thread_controller.dart';
import 'package:fb_mobile/features/buddy/application/proposal_resolution.dart';
import 'package:fb_mobile/features/buddy/presentation/cards/proposal_labels.dart';
import 'package:fb_mobile/l10n/gen/app_localizations.dart';
import 'package:flutter/widgets.dart' show Locale;
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

  // rule: A62 D15 logged line provenance
  test('A62 D15 an ordinary card logged after a meal estimate: the logged '
      'kcal has no "~", the day figure has "~"', () async {
    final h = BuddyHarness()..answer(message());
    await h.thread.send('2 eggs', texts);
    expect(
      await h.applier.apply(
        ChangeSet([
          LogEntries([
            NewDiaryEntry(
              id: h.ids.next(),
              when: EntryWhen.at(EntryTime.now(h.clock)),
              slotId: DefaultSlots.breakfastId,
              food: const UserEstimate(kcal: 500).food(),
              amount: UserEstimate.amount,
            ),
          ]),
        ], origin: Origin.direct),
      ),
      isA<Applied>(),
    );
    await pumpEventQueue();
    final cardId = h.state.turns.single.cards.single.id;
    await h.thread.confirm(cardId);
    final card = h.state.turns.single.cards.single;
    final logged = card.logged!;
    expect(logged.preview.intake!.estimated, isTrue);
    final l10n = lookupAppLocalizations(const Locale('en'));
    final kcal = DisplayRounding.kcal(logged.kcal).toString();
    final text = loggedText(l10n, logged.kcal, logged.preview);
    expect(text, isNot(contains(l10n.approx(kcal))));
    expect(text, contains(l10n.approx('')));
  });
}
