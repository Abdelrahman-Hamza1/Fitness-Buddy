import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/buddy/application/buddy_thread_controller.dart';
import 'package:fb_mobile/features/buddy/buddy.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/buddy_harness.dart';

void main() {
  // rule: A23 outcomes-for-a26
  test('A23 confirmed adjusted and discarded outcomes remain available to '
      'A26', () async {
    final h = BuddyHarness()
      ..answer(
        message([
          intent([item()], slot: 'breakfast'),
          intent([item()], slot: 'lunch'),
          intent([item()], slot: 'dinner'),
          intent([item()], slot: 'snacks'),
        ]),
      );
    await h.thread.send('four meals', texts);
    final [unchanged, adjusted, discarded, pending] =
        h.state.turns.single.cards;
    final start = h.clock.nowUtc();
    await h.thread.confirm(unchanged.id);
    h.thread.adjust(
      adjusted.id,
      ProposalSetAmount(
        adjusted.card.lines.single.entry.id,
        Quantity(2, 'piece'),
      ),
    );
    await h.thread.confirm(adjusted.id);
    await h.thread.discard(discarded.id);
    expect(h.state.turns.single.cards.map((c) => c.resolution), [
      CardResolution.logged,
      CardResolution.logged,
      CardResolution.discarded,
      CardResolution.open,
    ]);

    final repo = ProposalRepository(h.db);
    final resolved = await repo.resolved();
    expect(resolved.map((r) => r.id).toSet(), {
      unchanged.id,
      adjusted.id,
      discarded.id,
    });
    ProposalRecord of(String id) => resolved.singleWhere((r) => r.id == id);
    expect(of(unchanged.id).status, ProposalStatus.confirmed);
    expect(of(unchanged.id).outcome, ProposalOutcome.unchanged);
    expect(of(adjusted.id).status, ProposalStatus.confirmed);
    expect(of(adjusted.id).outcome, ProposalOutcome.adjusted);
    expect(of(discarded.id).status, ProposalStatus.discarded);
    expect(of(discarded.id).outcome, ProposalOutcome.discarded);
    for (final r in resolved) {
      expect(r.resolvedAt, isNotNull);
      expect(r.isPending, isFalse);
    }
    // Never a pending card; `since` filters by the resolution time.
    expect(resolved.any((r) => r.id == pending.id), isFalse);
    expect(await repo.resolved(since: start), hasLength(3));
    expect(
      await repo.resolved(since: start.add(const Duration(minutes: 1))),
      isEmpty,
    );
    // The other queries.
    expect((await repo.pending()).map((r) => r.id), [pending.id]);
    expect(await repo.watchPending().first, hasLength(1));
    final m = h.state.turns.single.assistantMessageId!;
    expect(await repo.byBudgetMessage(m), hasLength(4));
    expect((await repo.byId(pending.id))!.isPending, isTrue);
    expect(await repo.byId(h.ids.next()), isNull);
    // Records are domain values with content-free text.
    expect('${of(adjusted.id)}', isNot(contains('foods')));
  });
}
