import 'package:fb_domain/fb_domain.dart';
import 'package:glados/glados.dart';

import '../helpers/property.dart';
import 'proposal_codec_test.dart' show roundTrip;
import 'proposal_fixtures.dart';
import 'proposal_recompute_test.dart' show decodedItem, update;

Map<String, Object?> sharedRice(double amount) => item(
  match: food(key: 'usda:rice_cooked', kcal: 130, group: 'rice'),
  amount: amount,
  unit: 'g',
  explicit: false,
  share: {'fraction': .5, 'people': 6},
  dimensions: [
    dimension('state', [
      option(
        'cooked',
        candidate: food(key: 'usda:rice_cooked', kcal: 130, group: 'rice'),
      ),
    ], stated: 'dry'),
    fatDimension()..['statedValue'] = 'oil',
  ],
);
ProposalContext sharedContext() => context(
  yields: [YieldFactor(group: 'rice', from: .dry, to: .cooked, factor: 2.8)],
);

void main() {
  // rule: A21 mixed-facts-and-meal-coverage
  Glados(any.listWithLength(12, any.intInRange(0, 64)), propertyRuns).test(
    'A21 generated multi-card version and explicit-oil '
    'sequences retain exact guards',
    (steps) {
      const key = '019a1b2c-0000-7000-8000-000000001234';
      final fat = fatDimension()..['statedValue'] = 'oil';
      var s = session(
        message([
          intent([
            item(dimensions: [fat]),
          ], slot: 'breakfast'),
          intent([item(match: oilFood(), unit: 'tbsp')], slot: 'breakfast'),
          intent([
            item(
              match: food(key: key, source: 'personal'),
            ),
            item(
              match: food(key: key, source: 'personal'),
            ),
          ], slot: 'dinner'),
        ]),
        facts: ProposalFacts(
          personal: {
            key: localFood(key: key, source: .yours, personalVersion: 1),
          },
        ),
      );
      final explicitOil = s.cards.first.lines.last.entry.id;
      for (final step in steps) {
        final line = s.cards.last.lines[step % 2];
        s = update(
          s,
          ProposalSwap(
            line.entry.id,
            localFood(
              key: key,
              source: .yours,
              personalVersion: step % 3 + 1,
              kcal: 100 + step.toDouble(),
            ),
          ),
        ).session;
        s = update(
          s,
          ProposalSetRemoved(explicitOil, removed: step.isOdd),
        ).session;
        s = roundTrip(s);
        expect(
          s.cards.first.lines.where((l) => l.entry.food.ref.id == 'usda:oil'),
          hasLength(1),
        );
        if (!s.cards.last.canConfirm) {
          expect(s.cards.last.draftOps, isEmpty);
          expect(s.cards.last.issues, isNotEmpty);
          continue;
        }
        expect(
          s.cards.last.draftOps.whereType<RequirePersonalFood>().map(
            (op) => op.food.expectedVersion,
          ),
          s.cards.last.lines.map((l) => l.selectedFood!.personalVersion),
        );
      }
    },
  );

  // Bounded generated operation streams vary structure, order and lifecycle.
  Glados(
    any.listWithLength(24, any.intInRange(0, 256)),
    propertyRuns,
  ).test('AI-040 generated multi-card adjustment sequences '
      'preserve exact state and oil choices', (steps) {
    final ids = FixedIds();
    final rice = riceItem(amount: (steps.first + 1).toDouble());
    ((rice['dimensions']! as List<Object?>).first!
            as Map<String, Object?>)['statedValue'] =
        'dry';
    var s = session(
      message([
        intent(
          [rice, if (steps.first.isEven) item()],
          slot: 'breakfast',
          group: 'first',
        ),
        intent(
          [
            item(dimensions: [fatDimension()]),
            if (steps[1].isEven) item(amount: 2),
          ],
          slot: 'dinner',
          group: 'second',
        ),
      ]),
      ctx: sharedContext(),
      ids: ids,
    );
    final firstId = s.cards.first.id;
    final secondId = s.cards.last.id;
    final riceId = s.cards.first.lines.first.entry.id;
    final parentId = s.cards.last.lines.first.entry.id;
    for (final step in steps) {
      final card = s.cards.firstWhere((c) => c.id == secondId);
      final parent = card.lines.firstWhere((l) => l.entry.id == parentId);
      final fat = parent.dimensions.firstWhere((d) => d.kind == .fat);
      ProposalAdjustment adjustment;
      switch (step % 6) {
        case 0:
          final riceLine = s.cards.first.lines.first;
          final d = riceLine.dimensions.first;
          adjustment = ProposalSelect(d.id, d.options.last.id);
        case 1:
          adjustment = ProposalSelect(fat.id, fat.options[1].id);
        case 2:
          // Activate a component before editing its canonical quantity.
          s = update(s, ProposalSelect(fat.id, fat.options[1].id)).session;
          final oil = s.cards.last.lines.firstWhere(
            (l) => l.entry.food.ref.id == 'usda:oil',
          );
          s = update(
            s,
            ProposalSetAmount(oil.entry.id, Quantity(2, 'tsp')),
          ).session;
          adjustment = ProposalSelect(fat.id, fat.options.last.id);
        case 3:
          adjustment = ProposalSetWhen(
            firstId,
            time: sharedContext().referenceTime.onDate(
              sharedContext().referenceTime.localDate.plusDays(-(step % 5)),
            ),
          );
        case 4:
          adjustment = ProposalSetAmount(
            riceId,
            Quantity((step + 1).toDouble(), 'g'),
          );
        default:
          final extra = card.lines
              .where(
                (l) =>
                    l.entry.id != parentId && l.entry.food.ref.id != 'usda:oil',
              )
              .firstOrNull;
          if (extra == null) continue;
          s = update(
            s,
            ProposalSetRemoved(extra.entry.id, removed: true),
          ).session;
          adjustment = ProposalSetRemoved(extra.entry.id, removed: false);
      }
      final next = update(s, adjustment).session;
      expect(update(next, adjustment).session, next);
      s = roundTrip(next, ctx: sharedContext());
      expect(s.budget.questions.length, lessThanOrEqualTo(2));
      for (final c in s.cards) {
        expect(
          c.totals.kcal,
          c.lines.fold<int>(
                0,
                (sum, l) => sum + (l.snapshot.kcal * 100).round(),
              ) /
              100,
        );
      }
      if (step % 6 == 2) {
        final oil = s.cards.last.lines.firstWhere(
          (l) => l.entry.food.ref.id == 'usda:oil',
        );
        expect(oil.entry.amount.input, Quantity(1, 'tbsp'));
        expect(oil.snapshot.kcal, 119.34);
      }
    }
    final priorGroup = s.cards.last.lines.first.entry.dishGroupId;
    s = update(s, ProposalSetLifecycle(firstId, .confirmed)).session;
    final rebuilt = ProposalEngine.rebuild(
      s.cards.last,
      ProposalRequest(
        interpretation: message([
          intent(
            [
              item(dimensions: [fatDimension()]),
            ],
            slot: 'dinner',
            time: 'today',
            group: 'second',
          ),
        ]),
        messageId: '019a1b2c-0000-7000-8000-000000008888',
        idSource: ids,
        context: sharedContext(),
        facts: ProposalFacts(),
      ),
    ).value!.session;
    expect(rebuilt.cards.single.lines.first.entry.dishGroupId, priorGroup);
    expect(
      rebuilt.cards.single.preview.date,
      sharedContext().referenceTime.localDate,
    );
    expect(roundTrip(rebuilt, ctx: sharedContext()), rebuilt);
  });

  // WP2 build path; WP3/4 add reducer and restore coverage to the shared
  // budget.
  Glados(any.intInRange(1, 30), propertyRuns).test(
    'AQ-08 every build recompute and restore has at most two questions per '
    'message',
    (count) {
      final s = session(
        message([intent(List.generate(count, (_) => riceItem()))]),
      );
      expect(s.budget.questions.length, lessThanOrEqualTo(2));
      final changed = update(
        s,
        ProposalSetAmount(
          s.cards.single.lines.first.entry.id,
          Quantity(100, 'g'),
        ),
      ).session;
      expect(changed.budget.questions.length, lessThanOrEqualTo(2));
      expect(roundTrip(changed).budget.questions.length, lessThanOrEqualTo(2));
    },
  );
  Glados(any.intInRange(1, 50000), propertyRuns).test(
    'AI-031 totals equal sum of active rounded line snapshots',
    (hundredths) {
      final s = session(
        message([
          intent([
            riceItem(amount: hundredths / 100),
            item(amount: 3),
            item(match: oilFood(), unit: 'tsp'),
          ]),
        ]),
      );
      final lines = s.cards.single.lines;
      for (final field in <double Function(Nutrients)>[
        (n) => n.kcal,
        (n) => n.protein,
        (n) => n.carbs,
        (n) => n.fat,
        (n) => n.fiber,
      ]) {
        final expected =
            lines.fold<int>(
              0,
              (sum, l) => sum + (field(l.snapshot) * 100).round(),
            ) /
            100;
        expect(field(s.cards.single.totals), expected);
      }
    },
  );
  // rule: A21 determinism
  Glados(any.intInRange(1, 5000), propertyRuns).test(
    'A21 equal inputs and ID source sequence produce equal drafts ops and '
    'question order',
    (amount) {
      final json = message([
        intent([riceItem(amount: amount.toDouble())]),
      ]);
      final a = session(json);
      final b = session(json);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    },
  );
  Glados(any.intInRange(1, 5000), propertyRuns).test(
    'AI-040 recomputing the same absolute adjustment is idempotent',
    (amount) {
      final s = session(
        message([
          intent([riceItem()]),
        ]),
      );
      final edit = ProposalSetAmount(
        s.cards.single.lines.first.entry.id,
        Quantity(amount.toDouble(), 'g'),
      );
      final once = update(s, edit).session;
      final twice = update(once, edit);
      expect(twice.session, once);
      expect(twice.diff.isEmpty, isTrue);
    },
  );
  Glados(any.intInRange(1, 5000), propertyRuns).test(
    'AI-042 remove then restore preserves original totals and identities',
    (amount) {
      final s = session(
        message([
          intent([sharedRice(amount.toDouble())]),
        ]),
        ctx: sharedContext(),
      );
      final id = s.cards.single.lines.first.entry.id;
      final gone = update(s, ProposalSetRemoved(id, removed: true)).session;
      expect(update(gone, ProposalSetRemoved(id, removed: false)).session, s);
    },
  );
  Glados(any.intInRange(1, 5000), propertyRuns).test(
    'AI-042 remove then add same food with new ID restores equal totals',
    (amount) {
      final raw = sharedRice(amount.toDouble());
      final s = session(
        message([
          intent([raw]),
        ]),
        ctx: sharedContext(),
      );
      final gone = update(
        s,
        ProposalSetRemoved(s.cards.single.lines.first.entry.id, removed: true),
      ).session;
      final restored = update(
        gone,
        ProposalAdd(
          s.cards.single.id,
          'new',
          decodedItem(raw),
          FixedIds()..calls = 100,
        ),
      ).session;
      expect(restored.cards.single.totals, s.cards.single.totals);
      expect(
        restored.cards.single.lines.first.entry.id,
        isNot(s.cards.single.lines.first.entry.id),
      );
    },
  );
  Glados(any.intInRange(3, 12), propertyRuns).test(
    'AQ-08 answered questions never free issued slots across adjustments',
    (count) {
      var s = session(
        message([intent(List.generate(count, (_) => riceItem()))]),
      );
      final original = s.budget.questions;
      for (final q in original) {
        s = update(s, ProposalSelect(q.dimensionId, q.optionIds.first)).session;
      }
      expect(s.budget.questions, isEmpty);
    },
  );
  // rule: A21 privacy
  test('A21 proposal diagnostics contain no user content', () {
    final s = session(t01(), facts: ProposalFacts(cookingFatIds: {'usda:oil'}));
    for (final v in [
      s,
      ...s.cards,
      ...s.cards.single.lines,
      s.budget,
      ...s.budget.questions,
      build(message()..['model'] = 'secret').issue,
    ]) {
      expect(v.toString(), isNot(contains('Synthetic')));
      expect(v.toString(), isNot(contains('884')));
      expect(v.toString(), isNot(contains('طعام')));
    }
  });
}
