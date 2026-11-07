import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

final _saturday = LocalDate(2026, 10, 17);

Map<DayOfWeek, double> _every(double factor) => {
  for (final day in DayOfWeek.values) day: factor,
};

// Covers: TG-046, TG-040, TG-041, TG-053
void main() {
  group('TG-046 seven equal days are the daily number', () {
    test('TG-046 with no own day numbers the macros follow the suggestion', () {
      final plan = TargetPlan(baseKcal: 2150, floorKcal: 1500);
      expect(plan.dailyKcal, 2150);
      final day = plan.day(date: _saturday, weightKg: 80);
      final expected = MacroPlan.calculate(
        baseKcal: 2150,
        weightKg: 80,
      ).forDay(day.kcal);
      expect(day.macros.fatGrams, expected.fatGrams);
      expect(day.macros.fiberGrams, expected.fiberGrams);
    });

    test('TG-046 every weekday at 1,800 plans fat, fiber and carbs from '
        '1,800, protein stays from the weight', () {
      final plan = TargetPlan(
        baseKcal: 2150,
        floorKcal: 1500,
        dayFactors: _every(1800 / 2150),
      );
      expect(plan.dailyKcal, closeTo(1800, 1e-9));
      final day = plan.day(date: _saturday, weightKg: 80);
      final own = MacroPlan.calculate(
        baseKcal: 1800,
        weightKg: 80,
      ).forDay(1800);
      expect(day.kcal, closeTo(1800, 1e-9));
      expect(day.macros.fatGrams, closeTo(own.fatGrams!, 1e-9));
      expect(day.macros.fiberGrams, closeTo(own.fiberGrams, 1e-9));
      expect(day.macros.carbsGrams, closeTo(own.carbsGrams!, 1e-9));
      expect(day.macros.proteinGrams, 1.8 * 80);
    });

    test('TG-046 the same macros as an own target of 1,800', () {
      final byDay = TargetPlan(
        baseKcal: 2150,
        floorKcal: 1500,
        dayFactors: _every(1800 / 2150),
      ).day(date: _saturday, weightKg: 80);
      final own = TargetPlan(
        baseKcal: 1800,
        floorKcal: 1500,
        manual: true,
      ).day(date: _saturday, weightKg: 80);
      expect(byDay.macros.fatGrams, closeTo(own.macros.fatGrams!, 1e-9));
      expect(byDay.macros.carbsGrams, closeTo(own.macros.carbsGrams!, 1e-9));
      expect(byDay.macros.fiberGrams, closeTo(own.macros.fiberGrams, 1e-9));
    });

    test('TG-043 days that differ keep the suggestion as the macro base', () {
      final plan = TargetPlan(
        baseKcal: 2000,
        floorKcal: 1500,
        dayFactors: {DayOfWeek.friday: 1.25},
      );
      expect(plan.dailyKcal, 2000);
      final day = plan.day(date: _saturday, weightKg: 80);
      expect(
        day.macros.fiberGrams,
        MacroPlan.calculate(baseKcal: 2000, weightKg: 80).fiberGrams,
      );
    });

    test('TG-040 TG-041 equal days leave the weekly budget and rebalancing '
        'as they were', () {
      final plan = TargetPlan(
        baseKcal: 2150,
        floorKcal: 1500,
        dayFactors: _every(1800 / 2150),
      );
      final monday = _saturday.plusDays(2);
      final day = plan.day(
        date: monday,
        weightKg: 80,
        earlierIntake: [
          WeekIntake(date: _saturday, kcal: 2100),
          WeekIntake(date: _saturday.plusDays(1), kcal: 1800),
        ],
      );
      expect(day.week!.budgetKcal, closeTo(7 * 1800, 1e-6));
      // 300 over on Saturday spreads over the five days left.
      expect(day.kcal, closeTo(1800 - 300 / 5, 1e-6));
      // Carbs flex with the day; fat and fiber stay from 1,800.
      final own = MacroPlan.calculate(baseKcal: 1800, weightKg: 80);
      expect(day.macros.fatGrams, closeTo(own.fatGrams!, 1e-9));
      expect(day.macros.fiberGrams, closeTo(own.fiberGrams, 1e-9));
    });
  });

  group('TG-046 the Change sheet preview', () {
    test('TG-046 the preview is MacroPlan at the new number, and "was" is '
        "today's daily number", () {
      final macros = MacroSettings(fiberGrams: 30);
      final plan = TargetPlan(baseKcal: 2150, floorKcal: 1500, macros: macros);
      final preview = DailyTargetPreview.of(
        plan: plan,
        kcal: 1800,
        macroWeightKg: 75,
        expenditureKcal: 2400,
      );
      final expected = MacroPlan.calculate(
        baseKcal: 1800,
        weightKg: 75,
        settings: macros,
      ).forDay(1800);
      expect(preview.macros.proteinGrams, expected.proteinGrams);
      expect(preview.macros.fatGrams, expected.fatGrams);
      expect(preview.macros.carbsGrams, expected.carbsGrams);
      expect(preview.macros.fiberGrams, 30);
      expect(preview.currentKcal, 2150);
      expect(
        preview.currentMacros.carbsGrams,
        plan.day(date: _saturday, weightKg: 75).macros.carbsGrams,
      );
      expect(preview.kgPerWeek, closeTo(-600 * 7 / 7700, 1e-9));
      final shares = preview.shares!;
      expect(shares.protein + shares.fat + shares.carbs, closeTo(1, 1e-9));
      expect(shares.fat, closeTo(.3, 1e-9));
    });

    test('TG-054 calories and protein only has no shares; no expenditure '
        'no rate', () {
      final plan = TargetPlan(
        baseKcal: 2000,
        floorKcal: 1500,
        macros: MacroSettings(caloriesProteinOnly: true),
      );
      final preview = DailyTargetPreview.of(
        plan: plan,
        kcal: 1900,
        macroWeightKg: 70,
      );
      expect(preview.shares, isNull);
      expect(preview.kgPerWeek, isNull);
      expect(preview.toString(), 'DailyTargetPreview');
    });
  });
}
