import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

const _check = SanityCheck();

SanityResult _values({
  required double kcal,
  double protein = 0,
  double carbs = 0,
  double fat = 0,
  double fiber = 0,
  double alcohol = 0,
  NutrientBasis basis = NutrientBasis.per100g,
  SanityCheck check = _check,
}) => check.checkValues(
  kcal: kcal,
  protein: protein,
  carbs: carbs,
  fat: fat,
  fiber: fiber,
  alcohol: alcohol,
  basis: basis,
);

Matcher _is(SanityLevel level, SanityReason reason) => isA<SanityResult>()
    .having((r) => r.level, 'level', level)
    .having((r) => r.reason, 'reason', reason);

void main() {
  group('FD-012 sanity check:', () {
    test('FD-012 consistent food → ok (US-style carbs)', () {
      // Oats, USDA style: carbs 66.3 g include 10.6 g fiber.
      final result = _check.check(
        Nutrients(kcal: 389, protein: 16.9, carbs: 66.3, fat: 6.9, fiber: 10.6),
        NutrientBasis.per100g,
      );
      expect(result, _is(SanityLevel.ok, SanityReason.consistent));
      expect(result.convention, CarbConvention.fiberInCarbs);
      expect(result.expectedKcal, closeTo(394.9, 1e-9));
    });

    test('FD-012 consistent food → ok (EU-style carbs with fiber at '
        '2 kcal/g)', () {
      // Oats, EU label: carbs 58.7 g exclude 10.1 g fiber.
      final result = _values(
        kcal: 375,
        protein: 13.5,
        carbs: 58.7,
        fat: 7,
        fiber: 10.1,
      );
      expect(result, _is(SanityLevel.ok, SanityReason.consistent));
      expect(result.convention, CarbConvention.fiberSeparate);
      expect(result.expectedKcal, closeTo(372, 1e-9));
    });

    test('FD-012 alcohol counted at 7 kcal/g', () {
      // Beer per 100 ml.
      final beer = Nutrients(
        kcal: 43,
        protein: 0.5,
        carbs: 3.6,
        fat: 0,
        fiber: 0,
        extras: {NutrientKey.alcohol: 3.9},
      );
      final result = _check.check(beer, NutrientBasis.per100ml);
      expect(result, _is(SanityLevel.ok, SanityReason.consistent));
      expect(result.expectedKcal, closeTo(43.7, 1e-9));
      // Without the alcohol the same kcal look wrong.
      expect(
        _values(kcal: 43, protein: 0.5, carbs: 3.6).level,
        SanityLevel.warn,
      );
    });

    test('FD-012 15–30% off → warn', () {
      // Expected 330 kcal, stated 400: 70 kcal off, 17.5% of 400.
      final result = _values(kcal: 400, protein: 10, carbs: 50, fat: 10);
      expect(result, _is(SanityLevel.warn, SanityReason.kcalMismatch));
    });

    test('FD-012 > 30% off → fail', () {
      // Expected 330 kcal, stated 500: 170 kcal off, 34% of 500.
      final result = _values(kcal: 500, protein: 10, carbs: 50, fat: 10);
      expect(result, _is(SanityLevel.fail, SanityReason.kcalMismatch));
      // Too low counts the same: stated 200 vs expected 330 is 39% of 330.
      expect(
        _values(kcal: 200, protein: 10, carbs: 50, fat: 10).level,
        SanityLevel.fail,
      );
    });

    test('FD-012 low-kcal food within the 15 kcal floor → ok', () {
      // Expected 8 kcal, stated 20: 60% off but only 12 kcal.
      expect(
        _values(kcal: 20, protein: 0.5, carbs: 1.5),
        _is(SanityLevel.ok, SanityReason.consistent),
      );
      // 25 kcal off a 30 kcal drink is within the 30 kcal warn floor.
      expect(
        _values(kcal: 30, protein: 0.5, carbs: 0.75),
        _is(SanityLevel.warn, SanityReason.kcalMismatch),
      );
    });

    test('FD-012 negative value / kcal > 920 / macros > 105 g → hard fail', () {
      expect(
        _values(kcal: 100, protein: -1, carbs: 25),
        _is(SanityLevel.fail, SanityReason.invalidValue),
      );
      expect(
        _values(kcal: 100, carbs: 25, alcohol: -0.5),
        _is(SanityLevel.fail, SanityReason.invalidValue),
      );
      expect(
        _values(kcal: double.nan, carbs: 25),
        _is(SanityLevel.fail, SanityReason.invalidValue),
      );
      // 950 kcal matches 105.6 g fat, but nothing has more than 920 per 100.
      expect(
        _values(kcal: 950, fat: 105.6),
        _is(SanityLevel.fail, SanityReason.kcalTooHigh),
      );
      // 110 g of macros can't fit in 100 g, even with matching kcal.
      expect(
        _values(kcal: 490, protein: 40, carbs: 60, fat: 10),
        _is(SanityLevel.fail, SanityReason.macrosTooHeavy),
      );
    });

    test(
      'FD-012 the macro limit applies per 100 g only (honey per 100 ml)',
      () {
        expect(
          _values(
            kcal: 425,
            protein: 0.4,
            carbs: 115,
            basis: NutrientBasis.per100ml,
          ),
          _is(SanityLevel.ok, SanityReason.consistent),
        );
        expect(
          _values(kcal: 425, protein: 0.4, carbs: 115),
          _is(SanityLevel.fail, SanityReason.macrosTooHeavy),
        );
      },
    );

    test('FD-012 high-fiber US-style food (chia) is not a hard fail', () {
      // Chia seeds, USDA: carbs 42.1 g include 34.4 g fiber. P+C+F+fiber is
      // 123.7 g, but under the US convention the mass is P+C+F = 89.3 g (A4).
      final result = _values(
        kcal: 486,
        protein: 16.5,
        carbs: 42.1,
        fat: 30.7,
        fiber: 34.4,
      );
      expect(result, _is(SanityLevel.ok, SanityReason.consistent));
      expect(result.convention, CarbConvention.fiberInCarbs);
    });

    test('FD-012 under the EU convention fiber counts toward the macro '
        'limit', () {
      // P+C+F = 100 g, + 10 g fiber = 110 g; the EU reading fits 520 kcal.
      final result = _values(
        kcal: 520,
        protein: 20,
        carbs: 60,
        fat: 20,
        fiber: 10,
      );
      expect(result, _is(SanityLevel.fail, SanityReason.macrosTooHeavy));
      expect(result.convention, CarbConvention.fiberSeparate);
    });

    test('FD-012 result reports expected kcal and deviation', () {
      final result = _values(kcal: 400, protein: 10, carbs: 50, fat: 10);
      expect(result.expectedKcal, 330);
      expect(result.deviation, 70);
      expect(result.convention, CarbConvention.fiberInCarbs);
    });

    test('FD-012 thresholds live in one tolerance value', () {
      const defaults = SanityTolerance.defaults;
      expect(defaults.okKcal, 15);
      expect(defaults.okFraction, 0.15);
      expect(defaults.warnKcal, 30);
      expect(defaults.warnFraction, 0.30);
      expect(defaults.maxKcalPer100, 920);
      expect(defaults.maxMacroGramsPer100g, 105);
      expect(_check.tolerance, same(defaults));
      // A looser tolerance turns the 17.5% warning into ok.
      const loose = SanityCheck(SanityTolerance(okFraction: 0.25));
      expect(
        _values(kcal: 400, protein: 10, carbs: 50, fat: 10, check: loose).level,
        SanityLevel.ok,
      );
    });
  });
}
