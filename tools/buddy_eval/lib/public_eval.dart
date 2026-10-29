import 'dart:convert';

import 'package:yaml/yaml.dart';

typedef PublicJson = Map<String, dynamic>;

List<PublicJson> loadPublicCases(String source) {
  final root = jsonDecode(jsonEncode(loadYaml(source))) as PublicJson;
  final cases = (root['cases'] as List<dynamic>).cast<PublicJson>();
  if (cases.isEmpty ||
      cases.map((c) => c['id']).toSet().length != cases.length) {
    throw const FormatException('Cases must have unique IDs.');
  }
  return cases;
}

/// The phone's default meal slots (fb_domain `DefaultSlots`, TD-070): UUIDv5
/// natural IDs, so the eval exercises the same slot IDs as a real request.
const List<PublicJson> publicDefaultSlots = [
  {
    'id': '4c5aed24-f404-506e-a925-f0ff33099753',
    'name': 'Breakfast',
    'window': '04:00-11:00',
  },
  {
    'id': 'ca0daf21-3d15-53c5-b4ec-ee09a5e0c674',
    'name': 'Lunch',
    'window': '11:00-16:00',
  },
  {
    'id': '260cb3fe-def5-53e5-9f5c-d64f61a4ec3e',
    'name': 'Dinner',
    'window': '16:00-22:00',
  },
  {
    'id': '9c906ed8-064d-52d3-b116-803e12ee5630',
    'name': 'Snacks',
    'window': null,
  },
];

/// The case files `bin/public_eval.dart` can run: B08's M3 set and B09's intents.
const List<String> publicCaseFiles = ['m3', 'b09'];

/// A stable UUIDv7-shaped request ID per case file and position (the ledger
/// key is per user, the prefix only keeps the two files apart in reports).
String publicRequestId(String caseFile, int index) {
  final suffix = (index + 1).toRadixString(16).padLeft(12, '0');
  return caseFile == 'm3'
      ? '019a0000-0000-7000-8000-$suffix'
      : '019a0000-0000-7000-8b09-$suffix';
}

/// The `/v1/buddy/interpret` body for one public case. B09 cases carry their
/// own request `context` (case-local IDs) and `activeProposal`; M3 cases only
/// a memory slice.
PublicJson publicInterpretBody({
  required String id,
  required PublicJson test,
  required Object? now,
}) {
  final context = (test['context'] as PublicJson?) ?? const <String, dynamic>{};
  return {
    'requestId': id,
    'text': test['text'],
    'now': now,
    'tzOffsetMin': 180,
    'ramadan': {'active': false, 'fajr': null, 'maghrib': null},
    'slots': publicDefaultSlots,
    'activeProposal': test['activeProposal'],
    'context': {
      'personalFoods': context['personalFoods'] ?? <dynamic>[],
      'savedMeals': context['savedMeals'] ?? <dynamic>[],
      'openBatches': context['openBatches'] ?? <dynamic>[],
      'memory': context['memory'] ?? test['memory'] ?? <dynamic>[],
      'recentEntries': context['recentEntries'] ?? <dynamic>[],
      'customExercises': context['customExercises'] ?? <dynamic>[],
      if (context['activeCard'] != null) 'activeCard': context['activeCard'],
    },
  };
}

/// The report breakdown key of a case: `arabizi`, `ar` (Arabic letters in the
/// message) or `en`.
String languageGroup(PublicJson test) {
  if (test['script'] == 'arabizi') return 'arabizi';
  return RegExp('[\u0600-\u06FF]').hasMatch(test['text'] as String)
      ? 'ar'
      : 'en';
}

final RegExp _uuid = RegExp(
  '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
);

/// B09 PA5: every UUID in a response is an ID of the request context
/// (recentEntries, savedMeals, openBatches, personalFoods, activeProposal).
/// Slot and request IDs are not context references and never come back.
bool provenanceHolds(PublicJson request, PublicJson response) {
  final context = request['context'] as PublicJson;
  final allowed = <String>{
    for (final list in [
      'recentEntries',
      'savedMeals',
      'openBatches',
      'personalFoods',
    ])
      for (final row in (context[list] as List<dynamic>).cast<PublicJson>())
        (row['id'] as String).toLowerCase(),
    if (request['activeProposal'] != null)
      (request['activeProposal'] as String).toLowerCase(),
  };
  return _uuid
      .allMatches(jsonEncode(response))
      .every((m) => allowed.contains(m.group(0)!.toLowerCase()));
}

/// Grades one case: B09 cases (with `expected.intents`) by field, M3 cases by
/// B08's food checks; both add the PA5 provenance check.
PublicJson gradeCase(PublicJson test, PublicJson response, PublicJson request) {
  final expected = test['expected'] as PublicJson;
  final checks = expected.containsKey('intents')
      ? gradeIntents(test, response)
      : gradePublic(test, response);
  checks['provenance'] = provenanceHolds(request, response);
  return checks;
}

/// B09 interpretation-level grading (D13). `expected.intents` lists partial
/// intents: every key present must match the response (maps recursively,
/// lists by length and position, scalars exactly). Each top-level field name
/// becomes its own check (`targets`, `candidates`, `patch`, `batchId`, ...).
PublicJson gradeIntents(PublicJson test, PublicJson response) {
  final expected =
      ((test['expected'] as PublicJson)['intents'] as List<dynamic>)
          .cast<PublicJson>();
  final intents = (response['intents'] as List<dynamic>).cast<PublicJson>();
  final checks = <String, bool>{
    'intents':
        jsonEncode(intents.map((i) => i['kind']).toList()) ==
        jsonEncode(expected.map((i) => i['kind']).toList()),
    'language': intents.every((i) => i['language'] == test['language']),
    'script': intents.every((i) => i['script'] == test['script']),
  };
  for (var index = 0; index < expected.length; index++) {
    final actual = index < intents.length ? intents[index] : null;
    for (final entry in expected[index].entries) {
      if (entry.key == 'kind') continue;
      final ok =
          actual != null &&
          actual.containsKey(entry.key) &&
          subsetMatches(entry.value, actual[entry.key]);
      checks[entry.key] = (checks[entry.key] ?? true) && ok;
    }
  }
  return checks;
}

/// Whether [actual] contains [expected]: maps by the expected keys (a key must
/// exist), lists by length and position, other values exactly.
bool subsetMatches(Object? expected, Object? actual) {
  if (expected is Map) {
    return actual is Map &&
        expected.entries.every(
          (e) =>
              actual.containsKey(e.key) &&
              subsetMatches(e.value, actual[e.key]),
        );
  }
  if (expected is List) {
    if (actual is! List || actual.length != expected.length) return false;
    for (var i = 0; i < expected.length; i++) {
      if (!subsetMatches(expected[i], actual[i])) return false;
    }
    return true;
  }
  return expected == actual;
}

/// B08's M3 parse/resolution checks. Full proposal quantities/questions are B09b.
PublicJson gradePublic(PublicJson test, PublicJson response) {
  final expected = test['expected'] as PublicJson;
  final intents = (response['intents'] as List<dynamic>).cast<PublicJson>();
  final items = intents
      .where((i) => i['kind'] == 'foodLog')
      .expand((i) => (i['items'] as List<dynamic>).cast<PublicJson>())
      .toList();
  final names = expected['foods'] as List<dynamic>;
  final amounts = expected['amounts'] as List<dynamic>;
  final units = expected['units'] as List<dynamic>;
  final states = expected['states'] as List<dynamic>;
  final dimensions = items.expand(
    (i) => (i['dimensions'] as List<dynamic>).cast<PublicJson>(),
  );
  final checks = <String, bool>{
    'intents':
        jsonEncode(intents.map((i) => i['kind']).toList()) ==
        jsonEncode(expected['kinds']),
    'language': intents.every((i) => i['language'] == test['language']),
    'script': intents.every((i) => i['script'] == test['script']),
    'foods': items.length == names.length,
    'amounts': items.length == amounts.length,
    'states': true,
    'hints':
        jsonEncode(intents.map((i) => i['timeHint']).toList()) ==
            jsonEncode(expected['timeHints']) &&
        jsonEncode(intents.map((i) => i['slotHint']).toList()) ==
            jsonEncode(expected['slotHints']) &&
        jsonEncode(intents.map((i) => i['dishGroup']).toList()) ==
            jsonEncode(expected['dishGroups']),
    'weighIns':
        jsonEncode(
          intents
              .where((i) => i['kind'] == 'weighIn')
              .map((i) => {'value': i['value'], 'unit': i['unit']})
              .toList(),
        ) ==
        jsonEncode(expected['weighIns']),
    'shares': true,
    'explicit': true,
    'itemDimensions': true,
    'dimensionOptions': true,
    'dimensions': (expected['dimensions'] as List<dynamic>).every(
      (dynamic kind) => dimensions.any((d) => d['kind'] == kind),
    ),
  };
  for (var index = 0; index < items.length && index < names.length; index++) {
    final item = items[index];
    final match = item['match'] as PublicJson?;
    final amount = item['amount'] as PublicJson;
    checks['foods'] = checks['foods']! && match?['nameEn'] == names[index];
    checks['amounts'] =
        checks['amounts']! &&
        amount['value'] == amounts[index] &&
        amount['unit'] == units[index];
    checks['explicit'] =
        checks['explicit']! &&
        amount['explicit'] == (expected['explicit'] as List<dynamic>)[index];
    final expectedShare =
        (expected['shares'] as List<dynamic>)[index] as PublicJson?;
    final share = item['share'] as PublicJson?;
    checks['shares'] =
        checks['shares']! &&
        (expectedShare == null
            ? share == null
            : share != null &&
                  share['fraction'] == expectedShare['fraction'] &&
                  share['people'] == expectedShare['people']);
    final ownDimensions = (item['dimensions'] as List<dynamic>)
        .cast<PublicJson>();
    final kinds = ownDimensions.map((d) => d['kind'] as String).toList()
      ..sort();
    final expectedKinds =
        ((expected['itemDimensions'] as List<dynamic>)[index] as List<dynamic>)
            .cast<String>()
            .toList()
          ..sort();
    final statedVariant = (expected['statedVariants'] as List<dynamic>)[index];
    checks['itemDimensions'] =
        checks['itemDimensions']! &&
        jsonEncode(kinds) == jsonEncode(expectedKinds) &&
        (statedVariant == null ||
            ownDimensions.any(
              (d) =>
                  d['kind'] == 'variant' && d['statedValue'] == statedVariant,
            ));
    for (final dimension in ownDimensions) {
      final options = (dimension['options'] as List<dynamic>)
          .cast<PublicJson>();
      checks['dimensionOptions'] =
          checks['dimensionOptions']! &&
          options.every(
            (o) =>
                o['candidateKey'] == null ||
                o['candidate'] is PublicJson &&
                    (o['candidate'] as PublicJson)['key'] == o['candidateKey'],
          );
      if (dimension['kind'] == 'state' && dimension['statedValue'] == null) {
        final states = options
            .map((o) => (o['candidate'] as PublicJson?)?['state'])
            .whereType<String>()
            .toSet();
        checks['dimensionOptions'] =
            checks['dimensionOptions']! && states.length >= 2;
      }
    }
    checks['states'] =
        checks['states']! &&
        (states[index] == null || match?['state'] == states[index]);
  }
  return checks;
}

PublicJson summarizePublic(
  List<PublicJson> rows, {
  required String mode,
  String caseFile = 'm3',
}) {
  final times = rows.map((r) => r['elapsedMs'] as int).toList()..sort();
  PublicJson breakdown(String key) {
    final groups = <String, PublicJson>{};
    for (final row in rows) {
      final group = groups.putIfAbsent(
        row[key] as String,
        () => {'cases': 0, 'passed': 0},
      );
      group['cases'] = (group['cases'] as int) + 1;
      if (row['passed'] == true) {
        group['passed'] = (group['passed'] as int) + 1;
      }
    }
    return groups;
  }

  return {
    'mode': mode,
    'caseFile': caseFile,
    'scope':
        'Parse/resolution only (interpretation level); no A21 proposal or '
        'model-quality claim.',
    'cases': rows.length,
    'passed': rows.where((r) => r['passed'] == true).length,
    'p90Ms': times.isEmpty ? null : times[(times.length * .9).ceil() - 1],
    'byScript': breakdown('script'),
    'byLanguage': breakdown('group'),
    'rows': rows,
  };
}
