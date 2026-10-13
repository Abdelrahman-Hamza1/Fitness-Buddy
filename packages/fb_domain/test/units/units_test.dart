import 'package:fb_domain/fb_domain.dart';
import 'package:glados/glados.dart';

import '../helpers/property.dart';

void main() {
  group('LC-011 any unit converts to canonical grams/ml whatever the unit '
      'setting', () {
    test('mass units', () {
      expect(Mass.of(250, MassUnit.gram).grams, 250);
      expect(Mass.of(1.5, MassUnit.kilogram).grams, 1500);
      expect(Mass.of(8, MassUnit.ounce).grams, closeTo(226.796185, 1e-9));
      expect(Mass.of(1, MassUnit.pound).grams, 453.59237);
      expect(Mass.kilograms(81.2).grams, closeTo(81200, 1e-9));
      expect(Mass.grams(81200).kilograms, closeTo(81.2, 1e-12));
    });

    test('volume units', () {
      expect(Volume.of(330, VolumeUnit.milliliter).milliliters, 330);
      expect(Volume.of(1.5, VolumeUnit.liter).milliliters, 1500);
      expect(
        StoragePrecision.round(
          Volume.of(12, VolumeUnit.fluidOunce).milliliters,
        ),
        354.88,
      );
      expect(Volume.of(1, VolumeUnit.cup).milliliters, 240);
      expect(Volume.of(2, VolumeUnit.tablespoon).milliliters, 30);
      expect(Volume.of(1, VolumeUnit.teaspoon).milliliters, 5);
    });

    test('length units', () {
      expect(Length.of(10, LengthUnit.inch).centimeters, closeTo(25.4, 1e-12));
      expect(Length.of(1, LengthUnit.foot).centimeters, closeTo(30.48, 1e-12));
      expect(Length.feetAndInches(5, 11).centimeters, closeTo(180.34, 1e-9));
    });

    test('"8 oz chicken" in metric mode: stored as grams, shown per '
        'setting', () {
      final measures = FoodMeasures(basis: NutrientBasis.per100g);
      final resolved = measures.resolve(Quantity(8, 'oz')) as Resolved;
      expect(resolved.amount, 226.8);
      expect(resolved.basis, NutrientBasis.per100g);
      final stored = Mass.grams(resolved.amount);
      expect(
        UnitSystem.metric.showFoodMass(stored),
        const DisplayAmount(227, 'g'),
      );
      expect(
        UnitSystem.imperial.showFoodMass(stored),
        const DisplayAmount(8, 'oz'),
      );
    });

    test('unit codes are stable and resolve back', () {
      expect(MassUnit.values.map((u) => u.code), ['g', 'kg', 'oz', 'lb']);
      expect(VolumeUnit.values.map((u) => u.code), [
        'ml',
        'l',
        'fl_oz',
        'cup',
        'tbsp',
        'tsp',
      ]);
      expect(LengthUnit.values.map((u) => u.code), ['cm', 'in', 'ft']);
      for (final u in MassUnit.values) {
        expect(MassUnit.fromCode(u.code), u);
      }
      for (final u in VolumeUnit.values) {
        expect(VolumeUnit.fromCode(u.code), u);
      }
      for (final u in LengthUnit.values) {
        expect(LengthUnit.fromCode(u.code), u);
      }
      for (final u in PortionUnit.values) {
        expect(PortionUnit.fromCode(u.code), u);
      }
      expect(MassUnit.fromCode('G'), isNull);
      expect(VolumeUnit.fromCode('floz'), isNull);
      expect(LengthUnit.fromCode('m'), isNull);
      expect(PortionUnit.fromCode('can'), isNull);
    });

    test('isKnownFoodUnitCode covers mass, volume and portion codes', () {
      for (final code in [
        'g',
        'kg',
        'oz',
        'lb',
        'ml',
        'l',
        'fl_oz',
        'cup',
        'tbsp',
        'tsp',
        'piece',
        'loaf',
        'plate',
        'glass',
        'sandwich',
        'disc',
        'serving',
      ]) {
        expect(isKnownFoodUnitCode(code), isTrue, reason: code);
      }
      expect(isKnownFoodUnitCode('cm'), isFalse);
      expect(isKnownFoodUnitCode('bowl'), isFalse);
    });
  });

  group('LC-010 display values follow the unit system', () {
    test('metric is the default', () {
      expect(UnitSystem.defaultSystem, UnitSystem.metric);
    });

    test('metric: whole g and ml, kg with 1 decimal, whole cm', () {
      const s = UnitSystem.metric;
      expect(s.showFoodMass(Mass.grams(149.6)), const DisplayAmount(150, 'g'));
      expect(
        s.showBodyMass(Mass.kilograms(81.26)),
        const DisplayAmount(81.3, 'kg'),
      );
      expect(
        s.showVolume(Volume.milliliters(354.88)),
        const DisplayAmount(355, 'ml'),
      );
      expect(
        s.showLength(Length.centimeters(172.4)),
        const DisplayAmount(172, 'cm'),
      );
    });

    test('imperial: oz, lb, fl oz with 1 decimal, whole inches, ft+in', () {
      const s = UnitSystem.imperial;
      expect(s.showFoodMass(Mass.grams(226.8)), const DisplayAmount(8, 'oz'));
      expect(
        s.showBodyMass(Mass.kilograms(80)),
        const DisplayAmount(176.4, 'lb'),
      );
      expect(
        s.showVolume(Volume.milliliters(355)),
        const DisplayAmount(12, 'fl_oz'),
      );
      expect(
        s.showLength(Length.centimeters(81.3)),
        const DisplayAmount(32, 'in'),
      );
      expect(Length.centimeters(180.34).toFeetAndInches(), (
        feet: 5,
        inches: 11,
      ));
      // 182.6 cm is 71.9 in → 72 in → 6 ft 0 in, never 5 ft 12 in.
      expect(Length.centimeters(182.6).toFeetAndInches(), (feet: 6, inches: 0));
    });

    test('DisplayAmount is a value', () {
      expect(const DisplayAmount(1, 'g'), const DisplayAmount(1, 'g'));
      expect(const DisplayAmount(1, 'g'), isNot(const DisplayAmount(1, 'oz')));
      expect(
        const DisplayAmount(1, 'g').hashCode,
        const DisplayAmount(1, 'g').hashCode,
      );
      expect(const DisplayAmount(1, 'g').toString(), 'DisplayAmount(1.0 g)');
    });
  });

  group('LC-012 energy is kcal only', () {
    test('Energy holds kcal and nothing converts it', () {
      final e = Energy.kcal(250) + Energy.kcal(50);
      expect(e.kcal, 300);
      expect(e, Energy.kcal(300));
      expect(e.toString(), 'Energy(300.0 kcal)');
      expect(Energy.zero.kcal, 0);
      expect(DisplayRounding.kcal(e.kcal), 300);
    });
  });

  group('amount value objects', () {
    test('arithmetic, comparison and equality', () {
      final a = Mass.grams(100);
      final b = Mass.grams(40);
      expect((a + b).grams, 140);
      expect((a - b).grams, 60);
      expect((a * 2.5).grams, 250);
      expect(a > b, isTrue);
      expect(a >= Mass.grams(100), isTrue);
      expect(b < a, isTrue);
      expect(b <= b, isTrue);
      expect(a.compareTo(b), 1);
      expect([a, b, Mass.zero]..sort(), [Mass.zero, b, a]);
      expect(a, Mass.grams(100));
      expect(a.hashCode, Mass.grams(100).hashCode);
      expect(a, isNot(Volume.milliliters(100)));
      expect(a.toString(), 'Mass(100.0 g)');
      expect(Mass.grams(1.005).roundedForStorage(), Mass.grams(1.01));
      // A weight change can be negative.
      expect((b - a).grams, -60);
    });

    test('volume and length value objects', () {
      expect(Volume.zero + Volume.milliliters(5), Volume.milliliters(5));
      expect(Volume.milliliters(240).inUnit(VolumeUnit.cup), 1);
      expect(Volume.milliliters(1).toString(), 'Volume(1.0 ml)');
      expect(Length.centimeters(2.54).inUnit(LengthUnit.inch), 1);
      expect(Length.centimeters(1).toString(), 'Length(1.0 cm)');
      expect(
        Length.centimeters(80) + Length.centimeters(2.5),
        Length.centimeters(82.5),
      );
    });

    test('non-finite amounts are rejected', () {
      expect(() => Mass.grams(double.nan), throwsArgumentError);
      expect(() => Volume.milliliters(double.infinity), throwsArgumentError);
      expect(
        () => Length.centimeters(double.negativeInfinity),
        throwsArgumentError,
      );
      expect(() => Energy.kcal(double.nan), throwsArgumentError);
    });
  });

  group('property: unit round trips are identity within 1e-9 relative', () {
    Glados3(any.positiveAmount, any.massUnit, any.massUnit, propertyRuns).test(
      'g↔oz↔lb↔kg',
      (amount, from, via) {
        final grams = Mass.of(amount, from);
        final back = Mass.of(grams.inUnit(via), via).inUnit(from);
        expect(closeRelative(back, amount), isTrue, reason: '$back != $amount');
      },
    );

    Glados3(
      any.positiveAmount,
      any.volumeUnit,
      any.volumeUnit,
      propertyRuns,
    ).test('ml↔fl oz↔cup↔tbsp↔tsp↔l', (amount, from, via) {
      final ml = Volume.of(amount, from);
      final back = Volume.of(ml.inUnit(via), via).inUnit(from);
      expect(closeRelative(back, amount), isTrue, reason: '$back != $amount');
    });

    Glados3(
      any.positiveAmount,
      any.lengthUnit,
      any.lengthUnit,
      propertyRuns,
    ).test('cm↔in↔ft', (amount, from, via) {
      final cm = Length.of(amount, from);
      final back = Length.of(cm.inUnit(via), via).inUnit(from);
      expect(closeRelative(back, amount), isTrue, reason: '$back != $amount');
    });
  });
}
