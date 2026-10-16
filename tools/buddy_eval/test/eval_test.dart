import 'dart:convert';
import 'dart:io';

import 'package:buddy_eval/buddy_eval.dart';
import 'package:test/test.dart';

// covers: AI-010, AI-016, AC-041
void main() {
  final cases = loadCases(File('cases/smoke.yaml').readAsStringSync());

  Json outcomeFor(EvalCase test) {
    final wire =
        jsonDecode(File('fixtures/${test.id}.json').readAsStringSync()) as Json;
    final output = wire['output'] as List<dynamic>;
    final message = output[1] as Json;
    final content = (message['content'] as List<dynamic>).first as Json;
    return {
      'status': 'success',
      'interpretation': jsonDecode(content['text'] as String),
    };
  }

  test('three synthetic scripts grade deterministic parse expectations', () {
    expect(cases.map((c) => c.script), ['latin', 'arabic', 'arabizi']);
    for (final test in cases) {
      expect(passed(grade(test, outcomeFor(test))), isTrue);
    }
  });

  test('wrong identity, amount, unit, state, language or ambiguity fails', () {
    for (final field in [
      'canonicalNameEn',
      'amount',
      'unit',
      'state',
      'ambiguities',
      'amountExplicit',
    ]) {
      final outcome = outcomeFor(cases.first);
      final interpretation = outcome['interpretation'] as Json;
      final intent = (interpretation['intents'] as List<dynamic>).first as Json;
      final item = (intent['items'] as List<dynamic>).first as Json;
      item[field] = switch (field) {
        'amount' => 3,
        'ambiguities' => ['state'],
        'amountExplicit' => false,
        _ => 'wrong',
      };
      expect(passed(grade(cases.first, outcome)), isFalse, reason: field);
    }
    final wrongLanguage = outcomeFor(cases.first);
    (wrongLanguage['interpretation'] as Json)['language'] = 'arabic';
    expect(passed(grade(cases.first, wrongLanguage)), isFalse);
    expect(passed(grade(cases.first, {'status': 'unavailable'})), isFalse);
  });

  test(
    'fixture reports make no live measurement claim and contain no content',
    () {
      final report = markdownReport('fixture', [
        {
          'id': cases.first.id,
          'status': 'success',
          'passed': true,
          'elapsedMs': 123,
          'estimatedUsd': 0.1,
        },
      ]);
      expect(report, contains('not model quality'));
      expect(report, contains('not live measurements'));
      expect(report, isNot(contains(cases.first.text)));
      expect(report, isNot(contains('123')));
      expect(() => loadCases('cases: []\nexpected: {}'), throwsFormatException);
    },
  );
}
