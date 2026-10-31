import 'dart:math';

import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

import '../helpers/diary.dart';

DiaryEntry measured(
  double amount,
  double input,
  String unit,
  NutrientBasis basis,
) => DiaryEntry(
  id: entryA,
  version: 1,
  time: entry().time,
  localDate: entry().localDate,
  slotId: DefaultSlots.lunchId,
  food: riceFood(),
  snapshot: rice100,
  amount: EntryAmount(
    input: Quantity(input, unit),
    amount: amount,
    basis: basis,
  ),
);

void main() {
  test('AI-072 EntryFood equality includes the explicit edit flag', () {
    final food = riceFood();
    EntryFood chosen({required bool edited}) => EntryFood(
      ref: food.ref,
      names: food.names,
      per100: food.per100,
      provenance: food.provenance,
      editedByUser: edited,
    );
    expect(chosen(edited: true), chosen(edited: true));
    expect(chosen(edited: true).hashCode, chosen(edited: true).hashCode);
    expect(chosen(edited: true), isNot(chosen(edited: false)));
  });
  test('DY-020 cross-day group references stay ungrouped', () {
    final row = entry(dishGroupId: groupG);
    final group = DishGroup(
      id: groupG,
      version: 1,
      name: 'Dish',
      localDate: row.localDate.plusDays(-1),
      slotId: row.slotId,
    );
    final section = DayLayout.build(
      DefaultSlots.all,
      [group],
      [row],
    ).sections.singleWhere((s) => s.slot?.id == row.slotId);
    expect(section.items.single, isA<EntryItem>());
    expect(section.entryCopyGroupIds, isEmpty);
  });

  test('AI-072 field caps reject huge values; negative zero normalises', () {
    for (final field in NutrientField.values) {
      for (final value in [field.maxValue + 1, 1e308]) {
        expect(
          () => OverrideNutrients(entryA, 1, {field: value}),
          throwsArgumentError,
        );
      }
      final result = NutrientOverride.apply(
        rice100,
        amount: 100,
        values: {field: -0.0},
      );
      expect(result.valueOf(field), 0);
      expect(result.valueOf(field)!.isNegative, isFalse);
      expect(
        () => NutrientOverride.apply(
          rice100,
          amount: 1e-300,
          values: {field: field.maxValue},
        ),
        throwsArgumentError,
      );
      expect(
        NutrientOverride.apply(
          rice100,
          amount: 100,
          values: {field: field.maxValue},
        ).valueOf(field),
        field.maxValue,
      );
    }
  });
  test('DY-023 SaveMeal trims and enforces 1–60 characters, no NUL (#102)', () {
    SaveMeal build(String name) => SaveMeal(
      savedMealId: savedMeal,
      name: name,
      source: MealSource.entries([entryA]),
      expected: SourceVersions(entries: [VersionedId(entryA, 1)]),
    );
    expect(build(' Meal ').name, 'Meal');
    expect(build('a' * 60).name.length, 60);
    for (final name in ['', '   ', 'a' * 61, 'Lunch\u0000']) {
      expect(() => build(name), throwsArgumentError);
    }
  });

  test('DY-021 EntryMeasures: 1 loaf → 2 loaves = 120 g; a food '
      'cup on a g basis → 2 cups = 400 g; g ↔ oz on a g basis; '
      'volume hidden on a g basis without density', () {
    for (final (unit, size) in [('loaf', 60.0), ('cup', 200.0)]) {
      final e = measured(size, 1, unit, NutrientBasis.per100g);
      expect(EntryAmounts.resolve(e, Quantity(2, unit))!.amount, size * 2);
    }
    final e = measured(100, 100, 'g', NutrientBasis.per100g);
    expect(EntryAmounts.resolve(e, Quantity(1, 'oz'))!.amount, 28.35);
    expect(UnitOptions.of(EntryMeasures.of(e)), isNot(contains('ml')));
    expect(EntryAmounts.resolve(e, Quantity(1, 'ml')), isNull);
    expect(EntryAmounts.resolve(e, Quantity(0, 'g')), isNull);
    expect(EntryAmounts.resolve(e, Quantity(0.001, 'g')), isNull);
  });
  test('DY-021 a food cup of 200 ml on an ml basis: the unchanged '
      'input resolves to 200 ml (not 236.59) and 2 cups = 400 ml', () {
    final e = measured(200, 1, 'cup', NutrientBasis.per100ml);
    expect(EntryAmounts.resolve(e, e.amount.input)!.amount, 200);
    expect(EntryAmounts.resolve(e, Quantity(2, 'cup'))!.amount, 400);
  });
  test('DY-021 a standard unit whose generic size equals the '
      'stored amount (100 g, 250 ml) gets no reconstructed '
      'serving', () {
    for (final (unit, basis, amount) in [
      ('g', NutrientBasis.per100g, 100.0),
      ('ml', NutrientBasis.per100ml, 250.0),
    ]) {
      expect(
        EntryMeasures.of(measured(amount, amount, unit, basis)).servingUnits,
        isEmpty,
      );
    }
  });
  test('property: for any stored entry on either basis, '
      'EntryAmounts.resolve(entry, its own input) == the stored '
      'amount, and doubling the input doubles it (within storage '
      'precision)', () {
    final random = Random(805);
    for (var i = 0; i < 1000; i++) {
      final amount = (1 + random.nextInt(500000)) / 100;
      final input = (1 + random.nextInt(50000)) / 100;
      final e = measured(
        amount,
        input,
        ['cup', 'loaf', 'g', 'ml'][i % 4],
        NutrientBasis.values[i % 2],
      );
      expect(EntryAmounts.resolve(e, e.amount.input)!.amount, amount);
      expect(
        EntryAmounts.resolve(
          e,
          Quantity(input * 2, e.amount.input.unitCode),
        )!.amount,
        closeTo(amount * 2, 0.005),
      );
    }
    for (final e in [
      measured(0, 1, 'cup', NutrientBasis.per100g),
      measured(1, 0, 'cup', NutrientBasis.per100g),
      measured(1e308, 1e-308, 'cup', NutrientBasis.per100g),
    ]) {
      expect(reconstructedServingOf(e.amount), isNull);
    }
  });
  test('FoodHistoryItem.derivedServing follows the same rule (a '
      '200 ml cup re-logs as 200 ml)', () {
    final e = measured(200, 1, 'cup', NutrientBasis.per100ml);
    final h = FoodHistoryItem(
      food: e.food,
      amount: e.amount,
      uses: 1,
      lastUsedHlc: Hlc(wallMs: 1, counter: 0, deviceId: entryA),
    );
    expect(h.derivedServing!.amount, 200);
  });
  test('AI-072 property: overriding field f to v gives '
      'snapshot[f] == round(v) for amounts 0.01–5,000 and values '
      '0–5,000 with ≤ 2 decimals', () {
    final random = Random(8072);
    for (var i = 0; i < 1000; i++) {
      final amount = (1 + random.nextInt(500000)) / 100;
      final value = random.nextInt(500001) / 100;
      final field = NutrientField.values[i % NutrientField.values.length];
      final per100 = NutrientOverride.apply(
        rice100,
        amount: amount,
        values: {field: value},
      );
      final snapshot = const NutritionCalculator()
          .forAmount(
            per100: per100,
            amount: amount,
            basis: NutrientBasis.per100g,
          )
          .nutrients;
      expect(snapshot.valueOf(field), StoragePrecision.round(value));
      expect(field.unit, isNotEmpty);
      for (final other in NutrientField.values.where((f) => f != field)) {
        expect(per100.valueOf(other), rice100.valueOf(other));
      }
    }
    expect(
      () => NutrientOverride.apply(
        rice100,
        amount: 0,
        values: {NutrientField.kcal: 1},
      ),
      throwsArgumentError,
    );
    expect(
      () => NutrientOverride.apply(rice100, amount: 1, values: {}),
      throwsArgumentError,
    );
    for (final value in [-1.0, double.nan, double.infinity]) {
      expect(
        () => OverrideNutrients(entryA, 1, {NutrientField.kcal: value}),
        throwsArgumentError,
      );
    }
  });
  test('toString of OverrideNutrients shows no values', () {
    final a = OverrideNutrients(entryA, 1, {NutrientField.protein: 123.45});
    final b = OverrideNutrients(entryA, 1, {NutrientField.protein: 123.45});
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(OverrideNutrients(entryA, 2, b.values)));
    expect(a, isNot(OverrideNutrients(entryA, 1, {NutrientField.protein: 2})));
    expect(a, isNot('other'));
    expect(a.family, 'diary');
    expect('$a', 'OverrideNutrients($entryA@v1)');
    expect(a.values.clear, throwsUnsupportedError);
  });
  test('DY-023 CopyMeal constructor requires expected entries ⊆ '
      'copyIds keys ⊆ expected entries ∪ groups', () {
    final expected = SourceVersions(
      entries: [VersionedId(entryA, 1)],
      groups: [VersionedId(groupG, 2)],
    );
    expect(
      expected,
      SourceVersions(
        entries: [VersionedId(entryA, 1)],
        groups: [VersionedId(groupG, 2)],
      ),
    );
    expect(
      expected.hashCode,
      SourceVersions(
        entries: [VersionedId(entryA, 1)],
        groups: [VersionedId(groupG, 2)],
      ).hashCode,
    );
    expect(expected, isNot(SourceVersions(entries: [])));
    expect(
      () => SourceVersions(
        entries: [VersionedId(entryA, 1), VersionedId(entryA, 2)],
      ),
      throwsArgumentError,
    );
    CopyMeal build(Map<String, String> ids) => CopyMeal(
      MealSource.entries([entryA]),
      toDate: entry().localDate,
      copyIds: ids,
      expected: expected,
    );
    expect(build({entryA: copyA}).copyIds, {entryA: copyA});
    expect(build({entryA: copyA, groupG: copyG}).copyIds.length, 2);
    expect(() => build({groupG: copyG}), throwsArgumentError);
    expect(() => build({entryA: groupG}), throwsArgumentError);
    expect(() => build({entryA: copyA, entryB: copyB}), throwsArgumentError);
    expect(
      () => SaveMeal(
        savedMealId: savedMeal,
        name: 'Meal',
        source: MealSource.entries([entryA]),
        expected: expected,
      ),
      throwsArgumentError,
    );
  });
}
