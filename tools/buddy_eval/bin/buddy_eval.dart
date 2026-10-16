import 'dart:convert';
import 'dart:io';

import 'package:buddy_eval/buddy_eval.dart';
import 'package:buddy_eval/cli_runner.dart';

Future<void> main(List<String> args) async {
  if (args.any((arg) => arg != '--live') || args.length > 1) {
    stderr.writeln('Usage: buddy_eval [--live]');
    exitCode = 64;
    return;
  }
  final live = args.contains('--live');
  final mode = live ? 'live' : 'fixture';
  final root = findRoot();
  final directory = '${root.path}/tools/buddy_eval';
  final rows = <Json>[];
  try {
    final cases = loadCases(
      await File('$directory/cases/smoke.yaml').readAsString(),
    );
    // Resolve every fixture before starting the child; no failing file I/O owns an open pipe.
    final requests = <Json>[];
    for (final test in cases) {
      final fixture = live
          ? null
          : jsonDecode(
              await File('$directory/fixtures/${test.id}.json').readAsString(),
            );
      requests.add({'id': test.id, 'text': test.text, 'response': fixture});
    }
    final process = await runCli(
      Platform.environment['DOTNET'] ?? 'dotnet',
      [
        '${root.path}/backend/tools/BuddySpike/bin/Release/net10.0/FitnessBuddy.BuddySpike.dll',
        if (live) '--live',
      ],
      requests,
      workingDirectory: root.path,
    );
    final code = process.exitCode;
    final lines = const LineSplitter().convert(process.stdout as String);
    for (final line in lines) {
      final response = jsonDecode(line) as Json;
      final index = rows.length;
      if (index >= cases.length ||
          response['id'] != cases[index].id ||
          response['mode'] != mode) {
        throw const FormatException('Unexpected CLI response.');
      }
      final outcome = response['outcome'] as Json;
      final checks = grade(cases[index], outcome);
      rows.add({
        'id': cases[index].id,
        'status': outcome['status'],
        'passed': passed(checks),
        'checks': checks,
        'providerHttpStatus': outcome['providerHttpStatus'],
        'elapsedMs': live ? outcome['elapsedMs'] : null,
        'usage': live ? outcome['usage'] : null,
        'estimatedUsd': live ? outcome['estimatedUsd'] : null,
      });
    }
    if (code != 0 ||
        rows.length != cases.length ||
        rows.any((row) => row['passed'] != true)) {
      exitCode = 1;
    }
  } on Exception {
    stderr.writeln('buddy-eval: smoke failed; no automatic retry.');
    exitCode = 1;
  }
  final name = live ? 'B02-live' : 'B02-offline';
  final reports = Directory('$directory/reports');
  await reports.create(recursive: true);
  final report = {
    'mode': mode,
    'model': 'gpt-6-luna',
    'promptVersion': 'interpret-v0',
    'completed': rows.length == 3,
    'passed': exitCode == 0 && rows.length == 3,
    'cases': rows,
  };
  await File('${reports.path}/$name.json')
      .writeAsString('${const JsonEncoder.withIndent('  ').convert(report)}\n');
  await File('${reports.path}/$name.md')
      .writeAsString(markdownReport(mode, rows));
  stdout.writeln(
    'buddy-eval: $mode ${rows.where((row) => row['passed'] == true).length}/${rows.length} passed; reports/$name.md',
  );
}

Directory findRoot() {
  var root = Directory.current.absolute;
  while (!File('${root.path}/AGENTS.md').existsSync()) {
    if (root.parent.path == root.path) {
      throw StateError('Repository root not found.');
    }
    root = root.parent;
  }
  return root;
}
