import 'dart:math';

import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

FoodAmountDisplay display(
  Quantity input,
  double amount,
  NutrientBasis basis,
  UnitSystem system,
) => FoodAmountDisplay.of(
  input: input,
  amount: amount,
  basis: basis,
  system: system,
);

void expectPrimary(FoodAmountDisplay d, double value, String code) {
  expect(d.primary.value, value);
  expect(d.primary.unitCode, code);
}

CityCandidate city(
  String id,
  String name, {
  String ar = '',
  String country = 'PS',
  int population = 0,
}) => CityCandidate(
  id: id,
  keyEn: name,
  keyAr: ar,
  countryCode: country,
  population: population,
  nameEn: name,
);

void main() {
  test('LC-010 LC-011 FoodAmountDisplay: 100 g shows 100 g in '
      'metric and 3.5 oz in imperial; 8 oz typed shows 227 g in '
      'metric (both directions)', () {
    final input = Quantity(100, 'g');
    expectPrimary(display(input, 100, .per100g, .metric), 100, 'g');
    expectPrimary(display(input, 100, .per100g, .imperial), 3.5, 'oz');
    expectPrimary(
      display(Quantity(8, 'oz'), 226.796185, .per100g, .metric),
      227,
      'g',
    );
    expectPrimary(
      display(Quantity(8, 'oz'), 226.796185, .per100g, .imperial),
      8,
      'oz',
    );
  });
  test('LC-011 PA2 a standard input converts in its own dimension: '
      '250 ml on a g-basis food shows 250 ml / 8.5 fl oz, never '
      'grams as the primary', () {
    for (final system in UnitSystem.values) {
      final d = display(Quantity(250, 'ml'), 258, .per100g, system);
      expectPrimary(
        d,
        system == UnitSystem.metric ? 250 : 8.5,
        system == UnitSystem.metric ? 'ml' : 'fl_oz',
      );
      expect(d.primary.converted, isTrue);
    }
  });
  test('LC-011 PA2 density-backed inputs: 250 ml of milk (g basis) '
      'shows the stored grams as the secondary (258 g / 9.1 oz); '
      '100 g of oil on an ml basis shows ml / fl oz as the '
      'secondary', () {
    expect(
      display(Quantity(250, 'ml'), 258, .per100g, .metric).secondary,
      const DisplayAmount(258, 'g'),
    );
    expect(
      display(Quantity(250, 'ml'), 258, .per100g, .imperial).secondary,
      const DisplayAmount(9.1, 'oz'),
    );
    expect(
      display(Quantity(100, 'g'), 109, .per100ml, .metric).secondary,
      const DisplayAmount(109, 'ml'),
    );
    expect(
      display(Quantity(100, 'g'), 109, .per100ml, .imperial).secondary,
      const DisplayAmount(3.7, 'fl_oz'),
    );
  });
  test('LC-011 a portion or kitchen word stays as typed with the '
      'stored amount as the secondary (1 loaf (60 g) / (2.1 oz); 1 '
      'cup on an ml basis (240 ml) / (8.1 fl oz))', () {
    for (final (word, amount, basis, metric, imperial) in [
      (
        'loaf',
        60.0,
        NutrientBasis.per100g,
        const DisplayAmount(60, 'g'),
        const DisplayAmount(2.1, 'oz'),
      ),
      (
        'cup',
        240.0,
        NutrientBasis.per100ml,
        const DisplayAmount(240, 'ml'),
        const DisplayAmount(8.1, 'fl_oz'),
      ),
      (
        'tbsp',
        15.0,
        NutrientBasis.per100ml,
        const DisplayAmount(15, 'ml'),
        const DisplayAmount(0.5, 'fl_oz'),
      ),
      (
        'tsp',
        5.0,
        NutrientBasis.per100ml,
        const DisplayAmount(5, 'ml'),
        const DisplayAmount(0.2, 'fl_oz'),
      ),
    ]) {
      for (final system in UnitSystem.values) {
        final d = display(Quantity(1, word), amount, basis, system);
        expectPrimary(d, 1, word);
        expect(d.primary.converted, isFalse);
        expect(d.secondary, system == UnitSystem.metric ? metric : imperial);
      }
    }
  });
  test(
    'PA2 no secondary when it would repeat the primary (100 g on a g basis)',
    () {
      for (final system in UnitSystem.values) {
        expect(
          display(Quantity(100, 'g'), 100, .per100g, system).secondary,
          isNull,
        );
        expect(
          display(Quantity(100, 'ml'), 100, .per100ml, system).secondary,
          isNull,
        );
      }
    },
  );
  test('property: the primary of a standard input equals its own '
      'quantity converted with exact factors and rounded (S08 D3), '
      'never a density; the function only reads its inputs', () {
    final random = Random(1010);
    for (var run = 0; run < 1000; run++) {
      final mass = run.isEven;
      final system = UnitSystem.values[run % 3 == 0 ? 0 : 1];
      final code = mass
          ? MassUnit.values[random.nextInt(4)].code
          : ['ml', 'l', 'fl_oz'][random.nextInt(3)];
      final input = Quantity(random.nextDouble() * 1000, code);
      final before = (input.amount, input.unitCode);
      final factor = mass
          ? MassUnit.fromCode(code)!.grams
          : VolumeUnit.fromCode(code)!.milliliters;
      final divisor = mass ? system.foodMass.grams : system.volume.milliliters;
      final exact = input.amount * factor / divisor;
      final expected = system == UnitSystem.metric
          ? exact.roundToDouble()
          : (exact * 10).round() / 10;
      final basis = random.nextBool()
          ? NutrientBasis.per100g
          : NutrientBasis.per100ml;
      final stored = random.nextDouble() * 10000;
      final d = display(input, stored, basis, system);
      expectPrimary(
        d,
        expected,
        mass ? system.foodMass.code : system.volume.code,
      );
      expect((input.amount, input.unitCode), before);
      expect(
        display(input, stored + 100, basis, system).primary.value,
        d.primary.value,
      );
    }
  });
  test('LC-010 UnitOptions in imperial lists oz, lb before g; '
      'servings still lead; metric order unchanged (A07 tests '
      'green)', () {
    final bread = FoodMeasures(
      basis: .per100g,
      servingUnits: [ServingUnit.grams('loaf', 60)],
    );
    expect(UnitOptions.of(bread, system: .imperial).take(5), [
      'loaf',
      'oz',
      'lb',
      'g',
      'kg',
    ]);
    expect(UnitOptions.of(bread), ['loaf', 'g', 'oz', 'lb', 'kg']);
    final drink = FoodMeasures(basis: .per100ml);
    expect(UnitOptions.of(drink, system: .imperial), [
      'fl_oz',
      'cup',
      'tbsp',
      'tsp',
      'ml',
      'l',
    ]);
  });
  test('FD-022 DefaultPortion fallback is 100 g in metric and 4 oz '
      'in imperial; last-used still wins', () {
    final plain = FoodMeasures(basis: .per100g);
    final drink = FoodMeasures(basis: .per100ml);
    expect(DefaultPortion.choose(plain), Quantity(100, 'g'));
    expect(DefaultPortion.choose(plain, system: .imperial), Quantity(4, 'oz'));
    expect(DefaultPortion.choose(drink), Quantity(100, 'ml'));
    expect(
      DefaultPortion.choose(drink, system: .imperial),
      Quantity(8, 'fl_oz'),
    );
    expect(
      DefaultPortion.choose(
        plain,
        system: .imperial,
        lastUsed: Quantity(2, 'kg'),
      ),
      Quantity(2, 'kg'),
    );
    expect(
      DefaultPortion.choose(drink, system: .imperial, parsed: ParsedAmount(3)),
      Quantity(3, 'fl_oz'),
    );
  });
  test('LC-033 CityRanker: exact before prefix before word; PS and '
      'JO before others at equal strength; population descending; '
      'zero-population rows still returned; 50 max; deterministic '
      'ties', () {
    final cities = [
      city('exact', 'nab', country: 'EG'),
      city('prefix', 'nablus', country: 'EG'),
      city('word', 'old nab'),
      city('jo', 'nablus', country: 'JO', population: 10),
      city('ps', 'nablus'),
      city('psLarge', 'nablus', population: 50),
      city('psTieA', 'nablus', population: 50),
      city('psTieB', 'nablus', population: 50),
      city('ar', 'unmatched', ar: 'nab', country: 'JO'),
      city('no', 'banana'),
      city('partial', 'nab other'),
    ];
    final ids = CityRanker.rank('nab', [
      'nab',
    ], cities).map((c) => c.id).toList();
    expect(ids, [
      'ar',
      'exact',
      'psLarge',
      'psTieA',
      'psTieB',
      'partial',
      'ps',
      'jo',
      'prefix',
      'word',
    ]);
    expect(
      CityRanker.rank('nab', ['nab'], cities.reversed).map((c) => c.id),
      ids,
    );
    expect(CityRanker.rank('', [], cities), isEmpty);
    expect(CityRanker.rank('nab', ['nab'], cities, limit: 0), isEmpty);
    expect(CityRanker.rank('nab missing', ['nab', 'missing'], cities), isEmpty);
    expect(CityRanker.rank('abl', ['abl'], [city('sub', 'nablus')]), isEmpty);
    expect(
      CityRanker.rank(
        'nab',
        ['nab'],
        [for (var i = 0; i < 60; i++) city('$i', 'nab')],
      ),
      hasLength(50),
    );
    // Names break equal-population ties before IDs.
    // Custom region order remains explicit.
    expect(
      CityRanker.rank(
        'n',
        ['n'],
        [city('z', 'nab'), city('a', 'naz')],
      ).first.id,
      'z',
    );
    expect(
      CityRanker.rank('nab', ['nab'], cities, region: ['EG']).first.id,
      'exact',
    );
  });
  test('LC-033 suggestions: current city first, then 20 PS and 10 '
      'JO by population', () {
    final cities = [
      for (var i = 0; i < 25; i++) city('ps$i', 'p$i', population: i),
      for (var i = 0; i < 15; i++)
        city('jo$i', 'j$i', country: 'JO', population: i),
      city('current', 'Cairo', country: 'EG'),
    ];
    final suggestions = CityRanker.suggestions(cities, currentId: 'current');
    expect(suggestions.map((c) => c.id), [
      'current',
      for (var i = 24; i >= 5; i--) 'ps$i',
      for (var i = 14; i >= 5; i--) 'jo$i',
    ]);
    expect(
      CityRanker.suggestions(
        cities,
        currentId: 'ps24',
      ).map((c) => c.id).toSet(),
      hasLength(30),
    );
    expect(CityRanker.suggestions(cities, currentId: 'unknown'), hasLength(30));
    expect(CityRanker.suggestions([]), isEmpty);
  });
}
