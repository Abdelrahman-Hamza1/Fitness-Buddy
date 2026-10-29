import 'dart:convert';
import 'dart:io';

import 'package:buddy_eval/aq_metrics.dart';
import 'package:buddy_eval/public_eval.dart';
import 'package:test/test.dart';

String _path(String relative) => Directory.current.path.endsWith('buddy_eval')
    ? relative
    : 'tools/buddy_eval/$relative';

PublicJson _file(String name) =>
    jsonDecode(File(_path('cases/$name.yaml')).readAsStringSync())
        as PublicJson;

List<PublicJson> _cases(String name) =>
    loadPublicCases(File(_path('cases/$name.yaml')).readAsStringSync());

/// The generated release (`make catalog`; CI's dart-test builds it first).
File _release(String name) => File(
  Directory.current.path.endsWith('buddy_eval')
      ? '../../build/catalog/release/$name'
      : 'build/catalog/release/$name',
);

/// The D25 core of the b09 AQ subset (the plan names these four).
const _d25 = {'T03', 'T24', 'DY-045', 'AR-E-food-yesterday'};

/// D25 eligibility: plain foodLog/weighIn/clarify cases (expected and parsed)
/// without an active card or proposal; the `C-*` follow-ups stay
/// interpretation-level (the rebuild path is A22b's).
bool _plain(PublicJson test) {
  const kinds = {'foodLog', 'weighIn', 'clarify'};
  List<PublicJson> intents(String key) =>
      ((test[key] as PublicJson)['intents'] as List<dynamic>)
          .cast<PublicJson>();
  final context = test['context'] as PublicJson?;
  return intents('expected').every((i) => kinds.contains(i['kind'])) &&
      intents('parsed').every((i) => kinds.contains(i['kind'])) &&
      context?['activeCard'] == null &&
      test['activeProposal'] == null;
}

Iterable<PublicJson> _aqCases() =>
    [..._cases('m3'), ..._cases('b09')].where((c) => c.containsKey('aq'));

List<PublicJson> _entries(PublicJson test, String key) =>
    (((test['aq'] as PublicJson)[key] as List<dynamic>?) ?? const <dynamic>[])
        .cast<PublicJson>();

(int, int) _at(PublicJson entry) {
  final parts = (entry['at'] as String).split('/');
  return (int.parse(parts[0]), int.parse(parts[1]));
}

PublicJson _parsedItem(PublicJson test, (int, int) at) {
  final intents = ((test['parsed'] as PublicJson)['intents'] as List<dynamic>)
      .cast<PublicJson>();
  return ((intents[at.$1]['items'] as List<dynamic>)[at.$2]) as PublicJson;
}

PublicJson _fixture(String name) =>
    jsonDecode(File(_path('test/fixtures/aq/$name.json')).readAsStringSync())
        as PublicJson;

AqCaseResult _evaluate(PublicJson test, PublicJson response) => evaluateAqCase(
  test: test,
  response: response,
  messageId: publicRequestId('m3', 0),
  now: DateTime.utc(2026, 10, 21, 10),
  yields: const [],
  policy: aqPolicy(const {}),
);

void main() {
  test('Every M3 case and every plain foodLog B09 case declares an aq '
      'block', () {
    for (final test in _cases('m3')) {
      expect(test.containsKey('aq'), isTrue, reason: '${test['id']}');
    }
    final b09 = _cases('b09');
    for (final test in b09) {
      expect(test.containsKey('aq'), _plain(test), reason: '${test['id']}');
    }
    expect(
      b09.where((c) => c.containsKey('aq')).map((c) => c['id']).toSet(),
      containsAll(_d25),
    );
    expect(_file('m3')['catalogVersion'], 7);
    expect(_file('b09')['catalogVersion'], 7);
  });

  test('PA17 aq blocks state ambiguity explicitly; ambiguous cases list asks '
      'from the closed vocabulary and have no saved defaults', () {
    for (final test in _aqCases()) {
      final aq = test['aq'] as PublicJson;
      final id = '${test['id']}';
      expect(aq.containsKey('ambiguous'), isTrue, reason: id);
      expect(aq['ambiguous'], anyOf(isNull, isA<bool>()), reason: id);
      final asks = (aq['asks'] as List<dynamic>).cast<String>();
      final saved = aq['savedDefaults'] as PublicJson;
      if (aq['ambiguous'] == true) {
        expect(asks, isNotEmpty, reason: id);
        expect(aqAskKinds, containsAll(asks), reason: id);
        expect(saved, isEmpty, reason: id);
      } else {
        expect(asks, isEmpty, reason: id);
      }
    }
  });

  test('PA20 every aq item binds to an existing foodLog item of its own '
      'parsed fixture, in message order', () {
    for (final test in _aqCases()) {
      final id = '${test['id']}';
      final at = [for (final entry in _entries(test, 'items')) _at(entry)];
      for (var k = 1; k < at.length; k++) {
        final ordered =
            at[k].$1 > at[k - 1].$1 ||
            (at[k].$1 == at[k - 1].$1 && at[k].$2 > at[k - 1].$2);
        expect(ordered, isTrue, reason: '$id#$k');
      }
      final intents =
          ((test['parsed'] as PublicJson)['intents'] as List<dynamic>)
              .cast<PublicJson>();
      for (final (i, j) in at) {
        expect(intents[i]['kind'], 'foodLog', reason: id);
        expect(
          (intents[i]['items'] as List<dynamic>).length,
          greaterThan(j),
          reason: id,
        );
      }
      for (final entry in [
        ..._entries(test, 'items'),
        ..._entries(test, 'components'),
      ]) {
        final keys = (entry['keys'] as List<dynamic>?) ?? const <dynamic>[];
        expect(
          entry['estimate'] == true ? keys.isEmpty : keys.isNotEmpty,
          isTrue,
          reason: id,
        );
        if (entry['estimate'] == true) {
          expect(entry.containsKey('weighed'), isFalse, reason: id);
        }
      }
      for (final component in _entries(test, 'components')) {
        expect(component.containsKey('at'), isFalse, reason: id);
      }
    }
  });

  test('PA24 a parsed estimate needs an estimate expectation and a plausible '
      'per-100 g range', () {
    for (final test in _aqCases()) {
      final id = '${test['id']}';
      final estimates = {
        for (final entry in _entries(test, 'items'))
          if (entry['estimate'] == true) entry['at'] as String,
      };
      final intents =
          ((test['parsed'] as PublicJson)['intents'] as List<dynamic>)
              .cast<PublicJson>();
      for (final (i, intent) in intents.indexed) {
        final items = (intent['items'] as List<dynamic>).cast<PublicJson>();
        for (final (j, item) in items.indexed) {
          final range = item['estimate'] as PublicJson?;
          if (range == null) continue;
          expect(estimates, contains('$i/$j'), reason: id);
          final low = range['low'] as PublicJson;
          final high = range['high'] as PublicJson;
          for (final field in ['kcal', 'proteinG', 'carbsG', 'fatG']) {
            expect(
              (low[field] as num) <= (high[field] as num),
              isTrue,
              reason: '$id $field',
            );
          }
          for (final bound in [low, high]) {
            final kcal = (bound['kcal'] as num).toDouble();
            final atwater =
                4 * (bound['proteinG'] as num) +
                4 * (bound['carbsG'] as num) +
                9 * (bound['fatG'] as num);
            expect(kcal, inInclusiveRange(20, 900), reason: id);
            expect((atwater - kcal).abs() / kcal, lessThan(.25), reason: id);
          }
        }
      }
    }
  });

  test('D24 weighed items carry a stamp for every allowed key on a weighed '
      'unit', () {
    for (final test in _aqCases()) {
      final id = '${test['id']}';
      for (final entry in _entries(test, 'items')) {
        final weighed = entry['weighed'] as PublicJson?;
        if (weighed == null) continue;
        final stamps = weighed['per100Kcal'] as PublicJson;
        expect(
          stamps.keys.toSet(),
          (entry['keys'] as List<dynamic>).toSet(),
          reason: id,
        );
        expect((weighed['kcal'] as num) > 0, isTrue, reason: id);
        expect(
          ['g', 'kg', 'ml', 'l'],
          contains((entry['amount'] as PublicJson)['unit']),
          reason: id,
        );
        // Weighed = no assumed amount: the parsed item states it.
        expect(_parsedItem(test, _at(entry))['amountExplicit'], isTrue);
      }
    }
  });

  test(
    'D24 allowed keys and stamps match the release',
    () {
      // The file-level catalogVersion is informational (D24): only a
      // graded food's change fails here.
      final kcal = {
        for (final line in _release('foods.jsonl').readAsLinesSync())
          if (line.trim().isNotEmpty)
            (jsonDecode(line) as PublicJson)['id'] as String:
                ((jsonDecode(line) as PublicJson)['kcal'] as num).toDouble(),
      };
      for (final test in _aqCases()) {
        final id = '${test['id']}';
        final context = test['context'] as PublicJson?;
        final personal = {
          for (final row
              in ((context?['personalFoods'] as List<dynamic>?) ?? const [])
                  .cast<PublicJson>())
            row['id'] as String,
        };
        for (final entry in [
          ..._entries(test, 'items'),
          ..._entries(test, 'components'),
        ]) {
          for (final key in ((entry['keys'] as List<dynamic>?) ?? const [])) {
            expect(
              kcal.containsKey(key) || personal.contains(key),
              isTrue,
              reason: '$id $key',
            );
          }
          final weighed = entry['weighed'] as PublicJson?;
          for (final stamp
              in ((weighed?['per100Kcal'] as PublicJson?) ?? const {})
                  .entries) {
            expect(
              kcal[stamp.key],
              (stamp.value as num).toDouble(),
              reason: '$id ${stamp.key} (restamp: tools/buddy_eval/README.md)',
            );
          }
        }
      }
    },
    skip: _release('manifest.json').existsSync()
        ? false
        : 'build/catalog missing: run make catalog',
  );

  test('T03 saved defaults use the engine vocabulary: no question and the oil '
      'line from the default', () {
    for (final file in ['m3', 'b09']) {
      final test = _cases(file).singleWhere((c) => c['id'] == 'T03');
      expect((test['aq'] as PublicJson)['savedDefaults'], {
        'state:rice': 'dry',
        'fat:rice': 'oil:1.0:tbsp',
      });
      final result = _evaluate(test, _fixture('rice_chicken'));
      expect(result.facts['questions'], 0, reason: file);
      expect(result.units.where((u) => u.metric == 'components'), hasLength(1));
      for (final unit in result.units) {
        expect(unit.passed, isTrue, reason: '$file ${unit.unit} ${unit.code}');
      }
    }
  });

  test('T02 asks the rice state on the same message without defaults', () {
    final test = _cases('m3').singleWhere((c) => c['id'] == 'T02');
    final result = _evaluate(test, _fixture('rice_chicken'));
    expect(result.units.where((u) => u.metric == 'AQ-06'), hasLength(1));
    for (final unit in result.units) {
      expect(unit.passed, isTrue, reason: '${unit.unit} ${unit.code}');
    }
  });
}
