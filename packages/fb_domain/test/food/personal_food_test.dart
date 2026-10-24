import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

import '../helpers/diary.dart';

PersonalFoodDraft draft({
  String name = 'Private name',
  String? ar,
  String? brand,
  List<String> aliases = const [],
  List<String> barcodes = const [],
  List<PersonalFoodServing> servings = const [],
  PersonalFoodServing? entry,
  Nutrients? nutrients,
  NutrientBasis basis = NutrientBasis.per100ml,
  String createdFrom = 'form',
}) => PersonalFoodDraft(
  names: FoodNames(name, ar: ar),
  brand: brand,
  aliases: aliases,
  barcodes: barcodes,
  servings: servings,
  entryServing: entry,
  per100: nutrients ?? Nutrients.zero,
  basis: basis,
  createdFrom: createdFrom,
);
Nutrients n({
  double kcal = 0,
  double p = 0,
  double c = 0,
  double f = 0,
  double fiber = 0,
  Map<NutrientKey, double> extras = const {},
}) => Nutrients(
  kcal: kcal,
  protein: p,
  carbs: c,
  fat: f,
  fiber: fiber,
  extras: extras,
);
PersonalFood food(String id, PersonalFoodDraft d) =>
    PersonalFood(id: id, version: 1, draft: d);
void main() {
  test('FD-001 Gtin accepts valid GTIN-8/12/13/14 and rejects a '
      'wrong check digit or length', () {
    for (final code in [
      '96385074',
      '036000291452',
      '4006381333931',
      '10012345000017',
    ]) {
      expect(Gtin.isValid(code), isTrue);
      expect(
        Gtin.isValid(
          '${code.substring(0, code.length - 1)}'
          '${(int.parse(code.substring(code.length - 1)) + 1) % 10}',
        ),
        isFalse,
      );
    }
    for (final code in ['', '1', '123456789', 'abcdefgh', '1234567١']) {
      expect(Gtin.isValid(code), isFalse);
    }
  });
  test('FD-070 PersonalFoodDraft: name and Arabic name 1–80 after '
      'trimming, brand 1–60, ≤ 30 unique aliases, ≤ 10 valid '
      'barcodes, ≤ 10 servings with unique codes from the closed '
      'vocabulary', () {
    expect(
      draft(name: '  a  ', ar: '  ب  ', brand: '  b  ').names,
      FoodNames('a', ar: 'ب'),
    );
    expect(
      draft(
        name: 'a' * 80,
        ar: 'b' * 80,
        brand: 'c' * 60,
        aliases: List.generate(30, (i) => '$i'),
      ).validate(),
      isNull,
    );
    for (final d in [
      draft(name: 'a' * 81),
      draft(ar: 'a' * 81),
      draft(brand: ''),
      draft(brand: 'a' * 61),
      draft(aliases: ['']),
      draft(aliases: ['a', 'a']),
      draft(aliases: List.generate(31, (i) => '$i')),
      draft(barcodes: ['bad']),
      draft(barcodes: ['96385074', '96385074']),
      draft(
        servings: [
          PersonalFoodServing('piece', 1),
          PersonalFoodServing('piece', 2),
        ],
      ),
    ]) {
      expect(d.validate(), isNotNull);
    }
    expect(() => draft(name: ' '), throwsArgumentError);
    expect(() => draft(ar: ' '), throwsArgumentError);
    expect(
      () => PersonalFoodServing('raw-private-unit', 1),
      throwsArgumentError,
    );
    expect(draft(aliases: ['x' * 81]).validate(), InvalidDraft.aliases);
  });
  test('FD-070 each §3.0 bound accepts its limit and rejects just '
      'past it: kcal 920 / 920.01, grams 1,000 / 1,000.01, mg '
      '100,000 / 100,000.01, serving 0.1 / 0.09 and 5,000 / '
      '5,000.01; an entry serving unit without an amount (or the '
      'reverse) is rejected', () {
    for (final (limit, bad, build)
        in <(double, double, Nutrients Function(double))>[
          (920, 920.01, (v) => n(kcal: v)),
          (1000, 1000.01, (v) => n(p: v)),
          (1000, 1000.01, (v) => n(c: v)),
          (1000, 1000.01, (v) => n(f: v)),
          (1000, 1000.01, (v) => n(fiber: v)),
          (1000, 1000.01, (v) => n(extras: {NutrientKey.sugar: v})),
          (100000, 100000.01, (v) => n(extras: {NutrientKey.sodium: v})),
        ]) {
      expect(draft(nutrients: build(limit)).validate(), isNull);
      expect(draft(nutrients: build(bad)).validate(), isNotNull);
    }
    for (final size in [0.1, 5000.0]) {
      expect(PersonalFoodServing('piece', size).amount, size);
    }
    for (final size in [0.09, 5000.01]) {
      expect(() => PersonalFoodServing('piece', size), throwsArgumentError);
    }
    // The pair is one non-nullable value: half pairs cannot be constructed.
    expect(draft().entryServing, isNull);
    expect(
      draft(entry: PersonalFoodServing('piece', 1)).entryServing!.unit,
      'piece',
    );
  });
  test('FD-070 NaN, ±infinity and 1e308 are rejected for every '
      'number', () {
    for (final value in [
      double.nan,
      double.infinity,
      double.negativeInfinity,
      1e308,
    ]) {
      expect(() => PersonalFoodServing('piece', value), throwsArgumentError);
      for (final build in <Nutrients Function()>[
        () => n(kcal: value),
        () => n(p: value),
        () => n(c: value),
        () => n(f: value),
        () => n(fiber: value),
        for (final key in NutrientKey.values) () => n(extras: {key: value}),
      ]) {
        if (value.isFinite) {
          expect(draft(nutrients: build()).validate(), isNotNull);
        } else {
          expect(build, throwsArgumentError);
        }
      }
    }
  });
  test("PersonalFoodBounds equal §3.0's table, and the "
      "sync-entities schema's minimum, maximum, maxLength and "
      'enums wherever the schema expresses one', () {
    final root = Directory.current.path.endsWith('fb_domain') ? '../..' : '.';
    final contract = jsonDecode(
      File('$root/contracts/openapi/sync-entities.json').readAsStringSync(),
    ) as Map<String, Object?>;
    Map<String, Object?> object(Object? value) =>
        value! as Map<String, Object?>;
    final props = object(
      object(
        object(object(contract['entities'])['personalFood'])['1'],
      )['properties'],
    ).map((key, value) => MapEntry(key, object(value)));
    final plan = File(
      '$root/technical-planning/steps/A09-personal-foods-quick-add.md',
    ).readAsStringSync().split('**3.0 Shared')[1].split('**3.1')[0];
    for (final text in [
      '0–920',
      '0–1,000',
      '0–100,000',
      '0.1–5,000',
      '1–80',
      '1–60',
      '≤ 30',
      '≤ 10',
      '1–32',
    ]) {
      expect(plan, contains(text));
    }
    expect(props['per100Kcal']!['maximum'], PersonalFoodBounds.kcal);
    for (final key in [
      'per100ProteinG',
      'per100CarbsG',
      'per100FatG',
      'per100FiberG',
    ]) {
      expect(props[key]!['maximum'], PersonalFoodBounds.grams);
      expect(props[key]!['minimum'], 0);
    }
    expect(PersonalFoodBounds.milligrams, 100000);
    expect(
      plan.split('| `per100ExtrasJson` |')[1].split('\n')[0],
      contains('0–100,000'),
    );
    expect(plan.split('| `aliasesJson` |')[1].split('\n')[0], contains('≤ 30'));
    expect(
      plan.split('| `servingsJson` |')[1].split('\n')[0],
      contains('≤ 10'),
    );
    expect(PersonalFoodBounds.aliases, 30);
    expect(PersonalFoodBounds.barcodes, 10);
    expect(PersonalFoodBounds.servings, 10);
    for (final key in ['nameEn', 'nameAr']) {
      expect(props[key]!['maxLength'], PersonalFoodBounds.name);
    }
    expect(props['brand']!['maxLength'], PersonalFoodBounds.brand);
    expect(props['createdFrom']!['maxLength'], PersonalFoodBounds.createdFrom);
    for (final key in [
      'aliasesJson',
      'barcodesJson',
      'servingsJson',
      'per100ExtrasJson',
    ]) {
      expect(props[key]!['maxLength'], PersonalFoodBounds.jsonLength);
    }
    expect(
      props['entryServingAmount']!['minimum'],
      PersonalFoodBounds.minServing,
    );
    expect(
      props['entryServingAmount']!['maximum'],
      PersonalFoodBounds.maxServing,
    );
    expect(
      props['state']!['enum'],
      FoodState.values.map((s) => s.code).toList(),
    );
    expect(
      props['basis']!['enum'],
      NutrientBasis.values.map((b) => b.unitCode).toList(),
    );
    expect(
      (props['entryServingUnit']!['enum']! as List<Object?>)
          .whereType<String>()
          .toSet(),
      PersonalFoodBounds.units,
    );
    expect(props['entryServingUnit']!['enum'], contains(null));
    expect(PersonalFoodBounds.units, {
      ...PortionUnit.values.map((u) => u.code),
      'cup',
      'tbsp',
      'tsp',
    });
  });
  test('FD-012 the draft uses '
      'SanityCheck(SanityTolerance.defaults): invalidValue, '
      'kcalTooHigh and macrosTooHeavy are invalid; kcalMismatch '
      '(warn or fail) is valid and reported', () {
    expect(draft(nutrients: n(kcal: 921)).validate(), InvalidDraft.bounds);
    expect(
      draft(nutrients: n(p: 106), basis: NutrientBasis.per100g).validate(),
      InvalidDraft.sanity,
    );
    for (final kcal in [30.0, 900.0]) {
      final d = draft(nutrients: n(kcal: kcal));
      expect(d.validate(), isNull);
      expect(d.sanity.reason, SanityReason.kcalMismatch);
    }
    expect(
      const SanityCheck()
          .checkValues(
            kcal: double.nan,
            protein: 0,
            carbs: 0,
            fat: 0,
            fiber: 0,
            basis: NutrientBasis.per100g,
          )
          .reason,
      SanityReason.invalidValue,
    );
    expect(PersonalFoodBounds.kcal, SanityTolerance.defaults.maxKcalPer100);
  });
  test('FD-070 per-serving entry: a 30 g serving with 120 kcal is '
      'stored as 400 kcal per 100 g, with the serving unit and size', () {
    final d = PersonalFoodDraft.fromServing(
      names: FoodNames('Serving food'),
      valuesPerServing: n(kcal: 120),
      serving: PersonalFoodServing('piece', 30),
    );
    expect(d.per100.kcal, 400);
    expect(d.entryServing, PersonalFoodServing('piece', 30));
    expect(d.perServing().kcal, 120);
  });
  test('property: fromServing then perServing gives back the typed '
      'values within display rounding, for sizes 0.1–5,000 and '
      'values 0–5,000', () {
    final random = Random(901);
    for (var i = 0; i < 1000; i++) {
      final size = 0.1 + random.nextDouble() * 4999.9;
      final value = random.nextDouble() * 5000;
      final d = PersonalFoodDraft.fromServing(
        names: FoodNames('Property'),
        valuesPerServing: n(
          kcal: value,
          p: value,
          c: value,
          f: value,
          fiber: value,
          extras: {NutrientKey.sodium: value},
        ),
        serving: PersonalFoodServing('serving', size),
      );
      final back = d.perServing();
      for (final result in [
        back.kcal,
        back.protein,
        back.carbs,
        back.fat,
        back.fiber,
        back.extra(NutrientKey.sodium)!,
      ]) {
        expect(result, closeTo(value, 0.005));
      }
    }
  });
  test('FD-070 two servings of equal size (piece 30 g, serving 30 '
      'g): the stored entry unit decides which one reopens', () {
    final piece = PersonalFoodServing('piece', 30);
    final serving = PersonalFoodServing('serving', 30);
    final d = draft(servings: [piece, serving], entry: serving);
    expect(d.entryServing, serving);
    expect(d.entryServing, isNot(piece));
    expect(d.perServing(), Nutrients.zero);
    final f = food(entryA, d);
    expect(f.measures.servingUnits.keys, ['piece', 'serving']);
    expect(f.sanity.reason, SanityReason.consistent);
    final mass = food(
      entryB,
      draft(basis: NutrientBasis.per100g, servings: [piece]),
    );
    expect(mass.measures.servingUnits['piece']!.basis, NutrientBasis.per100g);
  });
  test('FD-002 a blank extra stays unknown; blank fiber is 0', () {
    final d = draft();
    expect(d.per100.fiber, 0);
    expect(d.per100.extra(NutrientKey.sugar), isNull);
    expect(d.perServing(), d.per100);
  });
  test('FD-073 merge combine: names and aliases of the merged food '
      "become aliases, de-duplicated by key, the survivor's own "
      'names excluded; an Arabic name fills an empty one; brand '
      'fills an empty one; barcodes are unioned; only new serving '
      'codes are added; values, basis, state and entry serving are '
      "the survivor's", () {
    final entry = PersonalFoodServing('piece', 30);
    final a = draft(
      name: 'A',
      aliases: ['old', 'OLD', 'a'],
      barcodes: ['96385074'],
      servings: [entry],
      entry: entry,
      nutrients: n(kcal: 1),
    );
    final b = draft(
      name: 'B',
      ar: 'ب',
      brand: 'Brand',
      aliases: ['OLD', 'alias'],
      barcodes: ['96385074', '036000291452'],
      servings: [
        PersonalFoodServing('piece', 40),
        PersonalFoodServing('cup', 100),
      ],
    );
    final result = PersonalFoodMerge.combine(
      food(entryA, a),
      food(entryB, b),
      keyOf: (s) => s.toLowerCase(),
    ) as PersonalFoodDraft;
    expect(result.aliases, ['old', 'OLD', 'a', 'B', 'alias']);
    expect(result.names, FoodNames('A', ar: 'ب'));
    expect(result.brand, 'Brand');
    expect(result.barcodes, ['96385074', '036000291452']);
    expect(result.servings, [entry, PersonalFoodServing('cup', 100)]);
    expect(result.per100, a.per100);
    expect(result.basis, a.basis);
    expect(result.state, a.state);
    expect(result.entryServing, a.entryServing);
    final withAr = draft(name: 'A', ar: 'أ', brand: 'Kept');
    final r = PersonalFoodMerge.combine(
      food(entryA, withAr),
      food(entryB, b),
      keyOf: (s) => s,
    ) as PersonalFoodDraft;
    expect(r.names.ar, 'أ');
    expect(r.aliases, contains('ب'));
    expect(r.brand, 'Kept');
  });
  test('FD-073 merge combine over the caps → tooMany', () {
    String gtin(int i) {
      final raw = i.toString().padLeft(7, '0');
      var sum = 0;
      for (var j = 0; j < 7; j++) {
        sum += int.parse(raw[6 - j]) * (j.isEven ? 3 : 1);
      }
      return '$raw${(10 - sum % 10) % 10}';
    }

    for (final (a, b) in [
      (
        draft(aliases: List.generate(30, (i) => 'alias$i')),
        draft(name: 'Overflow'),
      ),
      (draft(barcodes: List.generate(10, gtin)), draft(barcodes: [gtin(10)])),
      (
        draft(
          servings: PersonalFoodBounds.units
              .take(10)
              .map((u) => PersonalFoodServing(u, 1))
              .toList(),
        ),
        draft(
          servings: [PersonalFoodServing(PersonalFoodBounds.units.last, 1)],
        ),
      ),
    ]) {
      expect(
        PersonalFoodMerge.combine(
          food(entryA, a),
          food(entryB, b),
          keyOf: (s) => s,
        ),
        isA<MergeTooMany>(),
      );
    }
    expect(
      draft(barcodes: List.generate(11, gtin)).validate(),
      InvalidDraft.barcodes,
    );
    expect(
      draft(
        servings: PersonalFoodBounds.units
            .map((u) => PersonalFoodServing(u, 1))
            .toList(),
      ).validate(),
      InvalidDraft.servings,
    );
  });
  test('DY-031 LogSavedMeal constructor: at least one item; '
      'entryIds keys equal the expected items; new IDs unique and '
      'never a source ID', () {
    final meal = VersionedId(savedMeal, 1);
    final item = VersionedId(entryA, 1);
    expect(() => SavedMealVersions(meal: meal, items: []), throwsArgumentError);
    expect(
      () => SavedMealVersions(meal: meal, items: [item, item]),
      throwsArgumentError,
    );
    expect(SavedMealVersions(meal: meal, items: [meal]).items, [meal]);
    final v = SavedMealVersions(meal: meal, items: [item]);
    final when = EntryWhen.onDay(LocalDate(2026, 10, 1));
    for (final ids in <Map<String, String>>[
      {},
      {entryB: copyA},
      {entryA: entryA},
      {entryA: savedMeal},
      {entryA: 'bad'},
    ]) {
      expect(
        () => LogSavedMeal(expected: v, entryIds: ids, when: when),
        throwsArgumentError,
      );
    }
    final two = SavedMealVersions(
      meal: meal,
      items: [item, VersionedId(entryB, 1)],
    );
    expect(
      () => LogSavedMeal(
        expected: two,
        entryIds: {entryA: copyA, entryB: copyA},
        when: when,
      ),
      throwsArgumentError,
    );
    expect(
      () => LogSavedMeal(
        expected: v,
        entryIds: {entryA: copyA},
        when: when,
        slotId: 'bad',
      ),
      throwsArgumentError,
    );
    final op = LogSavedMeal(
      expected: v,
      entryIds: {entryA: copyA},
      when: when,
      slotId: groupG,
    );
    expect(op.family, 'diary');
    expect(() => op.entryIds[entryB] = copyB, throwsUnsupportedError);
    expect(() => RenameSavedMeal(savedMeal, 1, ''), throwsArgumentError);
    expect(() => RenameSavedMeal(savedMeal, 1, 'x' * 61), throwsArgumentError);
    expect(RenameSavedMeal(savedMeal, 1, ' name ').name, 'name');
    expect(DeleteSavedMeal(savedMeal, 1).expectedVersion, 1);
  });
  test('toString of every personalFood op, LogSavedMeal, '
      'RelinkFoodRefs, RenameSavedMeal and PersonalFoodDraft shows '
      'no names, aliases, barcodes or values', () {
    final d = draft(
      aliases: ['secret-alias'],
      barcodes: ['96385074'],
      nutrients: n(kcal: 321),
    );
    final v = VersionedId(entryA, 1);
    final source = SavedMealVersions(
      meal: VersionedId(savedMeal, 1),
      items: [v],
    );
    final ops = <Object>[
      d,
      PersonalFoodServing('piece', 30),
      food(entryA, d),
      CreatePersonalFood(entryA, d),
      UpdatePersonalFood(entryA, 1, d),
      DeletePersonalFood(v),
      MergePersonalFoods(survivor: v, merged: VersionedId(entryB, 1)),
      RequirePersonalFood(v),
      source,
      LogSavedMeal(
        expected: source,
        entryIds: {entryA: copyA},
        when: EntryWhen.onDay(LocalDate(2026, 10, 1)),
      ),
      RelinkFoodRefs(
        from: FoodRef.personal(entryA),
        to: FoodRef.personal(entryB),
      ),
      RenameSavedMeal(savedMeal, 1, 'secret-name'),
      DeleteSavedMeal(savedMeal, 1),
    ];
    for (final op in ops) {
      for (final text in [
        'Private name',
        'secret-alias',
        '96385074',
        '321',
        'secret-name',
      ]) {
        expect(op.toString(), isNot(contains(text)));
      }
    }
    expect(CreatePersonalFood(entryA, d).family, 'personalFood');
    for (final code in ['', 'x' * 33, 'with-dash']) {
      expect(draft(createdFrom: code).validate(), InvalidDraft.createdFrom);
    }
    final equal = draft(
      aliases: ['secret-alias'],
      barcodes: ['96385074'],
      nutrients: n(kcal: 321),
    );
    expect(d, equal);
    expect(d.hashCode, equal.hashCode);
    expect(d, isNot(draft()));
    expect(d, isNot('other'));
    final serving = PersonalFoodServing('piece', 30);
    expect(serving.hashCode, PersonalFoodServing('piece', 30).hashCode);
    expect(serving, isNot('other'));
    final pairs = <(Object, Object)>[
      (CreatePersonalFood(entryA, d), CreatePersonalFood(entryA, equal)),
      (UpdatePersonalFood(entryA, 1, d), UpdatePersonalFood(entryA, 1, equal)),
      (DeletePersonalFood(v), DeletePersonalFood(v)),
      (
        MergePersonalFoods(survivor: v, merged: VersionedId(entryB, 1)),
        MergePersonalFoods(survivor: v, merged: VersionedId(entryB, 1)),
      ),
      (RequirePersonalFood(v), RequirePersonalFood(v)),
      (source, SavedMealVersions(meal: VersionedId(savedMeal, 1), items: [v])),
      (
        RelinkFoodRefs(
          from: FoodRef.personal(entryA),
          to: FoodRef.personal(entryB),
        ),
        RelinkFoodRefs(
          from: FoodRef.personal(entryA),
          to: FoodRef.personal(entryB),
        ),
      ),
      (RenameSavedMeal(savedMeal, 1, 'x'), RenameSavedMeal(savedMeal, 1, 'x')),
      (DeleteSavedMeal(savedMeal, 1), DeleteSavedMeal(savedMeal, 1)),
    ];
    for (final (a, b) in pairs) {
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot('other'));
    }
    final log = LogSavedMeal(
      expected: source,
      entryIds: {entryA: copyA},
      when: EntryWhen.onDay(LocalDate(2026, 10, 1)),
    );
    final log2 = LogSavedMeal(
      expected: source,
      entryIds: {entryA: copyA},
      when: log.when,
    );
    expect(log, log2);
    expect(log.hashCode, log2.hashCode);
    expect(log, isNot('other'));
  });
  test('FD-070 definition accessors retain the exact draft; '
      'conversion overflow is redacted', () {
    final d = draft(
      brand: 'Brand',
      aliases: ['Alias'],
      barcodes: ['96385074'],
      servings: [PersonalFoodServing('piece', 30)],
      entry: PersonalFoodServing('piece', 30),
    );
    final f = food(entryA, d);
    expect(
      (
        f.names,
        f.aliases,
        f.brand,
        f.barcodes,
        f.state,
        f.basis,
        f.per100,
        f.servings,
        f.entryServing,
        f.createdFrom,
      ),
      (
        d.names,
        d.aliases,
        d.brand,
        d.barcodes,
        d.state,
        d.basis,
        d.per100,
        d.servings,
        d.entryServing,
        d.createdFrom,
      ),
    );
    expect(
      () => PersonalFoodDraft.fromServing(
        names: FoodNames('Private'),
        valuesPerServing: n(kcal: 1e308),
        serving: PersonalFoodServing('piece', 0.1),
      ),
      throwsA(
        isA<ArgumentError>().having(
          (e) => e.toString(),
          'redacted',
          isNot(contains('Infinity')),
        ),
      ),
    );
  });
  test('FD-070 personal-food identity has value equality', () {
    final a = food(entryA, draft());
    final b = food(entryA, draft());
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(food(entryB, draft())));
    expect(a, isNot('other'));
  });
  test('FD-070 personal foods obey 05 §5.5 wire representability '
      'without rounding or private error values', () {
    for (final value in [1e-30, 1.2345678901234567e-20]) {
      expect(draft(nutrients: n(kcal: value)).validate(), InvalidDraft.bounds);
      expect(
        draft(nutrients: n(extras: {NutrientKey.sodium: value})).validate(),
        InvalidDraft.bounds,
      );
    }
    for (final value in [
      0.0,
      -0.0,
      1e-28,
      1.2345678901234567e-12,
      1.0,
      100000.0,
    ]) {
      expect(PersonalFoodBounds.acceptsNutrient(value, 100000), isTrue);
    }
    for (final value in [double.nan, double.infinity, -1.0, 100001.0]) {
      expect(PersonalFoodBounds.acceptsNutrient(value, 100000), isFalse);
    }
    for (final d in [
      draft(name: 'private\u0000'),
      draft(ar: 'private\u0000'),
      draft(brand: 'private\u0000'),
      draft(aliases: ['private\u0000']),
    ]) {
      expect(d.validate(), isNotNull);
    }
  });
  test('FD-071 wire validation excludes app-only sanity', () {
    final stored = draft(
      basis: NutrientBasis.per100g,
      nutrients: n(kcal: 424, p: 106),
    );
    expect(stored.validateWire(), isNull);
    expect(stored.validate(), InvalidDraft.sanity);
    expect(draft(name: 'x' * 81).validateWire(), InvalidDraft.name);
  });
  test('FD-073 RelinkFoodRefs rejects non-personal and identical refs', () {
    for (final pair in [
      (FoodRef.estimate(), FoodRef.personal(entryB)),
      (FoodRef.catalog('catalog', version: '1'), FoodRef.personal(entryB)),
      (FoodRef.personal(entryA), FoodRef.estimate()),
      (FoodRef.personal(entryA), FoodRef.catalog('catalog', version: '1')),
      (FoodRef.personal(entryA), FoodRef.personal(entryA)),
    ]) {
      expect(
        () => RelinkFoodRefs(from: pair.$1, to: pair.$2),
        throwsArgumentError,
      );
    }
  });
  test('DY-031 RenameSavedMeal rejects NUL without content', () {
    expect(
      () => RenameSavedMeal(savedMeal, 1, 'private\u0000name'),
      throwsA(
        isA<ArgumentError>().having(
          (e) => e.toString(),
          'redacted',
          isNot(contains('private')),
        ),
      ),
    );
  });
}
