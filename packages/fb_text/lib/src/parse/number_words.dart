/// The number and fraction words of the quantity parser (S08 D12).
///
/// Words are written the way people type them. The parser compares them by
/// their search key (`normalizeKey`), so case, tashkeel, alef and teh marbuta
/// forms, ligatures and repeated letters don't matter, and one entry covers
/// "تلاتة" and "تلاته". A key with a space is a phrase over several words.
library;

/// English cardinals below twenty.
const Map<String, int> englishOnes = {
  'zero': 0,
  'one': 1,
  'two': 2,
  'three': 3,
  'four': 4,
  'five': 5,
  'six': 6,
  'seven': 7,
  'eight': 8,
  'nine': 9,
  'ten': 10,
  'eleven': 11,
  'twelve': 12,
  'thirteen': 13,
  'fourteen': 14,
  'fifteen': 15,
  'sixteen': 16,
  'seventeen': 17,
  'eighteen': 18,
  'nineteen': 19,
};

/// English tens, combined with a following one ("twenty five" = 25).
const Map<String, int> englishTens = {
  'twenty': 20,
  'thirty': 30,
  'forty': 40,
  'fifty': 50,
  'sixty': 60,
  'seventy': 70,
  'eighty': 80,
  'ninety': 90,
};

/// The English word for 100, after an optional one to nine or "a"
/// ("two hundred and fifty" = 250).
const String englishHundred = 'hundred';

/// The English "and" inside a cardinal ("one hundred and fifty").
const String englishAnd = 'and';

/// Articles that count as one at the start of the text ("an apple",
/// "a cup of tea", "a dozen eggs", "a half cup").
const Set<String> articleWords = {'a', 'an'};

/// English denominators after a cardinal: "three quarters" = ¾,
/// "two thirds" = ⅔, "one half" = ½.
const Map<String, int> englishDenominators = {
  'half': 2,
  'halves': 2,
  'third': 3,
  'thirds': 3,
  'quarter': 4,
  'quarters': 4,
};

/// Arabic number words 1 to 10 in MSA and Egyptian/Levantine spellings, and
/// a few Arabizi ones (S08 D12).
const Map<String, int> arabicNumberWords = {
  // 1
  'واحد': 1,
  'واحدة': 1,
  'wa7ed': 1,
  'wa7da': 1,
  'wahed': 1,
  // 2
  'اثنين': 2,
  'اتنين': 2,
  'اثنان': 2,
  'اثنتين': 2,
  'اثنتان': 2,
  'تنين': 2,
  'etnen': 2,
  'itnen': 2,
  'tnen': 2,
  // 3
  'ثلاثة': 3,
  'ثلاث': 3,
  'تلاتة': 3,
  'تلات': 3,
  'تلاتي': 3,
  'talata': 3,
  'tlata': 3,
  // 4
  'أربعة': 4,
  'أربع': 4,
  'arba3a': 4,
  // 5
  'خمسة': 5,
  'خمس': 5,
  'khamsa': 5,
  '5amsa': 5,
  // 6
  'ستة': 6,
  'ست': 6,
  'ستي': 6,
  'sitta': 6,
  'seta': 6,
  // 7
  'سبعة': 7,
  'سبع': 7,
  'sab3a': 7,
  // 8
  'ثمانية': 8,
  'ثماني': 8,
  'ثمان': 8,
  'تمانية': 8,
  'تماني': 8,
  'تمنية': 8,
  'tamanya': 8,
  // 9
  'تسعة': 9,
  'تسع': 9,
  'tes3a': 9,
  'tis3a': 9,
  // 10
  'عشرة': 10,
  'عشر': 10,
  '3ashara': 10,
  '3ashra': 10,
};

/// Fraction words on their own ("half a cup", "نص رغيف", "ربع كيلو",
/// "تلت تربع" = ¾), in English, Arabic and Arabizi.
const Map<String, double> fractionWords = {
  'half': 1 / 2,
  'quarter': 1 / 4,
  'third': 1 / 3,
  'نص': 1 / 2,
  'نصف': 1 / 2,
  'ربع': 1 / 4,
  'تلت': 1 / 3,
  'ثلث': 1 / 3,
  'تلتين': 2 / 3,
  'ثلثين': 2 / 3,
  'ثلثان': 2 / 3,
  'تلت تربع': 3 / 4,
  'تلات تربع': 3 / 4,
  'تلات أرباع': 3 / 4,
  'ثلاث أرباع': 3 / 4,
  'ثلاثة أرباع': 3 / 4,
  'nos': 1 / 2,
  'nus': 1 / 2,
  'nesf': 1 / 2,
  'nisf': 1 / 2,
  'rob3': 1 / 4,
  'rub3': 1 / 4,
  'telt': 1 / 3,
  'tult': 1 / 3,
};

/// Fractions added to (or, for "إلا", taken from) the number or unit before
/// them: "تلاتة ونص" = 3½, "كيلو ونص" = 1½ kg, "two and a half",
/// "كيلو إلا ربع" = ¾ kg.
const Map<String, double> addedFractions = {
  'and a half': 1 / 2,
  'and half': 1 / 2,
  'and a quarter': 1 / 4,
  'and a third': 1 / 3,
  'ونص': 1 / 2,
  'و نص': 1 / 2,
  'ونصف': 1 / 2,
  'و نصف': 1 / 2,
  'وربع': 1 / 4,
  'و ربع': 1 / 4,
  'وتلت': 1 / 3,
  'و تلت': 1 / 3,
  'وثلث': 1 / 3,
  'و ثلث': 1 / 3,
  'إلا ربع': -1 / 4,
  'إلا تلت': -1 / 3,
  'إلا ثلث': -1 / 3,
  'wnos': 1 / 2,
  'w nos': 1 / 2,
  'wnus': 1 / 2,
  'w nus': 1 / 2,
  'wrob3': 1 / 4,
  'w rob3': 1 / 4,
  'wtelt': 1 / 3,
  'w telt': 1 / 3,
};

/// Words for twelve, used alone ("dozen eggs") or as a multiplier
/// ("2 dozen", "half a dozen", "نص دستة").
const Set<String> dozenWords = {'dozen', 'dozens', 'دستة'};

/// Words between two numbers that make a range ("2 to 3", "اتنين أو
/// تلاتة"). Ranges are left to Buddy, so the parser gives up on them.
const Set<String> rangeWords = {'to', 'or', 'أو', 'ولا', 'aw', 'wala'};

/// "One" after a portion word, the Arabic word order ("رغيف واحد").
const Set<String> oneAfterUnitWords = {'واحد', 'واحدة', 'wa7ed', 'wa7da'};

/// Words between the unit and the food, dropped from the food text
/// ("cup of rice", "كوب من الرز").
const Set<String> ofWords = {'of', 'من'};
