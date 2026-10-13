import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

void main() {
  group('rounding:', () {
    test('half away from zero at storage precision '
        '(2.675→2.68, 1.005→1.01, 0.004→0)', () {
      expect(StoragePrecision.decimals, 2);
      expect(StoragePrecision.round(2.675), 2.68);
      expect(StoragePrecision.round(1.005), 1.01);
      expect(StoragePrecision.round(0.004), 0);
      expect(StoragePrecision.round(0.005), 0.01);
      expect(StoragePrecision.round(-2.675), -2.68);
      expect(StoragePrecision.round(-0.004), 0);
      expect(StoragePrecision.round(-0.004).isNegative, isFalse);
      expect(StoragePrecision.round(123.454999), 123.45);
      expect(StoragePrecision.round(99999.995), 100000);
    });

    test('other precisions and invalid input', () {
      expect(roundHalfAwayFromZero(2.5, 0), 3);
      expect(roundHalfAwayFromZero(-2.5, 0), -3);
      expect(roundHalfAwayFromZero(0.05, 1), 0.1);
      expect(roundHalfAwayFromZero(1.0000005, 6), 1.000001);
      expect(() => roundHalfAwayFromZero(double.nan, 2), throwsArgumentError);
      expect(
        () => roundHalfAwayFromZero(double.infinity, 2),
        throwsArgumentError,
      );
      expect(() => roundHalfAwayFromZero(1, -1), throwsRangeError);
      expect(() => roundHalfAwayFromZero(1, 7), throwsRangeError);
    });

    test('a value too large for 6 clean decimals throws', () {
      expect(roundHalfAwayFromZero(999999999999.99, 2), 999999999999.99);
      expect(
        () => roundHalfAwayFromZero(10_000_000_000_000, 2),
        throwsArgumentError,
      );
      expect(
        () => roundHalfAwayFromZero(-1_000_000_000_000_000, 0),
        throwsArgumentError,
      );
      expect(() => roundHalfAwayFromZero(1e300, 0), throwsArgumentError);
    });

    test('display rounding table (D3)', () {
      // kcal → whole.
      expect(DisplayRounding.kcal(164.5), 165);
      expect(DisplayRounding.kcal(164.49), 164);
      // Nutrient g → 1 decimal below 10 g, whole from 10 g.
      expect(DisplayRounding.nutrientGrams(3.25), 3.3);
      expect(DisplayRounding.nutrientGrams(9.94), 9.9);
      expect(DisplayRounding.nutrientGrams(9.96), 10);
      expect(DisplayRounding.nutrientGrams(10.4), 10);
      expect(DisplayRounding.nutrientGrams(31.5), 32);
      // mg → whole.
      expect(DisplayRounding.milligrams(412.5), 413);
      // Food g/ml → whole.
      expect(DisplayRounding.foodAmount(149.5), 150);
      // Body kg/lb, oz, fl oz → 1 decimal.
      expect(DisplayRounding.oneDecimal(81.25), 81.3);
      expect(DisplayRounding.oneDecimal(5.29), 5.3);
      // cm, in → whole.
      expect(DisplayRounding.length(172.5), 173);
    });

    test('day total rounds the sum of stored values, not displayed values', () {
      // Three snapshots of 0.4 kcal each show as 0 kcal each…
      final entries = [for (var i = 0; i < 3; i++) Energy.kcal(0.4)];
      expect(entries.map((e) => DisplayRounding.kcal(e.kcal)), [0, 0, 0]);
      // …and the day total is round(0.4 + 0.4 + 0.4) = 1, not 0 + 0 + 0.
      final total = entries.reduce((a, b) => a + b);
      expect(DisplayRounding.kcal(total.kcal), 1);

      final snapshots = [
        Nutrients(kcal: 10.45, protein: 0.34, carbs: 1, fat: 0, fiber: 0),
        Nutrients(kcal: 10.45, protein: 0.34, carbs: 1, fat: 0, fiber: 0),
      ];
      final day = Nutrients.sum(snapshots);
      expect(DisplayRounding.kcal(day.kcal), 21);
      expect(DisplayRounding.nutrientGrams(day.protein), 0.7);
    });
  });
}
