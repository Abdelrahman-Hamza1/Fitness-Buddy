import 'dart:convert';
import 'dart:io';

import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

import 'proposal_fixtures.dart';

void main() {
  // covers: AI-022, AQ-04, AQ-07
  test(
    'T01 AI-022 explicit tablespoon oil makes a separate line with no question',
    () {
      final s = session(
        jsonDecode(
          File('test/proposals/fixtures/t01-v1.json').readAsStringSync(),
        ) as Map<String, Object?>,
        facts: ProposalFacts(cookingFatIds: {'usda:oil'}),
      );
      expect(s.cards.single.lines.map((l) => l.snapshot.kcal), [72, 119.34]);
      expect(s.cards.single.totals.kcal, 191.34);
      expect(s.budget.questions, isEmpty);
      expect(s.cards.single.draftOps.first, isA<CreateDishGroup>());
    },
  );
  // covers: AQ-06, AQ-08
  test('T02 AQ-06 raw rice and cooking fat compete within two questions', () {
    expect(session(_t02()).budget.questions.length, 2);
  });
  // covers: AQ-07
  test('T03 AQ-07 saved rice and oil defaults suppress questions', () {
    final s = session(
      _t02(),
      ctx: context(
        defaults: {'state:rice': 'dry', 'fat:usda:chicken': 'oil:1.0:tbsp'},
      ),
    );
    expect(s.budget.questions, isEmpty);
    expect(s.cards.single.lines.length, 4);
    expect(
      s.cards.single.lines
          .where((l) => l.entry.food.ref.id == 'usda:oil')
          .single
          .snapshot
          .kcal,
      119.34,
    );
  });
  // covers: AQ-04, AQ-07
  test('T04 AQ-04 cooked chicken grams use database math without question', () {
    final s = session(
      message([
        intent([
          item(
            match: food(key: 'usda:chicken', kcal: 165),
            amount: 250,
            unit: 'g',
          ),
        ]),
      ]),
    );
    expect(s.cards.single.totals.kcal, closeTo(412.5, 41.25));
    expect(s.cards.single.totals.kcal, 412.5);
    expect(s.budget.questions, isEmpty);
  });
  // covers: AQ-10, AI-064
  test('T05 AQ-10 cheese guessed amount is badged and fat remains visible', () {
    final s = session(
      message([
        intent([
          item(amount: 2, dimensions: [fatDimension()]),
          item(
            match: food(
              key: 'usda:cheese',
              kcal: 250,
              servings: [serving('serving', 30)],
            ),
            amount: null,
            unit: null,
            explicit: false,
          ),
        ]),
      ]),
    );
    expect(s.cards.single.lines[1].entry.food.provenance.isEstimate, isTrue);
    expect(s.cards.single.lines[1].snapshot.kcal, 75);
    expect(s.cards.single.lines.first.chips, isNotEmpty);
  });
  // covers: AQ-07, AQ-04
  test(
    'T06 AQ-07 explicit milk with verified variant and ml facts asks nothing',
    () {
      final s = session(
        message([
          intent([
            item(
              match: food(key: 'usda:milk', kcal: 999),
              amount: 500,
              unit: 'ml',
            ),
          ]),
        ]),
        facts: ProposalFacts(
          packAvailable: true,
          catalog: {
            'usda:milk': localFood(
              key: 'usda:milk',
              basis: .per100ml,
              kcal: 60,
            ),
          },
        ),
      );
      expect(s.cards.single.totals.kcal, 300);
      expect(s.budget.questions, isEmpty);
    },
  );
  // rule: A21 unmatched-percentage routing
  test(
    'A21 T06 B08 unmatched percentage remains clarify without invented milk',
    () {
      final s = session(
        message([
          {
            'kind': 'clarify',
            'language': 'english',
            'script': 'latin',
            'reason': 'unmatchedFood',
          },
        ]),
      );
      expect(s.cards, isEmpty);
      expect(s.routing.single.kind, 'clarify');
    },
  );
  // covers: AQ-05, AQ-06
  test(
    'T07 AQ-05 reference plate has range and conditional variant question',
    () {
      final plate = serving('plate', 350)
        ..['rangeLo'] = 250.0
        ..['rangeHi'] = 450.0;
      final s = session(
        message([
          intent([
            item(
              match: food(
                key: 'ref:maqluba',
                source: 'reference',
                kcal: 190,
                servings: [plate],
              ),
              unit: 'plate',
              explicit: false,
            ),
          ]),
        ]),
      );
      expect(s.cards.single.totals.kcal, closeTo(665, 166.25));
      expect(s.cards.single.range!.lowKcal, 475);
      expect(s.cards.single.range!.highKcal, 855);
      expect(s.budget.questions, isEmpty);
    },
  );
  // covers: AQ-10
  test('T08 AQ-10 Arabic mloukhiyeh reference stays estimated', () {
    final i =
        intent([
            item(
              match: food(key: 'ref:mloukhiyeh', source: 'reference'),
              explicit: false,
            ),
          ])
          ..['language'] = 'arabic'
          ..['script'] = 'arabic';
    expect(
      session(message([i]))
          .cards
          .single
          .lines
          .single
          .entry
          .food
          .provenance
          .isEstimate,
      isTrue,
    );
  });
  // covers: AQ-10, AI-020
  test('T09 AQ-10 four guessed portions keep badges and one dish group', () {
    final s = session(
      message([
        intent([
          for (final id in ['labaneh', 'zaatar', 'oil', 'taboon'])
            item(
              match: food(key: 'usda:$id'),
              amount: null,
              unit: null,
              explicit: false,
            ),
        ], group: 'Breakfast'),
      ]),
    );
    expect(s.cards.single.lines.length, 4);
    expect(
      s.cards.single.lines.every((l) => l.entry.food.provenance.isEstimate),
      isTrue,
    );
    expect(s.cards.single.draftOps.whereType<CreateDishGroup>().length, 1);
  });
  // covers: AI-101, AQ-10
  test('T10 AI-101 large mansaf plate wins over six people', () {
    final s = session(
      message([
        intent([
          item(
            match: food(
              key: 'ref:mansaf',
              source: 'reference',
              kcal: 200,
              servings: [serving('plate', 450)],
            ),
            unit: 'plate',
            share: {'fraction': null, 'people': 6},
          ),
        ]),
      ]),
    );
    expect(s.cards.single.totals.kcal, 900);
    expect(
      s.cards.single.lines.single.entry.food.provenance.isEstimate,
      isTrue,
    );
  });
}

Map<String, Object?> _t02() => message([
  intent([
    riceItem(),
    item(
      match: food(key: 'usda:chicken', kcal: 120, state: 'raw'),
      amount: 200,
      unit: 'g',
      dimensions: [fatDimension()],
    ),
    item(
      match: food(
        key: 'usda:onion',
        kcal: 40,
        servings: [serving('piece', 110)],
      ),
    ),
  ], group: 'Rice and chicken'),
]);
