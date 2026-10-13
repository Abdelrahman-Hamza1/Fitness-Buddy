import 'package:fb_text/fb_text.dart';
import 'package:glados/glados.dart';

import '../helpers/property.dart';

/// English words for 0–999, written independently of the parser tables.
/// [hyphen] joins tens and ones with "-", [and] puts "and" after "hundred".
String _englishWords(int n, {required bool hyphen, required bool and}) {
  const ones = [
    'zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', //
    'nine', 'ten', 'eleven', 'twelve', 'thirteen', 'fourteen', 'fifteen',
    'sixteen', 'seventeen', 'eighteen', 'nineteen',
  ];
  const tens = [
    '', '', 'twenty', 'thirty', 'forty', 'fifty', 'sixty', 'seventy', //
    'eighty', 'ninety',
  ];
  String below100(int m) {
    if (m < 20) return ones[m];
    final rest = m % 10;
    if (rest == 0) return tens[m ~/ 10];
    return '${tens[m ~/ 10]}${hyphen ? '-' : ' '}${ones[rest]}';
  }

  if (n < 100) return below100(n);
  final hundreds = '${ones[n ~/ 100]} hundred';
  final rest = n % 100;
  if (rest == 0) return hundreds;
  return '$hundreds ${and ? 'and ' : ''}${below100(rest)}';
}

/// [cents] / 100 written with [style]: the decimal point and the digit
/// script vary.
String _formatCents(int cents, int style) {
  final whole = '${cents ~/ 100}';
  final fraction = (cents % 100).toString().padLeft(2, '0');
  final (point, zero) = switch (style) {
    0 => ('.', 0x30),
    1 => ('٫', 0x30), // ٫
    2 => (',', 0x30),
    3 => ('٫', 0x0660), // Arabic-Indic digits
    4 => ('.', 0x06F0), // Persian digits
    _ => ('.', 0xFF10), // fullwidth digits
  };
  final ascii = cents % 100 == 0 ? whole : '$whole$point$fraction';
  return String.fromCharCodes([
    for (final unit in ascii.codeUnits)
      if (unit >= 0x30 && unit <= 0x39) zero + unit - 0x30 else unit,
  ]);
}

void main() {
  group('parseNumber', () {
    test('digits, decimals, fractions and words', () {
      const cases = <String, double>{
        '2': 2,
        '٣': 3,
        '2.5': 2.5,
        '.5': 0.5,
        '٢٫٥': 2.5,
        '1,5': 1.5,
        '1,25': 1.25,
        '1,000': 1000,
        '12,345,678': 12345678,
        '1,000.5': 1000.5,
        '½': 0.5,
        '¼': 0.25,
        '¾': 0.75,
        '⅓': 1 / 3,
        '⅔': 2 / 3,
        '1½': 1.5,
        '1/2': 0.5,
        '3/4': 0.75,
        '1 1/2': 1.5,
        '2 ¾': 2.75,
        'zero': 0,
        'a': 1,
        'an': 1,
        'dozen': 12,
        'a dozen': 12,
        '2 dozen': 24,
        'half a dozen': 6,
        'twenty-five': 25,
        'one hundred': 100,
        'hundred': 100,
        'a hundred and fifty': 150,
        'one half': 0.5,
        'three quarters': 0.75,
        'two and a half': 2.5,
        'two and half': 2.5,
        'one and a third': 1 + 1 / 3,
        'نص': 0.5,
        'ربع': 0.25,
        'تلت': 1 / 3,
        'ثلثين': 2 / 3,
        'تلات تربع': 0.75,
        'تلاتة ونص': 3.5,
        'ثلاثة و نصف': 3.5,
        'اتنين إلا ربع': 1.75,
        'واحدة': 1,
        'wa7ed': 1,
        'etneen': 2,
        'tlata wnos': 3.5,
        'nuss': 0.5,
        '  7  ': 7,
      };
      for (final MapEntry(key: text, value: expected) in cases.entries) {
        expect(parseNumber(text), closeTo(expected, 1e-12), reason: text);
      }
    });

    test('anything more or less than one number → null', () {
      for (final text in [
        '',
        '-2',
        '2.',
        '2 eggs',
        'eggs',
        '2 3',
        '2-3',
        'two three',
        '1/0',
        '1.2.3',
        '1,5000',
        '1.5½',
        '1 3/2',
        'and a half',
      ]) {
        expect(parseNumber(text), isNull, reason: text);
      }
    });
  });

  group('property:', () {
    Glados2(
      any.intInRange(0, 10000000),
      any.intInRange(0, 6),
      propertyRuns,
    ).test('a formatted number parses back to itself (any digit script '
        'and decimal point)', (cents, style) {
      final text = _formatCents(cents, style);
      expect(parseNumber(text), closeTo(cents / 100, 1e-9), reason: text);
      if (cents > 0) {
        expect(
          parseQuantity('$text g rice'),
          ParsedQuantity(
            amount: cents / 100,
            unitCode: 'g',
            rest: 'rice',
            original: '$text g rice',
          ),
          reason: text,
        );
      }
    });

    Glados3(any.intInRange(0, 1000), any.bool, any.bool, propertyRuns).test(
      'English words 0–999 parse to their number',
      (n, hyphen, and) {
        final words = _englishWords(n, hyphen: hyphen, and: and);
        expect(parseNumber(words), n, reason: words);
      },
    );

    Glados3(
      any.intInRange(0, 100),
      any.intInRange(1, 16),
      any.intInRange(2, 17),
      propertyRuns,
    ).test('mixed numbers "w n/d" parse to w + n/d', (whole, top, bottom) {
      final numerator = top % bottom == 0 ? 1 : top % bottom;
      final text = whole == 0
          ? '$numerator/$bottom'
          : '$whole $numerator/$bottom';
      expect(
        parseNumber(text),
        closeTo(whole + numerator / bottom, 1e-12),
        reason: text,
      );
    });
  });
}
