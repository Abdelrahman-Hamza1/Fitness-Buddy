import 'package:fb_text/fb_text.dart';
import 'package:test/test.dart';

/// A parsed quantity with an explicit amount. [_expectAll] fills in an
/// empty [original] from the input.
ParsedQuantity _q(
  double amount,
  String? unit,
  String rest, [
  String original = '',
]) => ParsedQuantity(
  amount: amount,
  unitCode: unit,
  rest: rest,
  original: original,
);

/// A parsed quantity whose amount (one) was assumed.
ParsedQuantity _implicit(String unit, String rest) => ParsedQuantity(
  amount: 1,
  unitCode: unit,
  rest: rest,
  original: '',
  amountImplicit: true,
);

/// Spaces and punctuation around the text, which [ParsedQuantity.original]
/// leaves out.
final RegExp _around = RegExp(r'^[\s\p{P}]+|[\s\p{P}]+$', unicode: true);

/// Checks every `input → expected` pair, naming the input on failure. An
/// expected [ParsedQuantity.original] that is empty is the trimmed input.
void _expectAll(Map<String, ParsedQuantity?> cases) {
  for (final MapEntry(key: input, value: expected) in cases.entries) {
    expect(
      parseQuantity(input),
      expected == null || expected.original.isNotEmpty
          ? expected
          : ParsedQuantity(
              amount: expected.amount,
              unitCode: expected.unitCode,
              rest: expected.rest,
              original: input.replaceAll(_around, ''),
              amountImplicit: expected.amountImplicit,
            ),
      reason: input,
    );
  }
}

void main() {
  group('LC-051 portion words', () {
    test('LC-051 portion words رغيف صحن حبة كاسة سندويشة قرص map to codes', () {
      _expectAll({
        '2 رغيف عيش': _q(2, 'loaf', 'عيش'),
        'صحن فول': _implicit('plate', 'فول'),
        '3 حبات تفاح': _q(3, 'piece', 'تفاح'),
        'حبة موز': _implicit('piece', 'موز'),
        'كاسة عصير': _implicit('glass', 'عصير'),
        'كوباية شاي': _implicit('glass', 'شاي'),
        'كباية لبن': _implicit('glass', 'لبن'),
        'كاس مية': _implicit('glass', 'مية'),
        'سندويشة فلافل': _implicit('sandwich', 'فلافل'),
        'سندوتش شاورما': _implicit('sandwich', 'شاورما'),
        'قرص طعمية': _implicit('disc', 'طعمية'),
        'طبق كشري': _implicit('plate', 'كشري'),
        'حتة جبنة': _implicit('piece', 'جبنة'),
        'عيش 3 أرغفة': _q(3, 'loaf', 'عيش'),
        'حصة رز': _implicit('serving', 'رز'),
      });
    });

    test('LC-051 Arabic dual (رغيفين, حبتين, صحنين, كاستين) means 2', () {
      _expectAll({
        'رغيفين عيش': _q(2, 'loaf', 'عيش'),
        'حبتين بيض': _q(2, 'piece', 'بيض'),
        'صحنين فول': _q(2, 'plate', 'فول'),
        'كاستين عصير': _q(2, 'glass', 'عصير'),
        'كوبايتين شاي': _q(2, 'glass', 'شاي'),
        'سندويشتين جبنة': _q(2, 'sandwich', 'جبنة'),
        'قرصين طعمية': _q(2, 'disc', 'طعمية'),
        'رغيفان خبز': _q(2, 'loaf', 'خبز'),
        // At the end, the dual is a quantity on its own.
        'عيش رغيفين': _q(2, 'loaf', 'عيش'),
        // An explicit number wins over the dual.
        '3 رغيفين عيش': _q(3, 'loaf', 'عيش'),
        'رغيفين ونص عيش': _q(2.5, 'loaf', 'عيش'),
      });
    });

    test('LC-051 every listed dual form means two of its unit', () {
      final units = {
        for (final MapEntry(:key, :value) in arabicUnitWords.entries)
          normalizeKey(key): value,
      };
      for (final singular in arabicDualUnits) {
        for (final dual in arabicDualForms(singular)) {
          expect(
            parseQuantity('$dual food'),
            _q(2, units[normalizeKey(singular)], 'food', '$dual food'),
            reason: dual,
          );
        }
      }
      expect(arabicDualForms('حبة'), {'حبتين', 'حبتان'});
      expect(arabicDualForms('رغيف'), {'رغيفين', 'رغيفان'});
    });

    test('LC-051 ملعقة alone is a tablespoon, with a size word it follows the '
        'size (A10)', () {
      _expectAll({
        'ملعقة سكر': _implicit('tbsp', 'سكر'),
        'معلقة عسل': _implicit('tbsp', 'عسل'),
        'ملعقة كبيرة زيت': _implicit('tbsp', 'زيت'),
        'ملعقة صغيرة سكر': _implicit('tsp', 'سكر'),
        'معلقة صغيرة ملح': _implicit('tsp', 'ملح'),
        'ملعقة شاي قرفة': _implicit('tsp', 'قرفة'),
        'ملعقتين سكر': _q(2, 'tbsp', 'سكر'),
        'ملعقتين صغار سكر': _q(2, 'tsp', 'سكر'),
        'معلقتين صغيرتين سكر': _q(2, 'tsp', 'سكر'),
        '3 ملاعق كبيرة زيت': _q(3, 'tbsp', 'زيت'),
        'تلات معالق صغيرة سكر': _q(3, 'tsp', 'سكر'),
        'نص ملعقة صغيرة ملح': _q(0.5, 'tsp', 'ملح'),
        'ma3la2a soghayara sokkar': _implicit('tsp', 'sokkar'),
      });
    });

    test('LC-051 علبة (can or box) is not a unit yet (A10 backlog)', () {
      expect(
        parseQuantity('علبة تونة'),
        const ParsedQuantity.none('علبة تونة'),
      );
      expect(
        parseQuantity('2 علبة تونة'),
        _q(2, null, 'علبة تونة', '2 علبة تونة'),
      );
    });
  });

  group('LC-011 any unit is accepted', () {
    test('LC-011 "8 oz chicken" parses to 8 oz + "chicken"', () {
      expect(
        parseQuantity('8 oz chicken'),
        _q(8, 'oz', 'chicken', '8 oz chicken'),
      );
    });

    test('LC-011 every unit code has a word, with and without a space', () {
      _expectAll({
        '150 g chicken': _q(150, 'g', 'chicken'),
        '150g chicken': _q(150, 'g', 'chicken'),
        '1.5kg rice': _q(1.5, 'kg', 'rice'),
        '2 lbs beef': _q(2, 'lb', 'beef'),
        '250 ml milk': _q(250, 'ml', 'milk'),
        '1 l water': _q(1, 'l', 'water'),
        '12 fl oz cola': _q(12, 'fl_oz', 'cola'),
        '12 fl. oz. cola': _q(12, 'fl_oz', 'cola'),
        '2 cups of rice': _q(2, 'cup', 'rice'),
        '1 tbsp olive oil': _q(1, 'tbsp', 'olive oil'),
        '2 teaspoons sugar': _q(2, 'tsp', 'sugar'),
        '3 pieces chicken': _q(3, 'piece', 'chicken'),
        '2 loaves bread': _q(2, 'loaf', 'bread'),
        '1 plate koshari': _q(1, 'plate', 'koshari'),
        '1 glass juice': _q(1, 'glass', 'juice'),
        '2 sandwiches falafel': _q(2, 'sandwich', 'falafel'),
        '4 discs taameya': _q(4, 'disc', 'taameya'),
        '2 servings pasta': _q(2, 'serving', 'pasta'),
        '٢٠٠ جم فراخ': _q(200, 'g', 'فراخ'),
        '٢كيلو طماطم': _q(2, 'kg', 'طماطم'),
        'كوب من الأرز': _implicit('cup', 'الأرز'),
        'لتر لبن': _implicit('l', 'لبن'),
        '½cup sugar': _q(0.5, 'cup', 'sugar'),
        '２ｃｕｐｓ ｒｉｃｅ': _q(2, 'cup', 'ｒｉｃｅ'),
      });
    });
  });

  group('parse:', () {
    test('digits, decimals (. ٫ ,), Arabic-Indic digits, ½ and 1/2', () {
      _expectAll({
        '2 eggs': _q(2, null, 'eggs'),
        '2.5 cups milk': _q(2.5, 'cup', 'milk'),
        '.5 cup oats': _q(0.5, 'cup', 'oats', '.5 cup oats'),
        '٢٫٥ كوب لبن': _q(2.5, 'cup', 'لبن'),
        '1,5 l milk': _q(1.5, 'l', 'milk'),
        '1,25 kg flour': _q(1.25, 'kg', 'flour'),
        '1,500 g flour': _q(1500, 'g', 'flour'),
        '٣ بيضات': _q(3, null, 'بيضات'),
        '۴ تخم مرغ': _q(4, null, 'تخم مرغ'),
        '½ cup rice': _q(0.5, 'cup', 'rice'),
        '¼ cup oil': _q(0.25, 'cup', 'oil'),
        '¾ cup milk': _q(0.75, 'cup', 'milk'),
        '1/2 cup rice': _q(0.5, 'cup', 'rice'),
        '1 1/2 cups flour': _q(1.5, 'cup', 'flour'),
        '1½ cup sugar': _q(1.5, 'cup', 'sugar'),
        '2 ⅓ cups water': _q(2 + 1 / 3, 'cup', 'water'),
        '3 quarters cup oats': _q(0.75, 'cup', 'oats'),
        '2 dozen eggs': _q(24, null, 'eggs'),
        '2‏ eggs': _q(2, null, 'eggs'),
        '2 ونص كيلو رز': _q(2.5, 'kg', 'رز'),
      });
    });

    test('EN number words and "and a half"', () {
      _expectAll({
        'two eggs': _q(2, null, 'eggs'),
        'twenty-five almonds': _q(25, null, 'almonds'),
        'two hundred and fifty grams of chicken': _q(250, 'g', 'chicken'),
        'a hundred grams rice': _q(100, 'g', 'rice'),
        'two and a half cups milk': _q(2.5, 'cup', 'milk'),
        'one and a quarter cups flour': _q(1.25, 'cup', 'flour'),
        'half a cup of rice': _q(0.5, 'cup', 'rice'),
        'a half cup rice': _q(0.5, 'cup', 'rice'),
        'a quarter cup oil': _q(0.25, 'cup', 'oil'),
        'three quarters cup oats': _q(0.75, 'cup', 'oats'),
        'two thirds cup sugar': _q(2 / 3, 'cup', 'sugar'),
        'half chicken': _q(0.5, null, 'chicken'),
        'a dozen eggs': _q(12, null, 'eggs'),
        'dozen eggs': _q(12, null, 'eggs'),
        'half a dozen eggs': _q(6, null, 'eggs'),
        'an apple': _q(1, null, 'apple'),
        'a cup of tea': _q(1, 'cup', 'tea'),
        'cup and a half of rice': _q(1.5, 'cup', 'rice'),
        'Two Eggs': _q(2, null, 'Eggs'),
      });
    });

    test('AR words نص ربع تلت, "ونص", MSA and dialect spellings', () {
      _expectAll({
        'نص كيلو لحمة': _q(0.5, 'kg', 'لحمة'),
        'نصف كيلو لحم': _q(0.5, 'kg', 'لحم'),
        'ربع كيلو جبنة': _q(0.25, 'kg', 'جبنة'),
        'تلت كوب زيت': _q(1 / 3, 'cup', 'زيت'),
        'ثلث كوب سكر': _q(1 / 3, 'cup', 'سكر'),
        'تلت تربع كيلو رز': _q(0.75, 'kg', 'رز'),
        'ثلاثة أرباع كوب لبن': _q(0.75, 'cup', 'لبن'),
        'تلاتة ونص كيلو رز': _q(3.5, 'kg', 'رز'),
        'كيلو ونص طماطم': _q(1.5, 'kg', 'طماطم'),
        'كيلو و نص طماطم': _q(1.5, 'kg', 'طماطم'),
        'اتنين وربع كيلو بطاطس': _q(2.25, 'kg', 'بطاطس'),
        'كيلو إلا ربع لحمة': _q(0.75, 'kg', 'لحمة'),
        'اتنين رغيف عيش': _q(2, 'loaf', 'عيش'),
        'اثنين بيض': _q(2, null, 'بيض'),
        'تنين كاسات مي': _q(2, 'glass', 'مي'),
        'ثلاثة أرغفة خبز': _q(3, 'loaf', 'خبز'),
        'أربعة بيضات': _q(4, null, 'بيضات'),
        'خمس تمرات': _q(5, null, 'تمرات'),
        'عشرة حبات زيتون': _q(10, 'piece', 'زيتون'),
        'رغيف واحد عيش': _q(1, 'loaf', 'عيش'),
        'عيش رغيف واحد': _q(1, 'loaf', 'عيش'),
        'نص دستة بيض': _q(6, null, 'بيض'),
        'تلاتَة بيضات': _q(3, null, 'بيضات'),
      });
    });

    test('Arabizi nos/rob3/etnen', () {
      _expectAll({
        'nos kilo la7ma': _q(0.5, 'kg', 'la7ma'),
        'rob3 kilo gebna': _q(0.25, 'kg', 'gebna'),
        'etnen kobaya shai': _q(2, 'glass', 'shai'),
        'itnen 7aba mooz': _q(2, 'piece', 'mooz'),
        'wa7ed falafel': _q(1, null, 'falafel'),
        'talata w nos kilo ruz': _q(3.5, 'kg', 'ruz'),
        '3ashara 7abba zatoon': _q(10, 'piece', 'zatoon'),
        'ragheef 3esh': _implicit('loaf', '3esh'),
      });
    });

    test('quantity at the end ("chicken 150g")', () {
      _expectAll({
        'chicken 150g': _q(150, 'g', 'chicken'),
        'chicken breast 150 g': _q(150, 'g', 'chicken breast'),
        'rice 1.5 cups': _q(1.5, 'cup', 'rice'),
        'rice, 2 cups.': _q(2, 'cup', 'rice'),
        'eggs 2': _q(2, null, 'eggs'),
        'chicken half kilo': _q(0.5, 'kg', 'chicken'),
        'فول مدمس 2 صحن': _q(2, 'plate', 'فول مدمس'),
        'لبن كوباية واحدة': _q(1, 'glass', 'لبن'),
        'تفاح ٣': _q(3, null, 'تفاح'),
        'لحمة كيلو ونص': _q(1.5, 'kg', 'لحمة'),
      });
    });

    test('no quantity → amountImplicit = 1', () {
      for (final text in [
        'rice',
        'chicken 65 wings',
        '7up',
        '2% milk',
        'Coke Zero',
        'zero sugar cola',
        'vitamin a',
        'pound cake',
        'glass noodles',
        'rice cup',
        'فول صحن',
        'zero sugar cola',
        'غ سكر',
        'غ من سكر',
        'McGriddle',
      ]) {
        final parsed = parseQuantity(text);
        expect(parsed, ParsedQuantity.none(text), reason: text);
        expect(parsed!.amount, 1);
        expect(parsed.amountImplicit, isTrue);
        expect(parsed.hasQuantity, isFalse);
      }
      expect(parseQuantity('  (rice)  '), const ParsedQuantity.none('rice'));
      expect(parseQuantity('cup of tea')!.hasQuantity, isTrue);
      expect(parseQuantity('2 eggs')!.hasQuantity, isTrue);
    });

    test('unparseable text → null', () {
      for (final text in [
        '',
        '   ',
        '!?،',
        '150g',
        'رغيف',
        'nos ragheef',
        'a cup of',
        '2-3 eggs',
        '2 – 3 eggs',
        'two or three eggs',
        'اتنين أو تلاتة بيض',
        'eggs 2 to 3',
        'eggs two three',
        '2 eggs 3',
        '1 cup rice 150 g',
        '2 cups 3 eggs',
        '1/0 eggs',
        'eggs 1/0',
        '1.2.3 g rice',
        '1,5000 g rice',
        '1.5½ cup rice',
        '${'9' * 400} g rice',
        '0 g sugar',
        '0 eggs',
        'sugar 0 g',
        'rice 0',
        'ربع إلا تلت كيلو رز',
        '0x eggs',
        'x1/0 eggs',
      ]) {
        expect(parseQuantity(text), isNull, reason: text);
      }
    });
  });

  group('food names that look like quantities', () {
    test('parser keeps the whole text available for food names that look '
        'like quantities', () {
      // Today's split, pinned. Each is a hypothesis: callers match
      // `original` against the catalog before they trust `rest` (S15).
      final cases = <String, ParsedQuantity>{
        'حبة البركة': _implicit('piece', 'البركة'),
        'حبة حلوة': _implicit('piece', 'حلوة'),
        'سبع بهارات': _q(7, null, 'بهارات'),
        'Five Guys burger': _q(5, null, 'Guys burger'),
        '7 Up': _q(7, null, 'Up'),
        'seven up': _q(7, null, 'up'),
        '100 plus': _q(100, null, 'plus'),
        'omega 3': _q(3, null, 'omega'),
        'chicken 65': _q(65, null, 'chicken'),
        '3 in 1 coffee': _q(3, null, 'in 1 coffee'),
        'half and half cream': _q(1, null, 'cream'),
      };
      _expectAll(cases);
      for (final text in cases.keys) {
        expect(parseQuantity(text)!.original, text, reason: text);
      }
      expect(const ParsedQuantity.none('rice').original, 'rice');
      expect(parseQuantity(' (7 Up) ')!.original, '7 Up');
    });

    test('a number with a unit at the end wins over a bare portion word at '
        'the start', () {
      _expectAll({
        'حبة البركة ٥ غرام': _q(5, 'g', 'حبة البركة'),
        'رغيف عيش 2 رغيف': _q(2, 'loaf', 'رغيف عيش'),
        // Not a bare portion word, or no unit at the end: several items.
        'رغيفين عيش 2 رغيف': null,
        'cup of tea 2': null,
        'حبة البركة ٥': null,
      });
    });
  });

  group('parse: units and counts', () {
    test('LC-011 a microgram unit (µg, μg, mcg) is never grams', () {
      for (final text in [
        '50µg vitamin d',
        '50 µg vitamin d',
        '50 μg b12',
        '50μg b12',
        'vitamin d 50 µg',
        '50 µ g b12',
        '50 mcg b12',
        '50mcg b12',
        'b12 50 mcg',
        'b12 50 MCG',
      ]) {
        expect(parseQuantity(text), isNull, reason: text);
      }
    });

    test('LC-011 غ is grams after a number only', () {
      _expectAll({
        '5 غ سكر': _q(5, 'g', 'سكر'),
        '٥غ سكر': _q(5, 'g', 'سكر'),
        'سكر ٥ غ': _q(5, 'g', 'سكر'),
        'سكر ٥غ': _q(5, 'g', 'سكر'),
        'سكر غ': const ParsedQuantity.none('سكر غ'),
      });
    });

    test('fractions "of a" unit and times counts (2x, x2)', () {
      _expectAll({
        'a third of a cup rice': _q(1 / 3, 'cup', 'rice'),
        'one third cup rice': _q(1 / 3, 'cup', 'rice'),
        'half of a cup rice': _q(0.5, 'cup', 'rice'),
        'a quarter of a dozen eggs': _q(3, null, 'eggs'),
        '2x eggs': _q(2, null, 'eggs'),
        'x2 eggs': _q(2, null, 'eggs'),
        'eggs x2': _q(2, null, 'eggs'),
        'eggs ×3': _q(3, null, 'eggs'),
        'eggs 2X': _q(2, null, 'eggs'),
      });
    });
  });

  group('ParsedQuantity', () {
    test('value equality, hash and a readable toString', () {
      final a = _q(2, 'cup', 'rice');
      expect(a, _q(2, 'cup', 'rice'));
      expect(a.hashCode, _q(2, 'cup', 'rice').hashCode);
      expect(a, isNot(_q(2, 'cup', 'milk')));
      expect(a, isNot(_q(2, 'g', 'rice')));
      expect(a, isNot(_q(3, 'cup', 'rice')));
      expect(a, isNot(_implicit('cup', 'rice')));
      expect(a, isNot(_q(2, 'cup', 'rice', '2 cups rice')));
      expect(a.toString(), 'ParsedQuantity(2.0 cup, "rice")');
      expect(
        const ParsedQuantity.none('rice').toString(),
        'ParsedQuantity(1.0 - implicit, "rice")',
      );
    });
  });
}
