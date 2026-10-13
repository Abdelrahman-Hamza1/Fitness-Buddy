import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

Nutrients _n({
  double kcal = 100,
  double protein = 10,
  double carbs = 10,
  double fat = 2,
  double fiber = 1,
  Map<NutrientKey, double> extras = const {},
}) => Nutrients(
  kcal: kcal,
  protein: protein,
  carbs: carbs,
  fat: fat,
  fiber: fiber,
  extras: extras,
);

void main() {
  test('FD-002 core nutrients are required and non-negative; extras optional '
      'and kept apart from the core', () {
    final plain = _n();
    expect(plain.extras, isEmpty);
    expect(plain.extra(NutrientKey.sugar), isNull);

    final labelled = _n(
      extras: {NutrientKey.sugar: 4, NutrientKey.sodium: 380},
    );
    expect(labelled.extra(NutrientKey.sugar), 4);
    expect(labelled.extra(NutrientKey.sodium), 380);
    expect(labelled.extra(NutrientKey.alcohol), isNull);
    expect(
      () => labelled.extras[NutrientKey.alcohol] = 1,
      throwsUnsupportedError,
    );

    for (final bad in [-0.1, double.nan, double.infinity]) {
      expect(() => _n(kcal: bad), throwsArgumentError);
      expect(() => _n(protein: bad), throwsArgumentError);
      expect(() => _n(carbs: bad), throwsArgumentError);
      expect(() => _n(fat: bad), throwsArgumentError);
      expect(() => _n(fiber: bad), throwsArgumentError);
      expect(() => _n(extras: {NutrientKey.sugar: bad}), throwsArgumentError);
    }
  });

  test('FD-002 each optional nutrient has a fixed unit and a stable code', () {
    expect(
      {for (final k in NutrientKey.values) k.code: k.unit.code},
      {
        'sugar': 'g',
        'saturated_fat': 'g',
        'trans_fat': 'g',
        'sodium': 'mg',
        'cholesterol': 'mg',
        'alcohol': 'g',
      },
    );
    for (final key in NutrientKey.values) {
      expect(NutrientKey.fromCode(key.code), key);
    }
    expect(NutrientKey.fromCode('fiber'), isNull);
  });

  test('FD-002 adding Nutrients keeps an extra only if both sides have it', () {
    final a = _n(extras: {NutrientKey.sugar: 4, NutrientKey.sodium: 100});
    final b = _n(kcal: 50, extras: {NutrientKey.sugar: 1});
    final sum = a + b;
    expect(sum.kcal, 150);
    expect(sum.protein, 20);
    expect(sum.carbs, 20);
    expect(sum.fat, 4);
    expect(sum.fiber, 2);
    expect(sum.extras, {NutrientKey.sugar: 5});
    expect(Nutrients.sum([a, b, _n()]).extras, isEmpty);
    expect(Nutrients.sum([a, a]).extra(NutrientKey.sodium), 200);
    expect(Nutrients.sum(const []), Nutrients.zero);
  });

  test('FD-002 scaling keeps absent extras absent', () {
    final half = _n(extras: {NutrientKey.sugar: 4}).scale(0.5);
    expect(half.kcal, 50);
    expect(half.extra(NutrientKey.sugar), 2);
    expect(half.extra(NutrientKey.sodium), isNull);
    expect(() => _n().scale(-1), throwsArgumentError);
    expect(() => _n().scale(double.nan), throwsArgumentError);
  });

  test('rounded() rounds every value to storage precision', () {
    final r = _n(
      kcal: 164.675,
      protein: 1.005,
      carbs: 0.004,
      fat: 2.3449,
      fiber: 0,
      extras: {NutrientKey.sodium: 12.345},
    ).rounded();
    expect(
      r,
      _n(
        kcal: 164.68,
        protein: 1.01,
        carbs: 0,
        fat: 2.34,
        fiber: 0,
        extras: {NutrientKey.sodium: 12.35},
      ),
    );
  });

  test('Nutrients is a value', () {
    final a = _n(extras: {NutrientKey.sugar: 4});
    expect(a, _n(extras: {NutrientKey.sugar: 4}));
    expect(a.hashCode, _n(extras: {NutrientKey.sugar: 4}).hashCode);
    expect(a, isNot(_n()));
    expect(a, isNot(_n(extras: {NutrientKey.sugar: 5})));
    expect(a, isNot(_n(extras: {NutrientKey.sodium: 4})));
    expect(_n(), isNot(_n(kcal: 1)));
    expect(_n(), isNot(_n(protein: 1)));
    expect(_n(), isNot(_n(carbs: 1)));
    expect(_n(), isNot(_n(fat: 1)));
    expect(_n(), isNot(_n(fiber: 0)));
    expect(
      a.toString(),
      'Nutrients(kcal: 100.0, protein: 10.0, carbs: 10.0, fat: 2.0, '
      'fiber: 1.0, extras: {NutrientKey.sugar: 4.0})',
    );
  });
}
