import 'dart:math';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/today/application/today_numbers_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../presentation/support/today_targets_support.dart';

void main() {
  test('UX-050 without targets the view is the eaten numbers, rounded for '
      'display', () {
    final view = TodayNumbersView.of(
      eatenTotals(1239.5, protein: 82.44, fiber: 4.26),
      null,
    );
    expect(view, isA<EatenNumbers>());
    final eaten = view as EatenNumbers;
    expect(eaten.eatenKcal, 1240);
    expect(eaten.protein, DisplayRounding.nutrientGrams(82.44));
    expect(eaten.fiber, DisplayRounding.nutrientGrams(4.26));
    expect(view.toString(), 'EatenNumbers');
  });

  test('HM-001 remaining equals shown target minus shown eaten', () {
    // Sweeps targets and intakes whose fractions round both ways: the three
    // shown numbers always agree, and "over" is exactly a negative remainder.
    final random = Random(13);
    for (var i = 0; i < 500; i++) {
      final eatenKcal = random.nextDouble() * 4000;
      final day = targetsOn(
        weekDay(3),
        intake: [
          ate(weekDay(0), 1500 + random.nextDouble() * 1000),
          ate(weekDay(1), 1500 + random.nextDouble() * 1000),
        ],
      );
      final view =
          TodayNumbersView.of(eatenTotals(eatenKcal), day) as TargetNumbers;
      expect(view.targetKcal, DisplayRounding.kcal(day.day.kcal));
      expect(view.eatenKcal, DisplayRounding.kcal(eatenKcal));
      expect(view.remainingKcal, view.targetKcal - view.eatenKcal);
      expect(view.over, view.remainingKcal < 0);
    }
  });

  test('HM-002 the week line is the rounded week position with its '
      'uncounted days; TG-044 none in fixed mode', () {
    final weekly = TodayNumbersView.of(
      eatenTotals(0),
      targetsOn(
        weekDay(3),
        intake: [ate(weekDay(0), 1800.4), ate(weekDay(2), 2150.2)],
      ),
    ) as TargetNumbers;
    // Saturday −199.6, Monday +150.2 → −49.4; Sunday not counted.
    expect(weekly.week!.kcal, -49);
    expect(weekly.week!.uncountedDays, 1);

    final fixed = TodayNumbersView.of(
      eatenTotals(0),
      targetsOn(
        weekDay(3),
        settings: [sampleVersion(mode: TargetMode.fixed)],
        intake: [ate(weekDay(0), 1800)],
      ),
    ) as TargetNumbers;
    expect(fixed.week, isNull);
    expect(fixed.targetKcal, 2000);
  });

  test('HM-003 TG-054 macros carry their targets; calories and protein only '
      'leaves carbs and fat without one', () {
    final normal = TodayNumbersView.of(
      eatenTotals(1000, protein: 82.44),
      targetsOn(weekSat),
    ) as TargetNumbers;
    final macros = targetsOn(weekSat).day.macros;
    expect(normal.protein.eatenGrams, DisplayRounding.nutrientGrams(82.44));
    expect(
      normal.protein.targetGrams,
      DisplayRounding.macroTargetGrams(macros.proteinGrams),
    );
    expect(
      normal.carbs.targetGrams,
      DisplayRounding.macroTargetGrams(macros.carbsGrams!),
    );
    expect(
      normal.fat.targetGrams,
      DisplayRounding.macroTargetGrams(macros.fatGrams!),
    );
    expect(
      normal.fiber.targetGrams,
      DisplayRounding.macroTargetGrams(macros.fiberGrams),
    );

    final proteinOnly = TodayNumbersView.of(
      eatenTotals(1000),
      targetsOn(
        weekSat,
        settings: [
          sampleVersion(macros: MacroSettings(caloriesProteinOnly: true)),
        ],
      ),
    ) as TargetNumbers;
    expect(proteinOnly.protein.targetGrams, isNotNull);
    expect(proteinOnly.carbs.targetGrams, isNull);
    expect(proteinOnly.fat.targetGrams, isNull);
    expect(proteinOnly.fiber.targetGrams, isNotNull);
  });

  test('the views say nothing about their numbers in toString', () {
    final view = TodayNumbersView.of(
      eatenTotals(1234),
      targetsOn(weekDay(2)),
    ) as TargetNumbers;
    expect([view, view.week, view.protein].map((v) => v.toString()), [
      'TargetNumbers',
      'WeekLine',
      'MacroNumbers',
    ]);
  });
}
