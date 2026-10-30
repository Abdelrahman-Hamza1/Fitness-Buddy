import 'package:fb_mobile/features/buddy/application/buddy_thread_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/buddy_harness.dart';

void main() {
  // rule: A22b discard-undo
  test('AI-037 discard can be undone and writes nothing', () async {
    final h = BuddyHarness()..answer(twoMeals());
    await h.thread.send('an egg for breakfast and one for lunch', texts);
    final writes = h.applied.length;
    final lunch = h.state.turns.single.cards.last;
    await h.thread.discard(lunch.id);
    final discarded = h.state.turns.single.cards.last;
    expect(discarded.resolution, CardResolution.discarded);
    expect(discarded.discardedFrom, isNotNull);
    await h.thread.restoreDiscarded(lunch.id);
    final back = h.state.turns.single.cards.last;
    expect(back.resolution, CardResolution.open);
    expect(back.card.lines, lunch.card.lines);
    expect(back.card.canConfirm, isTrue);
    expect(h.applied, hasLength(writes));
    // It can be logged as usual afterwards.
    await h.thread.confirm(lunch.id);
    expect(h.state.turns.single.cards.last.resolution, CardResolution.logged);
  });

  test(
    'A22 discard is not undoable once a contributor writes on discard',
    () async {
      final h = BuddyHarness()..answer(twoMeals());
      h.contributors.add(TestContributor());
      await h.thread.send('an egg for breakfast and one for lunch', texts);
      final lunch = h.state.turns.single.cards.last;
      await h.thread.discard(lunch.id);
      final discarded = h.state.turns.single.cards.last;
      expect(discarded.resolution, CardResolution.discarded);
      expect(discarded.discardedFrom, isNull);
      await h.thread.restoreDiscarded(lunch.id);
      expect(
        h.state.turns.single.cards.last.resolution,
        CardResolution.discarded,
      );
    },
  );
}
