import 'dart:io';

import 'package:buddy_eval/public_eval.dart';
import 'package:test/test.dart';

void main() {
  test('AI-010 M3 cases cover required IDs and Arabic/Arabizi quarter', () {
    final cases = loadPublicCases(
      File(
        Directory.current.path.endsWith('buddy_eval')
            ? 'cases/m3.yaml'
            : 'tools/buddy_eval/cases/m3.yaml',
      ).readAsStringSync(),
    );
    final ids = cases.map((c) => c['id']).toSet();
    for (final id in [
      for (var n = 1; n <= 16; n++) 'T${n.toString().padLeft(2, '0')}',
      'T19',
      'T39',
      'T40',
      'T41',
    ]) {
      expect(ids, contains(id));
    }
    expect(
      cases.where((c) => c['script'] != 'latin').length,
      greaterThanOrEqualTo((cases.length / 4).ceil()),
    );
  });

  test(
    'AI-023 public grader rejects wrong cooked state and explicit amount',
    () {
      final test = loadPublicCases(
        File(
          Directory.current.path.endsWith('buddy_eval')
              ? 'cases/m3.yaml'
              : 'tools/buddy_eval/cases/m3.yaml',
        ).readAsStringSync(),
      ).singleWhere((c) => c['id'] == 'T04');
      final response = <String, dynamic>{
        'intents': [
          {
            'kind': 'foodLog',
            'language': 'english',
            'script': 'latin',
            'items': [
              {
                'match': {'nameEn': 'chicken breast', 'state': 'raw'},
                'amount': {'value': 250, 'unit': 'g'},
                'dimensions': <dynamic>[],
              },
            ],
          },
        ],
      };
      expect(gradePublic(test, response)['states'], isFalse);
      final item =
          ((response['intents'] as List).first as Map)['items'] as List;
      (item.first as Map)['amount'] = {'value': 25, 'unit': 'g'};
      expect(gradePublic(test, response)['amounts'], isFalse);
    },
  );
  test('AI-015 T39 wrong weigh-in value fails its own check', () {
    final cases = loadPublicCases(
      File(
        Directory.current.path.endsWith('buddy_eval')
            ? 'cases/m3.yaml'
            : 'tools/buddy_eval/cases/m3.yaml',
      ).readAsStringSync(),
    );
    final test = cases.singleWhere((c) => c['id'] == 'T39');
    final response = publicSample(test);
    expect(gradePublic(test, response).values, everyElement(isTrue));
    ((response['intents'] as List<dynamic>).last as PublicJson)['value'] = 972;
    expect(gradePublic(test, response)['weighIns'], isFalse);
  });
  test('AI-020 T14 lost date/slot and T02 misplaced state fail', () {
    final cases = loadPublicCases(
      File(
        Directory.current.path.endsWith('buddy_eval')
            ? 'cases/m3.yaml'
            : 'tools/buddy_eval/cases/m3.yaml',
      ).readAsStringSync(),
    );
    final dated = cases.singleWhere((c) => c['id'] == 'T14');
    final response = publicSample(dated);
    expect(gradePublic(dated, response).values, everyElement(isTrue));
    final intent = (response['intents'] as List<dynamic>).first as PublicJson;
    intent['timeHint'] = null;
    expect(gradePublic(dated, response)['hints'], isFalse);
    final grouped = cases.singleWhere((c) => c['id'] == 'T02');
    final dish = publicSample(grouped);
    expect(gradePublic(grouped, dish).values, everyElement(isTrue));
    final group = (dish['intents'] as List<dynamic>).first as PublicJson;
    final items = (group['items'] as List<dynamic>).cast<PublicJson>();
    items.last['dimensions'] = items.first['dimensions'];
    items.first['dimensions'] = <dynamic>[];
    expect(gradePublic(grouped, dish)['itemDimensions'], isFalse);
    group['dishGroup'] = null;
    expect(gradePublic(grouped, dish)['hints'], isFalse);
  });
  test('AI-072 T10 share and explicit flags cannot disappear', () {
    final cases = loadPublicCases(
      File(
        Directory.current.path.endsWith('buddy_eval')
            ? 'cases/m3.yaml'
            : 'tools/buddy_eval/cases/m3.yaml',
      ).readAsStringSync(),
    );
    final test = cases.singleWhere((c) => c['id'] == 'T10');
    final response = publicSample(test);
    expect(gradePublic(test, response).values, everyElement(isTrue));
    final intent = (response['intents'] as List<dynamic>).first as PublicJson;
    final item = (intent['items'] as List<dynamic>).first as PublicJson;
    item['share'] = null;
    (item['amount'] as PublicJson)['explicit'] = false;
    expect(gradePublic(test, response)['shares'], isFalse);
    expect(gradePublic(test, response)['explicit'], isFalse);
  });
  test('TD-070 public request sends the default slots with natural ids', () {
    final body = publicInterpretBody(
      id: '019a0000-0000-7000-8000-000000000001',
      test: {'text': 'two eggs', 'memory': <dynamic>[]},
      now: '2026-10-29T08:00:00Z',
    );
    final slots = (body['slots'] as List<dynamic>).cast<PublicJson>();
    expect(slots.map((s) => s['id']), [
      '4c5aed24-f404-506e-a925-f0ff33099753',
      'ca0daf21-3d15-53c5-b4ec-ee09a5e0c674',
      '260cb3fe-def5-53e5-9f5c-d64f61a4ec3e',
      '9c906ed8-064d-52d3-b116-803e12ee5630',
    ]);
    // UUIDv5, not v7: the server must accept natural context IDs.
    expect(slots.every((s) => (s['id'] as String)[14] == '5'), isTrue);
    expect((body['context'] as PublicJson)['memory'], isEmpty);
    expect(body['requestId'], '019a0000-0000-7000-8000-000000000001');
  });
}

// Build a sample from expected facts, then corrupt individual fields.
// Negative cases prove grading catches material parser regressions.
PublicJson publicSample(PublicJson test) {
  final expected = test['expected'] as PublicJson;
  final items = <PublicJson>[];
  final names = expected['foods'] as List<dynamic>;
  for (var i = 0; i < names.length; i++) {
    final kinds =
        ((expected['itemDimensions'] as List<dynamic>)[i] as List<dynamic>)
            .cast<String>();
    items.add({
      'match': {
        'nameEn': names[i],
        'state': (expected['states'] as List<dynamic>)[i] ?? 'raw',
      },
      'amount': {
        'value': (expected['amounts'] as List<dynamic>)[i],
        'unit': (expected['units'] as List<dynamic>)[i],
        'explicit': (expected['explicit'] as List<dynamic>)[i],
      },
      'share': (expected['shares'] as List<dynamic>)[i],
      'dimensions': [
        for (final kind in kinds)
          {
            'kind': kind,
            'statedValue': kind == 'variant'
                ? (expected['statedVariants'] as List<dynamic>)[i]
                : null,
            'options': [
              if (kind == 'state') ...[
                for (final state in ['raw', 'cooked'])
                  {
                    'value': state,
                    'candidateKey': state,
                    'candidate': {'key': state, 'state': state},
                  },
              ],
            ],
          },
      ],
    });
  }
  final kinds = (expected['kinds'] as List<dynamic>).cast<String>();
  final intents = <PublicJson>[];
  for (var i = 0; i < kinds.length; i++) {
    intents.add({
      'kind': kinds[i],
      'language': test['language'],
      'script': test['script'],
      'timeHint': (expected['timeHints'] as List<dynamic>)[i],
      'slotHint': (expected['slotHints'] as List<dynamic>)[i],
      'dishGroup': (expected['dishGroups'] as List<dynamic>)[i],
      if (kinds[i] == 'foodLog')
        'items': kinds.length == 1
            ? items
            : i == 0
            ? items.take(2).toList()
            : items.skip(2).toList(),
      if (kinds[i] == 'weighIn')
        ...((expected['weighIns'] as List<dynamic>).first as PublicJson),
    });
  }
  return {'intents': intents};
}
