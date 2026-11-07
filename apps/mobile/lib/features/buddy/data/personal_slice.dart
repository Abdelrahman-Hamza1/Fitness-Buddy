import 'package:fb_api_client/fb_api_client.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_text/fb_text.dart';

/// The personal slice of a turn (A66 D10, `06` §3.1) and `findMyFoods`
/// (§4.2): the personal foods whose normalized names or aliases share a
/// word with the text, most shared words first, then by ID, at most
/// [limit], each within the contract's bounds, with saved meals (whole-meal
/// facts) and open batches (per 100 g and what's left, A67 D13). Usual
/// meals aren't sent yet. Pure: no I/O.
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
    Iterable<SavedMeal> savedMeals = const [],
    Iterable<BatchFacts> batches = const [],
    Set<BuddyPersonalKind> kinds = const {},
  }) {
    final words = wordsOf(text);
    if (words.isEmpty) return const [];
    bool wants(BuddyPersonalKind k) => kinds.isEmpty || kinds.contains(k);
    final open = {for (final b in batches) b.food.id: b};
    // (shared words, ID, the item when it fits).
    final scored = <(int, String, BuddyPersonalItem? Function())>[];
    int shared(Iterable<String> names) =>
        {for (final n in names) ...wordsOf(n)}.intersection(words).length;
    for (final food in foods) {
      final batch = open[food.id];
      if (batch != null
          ? !wants(BuddyPersonalKind.batch)
          : !wants(BuddyPersonalKind.personalFood)) {
        continue;
      }
      final n = shared([..._namesOf(food), ...food.aliases]);
      if (n > 0) {
        scored.add((
          n,
          food.id,
          () => batch == null ? _item(food, words) : _batch(batch, words),
        ));
      }
    }
    if (wants(BuddyPersonalKind.savedMeal)) {
      for (final meal in savedMeals) {
        final n = shared([meal.name]);
        if (n > 0) scored.add((n, meal.id, () => _meal(meal)));
      }
    }
    scored.sort(
      (a, b) => a.$1 != b.$1 ? b.$1.compareTo(a.$1) : a.$2.compareTo(b.$2),
    );
    final out = <BuddyPersonalItem>[];
    for (final (_, _, item) in scored) {
      if (out.length == max) break;
      if (item() case final f?) out.add(f);
    }
    return out;
  }

  static BuddyNutrientsRequest? _nutrients(Nutrients n) {
    final values = [n.kcal, n.protein, n.carbs, n.fat, n.fiber];
    if (!values.every((v) => v.isFinite && v >= 0 && v <= _nutrient)) {
      return null;
    }
    return BuddyNutrientsRequest(
      kcal: n.kcal,
      proteinG: n.protein,
      carbsG: n.carbs,
      fatG: n.fat,
      fiberG: n.fiber,
    );
  }

  static String _cut(String s, int n) => s.length <= n ? s : s.substring(0, n);

  /// A saved meal with its whole-meal facts (DY-031).
  static BuddyPersonalItem? _meal(SavedMeal meal) {
    final name = meal.name.trim();
    final totals = _nutrients(meal.totals);
    if (name.isEmpty || !_fits(name) || totals == null || meal.items.isEmpty) {
      return null;
    }
    var grams = 0.0;
    for (final i in meal.items) {
      grams += i.amount.amount;
    }
    return BuddyPersonalItem(
      kind: BuddyPersonalKind.savedMeal,
      ref: meal.id,
      names: [name],
      aliases: const [],
      state: null,
      per100: null,
      servings: const [],
      portions: [
        BuddyPortionFacts(
          label: _cut('whole meal', 120),
          g: grams > 0 && grams <= _serving ? grams : null,
          nutrients: totals,
        ),
      ],
    );
  }

  /// An open batch: per 100 g and what's left (DY-043).
  static BuddyPersonalItem? _batch(BatchFacts batch, Set<String> words) {
    final base = _item(batch.food, words);
    final left = batch.remainingGrams;
    if (base == null) return null;
    final leftNutrients = left == null
        ? null
        : _nutrients(batch.food.per100.scale(left / 100));
    return BuddyPersonalItem(
      kind: BuddyPersonalKind.batch,
      ref: base.ref,
      names: base.names,
      aliases: base.aliases,
      state: base.state,
      per100: base.per100,
      servings: base.servings,
      portions: [
        if (left != null && leftNutrients != null && left <= _serving)
          BuddyPortionFacts(
            label: 'remaining',
            g: left,
            nutrients: leftNutrients,
          ),
      ],
    );
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
