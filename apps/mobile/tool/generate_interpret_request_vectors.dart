import 'dart:convert';
import 'dart:io';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/buddy/data/interpret_request_builder.dart';

/// The committed corpus (A22 D18, TD-093): every app-built interpret request
/// shape the server must admit, generated from the real builder.
const interpretRequestVectorsPath =
    'contracts/testdata/buddy/interpret-requests.json';

final EntryTime _now = EntryTime(DateTime.utc(2026, 10, 29, 5, 40), 180);

String _id(int n) => '019a3a1c-8f40-7000-8000-${n.toString().padLeft(12, '0')}';

PersonalFood _food(
  int n, {
  required String en,
  String? ar,
  List<String> aliases = const [],
  List<PersonalFoodServing> servings = const [],
  PersonalFoodServing? entry,
  NutrientBasis basis = NutrientBasis.per100g,
  FoodState state = FoodState.cooked,
  double kcal = 150,
}) => PersonalFood(
  id: _id(1000 + n),
  version: 1,
  draft: PersonalFoodDraft(
    names: FoodNames(en, ar: ar),
    aliases: aliases,
    basis: basis,
    state: state,
    servings: servings,
    entryServing: entry,
    per100: Nutrients(kcal: kcal, protein: 10, carbs: 20, fat: 5, fiber: 1.5),
  ),
);

/// The cases: `(id, what it pins, request)`.
List<(String, String, PreparedInterpret)> interpretRequestCases() {
  PreparedInterpret build(
    int n,
    String text, {
    List<MealSlot>? slots,
    List<PersonalFood> foods = const [],
  }) => InterpretRequestBuilder.build(
    requestId: _id(n),
    text: text,
    now: _now,
    slots: slots ?? DefaultSlots.all,
    personalFoods: foods,
  );

  final bounded = _food(
    1,
    en: 'Mum${'x' * 77}',
    ar: 'ملوخية ${'م' * 72}',
    aliases: [
      for (var i = 0; i < 30; i++) 'alias$i${'a' * (80 - 'alias$i'.length)}',
    ],
    servings: [
      for (final unit in PersonalFoodBounds.units.skip(1).take(10))
        PersonalFoodServing(unit, 5000),
    ],
    entry: PersonalFoodServing('piece', 0.1),
    kcal: 920,
  );
  final customSlots = [
    ...DefaultSlots.all,
    for (var i = 0; i < 10; i++)
      MealSlot(
        id: _id(500 + i),
        sortOrder: 10 + i,
        name: 'Meal ${i + 1}',
        window: TimeWindow(23 * 60 + i, i * 30 + 30),
      ),
    MealSlot(id: _id(600), sortOrder: 99, name: 'Old slot', active: false),
  ];
  return [
    (
      'default-slots',
      'Four default meal slots (UUIDv5 natural IDs), windows as HH:MM-HH:MM, '
          'snacks without one; no personal foods; every other list empty.',
      build(1, '2 eggs and toast'),
    ),
    (
      'arabic-message',
      'Arabic-script message matching an Arabic personal food name.',
      build(
        2,
        'أكلت ملوخية ورز',
        foods: [
          _food(2, en: 'Molokhia', ar: 'ملوخية'),
          _food(3, en: 'Lentil soup', ar: 'شوربة عدس'),
        ],
      ),
    ),
    (
      'arabizi-message',
      'Arabizi message matching a personal food alias.',
      build(
        3,
        'kalet 2 bayd w ful',
        foods: [
          _food(4, en: 'Fava beans', aliases: ['ful', 'foul']),
          _food(5, en: 'Toast'),
        ],
      ),
    ),
    (
      'personal-food-at-bounds',
      'A personal food at every bound: 80-unit names, 30 aliases cut to 10 '
          '(matching first), 11 servings incl. the entry serving, 920 kcal, '
          '0.1 and 5000 g amounts.',
      build(4, 'mum${'x' * 77} with alias29${'a' * 73}', foods: [bounded]),
    ),
    (
      'maximum-list-sizes',
      '15 active slots (4 default + 10 custom with wrapping windows + 1 '
          'inactive) cut to 12; 35 matching personal foods cut to 30, most '
          'shared words first, then by ID; a 1000-unit message.',
      build(
        5,
        'rice chicken salad ${'x' * 1000}'.substring(0, 1000),
        slots: customSlots,
        foods: [
          for (var i = 0; i < 35; i++)
            _food(
              100 + i,
              en: i.isEven ? 'Rice chicken $i' : 'Rice $i',
              basis: i % 3 == 0
                  ? NutrientBasis.per100ml
                  : NutrientBasis.per100g,
              servings: [PersonalFoodServing('cup', 240)],
            ),
        ],
      ),
    ),
  ];
}

/// The corpus file's exact text.
String generateInterpretRequestVectors() {
  final cases = [
    for (final (id, pins, request) in interpretRequestCases())
      {'id': id, 'pins': pins, 'request': request.toJson()},
  ];
  const encoder = JsonEncoder.withIndent('  ');
  return '${encoder.convert({'version': 1, 'cases': cases})}\n';
}

/// Writes the corpus (run from `apps/mobile`, `make gen-interpret-request-vectors`).
void main() {
  File('../../$interpretRequestVectorsPath')
    ..createSync(recursive: true)
    ..writeAsStringSync(generateInterpretRequestVectors());
}
