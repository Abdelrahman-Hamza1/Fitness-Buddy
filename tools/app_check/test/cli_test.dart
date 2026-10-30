import 'dart:io';

import 'package:fb_app_check/fb_app_check.dart';
import 'package:test/test.dart';

import 'helpers.dart';

({int code, String out, String err}) _run(List<String> arguments) {
  final out = StringBuffer();
  final err = StringBuffer();
  final code = runAppCheck(arguments, out: out, err: err);
  return (code: code, out: '$out', err: '$err');
}

void main() {
  test('a clean app: exit 0 and one OK line', () {
    final app = tempApp({
      'lib/features/today/today.dart': "export 'presentation/s.dart';\n",
      'lib/features/today/presentation/s.dart': 'final a = Text(l10n.x);\n',
    });
    final result = _run([app]);

    expect(result.code, exitOk);
    expect(
      result.out,
      'app-check: OK, 2 Dart files under $app/lib (generated files '
      'skipped), 0 allow comment(s)\n',
    );
  });

  test('violations: exit 1, sorted `path:line: rule: message` lines and a '
      'summary', () {
    final app = tempApp({
      'lib/features/today/presentation/s.dart': '''
import 'package:fb_mobile/features/me/presentation/me_screen.dart';
final a = Text('Hello');
final p = EdgeInsets.only(left: 8);
''',
      'lib/app/shell/shell.dart':
          "import 'package:go_router/go_router.dart';\n",
    });
    final result = _run(['$app/']);

    expect(result.code, exitViolations);
    expect(result.out, isEmpty);
    final lines = result.err.trimRight().split('\n');
    expect(lines.map((l) => l.split(': ').take(2).join(': ')), [
      '$app/lib/app/shell/shell.dart:1: go-router',
      '$app/lib/features/today/presentation/s.dart:1: feature-barrel',
      '$app/lib/features/today/presentation/s.dart:2: raw-string',
      '$app/lib/features/today/presentation/s.dart:3: directional',
      'app-check: 4 problem(s) in 2 file(s). Rules and fixes',
    ]);
  });

  test('generated files are skipped', () {
    final app = tempApp({
      'lib/app/router/app_router.g.dart': "final a = Text('Generated');\n",
      'lib/l10n/gen/app_localizations_en.dart':
          "String t = 'Today';\n"
          "final w = Text('x', textAlign: TextAlign.left);\n",
      'lib/app/x.freezed.dart': "final a = Text('Generated');\n",
      'lib/l10n/app_en.arb': '{"left": "Text(\'x\')"}',
    });
    final result = _run([app]);

    expect(result.err, isEmpty);
    expect(result.code, exitOk);
  });

  test('a "GENERATED CODE" header does not skip a hand-written file', () {
    final app = tempApp({
      'lib/app/y.dart':
          '// GENERATED CODE - DO NOT MODIFY BY HAND\n'
          "final a = Text('Generated');\n",
    });
    final result = _run([app]);

    expect(result.code, exitViolations);
    expect(result.err, contains('lib/app/y.dart:2: raw-string'));
  });

  test('the OK line counts the allow comments', () {
    final app = tempApp({
      'lib/app/a.dart':
          "final a = Text('Debug'); // app-check: allow raw-string debug\n"
          'final b = Alignment.centerLeft; '
          '// app-check: allow directional chart axis\n',
      'lib/app/b.g.dart':
          "final a = Text('x'); // app-check: allow raw-string generated\n",
    });
    final result = _run([app]);

    expect(result.err, isEmpty);
    expect(result.out, endsWith('2 allow comment(s)\n'));
  });

  test('--help prints the usage; bad arguments and folders exit 64', () {
    expect(_run(['--help']).out, contains('Usage: app_check [<app-dir>]'));
    expect(_run(['a', 'b']).code, exitUsage);
    expect(_run(['--strict']).code, exitUsage);

    final missing = _run(['${Directory.systemTemp.path}/no_such_app_dir']);
    expect(missing.code, exitUsage);
    expect(missing.err, contains('is not an app folder'));

    final noName = tempApp({'lib/main.dart': ''});
    File('$noName/pubspec.yaml').writeAsStringSync('description: x\n');
    expect(_run([noName]).err, contains('no `name:`'));
  });
}
