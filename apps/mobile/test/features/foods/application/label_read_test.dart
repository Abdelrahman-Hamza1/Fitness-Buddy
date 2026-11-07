import 'dart:convert';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/api/dio_factory.dart';
import 'package:fb_mobile/features/foods/application/label_reading.dart';
import 'package:fb_mobile/features/foods/data/label_api.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_http.dart';
import 'personal_food_application_test.dart' show form, value;

Map<String, Object?> _v(num? value, [String confidence = 'high']) => {
  'value': value,
  'confidence': confidence,
};

/// A label read as the server sends it: per serving of 240 ml, kcal from
/// kJ, an unsure fat value, no fiber.
Map<String, Object?> _label({bool found = true, String basis = 'perServing'}) =>
    {
      'found': found,
      'basis': found ? basis : null,
      'serving': found
          ? {
              'amount': 1,
              'unit': 'cup',
              'g': null,
              'ml': 240,
              'label': '1 cup (240 ml)',
              'confidence': 'high',
            }
          : null,
      'name': {'value': found ? 'Laban drink' : null, 'confidence': 'medium'},
      'nutrients': {
        'kcal': _v(found ? 150 : null),
        'proteinG': _v(found ? 8 : null),
        'carbsG': _v(found ? 12 : null),
        'fatG': _v(found ? 8 : null, 'low'),
        'fiberG': _v(null),
        'sugarG': _v(found ? 12 : null),
        'saturatedFatG': _v(null),
        'transFatG': _v(null),
        'sodiumMg': _v(found ? 120 : null),
        'cholesterolMg': _v(null),
        'kcalFromKj': found,
        'sodiumFromSalt': false,
      },
      'others': [
        if (found)
          {'name': 'Calcium', 'value': 300, 'unit': 'mg', 'confidence': 'high'},
      ],
    };

LabelApi _api(FakeHttpAdapter adapter) => LabelApi(
  createApiDio(
    baseUrl: Uri.parse('https://api.test'),
    adapter: adapter,
    interceptors: [],
  ),
);

void main() {
  test('AI-012 FD-041 a label read becomes the review input: its basis and '
      'serving, the values, and what to check', () async {
    final adapter = FakeHttpAdapter(respond: json(_label()));
    // A stand-in photo built at runtime (no key-shaped literal).
    final photo = base64Encode(List<int>.filled(16, 7));
    final outcome = await _api(adapter).read(photo);
    expect(adapter.requests.single.path, '/v1/buddy/label');
    expect((adapter.requests.single.data as Map)['image'], photo);
    final reading = (outcome as LabelRead).reading;
    expect(reading.basis, NutrientBasis.per100ml);
    expect((reading.perServing, reading.servingSize), (true, 240));
    expect(reading.name, 'Laban drink');
    expect(reading.values[PersonalFoodField.kcal], 150);
    expect(reading.values.containsKey(PersonalFoodField.fiber), isFalse);
    expect(reading.uncertain, {
      PersonalFoodField.kcal, // converted from kJ
      PersonalFoodField.fat, // low confidence
      PersonalFoodField.name, // medium confidence
    });
    expect(reading.others.single.name, 'Calcium');
  });

  test('no panel, the daily limit, no connection, a server failure', () async {
    Future<LabelOutcome> read(FakeResponder r) =>
        _api(FakeHttpAdapter(respond: r)).read('AA==');
    expect(
      (await read(json(_label(found: false))) as LabelNotRead).failure,
      LabelFailure.notFound,
    );
    expect(
      (await read(problem('rate-limited', 429)) as LabelNotRead).failure,
      LabelFailure.limited,
    );
    expect((await read(offline) as LabelNotRead).failure, LabelFailure.offline);
    expect(
      (await read(problem('unavailable', 503)) as LabelNotRead).failure,
      LabelFailure.unavailable,
    );
    expect(
      (await read(json({'found': true})) as LabelNotRead).failure,
      LabelFailure.unavailable,
    );
  });

  test('FD-041 FD-042 the form opens filled from the label, highlights '
      'what to check, and saves a food made from it', () async {
    final f = await form();
    final read = await _api(FakeHttpAdapter(respond: json(_label())))
        .read('AA==');
    f.controller.applyLabel((read as LabelRead).reading);
    var state = value(f.container);
    expect(state.mode, PersonalFoodMode.perServing);
    expect(state.basis, NutrientBasis.per100ml);
    expect(state.text(PersonalFoodField.servingSize), '240');
    expect(state.text(PersonalFoodField.name), 'Laban drink');
    expect(state.uncertain, contains(PersonalFoodField.fat));
    expect(state.fromLabel, isTrue);
    expect(state.labelOthers, hasLength(1));
    f.controller.setField(PersonalFoodField.fat, '8');
    state = value(f.container);
    expect(state.uncertain, isNot(contains(PersonalFoodField.fat)));
    final draft = state.validation.draft!;
    expect(draft.createdFrom, labelCreatedFrom);
    expect(draft.per100.kcal, closeTo(62.5, 0.01));
    expect(draft.basis, NutrientBasis.per100ml);
  });
}
