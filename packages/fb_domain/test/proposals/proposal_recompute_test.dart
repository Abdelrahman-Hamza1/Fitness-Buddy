import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

import 'proposal_fixtures.dart';

ProposalUpdate update(
  ProposalSession s,
  ProposalAdjustment a, {
  ProposalContext? ctx,
}) {
  final r = ProposalEngine.recompute(s, a, context: ctx);
  expect(r.issue, isNull);
  return r.value!;
}

ProposalItem decodedItem(Map<String, Object?> value) =>
    InterpretationDecoder.decode(
      message([
        intent([value]),
      ]),
      ProposalFacts(),
    ).value!.intents.single.items.single;

void valueChecks(Object value, Object equal) {
  expect(value, equal);
  expect(value.hashCode, equal.hashCode);
  expect(value.toString(), contains('redacted'));
}

class BadIds implements ProposalIdSource {
  @override
  String next() => throw ArgumentError('private input');
}

void main() {
  test('AI-040 amount and unit edits recompute from original food facts', () {
    final ids = FixedIds();
    final s = session(message(), ids: ids);
    final id = s.cards.single.lines.single.entry.id;
    final u = update(s, ProposalSetAmount(id, Quantity(100, 'g')));
    expect(u.session.cards.single.totals.kcal, 144);
    final v = update(u.session, ProposalSetAmount(id, Quantity(2, 'piece')));
    expect(v.session.cards.single.totals.kcal, 144);
    expect(ids.calls, 3);
    expect(
      update(
        s,
        ProposalSetAmount(id, Quantity(1, 'ml')),
      ).session.cards.single.canConfirm,
      isTrue,
    );
  });
  test(
    'AI-041 swap uses distinct alternatives or supplied search facts offline',
    () {
      final s = session(
        message([
          intent([riceItem()]),
        ]),
      );
      final line = s.cards.single.lines.single;
      final alternative = decodedItem(riceItem()).alternatives.single;
      final u = update(s, ProposalSwap(line.entry.id, alternative));
      expect(u.session.cards.single.totals.kcal, 260);
      expect(u.diff.changedDimensionIds, isNotEmpty);
      final v = update(u.session, ProposalSwap(line.entry.id, localFood()));
      expect(v.session.cards.single.totals.kcal, 400);
      expect(
        ProposalEngine.recompute(
          s,
          ProposalSwap(line.entry.id, localFood(key: '', source: .yours)),
        ).issue,
        ProposalIssue.invalidInput,
      );
    },
  );
  test('AI-042 add remove restore and generated oil preserve stable IDs', () {
    final s = session(
      message([
        intent([
          item(dimensions: [fatDimension()]),
        ]),
      ]),
    );
    final card = s.cards.single;
    final d = card.lines.first.dimensions.single;
    final withOil = update(s, ProposalSelect(d.id, d.options.last.id)).session;
    expect(withOil.cards.single.lines, hasLength(2));
    final removed = update(
      withOil,
      ProposalSetRemoved(card.lines.first.entry.id, removed: true),
    ).session;
    final restored = update(
      removed,
      ProposalSetRemoved(card.lines.first.entry.id, removed: false),
    ).session;
    expect(restored, withOil);
    final ids = FixedIds()..calls = 100;
    final add = ProposalAdd(card.id, 'add-1', decodedItem(item()), ids);
    final added = update(restored, add).session;
    expect(added.cards.single.lines, hasLength(3));
    expect(update(added, add).diff.isEmpty, isTrue);
    expect(ids.calls, 102);
    expect(
      ProposalEngine.recompute(
        added,
        ProposalAdd(card.id, 'add-1', decodedItem(item(amount: 2)), ids),
      ).issue,
      ProposalIssue.invalidInput,
    );
    expect(
      ProposalEngine.recompute(
        s,
        const ProposalSetRemoved('bad', removed: true),
      ).issue,
      ProposalIssue.invalidInput,
    );
  });
  test('AI-043 explicit time and slot win over deterministic fallback', () {
    final s = session(message());
    final card = s.cards.single;
    final time = EntryTime(DateTime.utc(2026, 10, 16, 20), 0);
    final u = update(
      s,
      ProposalSetWhen(card.id, time: time, slotId: DefaultSlots.dinner.id),
    );
    final line = u.session.cards.single.lines.single;
    expect(u.session.cards.single.id, card.id);
    expect(line.entry.when, EntryWhen.at(time));
    expect(line.entry.slotId, DefaultSlots.dinner.id);
    expect(
      u.diff.lineFields[line.entry.id],
      containsAll([ProposalField.time, ProposalField.slot]),
    );
    expect(
      ProposalEngine.recompute(
        s,
        ProposalSetWhen(card.id, slotId: 'bad'),
      ).issue,
      ProposalIssue.invalidInput,
    );
  });
  test('AI-043 unrecognised time hint falls back visibly and stays '
      'confirmable', () {
    final s = session(
      message([
        intent([item()], time: 'ba3d shway'),
      ]),
    );
    expect(s.cards.single.canConfirm, isTrue);
    expect(
      s.cards.single.lines.single.chips.last.dimensionId,
      endsWith('/timeSlot'),
    );
    expect(
      s.cards.single.lines.single.entry.when,
      EntryWhen.at(context().referenceTime),
    );
  });
  // rule: A21 normalized-slots
  test('A21 exact normalized slot matches resolve but arbitrary Arabic Arabizi '
      'hints fall back', () {
    final s = session(
      message([
        intent([item()], slot: '  DINNER  '),
      ]),
    );
    expect(s.cards.single.lines.single.entry.slotId, DefaultSlots.dinner.id);
    expect(s.cards.single.lines.single.chips, isEmpty);
    final unknown = session(
      message([
        intent([item()], slot: 'بعد شوي'),
      ]),
    );
    expect(unknown.cards.single.lines.single.chips, isNotEmpty);
  });
  // rule: A21 diff
  test('A21 diff identifies only changed lines fields questions totals and '
      'day preview', () {
    final s = session(
      message([
        intent([item(), riceItem()]),
      ]),
    );
    final id = s.cards.single.lines.first.entry.id;
    final u = update(s, ProposalSetAmount(id, Quantity(2, 'piece')));
    expect(u.diff.lineFields.keys, [id]);
    expect(u.diff.lineFields[id], {
      ProposalField.amount,
      ProposalField.nutrients,
    });
    expect(u.diff.cardFields[s.cards.single.id], {
      ProposalField.totals,
      ProposalField.dayPreview,
    });
    expect(u.diff.addedLineIds, isEmpty);
    expect(u.diff.removedLineIds, isEmpty);
    expect(u.diff.changedQuestionIds, isEmpty);
    expect(u.diff.toString(), 'ProposalDiff(redacted)');
  });
  // rule: A21 idempotence
  test('A21 identical adjustment produces empty diff', () {
    final s = session(message());
    final edit = ProposalSetAmount(
      s.cards.single.lines.single.entry.id,
      Quantity(2, 'piece'),
    );
    final once = update(s, edit).session;
    final twice = update(once, edit);
    expect(twice.diff.isEmpty, isTrue);
    expect(twice.session, once);
    expect(twice.session.hashCode, once.hashCode);
  });
  // rule: A21 canonical-recompute
  test('A21 selecting the same option does not compound yields or shares', () {
    final s = session(
      message([
        intent([riceItem()]),
      ]),
    );
    final d = s.cards.single.lines.single.dimensions.single;
    final edit = ProposalSelect(d.id, d.options.last.id);
    final once = update(s, edit).session;
    expect(update(once, edit).session, once);
    expect(
      ProposalEngine.recompute(s, ProposalSelect(d.id, 'bad')).issue,
      ProposalIssue.invalidInput,
    );
  });
  // rule: A21 readiness
  test('A21 removed all items cannot confirm and restoring recovers draft', () {
    final s = session(t01());
    var removed = s;
    for (final l in s.cards.single.lines) {
      removed = update(
        removed,
        ProposalSetRemoved(l.entry.id, removed: true),
      ).session;
    }
    expect(removed.cards.single.canConfirm, isFalse);
    for (final l in s.cards.single.lines) {
      removed = update(
        removed,
        ProposalSetRemoved(l.entry.id, removed: false),
      ).session;
    }
    expect(removed, s);
  });
  // rule: A21 immutable-values
  test(
    'A21 edits and diffs have immutable value equality and fixed failures',
    () {
      final s = session(message());
      final id = s.cards.single.lines.single.entry.id;
      final cardId = s.cards.single.id;
      final amount = ProposalSetAmount(id, Quantity(2, 'piece'));
      final food = localFood();
      final input = decodedItem(item());
      final ids = FixedIds()..calls = 100;
      final edits = <ProposalAdjustment>[
        amount,
        const ProposalSelect('dim', 'option'),
        ProposalSwap(id, food),
        ProposalSetRemoved(id, removed: true),
        ProposalAdd(cardId, 'token', input, ids),
        ProposalSetWhen(cardId, time: context().referenceTime),
        ProposalSetLifecycle(cardId, .discarded),
      ];
      for (final edit in edits) {
        valueChecks(edit, edit);
      }
      final a = update(s, amount);
      final b = update(s, amount);
      valueChecks(a, b);
      valueChecks(a.diff, b.diff);
      valueChecks(s.cards.single.preview, s.cards.single.preview);
      expect(a.diff.lineFields.clear, throwsUnsupportedError);
      expect(
        ProposalEngine.recompute(s, ProposalAdd(cardId, '', input, ids)).issue,
        ProposalIssue.invalidInput,
      );
      expect(
        ProposalEngine.recompute(
          s,
          const ProposalSetLifecycle('bad', .confirmed),
        ).issue,
        ProposalIssue.invalidInput,
      );
      expect(
        ProposalEngine.recompute(s, const ProposalSetWhen('bad')).issue,
        ProposalIssue.invalidInput,
      );
      expect(
        ProposalEngine.recompute(
          s,
          amount,
          context: ProposalContext(
            referenceTime: context().referenceTime,
            slots: const [],
          ),
        ).issue,
        ProposalIssue.needsConversion,
      );
    },
  );
  // rule: A21 portion-edit
  test('A21 explicit amount clears the portion choice and estimate', () {
    final raw = item(
      explicit: false,
      dimensions: [
        dimension('portion', [
          option('small', amount: 1, unit: 'piece'),
          option('large', amount: 3, unit: 'piece'),
        ]),
      ],
    );
    final s = session(
      message([
        intent([raw]),
      ]),
    );
    final d = s.cards.single.lines.single.dimensions.single;
    final chosen = update(s, ProposalSelect(d.id, d.options.last.id)).session;
    final u = update(
      chosen,
      ProposalSetAmount(
        chosen.cards.single.lines.single.entry.id,
        Quantity(100, 'g'),
      ),
    );
    expect(u.session.cards.single.totals.kcal, 144);
    expect(u.diff.lineFields.values.single, contains(ProposalField.estimate));
    final swapped = update(
      s,
      ProposalSwap(
        s.cards.single.lines.single.entry.id,
        localFood(source: .reference),
      ),
    );
    expect(
      swapped.diff.lineFields.values.single,
      contains(ProposalField.source),
    );
  });
  // rule: A21 source-guard
  test(
    'A21 personal guard resolves through frozen alternatives and components',
    () {
      const key = '019a1b2c-0000-7000-8000-000000001234';
      final personal = localFood(key: key, source: .yours, personalVersion: 2);
      final rice = riceItem();
      (rice['dimensions']! as List<Object?>).add(fatDimension());
      final s = session(
        message([
          intent([
            rice,
            item(
              match: food(key: key, source: 'personal'),
            ),
          ]),
        ]),
        facts: ProposalFacts(personal: {key: personal}),
      );
      expect(s.cards.single.draftOps.first, isA<RequirePersonalFood>());
      final edit = ProposalAdd(
        s.cards.single.id,
        'bad',
        decodedItem(item()),
        BadIds(),
      );
      expect(
        ProposalEngine.recompute(s, edit).issue,
        ProposalIssue.invalidInput,
      );
      expect(s.cards.single.preview.hashCode, isA<int>());
    },
  );
}
