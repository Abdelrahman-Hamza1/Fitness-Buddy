import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/buddy/data/interpret_request_builder.dart';
import 'package:fb_mobile/features/buddy/data/interpret_request_reader.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../foods/data/personal_food_harness.dart' show PersonalHarness;

const _requestId = '019a1b2c-0000-7000-8000-000000000001';
final EntryTime _now = EntryTime(DateTime.utc(2026, 10, 29, 5, 40), 180);

String _id(int n) => '019a1b2c-0000-7000-8000-${n.toString().padLeft(12, '0')}';

PersonalFood _food(
  int n,
  String en, {
  String? ar,
  List<String> aliases = const [],
  double kcal = 100,
  NutrientBasis basis = NutrientBasis.per100g,
  List<PersonalFoodServing> servings = const [],
}) => PersonalFood(
  id: _id(n),
  version: 1,
  draft: PersonalFoodDraft(
    names: FoodNames(en, ar: ar),
    aliases: aliases,
    basis: basis,
    servings: servings,
    per100: Nutrients(kcal: kcal, protein: 1, carbs: 2, fat: 3, fiber: 0),
  ),
);

void main() {
  // rule: A22 minimal-context
  test('A22 interpret context sends only matched personal foods within '
      'bounds', () {
    final foods = [
      _food(1, 'Grilled chicken', aliases: ['shish']),
      _food(2, 'Chicken rice', ar: 'رز بالدجاج'),
      _food(3, 'Lentil soup', ar: 'شوربة عدس'),
      // Shares only a one-letter word: never sent.
      _food(4, 'A'),
      // Can't be sent valid (per-100 over B08's 10000): skipped.
      _food(5, 'Chicken paste', kcal: 20000),
      _food(
        6,
        'Fava',
        aliases: [for (var i = 0; i < 30; i++) 'f$i', 'chicken'],
        basis: NutrientBasis.per100ml,
        servings: [PersonalFoodServing('cup', 240)],
      ),
    ];
    final request = InterpretRequestBuilder.build(
      requestId: _requestId,
      text: 'a chicken and rice plate',
      now: _now,
      slots: [
        ...DefaultSlots.all,
        MealSlot(
          id: _id(90),
          sortOrder: 9,
          name: '  Suhoor  ',
          window: TimeWindow(3 * 60, 4 * 60 + 30),
          mode: SlotMode.ramadan,
        ),
        MealSlot(id: _id(91), sortOrder: 8, name: 'Old', active: false),
      ],
      personalFoods: foods,
    ).body;
    expect(request.requestId, _requestId);
    expect(request.now, _now.occurredAtUtc);
    expect(request.tzOffsetMin, 180);
    expect(request.activeProposal, isNull);
    expect(request.ramadan.active, isFalse);
    expect(
      [for (final s in request.slots) (s.name, s.window)],
      [
        ('breakfast', '04:00-11:00'),
        ('lunch', '11:00-16:00'),
        ('dinner', '16:00-22:00'),
        ('snacks', null),
      ],
    );
    final sent = request.context.personalFoods;
    // Most shared words first (chicken + rice), then by ID.
    expect(sent.map((f) => f.id), [_id(2), _id(1), _id(6)]);
    expect(sent.first.names, ['Chicken rice', 'رز بالدجاج']);
    expect(sent.first.nutrients.kcal, 100);
    final fava = sent.last;
    expect(fava.aliases, hasLength(InterpretBounds.aliases));
    expect(fava.aliases.first, 'chicken');
    expect(fava.servings.single.ml, 240);
    expect(fava.servings.single.g, isNull);
    expect(fava.servings.single.source, 'personal');
    expect(request.context.savedMeals, isEmpty);
    expect(request.context.openBatches, isEmpty);
    expect(request.context.memory, isEmpty);
    expect(request.context.recentEntries, isEmpty);
    expect(request.context.customExercises, isEmpty);

    // Ramadan mode sends the Ramadan slots instead.
    final ramadan = InterpretRequestBuilder.build(
      requestId: _requestId,
      text: 'x',
      now: _now,
      slots: [
        MealSlot(
          id: _id(90),
          sortOrder: 9,
          name: 'Suhoor',
          window: TimeWindow(3 * 60, 4 * 60 + 30),
          mode: SlotMode.ramadan,
        ),
      ],
      personalFoods: foods,
      mode: SlotMode.ramadan,
    ).body;
    expect(ramadan.slots.single.window, '03:00-04:30');
    expect(ramadan.context.personalFoods, isEmpty);

    // At most 30 foods.
    final many = InterpretRequestBuilder.matchingFoods('rice', [
      for (var i = 0; i < 40; i++) _food(100 + i, 'Rice $i'),
    ]);
    expect(many, hasLength(InterpretBounds.personalFoods));
    expect(many.first.id, _id(100));
  });

  // rule: A22 minimal-context
  test('A22 joining words never tie a message to a personal food', () {
    final foods = [
      _food(1, 'Coffee with milk'),
      _food(2, 'Rice and lentils'),
      _food(3, 'قهوة مع حليب'),
      _food(4, 'ahwe ma3 7aleeb'),
    ];
    List<String> sent(String text) => [
      for (final f in InterpretRequestBuilder.matchingFoods(text, foods)) f.id,
    ];
    expect(sent('rice with chicken'), [_id(2)]);
    expect(sent('chicken with the bread'), isEmpty);
    expect(sent('رز مع دجاج'), isEmpty);
    expect(sent('djej ma3 ruz'), isEmpty);
    expect(sent('coffee'), [_id(1)]);
  });

  // rule: A22 request-reader
  test('A22 request reader reads slots and personal foods in one '
      'snapshot', () async {
    final h = PersonalHarness();
    await h.apply([
      CreatePersonalFood(
        _id(7),
        PersonalFoodDraft(
          names: FoodNames('Molokhia', ar: 'ملوخية'),
          per100: Nutrients(kcal: 50, protein: 1, carbs: 1, fat: 1, fiber: 1),
        ),
      ),
    ]);
    final prepared = await InterpretRequestReader(h.db)
        .prepare(requestId: _requestId, text: 'أكلت ملوخية', now: _now);
    expect(prepared.requestId, _requestId);
    expect(
      prepared.body.slots.map((s) => s.id),
      DefaultSlots.all.map((s) => s.id),
    );
    expect(prepared.body.context.personalFoods.single.id, _id(7));
    expect('$prepared', isNot(contains('ملوخية')));
    expect('${InterpretRequestReader(h.db)}', 'InterpretRequestReader');
  });
}
