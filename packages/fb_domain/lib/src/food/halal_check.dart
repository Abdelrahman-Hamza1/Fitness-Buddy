/// What a halal check can say about a food (FD-081). A warning, never a
/// block; [unknownSource] is worded as unknown, never as non-halal.
enum HalalFlag {
  /// The text names pork or a pork product.
  pork,

  /// The text names alcohol or an alcoholic drink.
  alcohol,

  /// Gelatin, emulsifiers or other ingredients whose animal source is
  /// unknown.
  unknownSource,
}

/// Keyword halal check over a food's name, Arabic name, ingredient text and
/// Open Food Facts tags (FD-081, A28a D11). Pure and offline.
///
/// Matching is on whole words of lower-cased text with Arabic letter forms
/// folded (alef forms, alef maqsura, taa marbuta, diacritics, tatweel), and
/// Arabic words may carry the usual one-letter prefixes and the article.
/// Phrases that look alike but aren't the thing (sugar alcohol, wine
/// vinegar, turkey ham, root beer…) are removed first. `en:halal`,
/// `en:vegan` and `en:vegetarian` tags drop [HalalFlag.unknownSource] only.
/// The lists are a first draft for the owner to review by use.
abstract final class HalalCheck {
  /// The flags for the given texts; empty when nothing matched.
  static Set<HalalFlag> check({
    String? name,
    String? nameAr,
    String? ingredients,
    Iterable<String> tags = const [],
  }) {
    final text = _fold([name, nameAr, ingredients].nonNulls.join(' \n '));
    if (text.trim().isEmpty) return const {};
    var cleaned = ' $text ';
    for (final phrase in _exclusions) {
      cleaned = cleaned.replaceAll(phrase, ' ');
    }
    final flags = <HalalFlag>{
      if (_pork.hasMatch(cleaned)) HalalFlag.pork,
      if (_alcohol.hasMatch(cleaned)) HalalFlag.alcohol,
      if (_unknown.hasMatch(cleaned) || _eNumbers.hasMatch(cleaned))
        HalalFlag.unknownSource,
    };
    final safe = tags.map((t) => t.toLowerCase()).toSet();
    if (safe.contains('en:halal') ||
        safe.contains('en:vegan') ||
        safe.contains('en:vegetarian')) {
      flags.remove(HalalFlag.unknownSource);
    }
    return flags;
  }

  static const _porkEn = [
    'pork', 'pig', 'pigs', 'swine', 'porcine', 'bacon', 'ham', 'hams', //
    'lard', 'prosciutto', 'pancetta', 'jambon', 'saindoux', 'domuz',
  ];
  static const _porkAr = [
    'خنزير',
    'لحم خنزير',
    'شحم خنزير',
    'دهن خنزير',
    'بيكون',
    'جامبون',
    'لارد',
  ];
  static const _alcoholEn = [
    'alcohol',
    'alcoholic',
    'ethanol',
    'ethyl alcohol',
    'wine',
    'wines',
    'beer',
    'liqueur',
    'liquor',
    'rum',
    'brandy',
    'whisky',
    'whiskey',
    'vodka',
    'cognac',
    'gin',
    'sherry',
    'marsala',
    'kirsch',
    'mirin',
  ];
  static const _alcoholAr = [
    'كحول',
    'كحولي',
    'كحوليه',
    'ايثانول',
    'نبيذ',
    'خمر',
    'بيره',
    'مشروب كحولي',
    'براندي',
    'ويسكي',
    'فودكا',
  ];
  static const _unknownEn = [
    'gelatin',
    'gelatine',
    'mono and diglycerides',
    'mono and di glycerides',
    'monoglycerides',
    'diglycerides',
    'glycerol',
    'glycerin',
    'glycerine',
    'animal fat',
    'animal fats',
    'rennet',
    'pepsin',
    'l cysteine',
  ];
  static const _unknownAr = [
    'جيلاتين',
    'جلاتين',
    'مستحلب حيواني',
    'احادي وثنائي الجليسريد',
    'جليسرين',
    'جلسرين',
    'منفحه',
    'دهن حيواني',
    'دهون حيوانيه',
  ];

  /// Removed before matching (already folded and space-padded).
  static final List<String> _exclusions = [
    for (final p in [
      'sugar alcohols',
      'sugar alcohol',
      'alcohol free',
      'non alcoholic',
      'nonalcoholic',
      '0 alcohol',
      'wine vinegar',
      'root beer',
      'ginger beer',
      'turkey ham',
      'chicken ham',
      'beef ham',
      'turkey bacon',
      'chicken bacon',
      'beef bacon',
      'halal bacon',
      'microbial rennet',
      'vegetable rennet',
      'vegetarian rennet',
      'vegetable glycerin',
      'vegetable glycerine',
      'خالي من الكحول',
      'خال من الكحول',
      'بدون كحول',
      'كحول سكري',
      'كحولات سكريه',
      'منفحه نباتيه',
      'منفحه ميكروبيه',
    ])
      ' ${_fold(p)} ',
  ];

  static final RegExp _pork = _words(_porkEn, _porkAr);
  static final RegExp _alcohol = _words(_alcoholEn, _alcoholAr);
  static final RegExp _unknown = _words(_unknownEn, _unknownAr);

  /// E441 gelatin, E422 glycerol, E470–E482 emulsifiers of possible animal
  /// origin, E542 bone phosphate, E920 L-cysteine.
  static final RegExp _eNumbers = RegExp(
    r'(?<=\s)e ?(441|422|470|471|472|473|474|475|477|478|481|482|542|920)'
    r'[a-f]?(?=\s)',
  );

  static RegExp _words(List<String> latin, List<String> arabic) {
    String alt(List<String> words) => words
        .map((w) => RegExp.escape(_fold(w)).replaceAll(' ', r'\s'))
        .join('|');
    // Arabic: optional و/ف/ب/ل/ك then the article, on the first word.
    return RegExp(
      '(?<=\\s)(?:(?:${alt(latin)})|'
      '(?:[وفبلك]?(?:ال)?(?:${alt(arabic)})))(?=\\s)',
    );
  }

  static final RegExp _letterOrDigit = RegExp(r'[\p{L}\p{N}]', unicode: true);

  /// Lower case, Arabic letter forms folded, everything that isn't a letter
  /// or digit turned into a single space.
  static String _fold(String text) {
    final out = StringBuffer();
    for (final rune in text.toLowerCase().runes) {
      final c = switch (rune) {
        0x0623 || 0x0625 || 0x0622 || 0x0671 => 0x0627, // أ إ آ ٱ → ا
        0x0649 => 0x064A, // ى → ي
        0x0629 => 0x0647, // ة → ه
        _ => rune,
      };
      if ((c >= 0x064B && c <= 0x0652) || c == 0x0670 || c == 0x0640) continue;
      final ch = String.fromCharCode(c);
      out.write(_letterOrDigit.hasMatch(ch) ? ch : ' ');
    }
    return out.toString().replaceAll(RegExp(r'\s+'), ' ');
  }
}
