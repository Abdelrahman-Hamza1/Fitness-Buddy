import 'package:fb_mobile/features/buddy/buddy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/buddy_harness.dart';

void main() {
  test('AI-045 HM-004 A57 T-B1 the pending count streams the number of open '
      'Buddy cards, of any kind', () async {
    final h = BuddyHarness()
      ..answer(
        message([
          intent([item()], slot: 'breakfast'),
          intent([item()], slot: 'lunch'),
        ]),
      );
    final container = ProviderContainer(
      overrides: [
        proposalRepositoryProvider.overrideWithValue(ProposalRepository(h.db)),
      ],
    );
    addTearDown(container.dispose);
    final seen = <int>[];
    final sub = container.listen(
      pendingProposalCountProvider,
      (_, next) => next.whenData(seen.add),
      fireImmediately: true,
    );
    addTearDown(sub.close);
    await pumpEventQueue();
    expect(seen.last, 0);

    await h.thread.send('two meals', texts);
    await pumpEventQueue();
    expect(seen.last, 2);

    final [first, _] = h.state.turns.single.cards;
    await h.thread.confirm(first.id);
    await pumpEventQueue();
    expect(seen.last, 1);
    // Equal counts in a row are not re-emitted.
    expect(seen, [0, 2, 1]);
  });
}
