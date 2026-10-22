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

/// Parse/resolution checks only. Full proposal quantities/questions await A21.
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

PublicJson summarizePublic(List<PublicJson> rows, {required String mode}) {
  final times = rows.map((r) => r['elapsedMs'] as int).toList()..sort();
  final languages = <String, PublicJson>{};
  for (final row in rows) {
    final script = row['script'] as String;
    final group = languages.putIfAbsent(
      script,
      () => {'cases': 0, 'passed': 0},
    );
    group['cases'] = (group['cases'] as int) + 1;
    if (row['passed'] == true) {
      group['passed'] = (group['passed'] as int) + 1;
    }
  }
  return {
    'mode': mode,
    'scope': 'Parse/resolution only; no A21 proposal or model-quality claim.',
    'cases': rows.length,
    'passed': rows.where((r) => r['passed'] == true).length,
    'p90Ms': times.isEmpty ? null : times[(times.length * .9).ceil() - 1],
    'byScript': languages,
    'rows': rows,
  };
}
