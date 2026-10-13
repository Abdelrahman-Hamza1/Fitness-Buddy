import 'package:fb_domain/fb_domain.dart';
import 'package:glados/glados.dart';

import '../helpers/property.dart';

void main() {
  const calculator = NutritionCalculator();

  // Cooked chicken breast per 100 g.
  final chicken = Nutrients(
    kcal: 165,
    protein: 31,
    carbs: 0,
    fat: 3.6,
    fiber: 0,
    extras: {NutrientKey.sodium: 74},
  );
  final chickenMeasures = FoodMeasures(
    basis: NutrientBasis.per100g,
    servingUnits: [ServingUnit.grams('piece', 172)],
  );

  NutrientSnapshot snapshotOf(CalculationResult result) => switch (result) {
    Computed(:final snapshot) => snapshot,
    NotComputed(:final reason) => fail('not computed: $reason'),
  };

  group('calculator:', () {
    test('per-100 g × grams / 100, snapshot rounded once', () {
      final input = Quantity(150, 'g');
      final snapshot = snapshotOf(
        calculator.compute(
          per100: chicken,
          measures: chickenMeasures,
          input: input,
        ),
      );
      expect(snapshot.amount, 150);
      expect(snapshot.basis, NutrientBasis.per100g);
      expect(snapshot.input, input);
      expect(
        snapshot.nutrients,
        Nutrients(
          kcal: 247.5,
          protein: 46.5,
          carbs: 0,
          fat: 5.4,
          fiber: 0,
          extras: {NutrientKey.sodium: 111},
        ),
      );
    });

    test('LC-011 8 oz is computed from the stored grams (226.8 g)', () {
      final snapshot = snapshotOf(
        calculator.compute(
          per100: chicken,
          measures: chickenMeasures,
          input: Quantity(8, 'oz'),
        ),
      );
      expect(snapshot.amount, 226.8);
      // 165 × 2.268 = 374.22 (not 165 × 2.26796185 = 374.21).
      expect(snapshot.nutrients.kcal, 374.22);
      expect(snapshot.nutrients.fat, 8.16);
      expect(snapshot.nutrients.extra(NutrientKey.sodium), 167.83);
    });

    test("LC-051 a portion unit is computed through the food's grams", () {
      final snapshot = snapshotOf(
        calculator.compute(
          per100: chicken,
          measures: chickenMeasures,
          input: Quantity(1, 'piece'),
        ),
      );
      expect(snapshot.amount, 172);
      expect(snapshot.nutrients.kcal, 283.8);
    });

    test('per-100 ml drink with ml input', () {
      final cola = Nutrients(
        kcal: 42,
        protein: 0,
        carbs: 10.6,
        fat: 0,
        fiber: 0,
        extras: {NutrientKey.sugar: 10.6},
      );
      final snapshot = snapshotOf(
        calculator.compute(
          per100: cola,
          measures: FoodMeasures(basis: NutrientBasis.per100ml),
          input: Quantity(330, 'ml'),
        ),
      );
      expect(snapshot.amount, 330);
      expect(snapshot.basis, NutrientBasis.per100ml);
      expect(snapshot.nutrients.kcal, 138.6);
      expect(snapshot.nutrients.carbs, 34.98);
      expect(snapshot.nutrients.extra(NutrientKey.sugar), 34.98);
    });

    test('zero amount → zero nutrients', () {
      final snapshot = snapshotOf(
        calculator.compute(
          per100: chicken,
          measures: chickenMeasures,
          input: Quantity(0, 'g'),
        ),
      );
      expect(snapshot.amount, 0);
      expect(
        snapshot.nutrients,
        Nutrients(
          kcal: 0,
          protein: 0,
          carbs: 0,
          fat: 0,
          fiber: 0,
          extras: {NutrientKey.sodium: 0},
        ),
      );
    });

    test(
      'an amount that does not resolve is not computed, with the reason',
      () {
        final result = calculator.compute(
          per100: chicken,
          measures: chickenMeasures,
          input: Quantity(1, 'cup'),
        );
        expect(
          result,
          isA<NotComputed>().having(
            (r) => r.reason,
            'reason',
            isA<NeedsDensity>(),
          ),
        );
      },
    );

    test('forAmount rounds the amount first and rejects invalid amounts', () {
      final snapshot = calculator.forAmount(
        per100: chicken,
        amount: 200.004,
        basis: NutrientBasis.per100g,
      );
      expect(snapshot.amount, 200);
      expect(snapshot.nutrients.kcal, 330);
      expect(snapshot.input, isNull);
      expect(
        () => calculator.forAmount(
          per100: chicken,
          amount: -1,
          basis: NutrientBasis.per100g,
        ),
        throwsArgumentError,
      );
      expect(
        () => calculator.forAmount(
          per100: chicken,
          amount: double.nan,
          basis: NutrientBasis.per100g,
        ),
        throwsArgumentError,
      );
    });

    test('recomputing from a stored snapshot gives the same nutrients', () {
      final first = snapshotOf(
        calculator.compute(
          per100: chicken,
          measures: chickenMeasures,
          input: Quantity(5.3, 'oz'),
        ),
      );
      final again = calculator.forAmount(
        per100: chicken,
        amount: first.amount,
        basis: first.basis,
      );
      expect(again.nutrients, first.nutrients);
    });
  });

  group('property: calculator', () {
    Glados3(
      any.per100Nutrients,
      any.storedAmount,
      any.storedAmount,
      propertyRuns,
    ).test('is linear within rounding (|f(a)+f(b)−f(a+b)| ≤ 0.015 per '
        'nutrient)', (per100, a, b) {
      Nutrients f(double amount) => calculator
          .forAmount(per100: per100, amount: amount, basis: .per100g)
          .nutrients;
      final split = f(a) + f(b);
      final whole = f(a + b);
      for (final (name, x, y) in _pairs(split, whole)) {
        expect((x - y).abs(), lessThanOrEqualTo(0.015 + 1e-9), reason: name);
      }
    });

    Glados3(
      any.per100Nutrients,
      any.storedAmount,
      any.storedAmount,
      propertyRuns,
    ).test('is non-negative and monotonic in amount', (per100, a, b) {
      final (small, large) = a <= b ? (a, b) : (b, a);
      Nutrients f(double amount) => calculator
          .forAmount(per100: per100, amount: amount, basis: .per100g)
          .nutrients;
      for (final (name, x, y) in _pairs(f(small), f(large))) {
        expect(x, greaterThanOrEqualTo(0), reason: name);
        expect(x, lessThanOrEqualTo(y), reason: name);
      }
    });
  });
}

/// The values of [a] and [b] side by side: the core five and the extras
/// both have.
List<(String, double, double)> _pairs(Nutrients a, Nutrients b) => [
  ('kcal', a.kcal, b.kcal),
  ('protein', a.protein, b.protein),
  ('carbs', a.carbs, b.carbs),
  ('fat', a.fat, b.fat),
  ('fiber', a.fiber, b.fiber),
  for (final MapEntry(:key, :value) in a.extras.entries)
    if (b.extra(key) case final other?) (key.code, value, other),
];
