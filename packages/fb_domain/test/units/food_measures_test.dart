import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

void main() {
  final bread = FoodMeasures(
    basis: NutrientBasis.per100g,
    servingUnits: [
      ServingUnit.grams('loaf', 90),
      ServingUnit.grams('cup', 30), // crumbs: the food's own cup wins
    ],
  );
  final milk = FoodMeasures(
    basis: NutrientBasis.per100ml,
    servingUnits: [ServingUnit.milliliters('glass', 250)],
    densityGramsPerMl: 1.03,
  );

  Matcher resolvesTo(double amount, NutrientBasis basis) => isA<Resolved>()
      .having((r) => r.amount, 'amount', amount)
      .having((r) => r.basis, 'basis', basis);

  test("LC-051 a food-specific portion unit (loaf) resolves to that food's "
      'grams', () {
    expect(bread.resolve(Quantity(2, 'loaf')), resolvesTo(180, .per100g));
    expect(bread.resolve(Quantity(0.5, 'loaf')), resolvesTo(45, .per100g));
    expect(milk.resolve(Quantity(1, 'glass')), resolvesTo(250, .per100ml));
  });

  test("LC-051 the food's own unit wins over a generic unit with the same "
      'code', () {
    expect(bread.resolve(Quantity(1, 'cup')), resolvesTo(30, .per100g));
  });

  test('LC-011 generic units on the matching basis', () {
    expect(bread.resolve(Quantity(1, 'lb')), resolvesTo(453.59, .per100g));
    expect(milk.resolve(Quantity(1, 'cup')), resolvesTo(240, .per100ml));
    expect(milk.resolve(Quantity(12, 'fl_oz')), resolvesTo(354.88, .per100ml));
  });

  test('a density converts between mass and volume, rounded to storage', () {
    // 103 g of milk is 100 ml; 1 cup of milk on a per-100 g food is 247.2 g.
    expect(milk.resolve(Quantity(103, 'g')), resolvesTo(100, .per100ml));
    final oil = FoodMeasures(
      basis: NutrientBasis.per100g,
      servingUnits: [ServingUnit.milliliters('glass', 200)],
      densityGramsPerMl: 0.92,
    );
    expect(oil.resolve(Quantity(1, 'tbsp')), resolvesTo(13.8, .per100g));
    expect(oil.resolve(Quantity(1, 'glass')), resolvesTo(184, .per100g));
    expect(oil.resolve(Quantity(1, 'tsp')), resolvesTo(4.6, .per100g));
  });

  test('volume input on a per-100 g food without density → NeedsDensity', () {
    final input = Quantity(1, 'cup');
    final rice = FoodMeasures(basis: NutrientBasis.per100g);
    expect(
      rice.resolve(input),
      isA<NeedsDensity>().having((f) => f.input, 'input', input),
    );
    final juice = FoodMeasures(basis: NutrientBasis.per100ml);
    expect(juice.resolve(Quantity(100, 'g')), isA<NeedsDensity>());
  });

  test('unknown serving unit → UnknownServingUnit', () {
    expect(
      bread.resolve(Quantity(1, 'plate')),
      isA<UnknownServingUnit>().having(
        (f) => f.input.unitCode,
        'code',
        'plate',
      ),
    );
  });

  test('invalid measures and quantities are rejected', () {
    expect(() => Quantity(-1, 'g'), throwsArgumentError);
    expect(() => Quantity(double.nan, 'g'), throwsArgumentError);
    expect(() => ServingUnit.grams('loaf', 0), throwsArgumentError);
    expect(
      () => ServingUnit.milliliters('glass', double.infinity),
      throwsArgumentError,
    );
    expect(
      () => FoodMeasures(basis: NutrientBasis.per100g, densityGramsPerMl: 0),
      throwsArgumentError,
    );
    expect(
      () => FoodMeasures(
        basis: NutrientBasis.per100g,
        servingUnits: [
          ServingUnit.grams('loaf', 90),
          ServingUnit.grams('loaf', 100),
        ],
      ),
      throwsArgumentError,
    );
  });

  test('Quantity keeps the input as typed and is a value', () {
    final q = Quantity(8, 'oz');
    expect(q.amount, 8);
    expect(q.unitCode, 'oz');
    expect(q, Quantity(8, 'oz'));
    expect(q, isNot(Quantity(8, 'g')));
    expect(q.hashCode, Quantity(8, 'oz').hashCode);
    expect(q.toString(), 'Quantity(8.0 oz)');
    expect(NutrientBasis.per100g.unitCode, 'g');
    expect(NutrientBasis.per100ml.unitCode, 'ml');
  });

  test('FoodState codes are stable and resolve back', () {
    expect(FoodState.values.map((s) => s.code), [
      'raw',
      'cooked',
      'dry',
      'drained',
      'fried',
      'as_sold',
    ]);
    for (final state in FoodState.values) {
      expect(FoodState.fromCode(state.code), state);
    }
    expect(FoodState.fromCode('asSold'), isNull);
  });
}
