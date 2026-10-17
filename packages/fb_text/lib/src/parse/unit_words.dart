/// The unit and portion words of the quantity parser (S08 D12, A10, LC-051).
///
/// Units come out as plain code strings, so `fb_text` doesn't depend on
/// `fb_domain`. A dev-only test checks that every code in [parsedUnitCodes]
/// is a unit `fb_domain` knows. Words are compared by their search key
/// (`normalizeKey`), like the number words. A key with a space is a phrase
/// over several words.
///
/// علبة (can or box) is the `can` unit (A05 D14, backlog #26). Its size
/// depends on the food (a cola can is 330 ml, a tuna can 160 g), so the
/// food's own `can` serving unit gives it; "bowl" or "slice" have no unit
/// code.
library;

/// Every unit code the parser can return: the mass and volume units of D4
/// and the portion units of LC-051 (whose grams depend on the food).
const Set<String> parsedUnitCodes = {
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
  'can',
};

/// English unit words, singular and plural. At the start of the text
/// without a number they need "of" after them ("cup of tea" is one cup,
/// but "pound cake" is a food, not a pound of cake).
const Map<String, String> englishUnitWords = {
  'g': 'g',
  'gm': 'g',
  'gms': 'g',
  'gr': 'g',
  'grs': 'g',
  'gram': 'g',
  'grams': 'g',
  'gramme': 'g',
  'grammes': 'g',
  'kg': 'kg',
  'kgs': 'kg',
  'kilo': 'kg',
  'kilos': 'kg',
  'kilogram': 'kg',
  'kilograms': 'kg',
  'kilogramme': 'kg',
  'kilogrammes': 'kg',
  'oz': 'oz',
  'ozs': 'oz',
  'ounce': 'oz',
  'ounces': 'oz',
  'lb': 'lb',
  'lbs': 'lb',
  'pound': 'lb',
  'pounds': 'lb',
  'ml': 'ml',
  'mls': 'ml',
  'milliliter': 'ml',
  'milliliters': 'ml',
  'millilitre': 'ml',
  'millilitres': 'ml',
  'l': 'l',
  'ltr': 'l',
  'ltrs': 'l',
  'liter': 'l',
  'liters': 'l',
  'litre': 'l',
  'litres': 'l',
  'fl oz': 'fl_oz',
  'floz': 'fl_oz',
  'fluid ounce': 'fl_oz',
  'fluid ounces': 'fl_oz',
  'cup': 'cup',
  'cups': 'cup',
  'tbsp': 'tbsp',
  'tbsps': 'tbsp',
  'tbs': 'tbsp',
  'tablespoon': 'tbsp',
  'tablespoons': 'tbsp',
  'table spoon': 'tbsp',
  'table spoons': 'tbsp',
  'tsp': 'tsp',
  'tsps': 'tsp',
  'teaspoon': 'tsp',
  'teaspoons': 'tsp',
  'tea spoon': 'tsp',
  'tea spoons': 'tsp',
  'piece': 'piece',
  'pieces': 'piece',
  'pc': 'piece',
  'pcs': 'piece',
  'loaf': 'loaf',
  'loaves': 'loaf',
  'plate': 'plate',
  'plates': 'plate',
  'glass': 'glass',
  'glasses': 'glass',
  'sandwich': 'sandwich',
  'sandwiches': 'sandwich',
  'disc': 'disc',
  'discs': 'disc',
  'disk': 'disc',
  'disks': 'disc',
  'serving': 'serving',
  'servings': 'serving',
  'can': 'can',
  'cans': 'can',
  'tin': 'can',
  'tins': 'can',
};

/// Arabic unit and portion words (and a few Arabizi ones), singular and
/// plural. They may start the text without a number, the way Arabic names
/// a portion ("رغيف عيش" is one loaf of bread).
///
/// كوب is the label cup (240 ml, D4). كاسة, كاس, كباية and كوباية are a
/// glass, whose size depends on the food. ملعقة alone is a tablespoon (a
/// documented assumption, D12); with a size word it follows
/// [spoonSizeWords] (A10).
const Map<String, String> arabicUnitWords = {
  // Mass.
  'جم': 'g',
  'جرام': 'g',
  'جرامات': 'g',
  'غرام': 'g',
  'غرامات': 'g',
  'غم': 'g',
  'كيلو': 'kg',
  'كيلوات': 'kg',
  'كيلوجرام': 'kg',
  'كيلوغرام': 'kg',
  'كجم': 'kg',
  'كغ': 'kg',
  'أونصة': 'oz',
  'أوقية': 'oz',
  'رطل': 'lb',
  'باوند': 'lb',
  // Volume.
  'مل': 'ml',
  'ملي': 'ml',
  'مللي': 'ml',
  'ملليلتر': 'ml',
  'مليلتر': 'ml',
  'لتر': 'l',
  'ليتر': 'l',
  'لترات': 'l',
  'كوب': 'cup',
  'أكواب': 'cup',
  'ملعقة': 'tbsp',
  'معلقة': 'tbsp',
  'ملاعق': 'tbsp',
  'معالق': 'tbsp',
  // Portions (LC-051).
  'حبة': 'piece',
  'حبات': 'piece',
  'قطعة': 'piece',
  'قطع': 'piece',
  'حتة': 'piece',
  'حتت': 'piece',
  'رغيف': 'loaf',
  'أرغفة': 'loaf',
  'رغفان': 'loaf',
  'صحن': 'plate',
  'صحون': 'plate',
  'طبق': 'plate',
  'أطباق': 'plate',
  'كاسة': 'glass',
  'كاس': 'glass',
  'كاسات': 'glass',
  'كباية': 'glass',
  'كبايات': 'glass',
  'كوباية': 'glass',
  'كوبايات': 'glass',
  'سندويشة': 'sandwich',
  'سندويش': 'sandwich',
  'سندويتش': 'sandwich',
  'ساندويتش': 'sandwich',
  'سندوتش': 'sandwich',
  'ساندوتش': 'sandwich',
  'سندوتشات': 'sandwich',
  'سندويتشات': 'sandwich',
  'قرص': 'disc',
  'أقراص': 'disc',
  'حصة': 'serving',
  'حصص': 'serving',
  'علبة': 'can',
  'علب': 'can',
  // Arabizi.
  'kobaya': 'glass',
  'kobbaya': 'glass',
  'kas': 'glass',
  'ma3la2a': 'tbsp',
  '7aba': 'piece',
  '7abba': 'piece',
  'sa7n': 'plate',
  'ragheef': 'loaf',
  'raghif': 'loaf',
  '3elbe': 'can',
  '3elba': 'can',
  '3elab': 'can',
};

/// Unit abbreviations that are a unit only right after a number ("٥ غ",
/// "٥غ"): alone they are too short to mean anything ("غ سكر" is no
/// quantity).
const Map<String, String> numberOnlyUnitWords = {'غ': 'g'};

/// Singular Arabic words of [arabicUnitWords] whose dual means two of them
/// (LC-051): رغيفين, حبتين, صحنين, كاستين, ملعقتين. The dual forms are
/// derived: a word ending in ة (ه in the key) swaps it for ت, then ين or ان
/// is added (حبة → حبتين, حبتان; رغيف → رغيفين, رغيفان).
const Set<String> arabicDualUnits = {
  'رغيف',
  'صحن',
  'طبق',
  'حبة',
  'قطعة',
  'حتة',
  'كاسة',
  'كاس',
  'كباية',
  'كوباية',
  'كوب',
  'سندويشة',
  'قرص',
  'حصة',
  'علبة',
  'ملعقة',
  'معلقة',
  'كيلو',
  'لتر',
};

/// Spoon words (singular and plural of [arabicUnitWords]) that take a size
/// word after them ([spoonSizeWords]). Their dual forms (ملعقتين) take one
/// too.
const Set<String> arabicSpoonWords = {
  'ملعقة',
  'معلقة',
  'ملاعق',
  'معالق',
  'ma3la2a',
};

/// The size after a spoon word (A10): ملعقة صغيرة or ملعقة شاي is a
/// teaspoon, ملعقة كبيرة or ملعقة أكل a tablespoon. Singular, dual and
/// plural adjectives are all accepted.
const Map<String, String> spoonSizeWords = {
  'صغيرة': 'tsp',
  'صغير': 'tsp',
  'صغيرتين': 'tsp',
  'صغيرين': 'tsp',
  'صغار': 'tsp',
  'شاي': 'tsp',
  'كبيرة': 'tbsp',
  'كبير': 'tbsp',
  'كبيرتين': 'tbsp',
  'كبيرين': 'tbsp',
  'كبار': 'tbsp',
  'أكل': 'tbsp',
  'طعام': 'tbsp',
  'soghayara': 'tsp',
  'kbeera': 'tbsp',
};
