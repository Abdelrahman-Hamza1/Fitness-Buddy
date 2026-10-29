// Recorded Buddy answers for journeys J1–J3 (A22 D18): contract-valid
// `BuddyInterpretation` bodies as the server returns them for the texts
// below. Synthetic: no real user's data. Catalog keys are from the shipped
// pack (`data/catalog_ids.lock`), so on a device the pack's own facts win;
// the embedded facts are what a phone without the pack would use.
//
// Plain maps with no imports, so the host tests and the Patrol fake
// transport share them.

/// J1 (`spec/01` J1): a home-cooked meal with weighed rice; Buddy asks
/// whether the rice was weighed raw or cooked, and about the oil.
const j1Text = '200g rice and 150g grilled chicken, cooked at home with oil';

/// J2: a family plate with no database match; Buddy estimates a range.
const j2Text = "a plate of my mom's maqluba";

/// J3: eating out, written in Arabic; the reply is English (AI-143).
const j3Text = 'اكلت شاورما دجاج مع خبز عربي';

Map<String, Object?> _n(double kcal, double p, double c, double f, double fi) =>
    {'kcal': kcal, 'proteinG': p, 'carbsG': c, 'fatG': f, 'fiberG': fi};

Map<String, Object?> _serving(String unit, double g) => {
  'unitCode': unit,
  'g': g,
  'ml': null,
  'rangeLo': null,
  'rangeHi': null,
  'source': 'reviewed',
};

Map<String, Object?> _food(
  String key,
  String en,
  String? ar,
  String state,
  Map<String, Object?> nutrients, {
  List<Map<String, Object?>> servings = const [],
  String? group,
}) => {
  'key': key,
  'nameEn': en,
  'nameAr': ar,
  'state': state,
  'source': 'usda',
  'nutrients': nutrients,
  'ranges': null,
  'servings': servings,
  'densityGPerMl': null,
  'yieldGroup': group,
};

final Map<String, Object?> _riceRaw = _food(
  'usda:rice_white_long_grain_raw',
  'Rice, white, long-grain, raw',
  'أرز أبيض نيء',
  'raw',
  _n(365, 7.1, 80, 0.7, 1.3),
  group: 'rice',
);

final Map<String, Object?> _riceCooked = _food(
  'usda:rice_white_long_grain_cooked',
  'Rice, white, long-grain, cooked',
  'أرز أبيض مطبوخ',
  'cooked',
  _n(130, 2.7, 28, 0.3, 0.4),
  group: 'rice',
);

final Map<String, Object?> _chicken = _food(
  'usda:chicken_breast_roasted',
  'Chicken breast, roasted',
  'صدر دجاج مشوي',
  'cooked',
  _n(165, 31, 0, 3.6, 0),
);

final Map<String, Object?> _oil = _food(
  'usda:olive_oil',
  'Olive oil',
  'زيت زيتون',
  'raw',
  _n(884, 0, 0, 100, 0),
  servings: [_serving('tbsp', 13.5), _serving('tsp', 4.5)],
);

final Map<String, Object?> _pita = _food(
  'usda:pita_white',
  'Pita bread, white',
  'خبز عربي',
  'as_sold',
  _n(275, 9.1, 56, 1.2, 2.2),
  servings: [_serving('loaf', 60)],
);

Map<String, Object?> _option(
  String value, {
  Map<String, Object?>? candidate,
  double? amount,
  String? unit,
}) => {
  'value': value,
  'candidateKey': candidate?['key'],
  'candidate': candidate,
  'amount': amount,
  'unit': unit,
};

Map<String, Object?> _item(
  String mention, {
  Map<String, Object?>? match,
  double? amount,
  String? unit,
  bool explicit = true,
  List<Map<String, Object?>> alternatives = const [],
  List<Map<String, Object?>> dimensions = const [],
  Map<String, Object?>? estimate,
}) => {
  'mention': mention,
  'match': match,
  'alternatives': alternatives,
  'amount': {'value': amount, 'unit': unit, 'explicit': explicit},
  'share': null,
  'dimensions': dimensions,
  'estimate': estimate,
};

Map<String, Object?> _answer(
  String language,
  String script,
  List<Map<String, Object?>> items, {
  String? dish,
}) => {
  'promptVersion': 'interpret-v2',
  'model': 'recorded-fixture',
  'intents': [
    {
      'kind': 'foodLog',
      'language': language,
      'script': script,
      'timeHint': null,
      'slotHint': null,
      'dateHint': null,
      'dishGroup': dish,
      'items': items,
    },
  ],
};

/// J1's answer: rice (raw or cooked? asked) and chicken (oil? asked).
Map<String, Object?> j1Interpretation() => _answer('english', 'latin', [
  _item(
    'rice',
    match: _riceRaw,
    amount: 200,
    unit: 'g',
    alternatives: [_riceCooked],
    dimensions: [
      {
        'kind': 'state',
        'statedValue': null,
        'options': [
          _option('raw', candidate: _riceRaw),
          _option('cooked', candidate: _riceCooked),
        ],
      },
    ],
  ),
  _item(
    'grilled chicken',
    match: _chicken,
    amount: 150,
    unit: 'g',
    dimensions: [
      {
        'kind': 'fat',
        'statedValue': null,
        'options': [
          _option('none', amount: 0, unit: 'tsp'),
          _option('oil', candidate: _oil, amount: 1, unit: 'tsp'),
          _option('oil', candidate: _oil, amount: 1, unit: 'tbsp'),
        ],
      },
    ],
  ),
], dish: 'Rice with chicken');

/// J2's answer: no match, a badged estimate with a range (AI-032).
Map<String, Object?> j2Interpretation() => _answer('english', 'latin', [
  _item(
    'maqluba',
    amount: 350,
    unit: 'g',
    explicit: false,
    estimate: {
      'range': {'low': _n(130, 6, 18, 4, 1.5), 'high': _n(190, 9, 24, 8, 2.5)},
      'reason': 'noMatch',
    },
  ),
]);

/// J3's answer: an estimated chicken shawarma and a matched pita, from an
/// Arabic message.
Map<String, Object?> j3Interpretation() => _answer('arabic', 'arabic', [
  _item(
    'شاورما دجاج',
    amount: 200,
    unit: 'g',
    explicit: false,
    estimate: {
      'range': {'low': _n(180, 12, 15, 7, 1), 'high': _n(250, 16, 20, 12, 2)},
      'reason': 'noMatch',
    },
  ),
  _item('خبز عربي', match: _pita, amount: 1, unit: 'loaf'),
]);

/// The recorded answer for [text], or null for any other message.
Map<String, Object?>? buddyFixtureFor(String text) => switch (text) {
  j1Text => j1Interpretation(),
  j2Text => j2Interpretation(),
  j3Text => j3Interpretation(),
  _ => null,
};
