import 'package:fb_domain/fb_domain.dart';

Map<String, Object?> n(double kcal) => {
  'kcal': kcal,
  'proteinG': kcal / 20,
  'carbsG': kcal / 10,
  'fatG': kcal / 30,
  'fiberG': kcal / 100,
};

Map<String, Object?> serving(String code, double amount, {bool ml = false}) => {
  'unitCode': code,
  'g': ml ? null : amount,
  'ml': ml ? amount : null,
  'rangeLo': null,
  'rangeHi': null,
  'source': 'reviewed',
};

Map<String, Object?> food({
  String key = 'usda:egg',
  double kcal = 144,
  String state = 'cooked',
  String source = 'usda',
  List<Object?>? servings,
  String? group,
}) => {
  'key': key,
  'nameEn': 'Synthetic food',
  'nameAr': 'طعام',
  'state': state,
  'source': source,
  'nutrients': n(kcal),
  'ranges': null,
  'servings': servings ?? [serving('piece', 50)],
  'densityGPerMl': 1.0,
  'yieldGroup': group,
};

Map<String, Object?> option(
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

Map<String, Object?> dimension(
  String kind,
  List<Object?> options, {
  String? stated,
}) => {'kind': kind, 'statedValue': stated, 'options': options};

Map<String, Object?> item({
  Map<String, Object?>? match,
  double? amount = 1,
  String? unit = 'piece',
  bool explicit = true,
  List<Object?> alternatives = const [],
  List<Object?> dimensions = const [],
  Map<String, Object?>? share,
}) => {
  'mention': 'Synthetic meal',
  'match': match ?? food(),
  'alternatives': alternatives,
  'amount': {'value': amount, 'unit': unit, 'explicit': explicit},
  'share': share,
  'dimensions': dimensions,
  'estimate': null,
};

Map<String, Object?> intent(
  List<Object?> items, {
  String? slot,
  String? time,
  String? group,
  String? date,
}) => {
  'kind': 'foodLog',
  'language': 'english',
  'script': 'latin',
  'timeHint': time,
  'slotHint': slot,
  'dishGroup': group,
  'dateHint': ?date,
  'items': items,
};

Map<String, Object?> message([List<Object?>? intents]) => {
  'promptVersion': 'interpret-v1',
  'model': 'synthetic-offline',
  'intents':
      intents ??
      [
        intent([item()]),
      ],
};

ProposalFood localFood({
  String key = 'usda:egg',
  FoodSource source = .database,
  NutrientBasis basis = .per100g,
  int? personalVersion,
  String? version = '1',
  ProposalFactOrigin origin = .embeddedServer,
  double kcal = 200,
}) => ProposalFood(
  key: key,
  names: FoodNames('Local'),
  state: .cooked,
  source: source,
  per100: nutrients(kcal),
  basis: basis,
  version: version,
  personalVersion: personalVersion,
  origin: origin,
  servings: [ProposalServing('piece', 50, basis, null, null)],
);

Nutrients nutrients(double kcal) => Nutrients(
  kcal: kcal,
  protein: kcal / 20,
  carbs: kcal / 10,
  fat: kcal / 30,
  fiber: kcal / 100,
);

class FixedIds implements ProposalIdSource {
  int calls = 0;
  @override
  String next() =>
      '019a1b2c-0000-7000-8000-${(++calls).toString().padLeft(12, '0')}';
}

ProposalContext context({
  Map<String, String> defaults = const {},
  Map<String, String> choices = const {},
  Iterable<YieldFactor> yields = const [],
}) => ProposalContext(
  referenceTime: EntryTime(DateTime.utc(2026, 10, 17, 8), 0),
  slots: [
    DefaultSlots.breakfast,
    DefaultSlots.lunch,
    DefaultSlots.dinner,
    DefaultSlots.snacks,
  ],
  savedDefaults: defaults,
  choices: choices,
  yields: yields,
);

ProposalBuildResult build(
  Map<String, Object?> json, {
  ProposalContext? ctx,
  ProposalFacts? facts,
  FixedIds? ids,
}) => ProposalEngine.build(
  ProposalRequest(
    interpretation: json,
    messageId: '019a1b2c-0000-7000-8000-000000009999',
    idSource: ids ?? FixedIds(),
    context: ctx ?? context(),
    facts: facts ?? ProposalFacts(),
  ),
);

ProposalSession session(
  Map<String, Object?> json, {
  ProposalContext? ctx,
  ProposalFacts? facts,
  FixedIds? ids,
}) => build(json, ctx: ctx, facts: facts, ids: ids).value!;

Map<String, Object?> oilFood() => food(
  key: 'usda:oil',
  kcal: 884,
  state: 'raw',
  servings: [serving('tbsp', 13.5), serving('tsp', 4.5)],
);

Map<String, Object?> fatDimension() => dimension('fat', [
  option('none', amount: 0, unit: 'tsp'),
  option('oil', candidate: oilFood(), amount: 1, unit: 'tsp'),
  option('oil', candidate: oilFood(), amount: 1, unit: 'tbsp'),
]);

Map<String, Object?> riceItem({double amount = 200}) => item(
  match: food(key: 'usda:rice_dry', kcal: 365, state: 'dry', group: 'rice'),
  amount: amount,
  unit: 'g',
  alternatives: [food(key: 'usda:rice_cooked', kcal: 130, group: 'rice')],
  dimensions: [
    dimension('state', [
      option(
        'dry',
        candidate: food(
          key: 'usda:rice_dry',
          kcal: 365,
          state: 'dry',
          group: 'rice',
        ),
      ),
      option(
        'cooked',
        candidate: food(key: 'usda:rice_cooked', kcal: 130, group: 'rice'),
      ),
    ]),
  ],
);

Map<String, Object?> t01() => message([
  intent([item(), item(match: oilFood(), unit: 'tbsp')], group: 'Egg with oil'),
]);

// Test-only baseline snapshot captured before storage mutation. Production uses
// ProposalInputLoader's independent database reads, never this fixture adapter.
TrustedFoodFacts trustedSession(ProposalSession s, {ProposalContext? ctx}) =>
    trustedRows([
      for (final card in s.cards) ProposalDraftCodec.encodeCard(s, card.id),
    ], ctx: ctx);

// The same baseline from card rows (for example decoded sync fields); a row
// without a food table contributes nothing and is left for restore to reject.
TrustedFoodFacts trustedRows(
  Iterable<Map<String, Object?>> rows, {
  ProposalContext? ctx,
}) {
  final foods = <String, ProposalFood>{};
  for (final row in rows) {
    if (row['foods'] is! List) continue;
    for (final raw in row['foods']! as List) {
      final f = raw as List;
      Nutrients nutrientsAt(Object? raw) {
        final n = raw! as List;
        return Nutrients(
          kcal: (n[0] as num).toDouble(),
          protein: (n[1] as num).toDouble(),
          carbs: (n[2] as num).toDouble(),
          fat: (n[3] as num).toDouble(),
          fiber: (n[4] as num).toDouble(),
          extras: {
            for (final e in (n[5] as Map).entries)
              NutrientKey.fromCode(e.key as String)!: (e.value as num)
                  .toDouble(),
          },
        );
      }

      final range = f[12] as List?;
      foods[f[0] as String] = ProposalFood(
        key: f[0] as String,
        names: FoodNames(f[1] as String, ar: f[2] as String?),
        state: FoodState.values[f[3] as int],
        source: FoodSource.values[f[4] as int],
        per100: nutrientsAt(f[5]),
        basis: NutrientBasis.values[f[6] as int],
        origin: ProposalFactOrigin.values[f[7] as int],
        version: f[8] as String?,
        personalVersion: f[9] as int?,
        density: f[10] as double?,
        yieldGroup: f[11] as String?,
        range: range == null
            ? null
            : ProposalRange(nutrientsAt(range[0]), nutrientsAt(range[1])),
        servings: [
          for (final v in (f[13] as List).cast<List<Object?>>())
            ProposalServing(
              v[0]! as String,
              v[1]! as double,
              NutrientBasis.values[v[2]! as int],
              v[3] as double?,
              v[4] as double?,
            ),
        ],
      );
    }
  }
  return TrustedFoodFacts(foods: foods, yields: ctx?.yields ?? const []);
}
