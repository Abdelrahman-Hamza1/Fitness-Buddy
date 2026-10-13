import 'package:fb_text/fb_text.dart';
import 'package:glados/glados.dart';

import '../helpers/property.dart';

/// What a key can contain once every fold has run (A2): `a`–`z`, `0`–`9`,
/// the space, and the Arabic letters that no fold maps away (no آ أ ؤ إ ئ ة
/// ى). Written out here, independent of the tables under test.
bool _inKeyAlphabet(int rune) =>
    (rune >= 0x61 && rune <= 0x7A) ||
    (rune >= 0x30 && rune <= 0x39) ||
    rune == 0x20 ||
    rune == 0x0621 ||
    rune == 0x0627 ||
    rune == 0x0628 ||
    (rune >= 0x062A && rune <= 0x063A) ||
    (rune >= 0x0641 && rune <= 0x0648) ||
    rune == 0x064A;

/// The longest run of one repeated code point in [runes], counting only
/// code points that pass [test].
int _longestRun(List<int> runes, bool Function(int rune) test) {
  var longest = 0;
  var current = 0;
  for (final (index, rune) in runes.indexed) {
    if (!test(rune)) {
      current = 0;
    } else {
      current = index > 0 && runes[index - 1] == rune ? current + 1 : 1;
    }
    if (current > longest) longest = current;
  }
  return longest;
}

void main() {
  group('normalize steps:', () {
    test('foldCompatibility folds fullwidth ASCII and Latin ligatures', () {
      expect(foldCompatibility('ＲＩＣＥ ｒｉｃｅ １００！～'), 'RICE rice 100!~');
      expect(foldCompatibility('ﬀﬁﬂﬃﬄﬅﬆ'), 'fffiflffifflstst');
      expect(
        foldCompatibility('\u{FF00}\u{FF5F}ｱ a ١'),
        '\u{FF00}\u{FF5F}ｱ a ١',
      );
    });

    test(
      'foldDigits maps Arabic-Indic and Persian digits and keeps the rest',
      () {
        expect(foldDigits('٠١٢٣٤٥٦٧٨٩'), '0123456789');
        expect(foldDigits('۰۱۲۳۴۵۶۷۸۹'), '0123456789');
        expect(foldDigits('a٫½ ٪'), 'a٫½ ٪');
      },
    );

    test('foldArabic deletes marks and folds letters, keeping the rest', () {
      expect(foldArabic('أَإِآٱ'), 'اااا');
      expect(foldArabic('ةىئؤء'), 'هييوء');
      expect(foldArabic('ﻻﻵ'), 'لالا');
      expect(foldArabic('کیڤپچگ'), 'كيفبجك');
      expect(foldArabic('فـولٰۭ'), 'فول');
      expect(foldArabic('Ab ½'), 'Ab ½');
    });

    test('foldLatin lowercases ASCII and folds accents without locale', () {
      expect(foldLatin('ABCXYZ'), 'abcxyz');
      expect(foldLatin('İIıi'), 'iiii');
      expect(foldLatin('ßÆœØÞ'), 'ssaeoeoth');
      expect(foldLatin('éͯ'), 'e');
      expect(foldLatin('×÷µ Б'), '×÷µ Б');
    });

    test(
      'collapseRepeats: Latin and long vowels from 2, other Arabic from 3',
      () {
        expect(collapseRepeats('aabbbc'), 'abc');
        expect(collapseRepeats('ااووييي'), 'اوي');
        expect(collapseRepeats('للبنننن'), 'للبن');
        expect(collapseRepeats('1100  ..'), '1100  ..');
        expect(collapseRepeats(''), '');
      },
    );
  });

  group('tables:', () {
    test(
      'the Latin table covers Latin-1 letters and Latin Extended-A once',
      () {
        final expected = {
          for (var rune = 0x00C0; rune <= 0x017F; rune++)
            if (rune != 0x00D7 && rune != 0x00F7) rune,
        };
        final listed = [
          for (final letters in latinFoldGroups.values) ...letters.runes,
        ];
        expect(listed.toSet(), expected);
        expect(listed, hasLength(expected.length), reason: 'listed twice');
        expect(latinFolds.keys.toSet(), expected);
      },
    );

    test('every fold produces key characters only', () {
      for (final fold in [
        ...latinFolds.values,
        ...arabicLetterFolds.values,
        ...latinLigatures.values,
      ]) {
        expect(fold.runes.every(_inKeyAlphabet), isTrue, reason: fold);
      }
    });

    test('the allowed set is a–z, 0–9, space and the Arabic letter ranges', () {
      final allowed = [
        for (var rune = 0; rune <= 0xFFFF; rune++)
          if (isKeyCharacter(rune)) rune,
      ];
      expect(allowed, [
        0x20,
        for (var r = 0x30; r <= 0x39; r++) r,
        for (var r = 0x61; r <= 0x7A; r++) r,
        for (var r = 0x0621; r <= 0x063A; r++) r,
        for (var r = 0x0641; r <= 0x064A; r++) r,
      ]);
    });
  });

  group('property:', () {
    Glados(any.anyText, propertyRuns).test(
      'normalizeKey is idempotent on arbitrary Arabic/Latin/digit/symbol '
      'strings',
      (text) {
        final key = normalizeKey(text);
        expect(normalizeKey(key), key);
      },
    );

    Glados(any.anyText, propertyRuns).test(
      'normalizeKey output only contains the allowed set, single inner spaces '
      'and collapsed runs',
      (text) {
        final key = normalizeKey(text);
        final runes = key.runes.toList();
        expect(runes.where((r) => !_inKeyAlphabet(r)), isEmpty);
        expect(key, isNot(startsWith(' ')));
        expect(key, isNot(endsWith(' ')));
        expect(key, isNot(contains('  ')));
        expect(
          _longestRun(runes, (r) => r >= 0x61 && r <= 0x7A),
          lessThanOrEqualTo(1),
        );
        expect(
          _longestRun(runes, (r) => r == 0x0627 || r == 0x0648 || r == 0x064A),
          lessThanOrEqualTo(1),
        );
        expect(
          _longestRun(runes, (r) => r >= 0x0621 && r <= 0x064A),
          lessThanOrEqualTo(2),
        );
      },
    );
  });
}
