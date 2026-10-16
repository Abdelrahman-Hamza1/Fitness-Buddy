import 'dart:convert';

import 'package:yaml/yaml.dart';

typedef Json = Map<String, dynamic>;

final class EvalCase {
  const new(this.id, this.text, this.language, this.script, this.expected);
  final String id;
  final String text;
  final String language;
  final String script;
  final Json expected;
}

List<EvalCase> loadCases(String source) {
  final root = jsonDecode(jsonEncode(loadYaml(source))) as Json;
  final expected = root['expected'] as Json;
  final cases = (root['cases'] as List<dynamic>).map((dynamic value) {
    final row = value as Json;
    return EvalCase(
      row['id'] as String,
      row['text'] as String,
      row['language'] as String,
      row['script'] as String,
      expected,
    );
  }).toList();
  if (cases.length != 3 || cases.map((c) => c.id).toSet().length != 3) {
    throw const FormatException('Exactly three unique smoke cases required.');
  }
  return cases;
}

/// Exact parse checks only; ambiguity detection is not the client's ask policy.
Json grade(EvalCase test, Json outcome) {
  if (outcome['status'] != 'success') {
    return {'providerSuccess': false};
  }
  final interpretation = outcome['interpretation'] as Json;
  final intents = interpretation['intents'] as List<dynamic>;
  final first = intents.isEmpty ? <String, dynamic>{} : intents.first as Json;
  final items = first['items'] as List<dynamic>? ?? [];
  final item = items.isEmpty ? <String, dynamic>{} : items.first as Json;
  final names = test.expected['names'] as List<dynamic>;
  final name = (item['canonicalNameEn'] as String? ?? '').trim().toLowerCase();
  return {
    'language': interpretation['language'] == test.language,
    'script': interpretation['script'] == test.script,
    'intent': intents.length == 1 && first['kind'] == test.expected['kind'],
    'food': items.length == 1 && names.contains(name),
    'amount':
        item['amount'] == test.expected['amount'] &&
        item['unit'] == test.expected['unit'] &&
        item['amountExplicit'] == true,
    'state': item['state'] == test.expected['state'],
    'ambiguities':
        jsonEncode(item['ambiguities']) ==
        jsonEncode(test.expected['ambiguities']),
  };
}

bool passed(Json checks) =>
    checks.isNotEmpty && checks.values.every((v) => v == true);

/// Reports contain case IDs and measurements only, never content or secrets.
String markdownReport(String mode, List<Json> rows) {
  final live = mode == 'live';
  final out = StringBuffer()
    ..writeln('# B02 ${live ? 'live smoke' : 'offline replay'}')
    ..writeln()
    ..writeln(
      'Model: `gpt-6-luna` · prompt: `interpret-v0` · '
      'standard pricing estimate dated 2026-10-16.',
    )
    ..writeln()
    ..writeln(
      live
          ? 'Owner-approved synthetic smoke only. No retries or fallback. '
                'At most three requests. Individual laptop-network samples, '
                'not percentiles or end-to-end proposal latency.'
          : 'Hand-authored synthetic fixtures through the real .NET SDK/adapter. '
                'No API key or external API calls. Replay plumbing only, '
                'not model quality; latency/tokens/cost are not live measurements.',
    )
    ..writeln()
    ..writeln(
      '| Case | Outcome | Parse checks | Elapsed ms | Input / cached / output tokens | Estimated USD |',
    )
    ..writeln('|---|---|---|---:|---|---:|');
  for (final row in rows) {
    final usage = row['usage'] as Json?;
    final tokens = usage == null
        ? 'unknown'
        : '${usage['input']} / ${usage['cachedInput']} / ${usage['output']}';
    out.writeln(
      '| ${row['id']} | ${row['status']} | '
      '${row['passed'] == true ? 'pass' : 'fail'} | '
      '${live ? (row['elapsedMs'] as num).toStringAsFixed(0) : 'fixture'} | '
      '${live ? tokens : 'fixture'} | '
      '${live ? row['estimatedUsd'] ?? 'unknown' : 'fixture'} |',
    );
  }
  final success =
      rows.length == 3 && rows.every((row) => row['passed'] == true);
  out
    ..writeln()
    ..writeln(
      'Completed ${rows.length}/3 cases; '
      '${rows.where((row) => row['passed'] == true).length} passed. '
      'Result: ${success ? 'pass' : 'fail'}.',
    )
    ..writeln()
    ..writeln(
      'No AQ threshold, language-equivalence claim or R1 sign-off follows from this set. AQ-02/03/06/07 and real ProposalEngine evaluation remain B08/B15/A21. AQ-12 needs the full app path and a representative sample. Other provider adapters and a fallback are intentionally absent (TD-067).',
    );
  return out.toString();
}
