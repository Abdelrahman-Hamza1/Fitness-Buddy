import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

import '../helpers/diary.dart';

void main() {
  final bread = FoodMeasures(
    basis: .per100g,
    servingUnits: [
      ServingUnit.grams('slice', 20),
      ServingUnit.grams('loaf', 60),
      ServingUnit.grams('cup', 30),
      ServingUnit.grams('zunit', 40),
      ServingUnit.grams('aunit', 50),
    ],
  );
  final plain = FoodMeasures(basis: .per100g);
  test('FD-022 defaults: last input, parse, first serving, 100 g/ml', () {
    expect(
      DefaultPortion.choose(
        bread,
        lastUsed: Quantity(2, 'slice'),
        parsed: ParsedAmount(3, 'loaf'),
      ),
      Quantity(2, 'slice'),
    );
    expect(
      DefaultPortion.choose(
        bread,
        lastUsed: Quantity(2, 'absent'),
        parsed: ParsedAmount(3, 'loaf'),
      ),
      Quantity(3, 'loaf'),
    );
    expect(
      DefaultPortion.choose(bread, parsed: ParsedAmount(2)),
      Quantity(2, 'loaf'),
    );
    expect(DefaultPortion.choose(bread), Quantity(1, 'loaf'));
    expect(DefaultPortion.choose(plain), Quantity(100, 'g'));
    expect(
      DefaultPortion.choose(FoodMeasures(basis: .per100ml)),
      Quantity(100, 'ml'),
    );
    expect(
      DefaultPortion.choose(plain, parsed: ParsedAmount(2)),
      Quantity(2, 'g'),
    );
    expect(
      DefaultPortion.choose(plain, parsed: ParsedAmount(2, 'ml')),
      Quantity(100, 'g'),
    );
    expect(
      DefaultPortion.choose(plain, lastUsed: Quantity(2, 'ml')),
      Quantity(100, 'g'),
    );
    expect(() => ParsedAmount(0), throwsArgumentError);
    expect(() => ParsedAmount(double.nan), throwsArgumentError);
    expect(() => ParsedAmount(-1), throwsArgumentError);
    expect(() => ParsedAmount(double.infinity), throwsArgumentError);
  });
  test('LC-011 servings, basis, all resolvable standards; no duplicates', () {
    expect(UnitOptions.of(bread), [
      'loaf',
      'slice',
      'cup',
      'aunit',
      'zunit',
      'g',
      'oz',
      'lb',
      'kg',
    ]);
    expect(UnitOptions.of(FoodMeasures(basis: .per100ml)), [
      'ml',
      'cup',
      'tbsp',
      'tsp',
      'fl_oz',
      'l',
    ]);
    final dense = FoodMeasures(
      basis: .per100g,
      densityGramsPerMl: 1,
      servingUnits: [
        ServingUnit.grams('g', 1),
        ServingUnit.grams('plate', 200),
      ],
    );
    expect(UnitOptions.of(dense), [
      'plate',
      'g',
      'oz',
      'lb',
      'kg',
      'ml',
      'cup',
      'tbsp',
      'tsp',
      'fl_oz',
      'l',
    ]);
    final wrongBasis = FoodMeasures(
      basis: .per100g,
      servingUnits: [ServingUnit.milliliters('glass', 200)],
    );
    expect(UnitOptions.of(wrongBasis), isNot(contains('glass')));
    expect(DefaultPortion.choose(wrongBasis), Quantity(100, 'g'));
  });
  FoodHistoryItem history(EntryAmount amount, {bool metadata = false}) =>
      FoodHistoryItem(
        food: riceFood(),
        amount: amount,
        uses: 4,
        lastUsedHlc: Hlc(wallMs: 10, counter: 0, deviceId: entryA),
        editedByUser: true,
        state: metadata ? FoodState.raw : null,
        brand: metadata ? 'brand' : null,
        yieldGroup: metadata ? 'rice' : null,
        sanity: metadata ? SanityLevel.ok : null,
      );
  test('FD-023 derived portions preserve g/ml basis and nullable metadata', () {
    for (final basis in NutrientBasis.values) {
      final item = history(
        EntryAmount(input: Quantity(2, 'glass'), amount: 500, basis: basis),
      );
      expect(item.derivedServing!.amount, 250);
      expect(item.derivedServing!.basis, basis);
      expect(item.derivedServing!.code, 'glass');
      expect(item.food.ref.version, '2026.10.1');
      expect(item.food.provenance.source, FoodSource.database);
      expect(item.amount.input, Quantity(2, 'glass'));
      expect(item.uses, 4);
      expect(item.lastUsedHlc.wallMs, 10);
      expect(item.editedByUser, isTrue);
      expect(item.state, isNull);
      expect(item.brand, isNull);
      expect(item.yieldGroup, isNull);
      expect(item.sanity, isNull);
    }
    final enriched = history(grams(100), metadata: true);
    expect(enriched.state, FoodState.raw);
    expect(enriched.brand, 'brand');
    expect(enriched.yieldGroup, 'rice');
    expect(enriched.sanity, SanityLevel.ok);
    for (final basis in NutrientBasis.values) {
      expect(
        history(
          EntryAmount(
            input: Quantity(100, basis.unitCode),
            amount: 100,
            basis: basis,
          ),
        ).derivedServing,
        isNull,
      );
    }
    // PA3: a food cup must preserve its logged size over the generic cup.
    expect(
      history(
        EntryAmount(input: Quantity(1, 'cup'), amount: 200, basis: .per100ml),
      ).derivedServing!.amount,
      200,
    );
    for (final pair in [(0.0, 100.0), (1.0, 0.0), (1e-320, 1e300)]) {
      expect(
        history(
          EntryAmount(
            input: Quantity(pair.$1, 'loaf'),
            amount: pair.$2,
            basis: .per100g,
          ),
        ).derivedServing,
        isNull,
      );
    }
  });
  StateSibling<String> food(
    String id,
    String key,
    FoodState state, {
    String? group = 'rice',
  }) => StateSibling(
    id: id,
    nameKey: key,
    state: state,
    yieldGroup: group,
    payload: id,
  );
  test(
    'FD-060 compatible rice siblings; exact qualifiers and yield groups',
    () {
      final cooked = food('cooked', 'rice white cooked', .cooked);
      final raw = food('raw', 'rice white raw', .raw);
      final dry = food('dry', 'rice white dry', .dry);
      expect(
        StateSibling.choose(
          picked: cooked,
          groupFoods: [raw, dry],
          stated: .raw,
        ),
        ['raw'],
      );
      expect(
        StateSibling.choose(picked: raw, groupFoods: [cooked], stated: .cooked),
        ['cooked'],
      );
      expect(
        StateSibling.choose(picked: cooked, groupFoods: [dry], stated: .dry),
        ['dry'],
      );
      expect(
        StateSibling.choose(
          picked: cooked,
          groupFoods: [
            food('wrong', 'rice brown raw', .raw),
            food('group', 'rice white raw', .raw, group: 'other'),
            food('b', 'rice white raw', .raw),
            food('a', 'rice white raw', .raw),
            food('short', 'rice white', .raw),
            food('cooked', 'rice white raw', .raw),
          ],
          stated: .raw,
        ),
        ['short', 'a', 'b'],
      );
      expect(
        StateSibling.choose(
          picked: cooked,
          groupFoods: [cooked],
          stated: .cooked,
        ),
        isEmpty,
      );
      expect(
        StateSibling.choose(
          picked: food('none', 'rice', .cooked, group: null),
          groupFoods: [raw],
          stated: .raw,
        ),
        isEmpty,
      );
      expect(
        StateSibling.choose(
          picked: food('none', 'cooked', .cooked),
          groupFoods: [raw],
          stated: .raw,
        ),
        isEmpty,
      );
    },
  );
  test('FD-060 PA12 beef ratios, cuts and skin qualifiers must match', () {
    final beef = food('90', 'beef ground 90 10 raw', .raw, group: 'beef');
    expect(
      StateSibling.choose(
        picked: beef,
        groupFoods: [
          food('80', 'beef ground 80 20 cooked', .cooked, group: 'beef'),
          food('steak', 'beef steak 90 10 cooked', .cooked, group: 'beef'),
        ],
        stated: .cooked,
      ),
      isEmpty,
    );
    final chicken = food(
      'roast',
      'chicken breast roasted',
      .cooked,
      group: 'chicken',
    );
    expect(
      StateSibling.choose(
        picked: chicken,
        groupFoods: [
          food(
            'skinless',
            'chicken breast skinless raw',
            .raw,
            group: 'chicken',
          ),
        ],
        stated: .raw,
      ),
      isEmpty,
    );
    expect(
      StateSibling.choose(
        picked: chicken,
        groupFoods: [food('raw', 'chicken breast raw', .raw, group: 'chicken')],
        stated: .raw,
      ),
      ['raw'],
    );
  });
}
