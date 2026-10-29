import 'dart:convert';
import 'dart:io';

import 'package:buddy_eval/public_eval.dart';
import 'package:test/test.dart';

List<PublicJson> _cases() => loadPublicCases(
  File(
    Directory.current.path.endsWith('buddy_eval')
        ? 'cases/b09.yaml'
        : 'tools/buddy_eval/cases/b09.yaml',
  ).readAsStringSync(),
);

PublicJson _case(String id) => _cases().singleWhere((c) => c['id'] == id);

PublicJson _body(PublicJson test) => publicInterpretBody(
  id: publicRequestId('b09', 0),
  test: test,
  now: '2026-10-21T12:00:00Z',
);

/// A response built from the expected partial intents (they are subsets of
/// themselves), then corrupted field by field in the negative tests.
PublicJson _sample(PublicJson test) => {
  'promptVersion': 'interpret-v2',
  'model': 'gpt-6-luna',
  'intents': [
    for (final intent
        in ((test['expected'] as PublicJson)['intents'] as List<dynamic>))
      {
        ...jsonDecode(jsonEncode(intent)) as PublicJson,
        'language': test['language'],
        'script': test['script'],
      },
  ],
};

const Map<String, List<String>> _floor = {
  'diaryEdit': ['targets'],
  'diaryDelete': ['targets'],
  'ambiguousReference': ['candidates', 'operation'],
  'batchPortion': ['batchId'],
  'batchClose': ['batchId'],
  'savedMealLog': ['savedMealId'],
  'savedMealCreate': ['activeProposal', 'targets', 'source'],
  'personalFoodCreate': ['stated', 'components'],
  'memoryChange': ['operation', 'memoryKind'],
};

PublicJson _intent(PublicJson response) =>
    (response['intents'] as List<dynamic>).first as PublicJson;

void main() {
  test('AI-091 B09 cases cover T03 and T20-T29, unique texts and an Arabic/Arabizi quarter', () {
    final cases = _cases();
    final ids = cases.map((c) => c['id']).toSet();
    for (final id in ['T03', for (var n = 20; n <= 29; n++) 'T$n', 'DY-045']) {
      expect(ids, contains(id));
    }
    expect(cases.map((c) => c['text']).toSet(), hasLength(cases.length));
    expect(
      cases.where((c) => c['script'] != 'latin').length * 4,
      greaterThanOrEqualTo(cases.length),
    );
    expect(cases.map(languageGroup).toSet(), {'en', 'ar', 'arabizi'});
    for (final test in cases) {
      // Every case grades at least one field beyond the kind sequence.
      final expected =
          ((test['expected'] as PublicJson)['intents'] as List<dynamic>)
              .cast<PublicJson>();
      expect(expected, isNotEmpty, reason: test['id'] as String);
      expect(
        expected.every((i) => i.keys.any((k) => k != 'kind')),
        isTrue,
        reason: test['id'] as String,
      );
      // The checker's per-kind floor (tools/scripts/check-buddy-eval.py).
      for (final intent in expected) {
        final floor = _floor[intent['kind']] ?? const <String>[];
        expect(intent.keys, containsAll(floor), reason: '${test['id']}');
      }
    }
  });

  test('AI-091 every expected sample passes, provenance included', () {
    for (final test in _cases()) {
      final checks = gradeCase(test, _sample(test), _body(test));
      expect(checks.values, everyElement(isTrue), reason: '${test['id']}');
      expect(checks, contains('provenance'));
    }
  });

  test('AI-091 grader fails wrong target', () {
    final test = _case('T26');
    final response = _sample(test);
    final recent =
        ((_body(test)['context'] as PublicJson)['recentEntries'] as List)
            .cast<PublicJson>();
    _intent(response)['targets'] = [recent[1]['id']];
    final checks = gradeCase(test, response, _body(test));
    expect(checks['targets'], isFalse);
    expect(checks['provenance'], isTrue); // a request ID, just the wrong one
  });

  test('AI-091 grader fails missing ambiguity', () {
    final test = _case('T29');
    final response = _sample(test);
    final intent = _intent(response)
      ..['kind'] = 'diaryEdit'
      ..remove('candidates')
      ..remove('operation');
    final expected =
        ((test['expected'] as PublicJson)['intents'] as List<dynamic>).first
            as PublicJson;
    intent['targets'] = [(expected['candidates'] as List<dynamic>).first];
    final checks = gradeCase(test, response, _body(test));
    expect(checks['intents'], isFalse);
    expect(checks['candidates'], isFalse);
    expect(checks['operation'], isFalse);
  });

  test('AI-050 grader fails wrong patch', () {
    final test = _case('T26');
    final response = _sample(test);
    ((_intent(response)['patch'] as PublicJson)['amount']
            as PublicJson)['value'] =
        200;
    expect(gradeCase(test, response, _body(test))['patch'], isFalse);
    final swap = _case('T29');
    final swapped = _sample(swap);
    (((_intent(swapped)['patch'] as PublicJson)['replacement']
                as PublicJson)['match']
            as PublicJson)['nameEn'] =
        'chicken breast';
    expect(gradeCase(swap, swapped, _body(swap))['patch'], isFalse);
  });

  test('AI-102 grader fails wrong batch ID', () {
    final test = _case('T21');
    final response = _sample(test);
    final batches =
        ((_body(test)['context'] as PublicJson)['openBatches'] as List)
            .cast<PublicJson>();
    _intent(response)['batchId'] = batches[1]['id'];
    final checks = gradeCase(test, response, _body(test));
    expect(checks['batchId'], isFalse);
    expect(checks['provenance'], isTrue);
  });

  test('AI-091 grader fails a foreign uuid anywhere in the response', () {
    final test = _case('T28');
    final body = _body(test);
    for (final foreign in [
      body['requestId'] as String,
      (publicDefaultSlots.first['id'] as String).toUpperCase(),
      '019a0000-0000-7000-8000-0000000000ff',
    ]) {
      final response = _sample(test);
      _intent(response)['targets'] = [foreign];
      expect(gradeCase(test, response, body)['provenance'], isFalse);
      final nested = _sample(test);
      _intent(nested)['reference'] = {'mention': 'x $foreign'};
      expect(gradeCase(test, nested, body)['provenance'], isFalse);
    }
  });

  test(
    'AI-044 request forwards the case context, card and active proposal',
    () {
      final test = _case('C-make-it-2-eggs');
      final body = _body(test);
      final context = body['context'] as PublicJson;
      expect(body['activeProposal'], test['activeProposal']);
      expect(body['activeProposal'], isNotNull);
      expect((context['activeCard'] as PublicJson)['slot'], 'Breakfast');
      final plain = _body(_case('T26'));
      expect(
        (plain['context'] as PublicJson).containsKey('activeCard'),
        isFalse,
      );
      expect((plain['context'] as PublicJson)['recentEntries'], isNotEmpty);
      expect(publicRequestId('b09', 0), isNot(publicRequestId('m3', 0)));
      expect(publicRequestId('b09', 0)[14], '7');
    },
  );

  test('B09 report breaks down by en, ar and arabizi', () {
    final rows = [
      for (final test in _cases())
        {
          'id': test['id'],
          'script': test['script'],
          'group': languageGroup(test),
          'passed': true,
          'elapsedMs': 1,
          'checks': <String, bool>{},
        },
    ];
    final report = summarizePublic(rows, mode: 'fixture', caseFile: 'b09');
    expect((report['byLanguage'] as PublicJson).keys.toSet(), {
      'en',
      'ar',
      'arabizi',
    });
    expect(report['caseFile'], 'b09');
  });

  test('subset matching compares maps by expected keys and lists exactly', () {
    expect(subsetMatches({'a': 1}, {'a': 1, 'b': 2}), isTrue);
    expect(subsetMatches({'a': null}, <String, dynamic>{}), isFalse);
    expect(subsetMatches([1, 2], [1, 2, 3]), isFalse);
    expect(subsetMatches([1, 2], [1, 2]), isTrue);
    expect(subsetMatches(150, 150.0), isTrue);
    expect(subsetMatches(null, 0), isFalse);
  });
}
