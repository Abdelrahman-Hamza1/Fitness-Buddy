import 'dart:convert';
import 'dart:io';

import 'package:fb_api_client/fb_api_client.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../tool/generate_interpret_request_vectors.dart';

final _uuid = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
);

bool _short(Object? s) => s is String && s.trim().isNotEmpty && s.length <= 200;

bool _amount(Object? v) => v == null || v is num && v > 0 && v <= 100000;

/// The server's `InterpretRequest.Validate` rules, except the UUID version of
/// context IDs (B09a WP0 accepts any non-nil UUID there; the backend test
/// binds and validates every vector).
void _expectAdmissible(String id, Map<String, Object?> r) {
  expect(isUuidV7(r['requestId']! as String), isTrue, reason: id);
  final text = r['text']! as String;
  expect(text.trim(), isNotEmpty, reason: id);
  expect(text.length, inInclusiveRange(1, 1000), reason: id);
  expect(r['tzOffsetMin'], inInclusiveRange(-840, 840), reason: id);
  expect(r['activeProposal'], isNull, reason: id);
  final slots = (r['slots']! as List<Object?>).cast<Map<String, Object?>>();
  expect(slots.length, lessThanOrEqualTo(12), reason: id);
  for (final s in slots) {
    expect(_uuid.hasMatch(s['id']! as String), isTrue, reason: id);
    expect(_short(s['name']), isTrue, reason: id);
    expect(s['window'] == null || _short(s['window']), isTrue, reason: id);
  }
  final context = r['context']! as Map<String, Object?>;
  final foods = (context['personalFoods']! as List<Object?>)
      .cast<Map<String, Object?>>();
  expect(foods.length, lessThanOrEqualTo(30), reason: id);
  expect(foods.map((f) => f['id']).toSet(), hasLength(foods.length));
  for (final f in foods) {
    expect(isUuidV7(f['id']! as String), isTrue, reason: id);
    final names = f['names']! as List<Object?>;
    final aliases = f['aliases']! as List<Object?>;
    final servings = (f['servings']! as List<Object?>)
        .cast<Map<String, Object?>>();
    expect(names.length, inInclusiveRange(1, 5), reason: id);
    expect(names.every(_short), isTrue, reason: id);
    expect(aliases.length, lessThanOrEqualTo(10), reason: id);
    expect(aliases.every(_short), isTrue, reason: id);
    expect(_short(f['state']), isTrue, reason: id);
    expect(servings.length, lessThanOrEqualTo(20), reason: id);
    for (final s in servings) {
      expect(_short(s['unitCode']) && _short(s['source']), isTrue);
      for (final k in ['g', 'ml', 'rangeLo', 'rangeHi']) {
        expect(_amount(s[k]), isTrue, reason: '$id $k');
      }
    }
    final n = f['nutrients']! as Map<String, Object?>;
    for (final v in n.values) {
      expect(v is num && v >= 0 && v <= 10000, isTrue, reason: id);
    }
  }
  for (final list in [
    'savedMeals',
    'openBatches',
    'memory',
    'recentEntries',
    'customExercises',
  ]) {
    expect(context[list], isEmpty, reason: '$id $list');
  }
}

void main() {
  // rule: A22 request-corpus
  test('A22 interpret request vectors match the builder byte for byte', () {
    final file = File('../../$interpretRequestVectorsPath');
    expect(
      file.readAsStringSync(),
      generateInterpretRequestVectors(),
      reason: 'run make gen-interpret-request-vectors and commit',
    );
    final corpus = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
    expect(corpus['version'], 1);
    final cases = (corpus['cases']! as List<Object?>)
        .cast<Map<String, Object?>>();
    expect(cases.map((c) => c['id']), [
      'default-slots',
      'arabic-message',
      'arabizi-message',
      'personal-food-at-bounds',
      'maximum-list-sizes',
    ]);
    for (final c in cases) {
      final id = c['id']! as String;
      final request = c['request']! as Map<String, Object?>;
      // The generated client reads it back unchanged.
      expect(
        jsonEncode(InterpretRequest.fromJson(request).toJson()),
        jsonEncode(request),
        reason: id,
      );
      _expectAdmissible(id, request);
    }
    Map<String, Object?> request(String id) =>
        cases.singleWhere((c) => c['id'] == id)['request']!
            as Map<String, Object?>;
    // Default slots keep their UUIDv5 natural IDs (B09a WP0 admits them).
    final slots = request('default-slots')['slots']! as List<Object?>;
    expect(
      slots.map((s) => (s! as Map<String, Object?>)['id']),
      DefaultSlots.all.map((s) => s.id),
    );
    final max = request('maximum-list-sizes');
    expect(max['slots'], hasLength(12));
    expect(
      (max['context']! as Map<String, Object?>)['personalFoods'],
      hasLength(30),
    );
    expect(max['text'], hasLength(1000));
  });
}
