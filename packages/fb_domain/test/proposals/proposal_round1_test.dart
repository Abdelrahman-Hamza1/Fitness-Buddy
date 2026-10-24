import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

import 'proposal_fixtures.dart';
import 'proposal_rebuild_test.dart' show follow;
import 'proposal_recompute_test.dart' show update;

void main() {
  test(
    'AI-044 compatible target time and slot edits follow moved intent indices',
    () {
      final ids = FixedIds();
      var s = session(
        message([
          intent([item()], slot: 'breakfast'),
          intent([item()], slot: 'dinner'),
        ]),
        ids: ids,
      );
      final when = context().referenceTime.onDate(
        context().referenceTime.localDate.plusDays(-2),
      );
      s = update(
        s,
        ProposalSetWhen(
          s.cards.last.id,
          time: when,
          slotId: DefaultSlots.lunch.id,
        ),
      ).session;
      final rebuilt = ProposalEngine.rebuild(
        s.cards.last,
        follow(
          message([
            intent([item()]),
          ]),
          ids,
        ),
      ).value!.session;
      expect(rebuilt.cards.single.preview.date, when.localDate);
      expect(
        rebuilt.cards.single.lines.single.entry.slotId,
        DefaultSlots.lunch.id,
      );
    },
  );
  // rule: A21 projected-environment-consistency
  test(
    'A21 card environments merge shared yield facts and reject conflicts',
    () {
      final ctx = context(
        defaults: {'state:rice': 'dry'},
        yields: [
          YieldFactor(group: 'rice', from: .dry, to: .cooked, factor: 2.8),
        ],
      );
      final s = session(
        message([
          intent([riceItem()], slot: 'breakfast'),
          intent([riceItem()], slot: 'dinner'),
        ]),
        ctx: ctx,
      );
      final rows = [
        for (final c in s.cards) ProposalDraftCodec.encodeCard(s, c.id),
      ];
      final budget = ProposalDraftCodec.encodeMessageBudget(s);
      expect(
        ProposalDraftCodec.restore(
          trustedFacts: trustedSession(s, ctx: ctx),
          budget,
          rows,
          context: ctx,
        ).value,
        s,
      );
      final env = rows.last['environment']! as List;
      ((env[3] as List).single as List)[3] = 3.0;
      expect(
        ProposalDraftCodec.restore(
          trustedFacts: trustedSession(s, ctx: ctx),
          budget,
          rows,
          context: ctx,
        ).issue,
        ProposalIssue.budgetConflict,
      );
    },
  );

  // rule: A21 catalog-alias
  test('A21 trusted dish aliases resolve to concrete facts '
      'and dimension identities', () {
    final f = localFood(key: 'ref:dish/chicken', source: .reference);
    final raw = food(key: 'ref:dish', source: 'reference');
    final r = build(
      message([
        intent([
          item(
            match: raw,
            dimensions: [
              dimension('variant', [option('chicken', candidate: raw)]),
            ],
          ),
        ]),
      ]),
      facts: ProposalFacts(
        catalog: {f.key: f},
        catalogAliases: {'ref:dish': f.key},
        packAvailable: true,
      ),
    );
    expect(r.issue, isNull);
    expect(r.value!.cards.single.lines.single.entry.food.ref.id, f.key);
  });

  // rule: A21 public-validation
  test('A21 public invalid ranges expose a fixed public exception', () {
    expect(
      () => ProposalRange(nutrients(2), nutrients(1)),
      throwsA(
        predicate<Object>(
          (e) => e.toString() == 'ProposalInputException(invalidInput)',
        ),
      ),
    );
  });
  // rule: A21 public-validation
  test(
    'A21 public servings reject nonpositive nonfinite and invalid bounds',
    () {
      for (final amount in [0.0, -1.0, double.nan, double.infinity]) {
        expect(
          () => ProposalServing('cup', amount, .per100g, null, null),
          throwsException,
        );
      }
      expect(
        () => ProposalServing('cup', 10, .per100g, 11, 12),
        throwsException,
      );
      expect(
        () => ProposalServing('cup', 10, .per100g, 1, null),
        throwsException,
      );
    },
  );
  // rule: A21 public-validation
  test(
    'A21 decoder translates nutrient constructor errors into fixed issues',
    () {
      final raw = food()..['nutrients'] = n(-1);
      expect(
        InterpretationDecoder.decode(
          message([
            intent([item(match: raw)]),
          ]),
          ProposalFacts(),
        ).issue,
        ProposalIssue.invalidInput,
      );
    },
  );
  // rule: A21 target-weight
  test('A21 absent weight makes target preview unavailable', () {
    final date = context().referenceTime.localDate;
    final ctx = ProposalContext(
      referenceTime: context().referenceTime,
      slots: context().slots,
      dayContext: ProposalDayContext(
        today: date,
        confirmed: {date: Nutrients.zero},
        history: TargetSettingsHistory([
          TargetSettings(
            id: '019a1b2c-0000-7000-8000-000000007777',
            version: 1,
            effectiveFrom: date,
            standard: TargetPlan(baseKcal: 2000, floorKcal: 1200),
          ),
        ]),
      ),
    );
    expect(
      session(message(), ctx: ctx).cards.single.preview.targetsUnavailable,
      isTrue,
    );
  });

  test('FD-060 adjusted cooked state supersedes stated dry with yield 2.8', () {
    final rice = riceItem();
    ((rice['dimensions']! as List<Object?>).first!
            as Map<String, Object?>)['statedValue'] =
        'dry';
    final s = session(
      message([
        intent([rice]),
      ]),
      ctx: context(
        yields: [
          YieldFactor(group: 'rice', from: .dry, to: .cooked, factor: 2.8),
        ],
      ),
    );
    final d = s.cards.single.lines.single.dimensions.single;
    final line = update(
      s,
      ProposalSelect(d.id, d.options.last.id),
    ).session.cards.single.lines.single;
    expect(line.entry.amount.amount, 200);
    expect(line.snapshot.kcal, 260);
    expect(line.yieldNote, isNull);
  });
  test('AI-040 newer fat selection replaces generated oil amount override', () {
    final s = session(
      message([
        intent([
          item(dimensions: [fatDimension()]),
        ]),
      ]),
    );
    final d = s.cards.single.lines.first.dimensions.single;
    final selected = update(s, ProposalSelect(d.id, d.options[1].id)).session;
    final edited = update(
      selected,
      ProposalSetAmount(
        selected.cards.single.lines.last.entry.id,
        Quantity(2, 'tsp'),
      ),
    ).session;
    final next = update(
      edited,
      ProposalSelect(d.id, d.options.last.id),
    ).session;
    expect(
      next.cards.single.lines.first.chips.single.optionId,
      d.options.last.id,
    );
    expect(
      next.cards.single.lines.last.entry.amount.input,
      Quantity(1, 'tbsp'),
    );
    expect(next.cards.single.lines.last.snapshot.kcal, 119.34);
  });
  test('AI-044 stated follow-up fat replaces generated oil override', () {
    final ids = FixedIds();
    final s = session(
      message([
        intent([
          item(dimensions: [fatDimension()]),
        ]),
      ]),
      ids: ids,
    );
    final d = s.cards.single.lines.first.dimensions.single;
    final selected = update(s, ProposalSelect(d.id, d.options[1].id)).session;
    final edited = update(
      selected,
      ProposalSetAmount(
        selected.cards.single.lines.last.entry.id,
        Quantity(2, 'tsp'),
      ),
    ).session;
    final fat = dimension('fat', [
      option('oil', candidate: oilFood(), amount: 1, unit: 'tbsp'),
    ], stated: 'oil');
    final next = ProposalEngine.rebuild(
      edited.cards.single,
      follow(
        message([
          intent([
            item(dimensions: [fat]),
          ]),
        ]),
        ids,
      ),
    ).value!.session;
    expect(
      next.cards.single.lines.last.entry.amount.input,
      Quantity(1, 'tbsp'),
    );
    expect(next.cards.single.lines.last.snapshot.kcal, 119.34);
  });
  test(
    'AI-022 coalesced intents contain exactly one explicit oil contribution',
    () {
      final fat = fatDimension()..['statedValue'] = 'oil';
      final s = session(
        message([
          intent([
            item(dimensions: [fat]),
          ]),
          intent([item(match: oilFood(), unit: 'tbsp')]),
        ]),
      );
      expect(s.cards, hasLength(1));
      expect(
        s.cards.single.lines.where((l) => l.entry.food.ref.id == 'usda:oil'),
        hasLength(1),
      );
      expect(s.cards.single.totals.kcal, 191.34);
    },
  );
  test('AI-044 rebuilding second card cannot inherit sibling time or slot', () {
    final ids = FixedIds();
    var s = session(
      message([
        intent([item()], slot: 'breakfast'),
        intent([item()], slot: 'dinner'),
      ]),
      ids: ids,
    );
    s = update(
      s,
      ProposalSetWhen(
        s.cards.first.id,
        time: context().referenceTime.onDate(
          context().referenceTime.localDate.plusDays(-3),
        ),
        slotId: DefaultSlots.lunch.id,
      ),
    ).session;
    final next = ProposalEngine.rebuild(
      s.cards.last,
      follow(
        message([
          intent([item()], slot: 'dinner'),
        ]),
        ids,
      ),
    ).value!.session;
    expect(next.cards.single.lines.single.entry.slotId, DefaultSlots.dinner.id);
    expect(next.cards.single.preview.date, context().referenceTime.localDate);
  });
  test('AI-044 newly stated time and slot supersede retained target edits', () {
    final ids = FixedIds();
    var s = session(
      message([
        intent([item()]),
      ]),
      ids: ids,
    );
    s = update(
      s,
      ProposalSetWhen(
        s.cards.single.id,
        time: context().referenceTime.onDate(
          context().referenceTime.localDate.plusDays(-3),
        ),
        slotId: DefaultSlots.lunch.id,
      ),
    ).session;
    final next = ProposalEngine.rebuild(
      s.cards.single,
      follow(
        message([
          intent([item()], slot: 'dinner', time: 'yesterday'),
        ]),
        ids,
      ),
    ).value!.session;
    expect(next.cards.single.lines.single.entry.slotId, DefaultSlots.dinner.id);
    expect(
      next.cards.single.preview.date,
      context().referenceTime.localDate.plusDays(-1),
    );
  });
  test(
    'AI-044 rebuilding second dish retains target group rather than sibling',
    () {
      final ids = FixedIds();
      var s = session(
        message([
          intent([item()], slot: 'breakfast', group: 'first'),
          intent([item()], slot: 'dinner', group: 'second'),
        ]),
        ids: ids,
      );
      final targetGroup = s.cards.last.lines.single.entry.dishGroupId;
      s = update(s, ProposalSetLifecycle(s.cards.first.id, .confirmed)).session;
      final next = ProposalEngine.rebuild(
        s.cards.last,
        follow(
          message([
            intent([item()], slot: 'dinner', group: 'second'),
          ]),
          ids,
        ),
      ).value!.session;
      expect(next.cards.single.lines.single.entry.dishGroupId, targetGroup);
    },
  );
  // rule: A21 exact-personal-snapshot
  test('A21 mixed personal versions keep exact guards through restore', () {
    const key = '019a1b2c-0000-7000-8000-000000001234';
    final one = localFood(key: key, source: .yours, personalVersion: 1);
    var s = session(
      message([
        intent([
          item(
            match: food(key: key, source: 'personal'),
          ),
          item(
            match: food(key: key, source: 'personal'),
          ),
        ]),
      ]),
      facts: ProposalFacts(personal: {key: one}),
    );
    s = update(
      s,
      ProposalSwap(
        s.cards.single.lines.last.entry.id,
        localFood(key: key, source: .yours, personalVersion: 2, kcal: 300),
      ),
    ).session;
    final restored = ProposalDraftCodec.restore(
      trustedFacts: trustedSession(s, ctx: context()),
      ProposalDraftCodec.encodeMessageBudget(s),
      [ProposalDraftCodec.encodeCard(s, s.cards.single.id)],
      context: context(),
    ).value!;
    expect(restored.cards.single.issues, contains(ProposalIssue.staleFacts));
  });
  // rule: A21 restore-trust-boundary
  test('A21 forged personal snapshot with current version is rejected', () {
    const key = '019a1b2c-0000-7000-8000-000000001234';
    final s = session(
      message([
        intent([
          item(
            match: food(key: key, source: 'personal'),
          ),
        ]),
      ]),
      facts: ProposalFacts(
        personal: {
          key: localFood(key: key, source: .yours, personalVersion: 1),
        },
      ),
    );
    final row = ProposalDraftCodec.encodeCard(s, s.cards.single.id);
    (((row['foods']! as List).first as List)[5] as List)[0] = 999.0;
    final result = ProposalDraftCodec.restore(
      trustedFacts: trustedSession(s, ctx: context()),
      ProposalDraftCodec.encodeMessageBudget(s),
      [row],
      context: context(),
    );
    expect(result.issue, isNull);
    expect(
      result.value!.cards.single.issues,
      contains(ProposalIssue.factsMismatch),
    );
    expect(result.value!.cards.single.canConfirm, isFalse);
  });
  // rule: A21 card-context-minimization
  test(
    'A21 card projection omits unrelated slot metadata defaults and choices',
    () {
      final base = context();
      final s = session(
        message(),
        ctx: ProposalContext(
          referenceTime: base.referenceTime,
          slots: [
            ...base.slots,
            MealSlot(
              id: '019a1b2c-0000-7000-8000-000000007123',
              sortOrder: 99,
              name: 'private routine',
              window: TimeWindow(1, 2),
            ),
          ],
          savedDefaults: {'state:private-food': 'private-preference'},
          choices: {'9/0/0': 'private-choice'},
        ),
      );
      final row = ProposalDraftCodec.encodeCard(s, s.cards.single.id);
      expect(row.toString(), isNot(contains('private')));
    },
  );
  // rule: A21 source-consistency
  test(
    'A21 cross-source key collision returns factsMismatch without throwing',
    () {
      const key = '019a1b2c-0000-7000-8000-000000001234';
      final result = build(
        message([
          intent([
            item(match: food(key: key)),
            item(
              match: food(key: key, source: 'personal'),
            ),
          ]),
        ]),
        facts: ProposalFacts(
          personal: {
            key: localFood(key: key, source: .yours, personalVersion: 1),
          },
        ),
      );
      expect(result.issue, ProposalIssue.factsMismatch);
    },
  );
  // rule: A21 preview-completeness
  test('A21 missing confirmed date makes intake preview unavailable', () {
    final base = context();
    var s = session(
      message(),
      ctx: ProposalContext(
        referenceTime: base.referenceTime,
        slots: base.slots,
        dayContext: ProposalDayContext(
          today: base.referenceTime.localDate,
          confirmed: {base.referenceTime.localDate: nutrients(500)},
        ),
      ),
    );
    s = update(
      s,
      ProposalSetWhen(
        s.cards.single.id,
        time: base.referenceTime.onDate(
          base.referenceTime.localDate.plusDays(-3),
        ),
      ),
    ).session;
    expect(s.cards.single.preview.remainingKcal, isNull);
    // A missing date must not masquerade as confirmed zero intake.
    expect(s.cards.single.preview.eaten, isNull);
  });
}
