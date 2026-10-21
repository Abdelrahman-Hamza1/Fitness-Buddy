import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

void main() {
  test('TG-050 TG-051 TG-052 TG-053 default macro worked example', () {
    final plan = MacroPlan.calculate(baseKcal: 2000, weightKg: 70);
    final day = plan.forDay(2000);
    expect(plan.baseKcal, 2000);
    expect(plan.proteinGrams, 126);
    expect(plan.fatGrams, closeTo(2000 * .3 / 9, 1e-12));
    expect(plan.fiberGrams, 28);
    expect(plan.baseCarbOverrideGrams, isNull);
    expect(day.kcal, 2000);
    expect(day.carbsGrams, closeTo(224, 1e-12));
    expect(day.energyDifferenceKcal, closeTo(0, 1e-9));
    expect(day.energyDeficitKcal, 0);
    final heavy = MacroPlan.calculate(baseKcal: 1500, weightKg: 100);
    expect(heavy.fatGrams, 60);
  });

  test('TG-054 explicit gram/percent overrides and fixed daily fiber', () {
    final input = MacroSettings(
      protein: MacroOverride.percent(25),
      fat: MacroOverride.grams(60),
      carbs: MacroOverride.percent(40),
      fiberGrams: 35,
    );
    final plan = MacroPlan.calculate(
      baseKcal: 2000,
      weightKg: 70,
      settings: input,
    );
    expect(input.protein!.value, 25);
    expect(input.protein!.isPercent, isTrue);
    expect(input.fat!.isPercent, isFalse);
    expect(plan.proteinGrams, 125);
    expect(plan.fatGrams, 60);
    expect(plan.fiberGrams, 35);
    expect(plan.baseCarbOverrideGrams, 200);
    final base = plan.forDay(2000);
    expect(base.energyDifferenceKcal, -160);
    expect(base.energyDeficitKcal, 0);
    expect(plan.forDay(2200).carbsGrams, 250);
    final grams = MacroPlan.calculate(
      baseKcal: 2000,
      weightKg: 70,
      settings: MacroSettings(
        protein: MacroOverride.grams(150),
        fat: MacroOverride.percent(10),
        carbs: MacroOverride.grams(200),
      ),
    );
    expect(grams.proteinGrams, 150);
    expect(grams.fatGrams, 42); // The g/kg floor wins over the override.
    expect(grams.forDay(2000).carbsGrams, 200);
  });

  test(
    'TG-055 fixed P/F/fiber; only carbs flex; low day reports macro deficit',
    () {
      final plan = MacroPlan.calculate(
        baseKcal: 2000,
        weightKg: 70,
        settings: MacroSettings(
          protein: MacroOverride.grams(150),
          fat: MacroOverride.grams(120),
        ),
      );
      final base = plan.forDay(2000);
      expect(base.energyDeficitKcal, 0);
      expect(base.carbsGrams, 80);
      final low = plan.forDay(1500);
      expect(low.proteinGrams, base.proteinGrams);
      expect(low.fatGrams, base.fatGrams);
      expect(low.fiberGrams, base.fiberGrams);
      expect(low.carbsGrams, 0);
      expect(low.energyDeficitKcal, 180);
      expect(low.energyDifferenceKcal, 180);
      final over = MacroPlan.calculate(
        baseKcal: 2000,
        weightKg: 70,
        settings: MacroSettings(
          protein: MacroOverride.grams(150),
          carbs: MacroOverride.grams(500),
        ),
      );
      expect(over.forDay(2000).energyDeficitKcal, greaterThan(0));
      expect(over.forDay(1).carbsGrams, greaterThanOrEqualTo(0));
    },
  );

  test('TG-054 calories and protein only has no fat/carbs targets', () {
    final plan = MacroPlan.calculate(
      baseKcal: 2000,
      weightKg: 70,
      settings: MacroSettings(
        caloriesProteinOnly: true,
        carbs: MacroOverride.percent(90),
      ),
    );
    final base = plan.forDay(2000);
    expect(base.proteinGrams, 126);
    expect(base.fatGrams, isNull);
    expect(base.carbsGrams, isNull);
    expect(base.energyDifferenceKcal, isNull);
    expect(base.energyDeficitKcal, 0);
    expect(plan.forDay(300).energyDeficitKcal, 204);
  });

  test('TG-054 invalid macros are rejected without private values', () {
    for (final value in [-1.0, double.nan, double.infinity, 1000001.0]) {
      expect(() => MacroOverride.grams(value), throwsArgumentError);
      expect(() => MacroSettings(fiberGrams: value), throwsArgumentError);
    }
    for (final value in [-1.0, 101.0, double.nan, double.infinity]) {
      expect(() => MacroOverride.percent(value), throwsArgumentError);
    }
    expect(MacroOverride.percent(0).gramsAt(2000, 4), 0);
    expect(MacroOverride.percent(100).gramsAt(2000, 4), 500);
    expect(MacroOverride.grams(0).value, 0);
    expect(() => MacroOverride.percent(25).gramsAt(0, 4), throwsArgumentError);
    expect(
      () => MacroOverride.percent(25).gramsAt(2000, 0),
      throwsArgumentError,
    );
    expect(
      () => MacroOverride.percent(100).gramsAt(1000000, 1e-310),
      throwsArgumentError,
    );
    expect(
      () => MacroPlan.calculate(baseKcal: 0, weightKg: 70),
      throwsArgumentError,
    );
    expect(
      () => MacroPlan.calculate(baseKcal: 2000, weightKg: 0),
      throwsArgumentError,
    );
    final plan = MacroPlan.calculate(baseKcal: 2000, weightKg: 70);
    expect(() => plan.forDay(double.nan), throwsArgumentError);
  });
}
