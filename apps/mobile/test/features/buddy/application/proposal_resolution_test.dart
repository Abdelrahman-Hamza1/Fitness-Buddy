import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/buddy/application/buddy_issues.dart';
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
      expect(set.ops, a.card.draftOps);
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
    expect(undone.resolution, CardResolution.undone);
    expect(undone.undoEntryId, isNull);
    // A second undo is a no-op; nothing else is reverted.
    expect(await h.thread.undo(card.id), isNull);
    expect(h.undo.entries, isEmpty);
  });

  // rule: A22 no-log-after-undo
  test('A22 log it after undo is not offered', () async {
    final h = await twoCards();
    final card = h.state.turns.single.cards.first;
    await h.thread.confirm(card.id);
    await h.thread.undo(card.id);
    final applied = h.applied.length;
    await h.thread.confirm(card.id);
    expect(h.applied.length, applied);
    final undone = h.state.turns.single.cards.first;
    expect(undone.resolution, CardResolution.undone);
    expect(undone.card.canConfirm, isFalse);
    expect((await h.entries()).where((e) => e.deletedAt == null), isEmpty);
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
    expect(
      (await h.db.select(h.db.syncOutbox).get()).map((r) => r.entity).toSet(),
      {'chatMessage'},
    );
  });

  // rule: A22 discard
  test('AI-037 discard removes the card and logs nothing', () async {
    final h = await twoCards();
    final card = h.state.turns.single.cards.first;
    final before = h.applied.length;
    await h.thread.discard(card.id);
    expect(h.applied.length, before);
    expect(await h.entries(), isEmpty);
    final discarded = h.state.turns.single.cards.first;
    expect(discarded.resolution, CardResolution.discarded);
    expect(discarded.card.lifecycle, ProposalLifecycle.discarded);
    await h.thread.confirm(card.id);
    expect(h.applied.length, before);
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
