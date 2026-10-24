import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/amount_text.dart';
import 'package:fb_mobile/core/l10n/domain_labels.dart';
import 'package:fb_mobile/l10n/gen/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = AppLocalizationsEn();

  String serving(
    Quantity input,
    UnitSystem system, {
    NutrientBasis basis = NutrientBasis.per100g,
  }) => servingText(l10n, input: input, basis: basis, system: system);

  String amount(
    Quantity input,
    double canonical,
    UnitSystem system, {
    NutrientBasis basis = NutrientBasis.per100g,
  }) => foodAmountText(
    l10n,
    input: input,
    amount: canonical,
    basis: basis,
    system: system,
  );

  test('LC-010 servingText: a standard input follows the unit system, in '
      'its own dimension (D4 a)', () {
    expect(serving(Quantity(100, 'g'), UnitSystem.metric), '100 g');
    expect(serving(Quantity(100, 'g'), UnitSystem.imperial), '3.5 oz');
    expect(serving(Quantity(8, 'oz'), UnitSystem.metric), '227 g');
    expect(serving(Quantity(8, 'oz'), UnitSystem.imperial), '8 oz');
    expect(serving(Quantity(250, 'ml'), UnitSystem.imperial), '8.5 fl oz');
    expect(serving(Quantity(250, 'ml'), UnitSystem.metric), '250 ml');
  });

  test('LC-011 servingText: a portion or kitchen word stays as typed in '
      'both systems (D4 b)', () {
    for (final system in UnitSystem.values) {
      expect(serving(Quantity(1, 'loaf'), system), '1 loaf');
      expect(serving(Quantity(2, 'loaf'), system), '2 loaves');
      expect(serving(Quantity(1.5, 'cup'), system), '1.5 cups');
    }
  });

  test('LC-011 foodAmountText: the stored amount follows only where it adds '
      'information (D4 c)', () {
    expect(amount(Quantity(1, 'loaf'), 60, UnitSystem.metric), '1 loaf (60 g)');
    expect(
      amount(Quantity(1, 'loaf'), 60, UnitSystem.imperial),
      '1 loaf (2.1 oz)',
    );
    // Same dimension as the basis: nothing to add.
    expect(amount(Quantity(100, 'g'), 100, UnitSystem.metric), '100 g');
    expect(amount(Quantity(8, 'oz'), 226.8, UnitSystem.metric), '227 g');
    // A density-backed input: the stored grams are the secondary.
    expect(
      amount(Quantity(250, 'ml'), 258, UnitSystem.imperial),
      '8.5 fl oz (9.1 oz)',
    );
    expect(
      amount(Quantity(250, 'ml'), 258, UnitSystem.metric),
      '250 ml (258 g)',
    );
  });

  test('LC-010 foodMassText: a weight in the unit system (yield note)', () {
    expect(foodMassText(l10n, 100, system: UnitSystem.metric), '100 g');
    expect(foodMassText(l10n, 100, system: UnitSystem.imperial), '3.5 oz');
  });

  test('LC-011 PA2 an unknown serving code shows its size in the selected '
      'system, never grams or ml in imperial (D4)', () {
    // 'handful' has no word: "portion", with the food's size for it.
    final grams = ServingUnit.grams('handful', 60);
    final millilitres = ServingUnit.milliliters('handful', 250);
    String text(NutrientBasis basis, ServingUnit unit, UnitSystem system) =>
        servingText(
          l10n,
          input: Quantity(1, 'handful'),
          basis: basis,
          system: system,
          serving: unit,
        );

    expect(
      text(NutrientBasis.per100g, grams, UnitSystem.metric),
      '1 portion (60 g)',
    );
    expect(
      text(NutrientBasis.per100g, grams, UnitSystem.imperial),
      '1 portion (2.1 oz)',
    );
    expect(
      text(NutrientBasis.per100ml, millilitres, UnitSystem.metric),
      '1 portion (250 ml)',
    );
    expect(
      text(NutrientBasis.per100ml, millilitres, UnitSystem.imperial),
      '1 portion (8.5 fl oz)',
    );
    // The same label through the full amount text and the unit label itself.
    expect(
      foodAmountText(
        l10n,
        input: Quantity(2, 'handful'),
        amount: 120,
        basis: NutrientBasis.per100g,
        system: UnitSystem.imperial,
        serving: grams,
      ),
      '2 portions (2.1 oz) (4.2 oz)',
    );
    expect(
      unitLabel(
        l10n,
        'handful',
        1,
        serving: grams,
        system: UnitSystem.imperial,
      ),
      'portion (2.1 oz)',
    );
  });
}
