import 'package:fb_domain/fb_domain.dart';
import 'package:glados/glados.dart';

import '../helpers/property.dart';

void main() {
  final converter = YieldConverter([
    YieldFactor(
      group: 'rice',
      from: FoodState.dry,
      to: FoodState.cooked,
      factor: 2.5,
    ),
    YieldFactor(
      group: 'chicken',
      from: FoodState.raw,
      to: FoodState.cooked,
      factor: 0.75,
    ),
  ]);

  group('FD-060 yield conversion:', () {
    test('FD-060 cooked amount converts to dry via the factor', () {
      final note = converter.convert(
        amount: Mass.grams(200),
        group: 'rice',
        from: FoodState.dry,
        to: FoodState.cooked,
      )!;
      expect(note.toAmount, Mass.grams(500));
      expect(note.factor, 2.5);
    });

    test('FD-060 inverse row is used when only the reverse exists', () {
      // 500 g cooked rice → 200 g dry, then the dry food's per-100 g values.
      final note = converter.convert(
        amount: Mass.grams(500),
        group: 'rice',
        from: FoodState.cooked,
        to: FoodState.dry,
      )!;
      expect(note.toAmount.grams, closeTo(200, 1e-9));
      expect(note.factor, 0.4);
    });

    test('FD-060 a direct row wins over the inverse of the reverse row', () {
      final both = YieldConverter([
        YieldFactor(
          group: 'pasta',
          from: FoodState.dry,
          to: FoodState.cooked,
          factor: 2.2,
        ),
        YieldFactor(
          group: 'pasta',
          from: FoodState.cooked,
          to: FoodState.dry,
          factor: 0.5,
        ),
      ]);
      expect(
        both
            .convert(
              amount: Mass.grams(100),
              group: 'pasta',
              from: FoodState.cooked,
              to: FoodState.dry,
            )!
            .factor,
        0.5,
      );
    });

    test('FD-060 no factor → null', () {
      expect(
        converter.convert(
          amount: Mass.grams(100),
          group: 'rice',
          from: FoodState.raw,
          to: FoodState.fried,
        ),
        isNull,
      );
      expect(
        converter.convert(
          amount: Mass.grams(100),
          group: 'lentils',
          from: FoodState.dry,
          to: FoodState.cooked,
        ),
        isNull,
      );
    });

    test('FD-060 the same state converts with factor 1', () {
      final note = converter.convert(
        amount: Mass.grams(150),
        group: 'anything',
        from: FoodState.cooked,
        to: FoodState.cooked,
      )!;
      expect(note.factor, 1);
      expect(note.toAmount, Mass.grams(150));
    });

    test('FD-060 the calculator uses the exact converted amount (A8)', () {
      // 333 g cooked rice → 133.2 g dry exactly; the note says ≈ 135 g.
      final note = converter.convert(
        amount: Mass.grams(333),
        group: 'rice',
        from: FoodState.cooked,
        to: FoodState.dry,
      )!;
      expect(note.toGramsForNote, 135);
      final dryRice = Nutrients(
        kcal: 360,
        protein: 6.6,
        carbs: 79,
        fat: 0.6,
        fiber: 1.3,
      );
      final snapshot = const NutritionCalculator().forAmount(
        per100: dryRice,
        amount: note.toAmount.grams,
        basis: NutrientBasis.per100g,
      );
      expect(snapshot.amount, 133.2);
      expect(snapshot.nutrients.kcal, 479.52);
    });

    test('FD-060 invalid rows are rejected', () {
      expect(
        () => YieldFactor(
          group: 'rice',
          from: FoodState.dry,
          to: FoodState.cooked,
          factor: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => YieldFactor(
          group: 'rice',
          from: FoodState.dry,
          to: FoodState.cooked,
          factor: double.nan,
        ),
        throwsArgumentError,
      );
      expect(
        () => YieldFactor(
          group: 'rice',
          from: FoodState.dry,
          to: FoodState.dry,
          factor: 1,
        ),
        throwsArgumentError,
      );
      final row = YieldFactor(
        group: 'rice',
        from: FoodState.dry,
        to: FoodState.cooked,
        factor: 2.5,
      );
      expect(() => YieldConverter([row, row]), throwsArgumentError);
    });

    Glados3(
      any.positiveAmount,
      any.yieldFactor,
      any.foodState,
      propertyRuns,
    ).test('property: convert there and back is identity within 1e-9', (
      grams,
      factor,
      to,
    ) {
      const from = FoodState.raw;
      final target = to == from ? FoodState.cooked : to;
      final yields = YieldConverter([
        YieldFactor(group: 'g', from: from, to: target, factor: factor),
      ]);
      final there = yields.convert(
        amount: Mass.grams(grams),
        group: 'g',
        from: from,
        to: target,
      )!;
      final back = yields.convert(
        amount: there.toAmount,
        group: 'g',
        from: target,
        to: from,
      )!;
      expect(
        closeRelative(back.toAmount.grams, grams),
        isTrue,
        reason: '${back.toAmount.grams} != $grams',
      );
    });
  });

  group('FD-062 yield note:', () {
    test('FD-062 yield note carries from/to amounts and states, rounded to '
        '5 g ("200 g dry ≈ 500 g cooked")', () {
      final note = converter.convert(
        amount: Mass.grams(200),
        group: 'rice',
        from: FoodState.dry,
        to: FoodState.cooked,
      )!;
      expect(note.fromAmount, Mass.grams(200));
      expect(note.fromState, FoodState.dry);
      expect(note.toState, FoodState.cooked);
      expect(note.toGramsForNote, 500);
    });

    test('FD-062 the note rounds to 5 g from 50 g, whole grams below', () {
      int noteFor(double rawGrams) => converter
          .convert(
            amount: Mass.grams(rawGrams),
            group: 'chicken',
            from: FoodState.raw,
            to: FoodState.cooked,
          )!
          .toGramsForNote;
      expect(noteFor(649.33), 485); // 486.9975 g cooked
      expect(noteFor(130), 100); // 97.5 g → nearest 5 (ties away) = 100
      expect(noteFor(66), 50); // 49.5 g → whole grams = 50
      expect(noteFor(60), 45); // exactly 45 g
      expect(noteFor(62), 47); // 46.5 g → 47
    });
  });
}
