import 'package:fb_text/fb_text.dart';
import 'package:glados/glados.dart';

import '../helpers/property.dart';

/// Every single unit word with its code, by search key.
final Map<String, String> _unitWords = {
  for (final table in [englishUnitWords, arabicUnitWords, numberOnlyUnitWords])
    for (final MapEntry(:key, :value) in table.entries)
      normalizeKey(key): value,
};

/// The search keys of every word the number grammar reads.
final Set<String> _numberKeys = {
  for (final word in [
    ...englishOnes.keys,
    ...englishTens.keys,
    englishHundred,
    ...articleWords,
    ...englishDenominators.keys,
    ...arabicNumberWords.keys,
    ...fractionWords.keys,
    ...addedFractions.keys,
    ...dozenWords,
    ...rangeWords,
    ...oneAfterUnitWords,
    ...ofWords,
  ])
    normalizeKey(word),
};

/// Food words that are neither numbers nor units.
const _foods = ['rice', 'chicken breast', 'فول مدمس', 'عيش بلدي', 'labneh'];

void main() {
  group('tables:', () {
    test('every unit word maps to a known code, and every code has a word', () {
      final codes = {
        ...englishUnitWords.values,
        ...arabicUnitWords.values,
        ...numberOnlyUnitWords.values,
        ...spoonSizeWords.values,
      };
      expect(codes, parsedUnitCodes);
    });

    test('no word means two things after normalization', () {
      for (final table in [
        englishOnes,
        englishTens,
        englishDenominators,
        arabicNumberWords,
        fractionWords,
        addedFractions,
        englishUnitWords,
        arabicUnitWords,
        numberOnlyUnitWords,
        spoonSizeWords,
      ]) {
        final seen = <String, Object>{};
        for (final MapEntry(:key, :value) in table.entries) {
          final normalized = normalizeKey(key);
          expect(normalized, isNotEmpty, reason: key);
          final before = seen.putIfAbsent(normalized, () => value);
          expect(before, value, reason: '$key collides as "$normalized"');
        }
      }
      final english = {for (final w in englishUnitWords.keys) normalizeKey(w)};
      final arabic = {for (final w in arabicUnitWords.keys) normalizeKey(w)};
      expect(english.intersection(arabic), isEmpty);
      expect(_unitWords.keys.toSet().intersection(_numberKeys), isEmpty);
      final duals = {
        for (final word in arabicDualUnits) ...arabicDualForms(word),
      };
      expect(duals.intersection(_unitWords.keys.toSet()), isEmpty);
      expect(duals.intersection(_numberKeys), isEmpty);
    });

    test('dual and spoon words are Arabic unit words, spoons are tbsp', () {
      for (final word in arabicDualUnits) {
        expect(arabicUnitWords, contains(word), reason: word);
      }
      for (final word in arabicSpoonWords) {
        expect(arabicUnitWords[word], 'tbsp', reason: word);
      }
    });

    test('LC-051 LC-011 every unit word is read as its code', () {
      for (final MapEntry(:key, :value) in _unitWords.entries) {
        expect(
          parseQuantity('2 $key food'),
          ParsedQuantity(
            amount: 2,
            unitCode: value,
            rest: 'food',
            original: '2 $key food',
          ),
          reason: key,
        );
      }
    });

    test('every number and fraction word is read as its value', () {
      final words = <String, double>{
        for (final MapEntry(:key, :value) in englishOnes.entries)
          key: value.toDouble(),
        for (final MapEntry(:key, :value) in englishTens.entries)
          key: value.toDouble(),
        for (final MapEntry(:key, :value) in arabicNumberWords.entries)
          key: value.toDouble(),
        ...fractionWords,
        for (final MapEntry(:key, :value) in addedFractions.entries)
          '3 $key': 3 + value,
        for (final MapEntry(:key, :value) in englishDenominators.entries)
          'six $key': 6 / value,
        for (final word in dozenWords) 'two $word': 24,
      };
      for (final MapEntry(:key, :value) in words.entries) {
        expect(parseNumber(key), closeTo(value, 1e-12), reason: key);
      }
    });
  });

  group('property:', () {
    Glados3(
      any.intInRange(1, 1000),
      any.intInRange(0, 1 << 20),
      any.intInRange(0, _foods.length),
      propertyRuns,
    ).test('LC-011 "<n> <unit> <food>" and "<food> <n> <unit>" give n, the '
        "unit's code and the food", (n, pick, food) {
      final words = _unitWords.keys.toList();
      final unit = words[pick % words.length];
      for (final text in [
        '$n $unit ${_foods[food]}',
        '${_foods[food]} $n $unit',
      ]) {
        expect(
          parseQuantity(text),
          ParsedQuantity(
            amount: n.toDouble(),
            unitCode: _unitWords[unit],
            rest: _foods[food],
            original: text,
          ),
        );
      }
    });

    Glados(any.anyText, propertyRuns).test(
      'parseQuantity never throws; a result has a positive finite amount, a '
      'known unit and non-empty food text taken from the input',
      (text) {
        parseNumber(text);
        final parsed = parseQuantity(text);
        if (parsed == null) return;
        expect(parsed.amount, greaterThan(0));
        expect(parsed.amount.isFinite, isTrue);
        expect(parsed.rest, isNotEmpty);
        expect(text, contains(parsed.original));
        expect(parsed.original, contains(parsed.rest));
        expect(
          parsed.unitCode == null || parsedUnitCodes.contains(parsed.unitCode),
          isTrue,
        );
      },
    );
  });
}
