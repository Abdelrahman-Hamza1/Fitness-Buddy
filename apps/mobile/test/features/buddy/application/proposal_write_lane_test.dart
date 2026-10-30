import 'dart:async';
import 'dart:math';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/features/buddy/application/buddy_thread_controller.dart';
import 'package:fb_mobile/features/buddy/application/proposal_session_writer.dart';
import 'package:fb_mobile/features/buddy/application/proposal_write_lane.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/buddy_harness.dart';

/// A harness with a reply of personal-food cards for [slots].
Future<(BuddyHarness, String)> _cards({
  List<String> slots = const ['breakfast', 'lunch', 'dinner'],
}) async {
  final h = BuddyHarness();
  final key = await h.personalFood();
  h.answer(BuddyHarness.personalMeals(key, slots: slots));
  await h.thread.send('my food', texts);
  expect(h.state.turns.single.cards, hasLength(slots.length));
  return (h, key);
}

/// Every stored assistant session restores (one revision across its budget
/// and members); returns how many were checked.
Future<int> _allRestore(BuddyHarness h, String reason) async {
  var checked = 0;
  for (final row in await h.chat()) {
    if (row.role != 'assistant' || row.budgetJson == null) continue;
    final result = await h.restorer.session(
      row.id,
      referenceTime: h.state.turns.first.message.time,
    );
    expect(result.issue, isNull, reason: '$reason: ${row.id}');
    checked++;
  }
  return checked;
}

int? _revision(String? json) => proposalRevisionOf(json);

void main() {
  // rule: A23 lane-serial
  test('A23 the write lane runs jobs one after another and survives a '
      'failing job', () async {
    final lane = ProposalWriteLane();
    final order = <int>[];
    final gate = Completer<void>();
    final first = lane.run(() async {
      await gate.future;
      order.add(1);
    });
    final failing = lane.run<void>(() async => throw StateError('x'));
    final third = lane.run(() async => order.add(3));
    gate.complete();
    await first;
    await expectLater(failing, throwsStateError);
    await third;
    expect(order, [1, 3]);
    // Coalesced: one pending write per message, latest wins.
    lane
      ..schedule('m')
      ..schedule('m');
    expect(lane.isPending('m'), isTrue);
    final written = <String>[];
    await lane.flush((m) async {
      written.add(m);
      return false;
    });
    expect(written, ['m']);
    expect(lane.isPending('m'), isFalse);
    expect('$lane', isNot(contains('m,')));
  });

  // rule: A23 stale-guard
  test('A23 a stale session write never overwrites a newer stored '
      'session', () async {
    final (h, _) = await _cards();
    final turn = h.state.turns.single;
    final m = turn.assistantMessageId!;
    final card = turn.cards.first;
    final line = card.card.lines.single.entry.id;
    h.thread.setAmount(card.id, line, Quantity(150, 'g'));
    final older = h.state.turns.single.cards.first.session;
    h.thread.setAmount(card.id, line, Quantity(250, 'g'));
    // Adjustments wait for a flush (no write per tap).
    final writes = h.applied.length;
    expect(h.applied, hasLength(writes));
    await h.thread.flush();
    expect(h.applied, hasLength(writes + 1));
    final stored = _revision((await h.row(m)).budgetJson);
    final draft = (await h.proposal(card.id)).draftJson;
    expect(
      stored,
      greaterThan(_revision(ProposalSessionWriter.budget(older))!),
    );
    // The older in-memory session is refused, nothing changes.
    expect(await h.resolution.persist(older, h.state.membership), isFalse);
    expect(_revision((await h.row(m)).budgetJson), stored);
    expect((await h.proposal(card.id)).draftJson, draft);
    // A second flush with nothing pending writes nothing.
    final tried = h.applied.length;
    await h.thread.flush();
    expect(h.applied, hasLength(tried));
    expect(await _allRestore(h, 'after flush'), 1);
    // The stored card has the latest amount.
    final restored = (await h.restorer.session(
      m,
      referenceTime: turn.message.time,
    )).value!;
    expect(
      restored.cards.first.lines.single.entry.amount.input,
      Quantity(250, 'g'),
    );
  });

  // rule: A23 sibling-confirms
  test('A23 sibling cards confirmed together keep both drafts', () async {
    final (h, _) = await _cards(slots: ['breakfast', 'lunch']);
    final turn = h.state.turns.single;
    final m = turn.assistantMessageId!;
    final [a, b] = turn.cards;
    h.thread
      ..setAmount(a.id, a.card.lines.single.entry.id, Quantity(120, 'g'))
      ..setAmount(b.id, b.card.lines.single.entry.id, Quantity(80, 'g'));
    // Both taps before either write lands.
    await Future.wait([h.thread.confirm(a.id), h.thread.confirm(b.id)]);
    final cards = h.state.turns.single.cards;
    expect(cards.map((c) => c.resolution), [
      CardResolution.logged,
      CardResolution.logged,
    ]);
    final ra = await h.proposal(a.id);
    final rb = await h.proposal(b.id);
    expect([ra.status, rb.status], ['confirmed', 'confirmed']);
    expect([ra.outcome, rb.outcome], ['adjusted', 'adjusted']);
    final entries = (await h.entries()).where((e) => e.deletedAt == null);
    expect(entries.map((e) => e.amount).toSet(), {120.0, 80.0});
    // One stored session: both rows and the budget at one revision.
    final revision = _revision((await h.row(m)).budgetJson);
    expect(_revision(ra.draftJson), revision);
    expect(_revision(rb.draftJson), revision);
    expect(await _allRestore(h, 'siblings'), 1);
  });

  // rule: A23 lane-property
  test('A23 adjustments persist the whole session latest wins', () async {
    // Seeded random sequences (no glados in the app package): any persisted
    // order of adjust, context refresh, confirm, discard, follow-up and
    // rebuild leaves every stored message session restorable.
    const steps = [
      'adjust',
      'refresh',
      'confirm',
      'discard',
      'followUp',
      'rebuild',
      'flush',
    ];
    final sequences = <List<String>>[
      ['refresh', 'followUp', 'confirm'],
      ['adjust', 'followUp', 'adjust', 'flush'],
      ['adjust', 'rebuild', 'adjust', 'discard'],
      for (var seed = 0; seed < 12; seed++)
        () {
          final random = Random(seed);
          return [
            for (var i = 0; i < 7; i++) steps[random.nextInt(steps.length)],
          ];
        }(),
    ];
    for (final (n, sequence) in sequences.indexed) {
      final random = Random(100 + n);
      final (h, key) = await _cards();
      var version = 1;
      List<BuddyCard> open() => [
        for (final t in h.state.turns)
          for (final c in t.cards)
            if (c.resolution == CardResolution.open) c,
      ];
      BuddyCard? pick() {
        final cards = open();
        return cards.isEmpty ? null : cards[random.nextInt(cards.length)];
      }

      for (final step in sequence) {
        final card = pick();
        switch (step) {
          case 'adjust':
            if (card == null || card.card.lines.isEmpty) break;
            h.thread.setAmount(
              card.id,
              card.card.lines.first.entry.id,
              Quantity(50.0 + random.nextInt(200), 'g'),
            );
          case 'refresh':
            // Logged by hand elsewhere (the card's own entries): open cards
            // refresh in memory only; that card can't be logged again.
            if (card == null || card.card.draftOps.isEmpty) break;
            await h.applier.apply(
              ChangeSet(card.card.draftOps, origin: Origin.direct),
            );
            await pumpEventQueue();
          case 'confirm':
            if (card != null) await h.thread.confirm(card.id);
          case 'discard':
            if (card != null) await h.thread.discard(card.id);
          case 'followUp':
            if (h.state.followUpCard == null) break;
            h.answer(
              message([
                intent([
                  item(
                    match: food(key: key, source: 'personal'),
                    amount: 20.0 + random.nextInt(300),
                    unit: 'g',
                  ),
                ]),
              ]),
            );
            await h.thread.send('make it more', texts);
          case 'rebuild':
            // The food changed: the next confirm rebuilds into its own
            // message.
            final updated = await h.applier.apply(
              ChangeSet([
                UpdatePersonalFood(
                  key,
                  version,
                  PersonalFoodDraft(
                    names: FoodNames('Private'),
                    per100: Nutrients(
                      kcal: 100.0 + version,
                      protein: 1,
                      carbs: 1,
                      fat: 1,
                      fiber: 0,
                    ),
                  ),
                ),
              ], origin: Origin.direct),
            );
            expect(updated, isA<Applied>(), reason: '$sequence');
            version++;
            await pumpEventQueue();
            if (card != null) await h.thread.confirm(card.id);
          case 'flush':
            await h.thread.flush();
        }
        await _allRestore(h, '$sequence after $step');
      }
      await h.thread.flush();
      expect(await _allRestore(h, '$sequence at the end'), greaterThan(0));
    }
  });
}
