import 'dart:async';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/account/profile_generation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/buddy_harness.dart';

void main() {
  // rule: A23 generation-drop
  test('A23 restore and persistence results from an older profile generation '
      'are dropped', () async {
    final h = BuddyHarness();
    final key = await h.personalFood();
    h.answer(BuddyHarness.personalMeals(key));
    await h.thread.send('my food', texts);
    await h.thread.ensureRestored(0);
    final [a, b] = h.state.turns.single.cards;
    void bump() => h.container.read(profileGenerationProvider.notifier).bump();

    // A confirm in flight across a switch: its completion never reaches the
    // new profile's thread.
    final gate = Completer<void>();
    h.beforeApply = (set) async {
      if (set.origin == Origin.proposal(a.id)) await gate.future;
    };
    final confirming = h.thread.confirm(a.id);
    await pumpEventQueue();
    bump();
    gate.complete();
    await confirming;
    h.beforeApply = null;
    expect(h.state.turns, isEmpty, reason: 'the late confirm is dropped');
    await pumpEventQueue();
    // The new generation restored this profile's stored cards on its own.
    expect(h.state.turns, isNotEmpty);
    expect(h.state.turns.every((t) => t.profileGeneration == 1), isTrue);
    // An old generation's restore does nothing now.
    final turns = h.state.turns;
    await h.thread.ensureRestored(0);
    expect(identical(h.state.turns, turns), isTrue);

    // A coalesced write scheduled before a switch isn't written after it.
    final open = h.state.turns.single.cards.firstWhere((c) => c.id == b.id);
    h.thread.setAmount(
      b.id,
      open.card.lines.single.entry.id,
      Quantity(321, 'g'),
    );
    final draft = (await h.proposal(b.id)).draftJson;
    final writes = h.applied.length;
    bump();
    await h.thread.flush();
    expect(h.applied, hasLength(writes));
    expect((await h.proposal(b.id)).draftJson, draft);

    // A card logged before a switch can't be undone from the new thread.
    await pumpEventQueue();
    final card = h.state.turns.single.cards.firstWhere((c) => c.id == b.id);
    await h.thread.confirm(card.id);
    expect((await h.proposal(b.id)).status, 'confirmed');
    bump();
    await pumpEventQueue();
    expect(await h.thread.undo(b.id), isNull);
    expect((await h.proposal(b.id)).status, 'confirmed');
  });
}
