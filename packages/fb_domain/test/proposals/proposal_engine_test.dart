import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

import 'proposal_codec_test.dart' show cardRows, roundTrip;
import 'proposal_fixtures.dart';

void main() {
  // rule: A22 date-hint
  test(
    'A22 engine prefers dateHint and falls back to a yesterday time hint',
    () {
      LocalDate dayOf(ProposalSession s) =>
          (s.cards.single.lines.single.entry.when as EntryAt).time.localDate;
      expect(
        dayOf(
          session(
            message([
              intent([item()], date: 'daysAgo:3'),
            ]),
          ),
        ),
        LocalDate(2026, 10, 14),
      );
      // The day grammar wins over a literal time hint.
      expect(
        dayOf(
          session(
            message([
              intent([item()], date: 'today', time: 'yesterday'),
            ]),
          ),
        ),
        LocalDate(2026, 10, 17),
      );
      expect(
        dayOf(
          session(
            message([
              intent([item()], time: 'yesterday'),
            ]),
          ),
        ),
        LocalDate(2026, 10, 16),
      );
      expect(
        dayOf(
          session(
            message([
              intent([item()], date: 'date:10-03'),
            ]),
          ),
        ),
        LocalDate(2026, 10, 3),
      );
    },
  );

  // rule: A22 date-hint
  test(
    'A22 a future or unparseable dateHint routes the intent unrecognized',
    () {
      for (final date in [
        'date:2026-10-18',
        'tomorrow',
        'daysAgo:1',
        // Outside the diary's reach: before the epoch, more than ten years.
        'date:1969-12-31',
        'daysAgo:3651',
      ]) {
        final s = session(
          message([
            intent([item()], date: date),
            intent([riceItem()]),
          ]),
        );
        expect(s.cards, hasLength(1), reason: date);
        expect(s.routing.map((i) => i.kind), ['unrecognized'], reason: date);
        expect(s.routing.single.items, isEmpty);
      }
    },
  );

  // rule: B09 decoder forward-compat
  test('B09 foodLog plus an unknown kind builds the card, routes unrecognized, '
      'leaves the question budget untouched and round-trips the codec', () {
    final foodOnly = session(
      message([
        intent([riceItem()]),
      ]),
    );
    final mixed = session(
      message([
        intent([riceItem()]),
        {
          'kind': 'savedMealLog',
          'language': 'en',
          'script': 'latin',
          'listRef': {'ref': 2},
        },
      ]),
    );
    expect(mixed.cards.length, 1);
    expect(mixed.cards, foodOnly.cards);
    expect(mixed.budget, foodOnly.budget);
    expect(mixed.budget.questions.length, 1);
    expect(mixed.routing.map((i) => (i.index, i.kind)), [(1, 'unrecognized')]);
    expect(mixed.routing.single.items, isEmpty);
    final restored = roundTrip(mixed);
    expect(restored.cards, mixed.cards);
    expect(restored.budget, mixed.budget);
    expect(cardRows(restored), cardRows(mixed));
  });
  test('AI-060 stated then saved then fallback resolves each dimension', () {
    final json = message([
      intent([riceItem()]),
    ]);
    expect(session(json).budget.questions.length, 1);
    final saved = session(
      json,
      ctx: context(defaults: {'state:rice': 'cooked'}),
    );
    expect(saved.cards.single.totals.kcal, 260);
    expect(saved.budget.questions, isEmpty);
    expect(
      saved.cards.single.lines.single.chips.single.origin,
      ProposalChoiceOrigin.savedDefault,
    );
    final chosen = session(
      json,
      ctx: context(
        defaults: {'state:rice': 'dry'},
        choices: {'0/0/0': '0/0/0/1'},
      ),
    );
    expect(chosen.cards.single.totals.kcal, 260);
    expect(
      chosen.cards.single.lines.single.chips.single.origin,
      ProposalChoiceOrigin.userAdjusted,
    );
    final stated = riceItem();
    (stated['dimensions']! as List<Object?>)[0] = dimension('state', [
      option(
        'dry',
        candidate: food(
          key: 'usda:rice_dry',
          kcal: 365,
          state: 'dry',
          group: 'rice',
        ),
      ),
      option(
        'cooked',
        candidate: food(key: 'usda:rice_cooked', kcal: 130, group: 'rice'),
      ),
    ], stated: 'cooked');
    expect(
      session(
        message([
          intent([stated]),
        ]),
        ctx: context(defaults: {'state:rice': 'dry'}),
      ).cards.single.totals.kcal,
      260,
    );
    expect(
      session(
        json,
        ctx: context(defaults: {'state:rice': 'absent'}),
      ).budget.questions.length,
      1,
    );
  });
  test(
    'AI-061 highest impact questions are selected across the whole message',
    () {
      final s = session(
        message([
          intent([riceItem()]),
          intent([riceItem(amount: 300)], slot: 'lunch'),
          intent([riceItem(amount: 400)], slot: 'dinner'),
        ]),
      );
      expect(s.cards.length, 3);
      expect(s.budget.questions.map((q) => q.dimensionId), ['2/0/0', '1/0/0']);
    },
  );
  test('AI-061 ties use stable input order and overflow becomes chips', () {
    final s = session(
      message([
        intent([riceItem(), riceItem(), riceItem()]),
      ]),
    );
    expect(s.budget.questions.map((q) => q.dimensionId), ['0/0/0', '0/1/0']);
    expect(s.cards.single.lines.every((l) => l.chips.isNotEmpty), isTrue);
  });
  test('FD-062 state mismatch converts amount once and records yield note', () {
    final cooked = food(key: 'usda:rice', kcal: 130, group: 'rice');
    final i = item(
      match: cooked,
      amount: 200,
      unit: 'g',
      dimensions: [
        dimension('state', [
          option('cooked', candidate: cooked),
        ], stated: 'dry'),
      ],
    );
    final s = session(
      message([
        intent([i]),
      ]),
      ctx: context(
        yields: [
          YieldFactor(group: 'rice', from: .dry, to: .cooked, factor: 2.5),
        ],
      ),
    );
    final line = s.cards.single.lines.single;
    expect(line.entry.amount.amount, 500);
    expect(line.snapshot.kcal, 650);
    expect(
      line.entry.food.provenance.assumptions,
      contains('a1:yield:dry:cooked:200.0:500.0'),
    );
    expect(line.yieldNote!.toAmount.grams, 500);
  });
  test('FD-060 missing yield or density never invents grams', () {
    final cooked = food(key: 'usda:rice', kcal: 130, group: 'rice');
    for (final i in [
      item(
        match: cooked,
        amount: 200,
        unit: 'g',
        dimensions: [
          dimension('state', [
            option('cooked', candidate: cooked),
          ], stated: 'dry'),
        ],
      ),
      item(match: food()..['densityGPerMl'] = null, amount: 100, unit: 'ml'),
      item(unit: 'unknown'),
    ]) {
      final card = session(
        message([
          intent([i]),
        ]),
      ).cards.single;
      expect(card.canConfirm, isFalse);
      expect(card.issues, [ProposalIssue.needsConversion]);
      expect(card.draftOps, isEmpty);
    }
  });
  test('FD-061 explicit oil is separate counted once and retention '
      'scales original amount', () {
    final s = session(
      message([
        intent([
          item(dimensions: [fatDimension()]),
          item(match: oilFood(), unit: 'tbsp'),
        ]),
      ]),
      facts: ProposalFacts(cookingFatIds: {'usda:oil'}),
    );
    expect(s.cards.single.lines.length, 2);
    expect(s.budget.questions, isEmpty);
    final i = item(
      match: oilFood(),
      unit: 'tbsp',
      dimensions: [
        dimension('oilRetention', [
          option('most', amount: .25, unit: 'fraction'),
        ], stated: 'most'),
      ],
    );
    final line = session(
      message([
        intent([i]),
      ]),
      facts: ProposalFacts(cookingFatIds: {'usda:oil'}),
    ).cards.single.lines.single;
    expect(
      line.snapshot.kcal,
      29.88,
    ); // 13.5*.25 -> stored 3.38 g -> 29.88 kcal.
    expect(line.entry.food.provenance.assumptions, contains('a1:oil:most'));
  });
  test('FD-061 prepared deep fried food does not get synthetic oil', () {
    final c = session(
      message([
        intent([item(match: food(state: 'fried'))]),
      ]),
    ).cards.single;
    expect(c.lines.length, 1);
    expect(c.lines.single.chips, isEmpty);
  });
  test('AI-101 explicit plate beats people and fractions are applied once', () {
    final mansaf = food(
      key: 'ref:mansaf',
      source: 'reference',
      kcal: 200,
      servings: [serving('plate', 400)],
    );
    final explicit = session(
      message([
        intent([
          item(
            match: mansaf,
            unit: 'plate',
            share: {'fraction': null, 'people': 6},
          ),
        ]),
      ]),
    ).cards.single;
    expect(explicit.totals.kcal, 800);
    final share = session(
      message([
        intent([
          item(
            match: mansaf,
            amount: 600,
            unit: 'g',
            explicit: false,
            share: {'fraction': null, 'people': 6},
          ),
        ]),
      ]),
    ).cards.single;
    expect(share.totals.kcal, 200);
    expect(
      share.lines.single.entry.food.provenance.assumptions,
      contains('a1:share:1/6'),
    );
    expect(
      session(
        message([
          intent([
            item(
              amount: 100,
              unit: 'g',
              explicit: false,
              share: {'fraction': .25, 'people': 6},
            ),
          ]),
        ]),
      ).cards.single.totals.kcal,
      36,
    );
  });
  test('AI-031 empty or unresolved card has no executable draft ops', () {
    expect(session(message([intent([])])).cards.single.canConfirm, isFalse);
    expect(
      build(message()..['model'] = null).issue,
      ProposalIssue.invalidInput,
    );
    final missing = ProposalContext(
      referenceTime: context().referenceTime,
      slots: [],
    );
    expect(build(message(), ctx: missing).issue, ProposalIssue.needsConversion);
    expect(
      build(message(), ids: _InvalidIds()).issue,
      ProposalIssue.invalidInput,
    );
  });
  test('AI-033 entry assumption codes are versioned canonical and '
      'contain no display text', () {
    final card = session(
      message([
        intent([riceItem()]),
      ]),
      ctx: context(defaults: {'state:rice': 'dry'}),
    ).cards.single;
    expect(card.lines.single.entry.food.provenance.assumptions, [
      'a1:origin:savedDefault',
    ]);
    expect(card.lines.single.toString(), isNot(contains('Synthetic')));
    expect(card.hashCode, isA<int>());
  });
  test('FD-061 explicit tablespoon of olive oil in cookingFatIds gets '
      'the retention chip', () {
    final ids = <String>{'usda:oil'};
    final facts = ProposalFacts(cookingFatIds: ids);
    ids.clear();
    final line = session(t01(), facts: facts).cards.single.lines.last;
    expect(line.chips.single.dimensionId, endsWith('oilRetention'));
    expect(line.chips.single.optionId, endsWith('/all'));
    expect(line.entry.food.provenance.assumptions, ['a1:oil:all']);
    expect(
      line.dimensions.single.options.map((o) => o.id),
      contains(line.chips.single.optionId),
    );
  });
  test(
    'FD-061 an explicit oil outside cookingFatIds has no chip and no question',
    () {
      final s = session(t01());
      expect(s.cards.single.lines.last.chips, isEmpty);
      expect(s.budget.questions, isEmpty);
      expect(s.cards.single.lines.last.snapshot.kcal, 119.34);
    },
  );
  test(
    'FD-061 an oil among the fat dimension options counts as a cooking fat',
    () {
      final s = session(
        message([
          intent([
            item(dimensions: [fatDimension()]),
            item(match: oilFood(), unit: 'tbsp'),
          ]),
        ]),
      );
      expect(s.cards.single.lines.length, 2);
      expect(s.cards.single.lines.last.chips.single.optionId, endsWith('/all'));
      expect(s.budget.questions, isEmpty);
    },
  );
  // rule: A21 safe-boundary and explicit environment
  test(
    'A21 build preserves personal guards and sanitizes primitive failures',
    () {
      const personal = '019a1b2c-0000-7000-8000-000000000050';
      final facts = ProposalFacts(
        personal: {
          personal: localFood(
            key: personal,
            source: .yours,
            personalVersion: 4,
          ),
        },
      );
      final s = session(
        message([
          intent([
            item(
              match: food(key: personal, source: 'personal'),
            ),
          ]),
        ]),
        facts: facts,
      );
      expect(s.cards.single.draftOps.first, isA<RequirePersonalFood>());
      expect(
        (s.cards.single.draftOps.first as RequirePersonalFood)
            .food
            .expectedVersion,
        4,
      );
      final before = session(
        message([
          intent([item()], time: 'yesterday'),
        ]),
      );
      expect(
        (before.cards.single.lines.single.entry.when as EntryAt).time.localDate,
        LocalDate(2026, 10, 16),
      );
      final duplicate = YieldFactor(
        group: 'rice',
        from: .dry,
        to: .cooked,
        factor: 2.5,
      );
      expect(
        build(message(), ctx: context(yields: [duplicate, duplicate])).issue,
        ProposalIssue.invalidInput,
      );
      final ctx = context();
      final request = ProposalRequest(
        interpretation: message(),
        messageId: 'bad-id',
        idSource: FixedIds(),
        context: ctx,
        facts: ProposalFacts(),
      );
      expect(ProposalEngine.build(request).issue, ProposalIssue.invalidInput);
      expect(ctx.toString(), 'ProposalContext(redacted)');
      expect(request.toString(), 'ProposalRequest(redacted)');
    },
  );
  test('FD-061 most oil option uses the visible policy constant', () {
    final facts = ProposalFacts(cookingFatIds: {'usda:oil'});
    final line = session(
      t01(),
      facts: facts,
      ctx: context(choices: {'0/1/oilRetention': 'most'}),
    ).cards.single.lines.last;
    expect(line.snapshot.kcal, 29.88);
    expect(
      line.dimensions.single.options.last.effect,
      const ProposalRetentionEffect(ProposalPolicyConstants.mostOilLeft),
    );
    expect(line.chips.single.origin, ProposalChoiceOrigin.userAdjusted);
    final all = session(
      t01(),
      facts: facts,
      ctx: context(choices: {'0/1/oilRetention': 'all'}),
    ).cards.single.lines.last;
    expect(all.snapshot.kcal, 119.34);
  });

  test(
    'AI-101 explicit amounts win over share dimensions without compounding',
    () {
      Map<String, Object?> shared({required bool explicit}) => item(
        amount: 100,
        unit: 'g',
        explicit: explicit,
        share: {'fraction': .25, 'people': 6},
        dimensions: [
          dimension('share', [option('half', amount: .5, unit: 'fraction')]),
        ],
      );
      expect(
        session(
          message([
            intent([shared(explicit: true)]),
          ]),
        ).cards.single.totals.kcal,
        144,
      );
      expect(
        session(
          message([
            intent([shared(explicit: false)]),
          ]),
        ).cards.single.totals.kcal,
        72,
      );
    },
  );
  test(
    'AQ-10 unmatched fallback computes midpoint with forced source and range',
    () {
      final i = item(amount: 50, unit: 'g')
        ..['match'] = null
        ..['estimate'] = {
          'range': {'low': n(100), 'high': n(200)},
          'reason': 'noMatch',
        };
      final line = session(
        message([
          intent([i]),
        ]),
      ).cards.single.lines.single;
      expect(line.snapshot.kcal, 75);
      expect(line.range, EstimateRange(50, 100));
      expect(line.entry.food.provenance.source, FoodSource.estimate);
      expect(line.entry.food.provenance.isEstimate, isTrue);
      expect(line.entry.food.names.en, 'Synthetic meal');
    },
  );

  // rule: A21 creation-time allocation
  test(
    'A21 ID source allocates at build add and unmatched rebuild lines only',
    () {
      // WP2 pins build allocation. WP3 adds add/unmatched-rebuild assertions.
      final ids = FixedIds();
      final s = session(t01(), ids: ids);
      expect(ids.calls, 6); // Card, group, two lines and two reserved oil IDs.
      s.cards.single.totals;
      s.cards.single.hashCode;
      expect(ids.calls, 6);
      expect(s, session(t01()));
    },
  );
  // rule: A22 default-answer
  test('A22 a question lists the assumed (fallback) answer first', () {
    final s = session(
      message([
        intent([
          riceItem(),
          item(dimensions: [fatDimension()]),
        ]),
      ]),
    );
    expect(s.budget.questions, hasLength(2));
    for (final question in s.budget.questions) {
      final chip = s.cards
          .expand((c) => c.lines)
          .expand((l) => l.chips)
          .singleWhere((c) => c.dimensionId == question.dimensionId);
      expect(chip.origin, ProposalChoiceOrigin.fallback);
      expect(question.optionIds.first, chip.optionId);
    }
  });
}

final class _InvalidIds extends FixedIds {
  @override
  String next() => 'not-a-uuid';
}
