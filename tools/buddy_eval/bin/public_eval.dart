import 'dart:convert';
import 'dart:io';

import 'package:buddy_eval/aq_metrics.dart';
import 'package:buddy_eval/public_eval.dart';

/// Private stdin supplies a temporary session token; no credential in argv/report.
///
/// With `aq: {catalogDir}` in the configuration the run is B09b's AQ mode:
/// only cases with an `aq` block, each 200 response through the real
/// ProposalEngine (`lib/aq_metrics.dart`). AQ mode exits 1 only on harness
/// failures (non-200, provenance, exceptions); thresholds are the checker's.
Future<void> main() async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  var stage = 'configuration';
  try {
    final config =
        jsonDecode(await stdin.transform(utf8.decoder).join()) as PublicJson;
    final base = Uri.parse(config['endpoint'] as String);
    if (base.scheme != 'https' &&
        !(base.scheme == 'http' &&
            ['localhost', '127.0.0.1', '::1'].contains(base.host))) {
      throw const FormatException('HTTPS or local test endpoint required.');
    }
    stage = 'cases';
    final caseFile = (config['caseFile'] as String?) ?? 'm3';
    if (!publicCaseFiles.contains(caseFile)) {
      throw const FormatException('Unknown case file.');
    }
    final aqConfig = config['aq'] as PublicJson?;
    final all = loadPublicCases(
      await File('tools/buddy_eval/cases/$caseFile.yaml').readAsString(),
    ).where((c) => aqConfig == null || c.containsKey('aq')).toList();
    final ids = (config['caseIds'] as List<dynamic>?)?.cast<String>();
    if (ids != null &&
        (ids.toSet().length != ids.length ||
            ids.any((id) => !all.any((c) => c['id'] == id)))) {
      throw const FormatException('Unknown or duplicate case IDs.');
    }
    final cases = ids == null
        ? all
        : ids.map((id) => all.singleWhere((c) => c['id'] == id)).toList();
    final api = _Api(client, base, config);
    if (aqConfig != null) {
      stage = 'release';
      final dir = aqConfig['catalogDir'] as String;
      final release = parseAqRelease(
        manifest: await File('$dir/release/manifest.json').readAsString(),
        yieldsJsonl: await File('$dir/release/yields.jsonl').readAsString(),
      );
      stage = 'client-config';
      final policy = aqPolicy(await api.thresholds());
      final now = DateTime.parse(config['now'] as String);
      final rows = <PublicJson>[];
      final results = <AqCaseResult>[];
      for (var index = 0; index < cases.length; index++) {
        final test = cases[index];
        final id = publicRequestId(caseFile, index);
        final body = publicInterpretBody(
          id: id,
          test: test,
          now: config['now'],
        );
        stage = 'connect-$index';
        final (status, answer, elapsed) = await api.interpret(id, body);
        stage = 'evaluate-$index';
        final checks = <String, bool>{'httpSuccess': status == 200};
        PublicJson? facts;
        if (status == 200) {
          final response = jsonDecode(answer) as PublicJson;
          checks['provenance'] = provenanceHolds(body, response);
          final result = evaluateAqCase(
            test: test,
            response: response,
            messageId: id,
            now: now,
            yields: release.yields,
            policy: policy,
          );
          results.add(result);
          facts = result.facts;
        }
        rows.add({
          'id': test['id'],
          'script': test['script'],
          'group': languageGroup(test),
          'status': status,
          'checks': checks,
          'passed': checks.values.every((v) => v),
          'elapsedMs': elapsed,
          'engine': facts,
        });
      }
      stage = 'report';
      final report = summarizeAq(
        rows: rows,
        results: results,
        mode: config['mode'] as String,
        caseFile: caseFile,
        release: release,
        policy: policy,
      );
      await _write(config['report'] as String, report);
      final ran = rows.where((r) => r['passed'] == true).length;
      stdout.writeln('Buddy AQ eval ($caseFile): $ran/${rows.length} ran');
      if (ran != rows.length) exitCode = 1;
      return;
    }
    final rows = <PublicJson>[];
    for (var index = 0; index < cases.length; index++) {
      final test = cases[index];
      final id = publicRequestId(caseFile, index);
      final body = publicInterpretBody(id: id, test: test, now: config['now']);
      stage = 'connect-$index';
      final (status, answer, elapsed) = await api.interpret(id, body);
      stage = 'grade';
      final checks = status == 200
          ? gradeCase(test, jsonDecode(answer) as PublicJson, body)
          : <String, dynamic>{'httpSuccess': false};
      rows.add({
        'id': test['id'],
        'script': test['script'],
        'group': languageGroup(test),
        'status': status,
        'checks': checks,
        'passed': checks.values.every((dynamic v) => v == true),
        'elapsedMs': elapsed,
      });
    }
    stage = 'report';
    final report = summarizePublic(
      rows,
      mode: config['mode'] as String,
      caseFile: caseFile,
    );
    await _write(config['report'] as String, report);
    stdout.writeln('Buddy public eval: ${report['passed']}/${report['cases']}');
    if (report['passed'] != report['cases']) exitCode = 1;
  } on Object catch (error) {
    stderr.writeln(
      'Buddy eval failed at $stage (${error.runtimeType}); '
      'content omitted.',
    );
    exitCode = 1;
  } finally {
    client.close(force: true);
  }
}

Future<void> _write(String path, PublicJson report) => File(path)
    .writeAsString('${const JsonEncoder.withIndent('  ').convert(report)}\n');

/// The loopback API with the app's headers; redirects are refused.
final class _Api {
  const new(this._client, this._base, this._config);

  final HttpClient _client;
  final Uri _base;
  final PublicJson _config;

  void _headers(HttpClientRequest request) {
    request.followRedirects = false;
    request.headers
      ..set(HttpHeaders.authorizationHeader, 'Bearer ${_config['token']}')
      ..set('X-App-Version', '0.1.0')
      ..set('X-Platform', 'android')
      ..set('X-Device-Id', _config['deviceId'] as String);
  }

  /// One interpret call: status, body and elapsed milliseconds.
  Future<(int, String, int)> interpret(String id, PublicJson body) async {
    final request = await _client.postUrl(_base.resolve('/v1/buddy/interpret'));
    _headers(request);
    request.headers
      ..set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8')
      ..set('Idempotency-Key', id);
    request.add(utf8.encode(jsonEncode(body)));
    final watch = Stopwatch()..start();
    final response = await request.close().timeout(const Duration(seconds: 50));
    final answer = await response.transform(utf8.decoder).join();
    watch.stop();
    return (response.statusCode, answer, watch.elapsedMilliseconds);
  }

  /// `/v1/config` thresholds (S1), the production policy source. Absent keys
  /// fall back to the engine's built-in defaults.
  Future<Map<String, double>> thresholds() async {
    final request = await _client.getUrl(_base.resolve('/v1/config'));
    _headers(request);
    final response = await request.close().timeout(const Duration(seconds: 20));
    final answer = await response.transform(utf8.decoder).join();
    if (response.statusCode != 200) {
      throw const FormatException('Client config unavailable.');
    }
    final values =
        ((jsonDecode(answer) as PublicJson)['thresholds'] as PublicJson?) ??
        const <String, dynamic>{};
    return {
      for (final e in values.entries)
        if (e.value is num) e.key: (e.value as num).toDouble(),
    };
  }
}
