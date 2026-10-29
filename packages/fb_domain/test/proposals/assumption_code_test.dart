import 'package:fb_domain/fb_domain.dart';
import 'package:glados/glados.dart';

import '../helpers/property.dart';
import 'proposal_fixtures.dart';

void main() {
  // rule: A22 assumption-codes
  test('A22 assumption codes parse what the engine writes', () {
    // Every code the engine emits for a weighed, shared, oiled meal.
    final cooked = food(key: 'usda:rice', kcal: 130, group: 'rice');
    final s = session(
      message([
        intent([
          // Weighed dry, matched cooked: a yield conversion.
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
          item(dimensions: [fatDimension()]),
          // Shared dishes without an explicit amount.
          item(explicit: false, share: {'fraction': 0.5, 'people': null}),
          item(explicit: false, share: {'fraction': null, 'people': 3}),
        ]),
      ]),
      ctx: context(
        yields: [
          YieldFactor(group: 'rice', from: .dry, to: .cooked, factor: 2.5),
        ],
      ),
    );
    final codes = {
      for (final card in s.cards)
        for (final line in card.lines)
          ...line.entry.food.provenance.assumptions,
    };
    expect(codes, isNotEmpty);
    for (final raw in codes) {
      final parsed = AssumptionCode.parse(raw);
      expect(parsed, isNotNull, reason: raw);
      expect(parsed!.code, raw, reason: raw);
    }
    expect(codes, contains('a1:share:0.5/1'));
    expect(codes, contains('a1:share:1/3'));
    expect(codes, contains('a1:yield:dry:cooked:200.0:500.0'));
    expect(codes.any((c) => c.startsWith('a1:origin:')), isTrue);

    expect(
      AssumptionCode.parse('a1:yield:dry:cooked:200.0:500.0'),
      const YieldAssumption(
        fromState: FoodState.dry,
        toState: FoodState.cooked,
        fromGrams: 200,
        toGrams: 500,
      ),
    );
    expect(
      AssumptionCode.parse('a1:oil:most'),
      const OilAssumption(all: false),
    );
    expect(
      (AssumptionCode.parse('a1:share:0.5/1')! as ShareAssumption).share,
      0.5,
    );
    expect(
      AssumptionCode.parse('a1:origin:savedDefault'),
      const OriginAssumption(ProposalChoiceOrigin.savedDefault),
    );
  });

  // rule: A22 assumption-codes
  test('A22 malformed or unknown assumption codes parse to null', () {
    for (final raw in [
      '',
      'Assuming 1 tbsp oil',
      'a2:oil:all',
      'a1:oil',
      'a1:oil:half',
      'a1:oil:all:extra',
      'a1:time:reference',
      'a1:slot:inferred',
      'a1:yield:dry:cooked:200',
      'a1:yield:dry:boiled:200:500',
      'a1:yield:dry:cooked:-1:500',
      'a1:yield:dry:cooked:abc:500',
      'a1:share:3/2',
      'a1:share:0/1',
      'a1:share:1',
      'a1:share:1/x',
      'a1:share:1e-3/1',
      'a1:yield:dry:cooked:200.0:100001.0',
      'a1:yield:dry:cooked:${'9' * 400}:500',
      'a1:share:1/${'9' * 400}',
      'a1:origin:model',
      'A1:oil:all',
    ]) {
      expect(AssumptionCode.parse(raw), isNull, reason: raw);
    }
  });

  Glados2(any.intInRange(1, 1000), any.intInRange(1, 50), propertyRuns).test(
    'A22 share codes round trip',
    (thousandths, people) {
      final fraction = thousandths / 1000;
      for (final share in [
        ShareAssumption.fraction(fraction),
        ShareAssumption.people(people),
      ]) {
        final parsed = AssumptionCode.parse(share.code)! as ShareAssumption;
        expect(parsed.code, share.code);
        expect(parsed.share, closeTo(share.share, 1e-12));
      }
    },
  );
}
