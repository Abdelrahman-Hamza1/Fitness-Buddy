import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/buddy/application/buddy_thread_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/buddy_harness.dart';

void main() {
  // rule: A22b discard-undo
  test('AI-037 discard can be undone and the card opens again', () async {
    final h = BuddyHarness()..answer(twoMeals());
    await h.thread.send('an egg for breakfast and one for lunch', texts);
    final writes = h.applied.length;
    final lunch = h.state.turns.single.cards.last;
    await h.thread.discard(lunch.id);
    final discarded = h.state.turns.single.cards.last;
    expect(discarded.resolution, CardResolution.discarded);
    // A23 D10: one undoable change set, no diary op.
    expect(discarded.undoEntryId, isNotNull);
    expect(h.applied, hasLength(writes + 1));
    expect(h.applied.last.ops.whereType<DiaryOp>(), isEmpty);
    expect((await h.proposal(lunch.id)).status, 'discarded');
    expect(await h.thread.restoreDiscarded(lunch.id), UndoOutcome.undone);
    final back = h.state.turns.single.cards.last;
    expect(back.resolution, CardResolution.open);
    expect(back.card.lines, lunch.card.lines);
    expect(back.card.canConfirm, isTrue);
    expect((await h.proposal(lunch.id)).status, 'pending');
    expect(await h.entries(), isEmpty);
    // It can be logged as usual afterwards.
    await h.thread.confirm(lunch.id);
    expect(h.state.turns.single.cards.last.resolution, CardResolution.logged);
  });

  test('A23 a discard nobody writes has no undo', () async {
    final h = BuddyHarness()..answer(twoMeals());
    h.contributors.clear();
    await h.thread.send('an egg for breakfast and one for lunch', texts);
    final writes = h.applied.length;
    final lunch = h.state.turns.single.cards.last;
    await h.thread.discard(lunch.id);
    final discarded = h.state.turns.single.cards.last;
    expect(discarded.resolution, CardResolution.discarded);
    expect(discarded.undoEntryId, isNull);
    expect(h.applied, hasLength(writes));
    expect(await h.thread.restoreDiscarded(lunch.id), isNull);
    expect(
      h.state.turns.single.cards.last.resolution,
      CardResolution.discarded,
    );
  });
}
