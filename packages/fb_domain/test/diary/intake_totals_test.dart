import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

import '../helpers/diary.dart';

void main() {
  group('IntakeTotals:', () {
    test('IntakeTotals coverage full/partial/none; valueOf null for none; '
        'estimated from Buddy and user estimates', () {
      final known = entry(snapshot: snapshotOf(200, protein: 25));
      final kcalOnly = estimateEntry();
      final withProtein = estimateEntry(id: entryC, kcal: 300, protein: 10);

      final full = DiaryTotals.intake([known]);
      expect(full.coverage(NutrientField.protein), NutrientCoverage.full);
      expect(full.estimated, isFalse);

      final none = DiaryTotals.intake([kcalOnly]);
      expect(none.coverage(NutrientField.protein), NutrientCoverage.none);
      expect(none.valueOf(NutrientField.protein), isNull);
      expect(none.valueOf(NutrientField.kcal), 700);
      expect(none.estimated, isTrue);

      final mixed = DiaryTotals.intake([known, kcalOnly, withProtein]);
      expect(mixed.coverage(NutrientField.protein), NutrientCoverage.partial);
      expect(mixed.valueOf(NutrientField.protein), 35);
      expect(mixed.isLowerBound(NutrientField.protein), isTrue);
      expect(mixed.coverage(NutrientField.fiber), NutrientCoverage.partial);
      expect(mixed.coverage(NutrientField.kcal), NutrientCoverage.full);
      expect(mixed.sum.kcal, 1200);

      // Buddy's estimate: every value known, still "~".
      final buddy = entry(
        id: entryC,
        food: EntryFood(
          ref: FoodRef.estimate(),
          names: FoodNames('Koshari'),
          per100: rice100,
          provenance: Provenance(source: FoodSource.estimate),
        ),
      );
      final b = DiaryTotals.intake([known, buddy]);
      expect(b.estimated, isTrue);
      expect(b.coverage(NutrientField.protein), NutrientCoverage.full);
      expect(b.isApproximate(NutrientField.protein), isTrue);
    });

    test('DY-006 a day estimate is kcal only, estimated, every macro unknown; '
        'adding food keeps the flag', () {
      final day = IntakeTotals.ofDayEstimate(2300);
      expect(day.sum.kcal, 2300);
      expect(day.estimated, isTrue);
      expect(day.dayEstimate, isTrue);
      for (final field in IntakeTotals.unknowable) {
        expect(day.coverage(field), NutrientCoverage.none, reason: '$field');
        expect(day.valueOf(field), isNull);
      }
      expect('$day', isNot(contains('2300')));
      final week = day + IntakeTotals.known(Nutrients.zero);
      expect(week.dayEstimate, isTrue);
      expect(week.coverage(NutrientField.protein), NutrientCoverage.partial);
    });

    test('IntakeTotals + and fromCounts agree with ofEntries', () {
      final a = DiaryTotals.intake([entry(snapshot: snapshotOf(100))]);
      final b = DiaryTotals.intake([estimateEntry(kcal: 50)]);
      final sum = a + b;
      expect(sum.items, 2);
      expect(sum.coverage(NutrientField.carbs), NutrientCoverage.partial);
      expect(sum.estimated, isTrue);
      final counted = IntakeTotals.fromCounts(
        sum: sum.sum,
        items: 2,
        estimates: 1,
        proteinUnknown: 1,
        carbsUnknown: 1,
        fatUnknown: 1,
        fiberUnknown: 1,
      );
      expect(counted, sum);
      expect(
        () => IntakeTotals.fromCounts(
          sum: Nutrients.zero,
          items: 1,
          estimates: 0,
          proteinUnknown: 2,
        ),
        throwsArgumentError,
      );
    });

    test('DY-024 dish group with an estimate member is estimated; DY-031 '
        'saved meal keeps known flags and "~"', () {
      final group = DishGroup(
        id: groupG,
        version: 1,
        name: 'Dinner out',
        localDate: LocalDate(2026, 10, 13),
        slotId: DefaultSlots.lunchId,
      );
      final members = [entry(dishGroupId: groupG), estimateEntry(protein: 30)];
      final item = GroupItem(group, members);
      expect(item.intake.estimated, isTrue);
      expect(item.intake.isLowerBound(NutrientField.carbs), isTrue);

      final estimate = const UserEstimate(kcal: 600, protein: 0).food();
      final meal = SavedMeal(
        id: savedMeal,
        version: 1,
        name: 'Friday',
        items: [
          SavedMealItem(
            id: entryA,
            version: 1,
            sortOrder: 0,
            food: estimate,
            amount: UserEstimate.amount,
            snapshot: estimate.per100,
          ),
        ],
      );
      expect(meal.intake.estimated, isTrue);
      expect(meal.intake.valueOf(NutrientField.protein), 0);
      expect(meal.intake.valueOf(NutrientField.carbs), isNull);
    });

    test('IN-003 averages: kcal over all days, each macro over its fully '
        'known days only; a single day flags lower bounds', () {
      final fullDay = DiaryTotals.intake([
        entry(snapshot: snapshotOf(2000, protein: 100)),
      ]);
      final kcalOnlyDay = DiaryTotals.intake([estimateEntry(kcal: 1800)]);
      final mixedDay = DiaryTotals.intake([
        entry(snapshot: snapshotOf(500, protein: 25)),
        estimateEntry(kcal: 900),
      ]);
      final avg = IntakeAverages.over([fullDay, kcalOnlyDay, mixedDay])!;
      expect(avg.kcal, closeTo((2000 + 1800 + 1400) / 3, 1e-9));
      expect(avg.protein, 100, reason: 'only the fully known day counts');
      expect(avg.estimated, isTrue);
      expect(IntakeAverages.over(const []), isNull);
      final none = IntakeAverages.over([kcalOnlyDay])!;
      expect(none.protein, isNull);

      final day = IntakeAverages.ofDay(mixedDay);
      expect(day.protein, 25);
      expect(day.lowerBound, contains(NutrientField.protein));
      expect(day.isApproximate(NutrientField.protein), isTrue);
      expect(IntakeAverages.ofDay(kcalOnlyDay).protein, isNull);
    });
  });
}
