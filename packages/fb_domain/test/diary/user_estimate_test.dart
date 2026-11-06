import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

import '../helpers/diary.dart';

void main() {
  group('UserEstimate:', () {
    test('DY-005 user estimate food: typed values, userEstimate, protein '
        'known only when typed, fiber unknown, explicit 0 known', () {
      final food = const UserEstimate(
        kcal: 700,
        name: '  Shawarma plate  ',
        protein: 35,
        fat: 0,
      ).food();
      expect(food.userEstimate, isTrue);
      expect(food.editedByUser, isTrue);
      expect(food.ref.kind, FoodRefKind.estimate);
      expect(food.ref.id, isNull);
      expect(food.provenance.source, FoodSource.yours);
      expect(food.provenance.isEstimate, isTrue);
      expect(food.names.en, 'Shawarma plate');
      expect(food.per100.kcal, 700);
      expect(food.per100.protein, 35);
      expect(food.per100.carbs, 0);
      expect(food.per100.fat, 0);
      expect(food.known, {NutrientField.protein, NutrientField.fat});
      expect(food.known, isNot(contains(NutrientField.fiber)));
      expect(UserEstimate.amount.amount, 100);
      expect(UserEstimate.amount.input, Quantity(1, 'serving'));
    });

    test('DY-005 editing keeps fiber, its known state, extras and the '
        'provenance the editor does not show', () {
      final base = const UserEstimate(kcal: 700, protein: 30).food();
      final current = EntryFood(
        ref: base.ref,
        names: base.names,
        per100: Nutrients(
          kcal: 700,
          protein: 30,
          carbs: 0,
          fat: 0,
          fiber: 9,
          extras: {NutrientKey.sodium: 800},
        ),
        provenance: base.provenance,
        editedByUser: true,
        userEstimate: true,
        known: {NutrientField.protein, NutrientField.fiber},
      );
      final edited = const UserEstimate(
        kcal: 650,
        name: 'Out',
        carbs: 80,
      ).foodReplacing(current);
      expect(edited.per100.kcal, 650);
      expect(edited.names.en, 'Out');
      expect(
        (edited.per100.protein, edited.per100.carbs, edited.per100.fiber),
        (0.0, 80.0, 9.0),
      );
      expect(edited.per100.extras, {NutrientKey.sodium: 800.0});
      expect(edited.known, {NutrientField.carbs, NutrientField.fiber});
      expect(edited.userEstimate, isTrue);
      // An estimate without fiber keeps it unknown (W3: stored 0).
      final plain = const UserEstimate(kcal: 500).foodReplacing(base);
      expect(plain, const UserEstimate(kcal: 500).food());
    });

    test('DY-005 unnamed estimate stores the fixed name and reads back '
        'unnamed; Edit prefill round-trips', () {
      const typed = UserEstimate(kcal: 450, carbs: 60);
      final food = typed.food();
      expect(food.names.en, UserEstimate.unnamedName);
      expect(UserEstimate.of(food), typed);
      expect(UserEstimate.of(riceFood()), isNull);
    });

    test('DY-005 UserEstimate.check bounds (kcal 0, 10001, macro 1001)', () {
      expect(const UserEstimate(kcal: 0).check(), UserEstimateProblem.kcal);
      expect(const UserEstimate(kcal: 10001).check(), UserEstimateProblem.kcal);
      expect(
        const UserEstimate(kcal: double.nan).check(),
        UserEstimateProblem.kcal,
      );
      expect(
        const UserEstimate(kcal: 500, protein: 1001).check(),
        UserEstimateProblem.macro,
      );
      expect(
        const UserEstimate(kcal: 500, fat: -1).check(),
        UserEstimateProblem.macro,
      );
      expect(const UserEstimate(kcal: 1).check(), isNull);
      expect(const UserEstimate(kcal: 10000, carbs: 1000).check(), isNull);
      expect(() => const UserEstimate(kcal: 0).food(), throwsArgumentError);
    });

    test('FD-012 a 10,000 kcal estimate is a total, not a food: it builds '
        'although no food has that per 100 g', () {
      final food = const UserEstimate(kcal: 10000).food();
      expect(food.per100.kcal, 10000);
    });

    test('W3 EntryFood rejects unknown with nonzero per-100; DiaryEntry '
        'rejects a nonzero snapshot; W1/W2 shapes', () {
      final food = const UserEstimate(kcal: 700).food();
      expect(
        () => EntryFood(
          ref: food.ref,
          names: food.names,
          per100: snapshotOf(700),
          provenance: food.provenance,
          userEstimate: true,
          known: const {},
        ),
        throwsArgumentError,
      );
      expect(
        () => entry(food: food, snapshot: snapshotOf(700)),
        throwsArgumentError,
      );
      // W2: unknowns only on a user estimate.
      expect(
        () => EntryFood(
          ref: FoodRef.estimate(),
          names: FoodNames('x'),
          per100: Nutrients.zero,
          provenance: Provenance(source: FoodSource.estimate),
          known: const {},
        ),
        throwsArgumentError,
      );
      // W1: a user estimate is an estimate reference from `yours`.
      expect(
        () => EntryFood(
          ref: FoodRef.personal('p1'),
          names: FoodNames('x'),
          per100: rice100,
          provenance: Provenance(source: FoodSource.yours, isEstimate: true),
          userEstimate: true,
        ),
        throwsArgumentError,
      );
    });

    test('D18 toString of UserEstimate, IntakeTotals and EntryFood holds no '
        'user content', () {
      const typed = UserEstimate(kcal: 777, name: 'Secret dinner', fat: 33);
      final e = estimateEntry(kcal: 777, fat: 33);
      for (final text in [
        '$typed',
        '${typed.food()}',
        '${DiaryTotals.intake([e])}',
        '${IntakeAverages.ofDay(DiaryTotals.intake([e]))}',
      ]) {
        expect(text, isNot(contains('Secret')));
        expect(text, isNot(contains('777')));
        expect(text, isNot(contains('33')));
      }
    });
  });
}
