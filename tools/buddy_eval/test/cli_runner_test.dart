import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:buddy_eval/cli_runner.dart';
import 'package:test/test.dart';

void main() {
  test('missing fixtures fail before any child process is started', () async {
    final root = await Directory.systemTemp.createTemp('buddy-eval-');
    final marker = File('${root.path}/child-started');
    try {
      await File('${root.path}/AGENTS.md').writeAsString('test root');
      final cases = File('${root.path}/tools/buddy_eval/cases/smoke.yaml');
      await cases.parent.create(recursive: true);
      await cases.writeAsString(await File('cases/smoke.yaml').readAsString());
      final child = File(
        '${root.path}/backend/tools/BuddySpike/bin/Release/net10.0/'
        'FitnessBuddy.BuddySpike.dll',
      );
      await child.parent.create(recursive: true);
      await child.writeAsString(
        "import 'dart:io'; void main() { "
        'File(${jsonEncode(marker.path)}).writeAsStringSync("started"); }',
      );
      final result = await Process.run(
        Platform.resolvedExecutable,
        [File('bin/buddy_eval.dart').absolute.path],
        workingDirectory: root.path,
        environment: {'DOTNET': Platform.resolvedExecutable},
      ).timeout(const Duration(seconds: 10));
      expect(result.exitCode, 1);
      expect(marker.existsSync(), isFalse);
      expect(result.stderr, contains('no automatic retry'));
    } finally {
      await root.delete(recursive: true);
    }
  });

  test(
    'early child exit is bounded and content-bearing diagnostics dropped',
    () async {
      final result = await runCli(Platform.resolvedExecutable, [
        'test/fixtures/cli_child.dart',
        'exit',
      ], []);
      expect(result.exitCode, 1);
      expect(result.stderr, isEmpty);
      expect(result.stdout, isEmpty);
    },
  );

  test('timeout kills and reaps a child with open streams', () async {
    await expectLater(
      runCli(
        Platform.resolvedExecutable,
        ['test/fixtures/cli_child.dart', 'hang'],
        [],
        timeout: const Duration(milliseconds: 400),
      ),
      throwsA(isA<TimeoutException>()),
    );
  });
}
