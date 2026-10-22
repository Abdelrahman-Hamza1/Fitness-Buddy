import 'dart:convert';
import 'dart:io';

import 'package:buddy_eval/public_eval.dart';

/// Private stdin supplies a temporary session token; no credential in argv/report.
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
    final all = loadPublicCases(
      await File('tools/buddy_eval/cases/m3.yaml').readAsString(),
    );
    final ids = (config['caseIds'] as List<dynamic>?)?.cast<String>();
    if (ids != null &&
        (ids.toSet().length != ids.length ||
            ids.any((id) => !all.any((c) => c['id'] == id)))) {
      throw const FormatException('Unknown or duplicate case IDs.');
    }
    final cases = ids == null
        ? all
        : ids.map((id) => all.singleWhere((c) => c['id'] == id)).toList();
    final rows = <PublicJson>[];
    for (var index = 0; index < cases.length; index++) {
      final test = cases[index];
      final suffix = (index + 1).toRadixString(16).padLeft(12, '0');
      final id = '019a0000-0000-7000-8000-$suffix';
      stage = 'connect-$index';
      final request = await client.postUrl(base.resolve('/v1/buddy/interpret'));
      request.followRedirects = false;
      request.headers
        ..set(HttpHeaders.authorizationHeader, 'Bearer ${config['token']}')
        ..set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8')
        ..set('X-App-Version', '0.1.0')
        ..set('X-Platform', 'android')
        ..set('X-Device-Id', config['deviceId'] as String)
        ..set('Idempotency-Key', id);
      request.add(
        utf8.encode(
          jsonEncode({
            'requestId': id,
            'text': test['text'],
            'now': config['now'],
            'tzOffsetMin': 180,
            'ramadan': {'active': false, 'fajr': null, 'maghrib': null},
            'slots': <dynamic>[],
            'activeProposal': null,
            'context': {
              'personalFoods': <dynamic>[],
              'savedMeals': <dynamic>[],
              'openBatches': <dynamic>[],
              'memory': test['memory'],
              'recentEntries': <dynamic>[],
              'customExercises': <dynamic>[],
            },
          }),
        ),
      );
      final watch = Stopwatch()..start();
      stage = 'response';
      final response = await request.close().timeout(
        const Duration(seconds: 50),
      );
      final body = await response.transform(utf8.decoder).join();
      watch.stop();
      stage = 'grade';
      final checks = response.statusCode == 200
          ? gradePublic(test, jsonDecode(body) as PublicJson)
          : <String, dynamic>{'httpSuccess': false};
      rows.add({
        'id': test['id'],
        'script': test['script'],
        'status': response.statusCode,
        'checks': checks,
        'passed': checks.values.every((dynamic v) => v == true),
        'elapsedMs': watch.elapsedMilliseconds,
      });
    }
    stage = 'report';
    final report = summarizePublic(rows, mode: config['mode'] as String);
    final path = config['report'] as String;
    await File(
      path,
    ).writeAsString('${const JsonEncoder.withIndent('  ').convert(report)}\n');
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
