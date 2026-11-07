import 'package:fb_api_client/fb_api_client.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_text/fb_text.dart';

/// The personal slice of a turn (A66 D10, `06` §3.1) and `findMyFoods`
/// (§4.2): the personal foods whose normalized names or aliases share a
/// word with the text, most shared words first, then by ID, at most
/// [limit], each within the contract's bounds. Saved meals, open batches
/// and usual meals join with A67. Pure: no I/O.
abstract final class PersonalSlice {
  /// The most items sent.
  static const limit = 20;

  static const _names = 5;
  static const _aliases = 10;
  static const _servings = 20;
  static const _value = 200;
  static const double _nutrient = 10000;
  static const double _serving = 100000;

  /// The foods of [foods] matching [text], as request items.
  static List<BuddyPersonalItem> match(
    String text,
    Iterable<PersonalFood> foods, {
    int max = limit,
  }) {
    final words = wordsOf(text);
    if (words.isEmpty) return const [];
    final scored = <(int, PersonalFood)>[];
    for (final food in foods) {
      final shared = {
        for (final name in [..._namesOf(food), ...food.aliases])
          ...wordsOf(name),
      }.intersection(words).length;
      if (shared > 0) scored.add((shared, food));
    }
    scored.sort(
      (a, b) =>
          a.$1 != b.$1 ? b.$1.compareTo(a.$1) : a.$2.id.compareTo(b.$2.id),
    );
    final out = <BuddyPersonalItem>[];
    for (final (_, food) in scored) {
      if (out.length == max) break;
      if (_item(food, words) case final f?) out.add(f);
    }
    return out;
  }

  static BuddyPersonalItem? _item(PersonalFood food, Set<String> words) {
    final names = [
      for (final n in _namesOf(food))
        if (n.trim() case final t when t.isNotEmpty) t,
    ];
    final matched = <String>[];
    final rest = <String>[];
    for (final alias in food.aliases.map((a) => a.trim())) {
      (wordsOf(alias).intersection(words).isEmpty ? rest : matched).add(alias);
    }
    final aliases = [...matched, ...rest].take(_aliases).toList();
    final p = food.per100;
    final nutrients = [p.kcal, p.protein, p.carbs, p.fat, p.fiber];
    final units = [
      ...food.servings,
      if (food.entryServing case final e?)
        if (!food.servings.any((s) => s.unit == e.unit)) e,
    ];
    if (names.isEmpty ||
        names.length > _names ||
        !names.every(_fits) ||
        !aliases.every(_fits) ||
        !_fits(food.state.code) ||
        units.length > _servings ||
        !nutrients.every((v) => v.isFinite && v >= 0 && v <= _nutrient) ||
        !units.every(
          (s) => s.amount.isFinite && s.amount > 0 && s.amount <= _serving,
        )) {
      return null;
    }
    return BuddyPersonalItem(
      kind: BuddyPersonalKind.personalFood,
      ref: food.id,
      names: names,
      aliases: aliases,
      state: food.state.code,
      per100: BuddyNutrientsRequest(
        kcal: p.kcal,
        proteinG: p.protein,
        carbsG: p.carbs,
        fatG: p.fat,
        fiberG: p.fiber,
      ),
      servings: [
        for (final s in units)
          BuddyServing(
            unitCode: s.unit,
            g: food.basis == NutrientBasis.per100g ? s.amount : null,
            ml: food.basis == NutrientBasis.per100ml ? s.amount : null,
            rangeLo: null,
            rangeHi: null,
            source: 'personal',
          ),
      ],
      portions: const [],
    );
  }

  static List<String> _namesOf(PersonalFood food) => [
    food.names.en,
    ?food.names.ar,
  ];

  /// The words of [text] that can tie it to a food: normalized (fb_text,
  /// as the catalog), 2+ characters, not a joining word.
  static Set<String> wordsOf(String text) => {
    for (final w in normalizeKey(text).split(' '))
      if (w.length >= 2 && !_stopwords.contains(w)) w,
  };

  /// Joining words in English, Arabic and Arabizi, normalized like names.
  static final Set<String> _stopwords = {
    for (final w in const [
      'with', 'and', 'of', 'the', 'an', 'in', 'on', 'or', 'some', 'my',
      'for', 'to', 'at', 'plus', 'without', //
      'مع', 'في', 'من', 'على', 'او', 'أو', 'بدون', //
      'ma3', 'm3', 'wa', 'fi', 'min', 'mn', '3la', 'aw', 'bdoon', 'bdun',
    ])
      normalizeKey(w),
  };

  static bool _fits(String value) =>
      value.trim().isNotEmpty && value.length <= _value;
}
