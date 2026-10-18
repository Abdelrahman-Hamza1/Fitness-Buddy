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
  group('--package mode (A02 D17)', () {
    test('fires on the marked lines of the fixture, with only '
        'raw-string and directional', () {
      final source = fixture('package_mode_bad.txt');
      final violations = checkFile(
        path: 'lib/src/components/bad.dart',
        source: source,
        packageName: 'fb_design_system',
        packageMode: true,
      );
      expect(found(violations), expectedMarks(source));
      expect(expectedMarks(source), hasLength(4));
    });

    test('raw strings are checked in every file of lib/, not only in '
        'presentation/', () {
      const source = "final w = Text('Hello');\n";
      for (final path in [
        'lib/src/components/button.dart',
        'lib/src/tokens/colors.dart',
        'lib/fb_design_system.dart',
      ]) {
        expect(
          found(
            checkFile(
              path: path,
              source: source,
              packageName: 'fb_design_system',
              packageMode: true,
            ),
          ),
          {'1 raw-string'},
          reason: path,
        );
        // In app mode the same file is not a UI file.
        expect(check(path, source), isEmpty, reason: 'app mode: $path');
      }
    });

    test('the app rules do not run: no import, drift or write-path rules', () {
      final violations = checkFile(
        path: 'lib/src/data/thing.dart',
        source: '''
import 'package:dio/dio.dart';
import 'package:fb_design_system/features/x/data/y.dart';
final a = db.into(table);
''',
        packageName: 'fb_design_system',
        packageMode: true,
      );
      expect(violations, isEmpty);
    });

    test('generated gen-l10n output is skipped', () {
      expect(
        checkFile(
          path: 'lib/l10n/gen/fb_localizations_en.dart',
          source: "String t = Text('Today');\n",
          packageName: 'fb_design_system',
          packageMode: true,
        ),
        isEmpty,
      );
    });

    test('CLI: exit 1 on a raw string and a left/right fixture, with a '
        'package-specific hint', () {
      final pkg = tempApp({
        'lib/src/components/a.dart': "final a = Text('Hello');\n",
        'lib/src/components/b.dart': 'final p = EdgeInsets.only(left: 8);\n',
      });
      final result = _run(['--package', pkg]);

      expect(result.code, exitViolations);
      expect(result.err, contains('lib/src/components/a.dart:1: raw-string'));
      expect(result.err, contains('FbLocalizations'));
      expect(result.err, contains('lib/src/components/b.dart:1: directional'));
    });

    test('CLI: exit 0 and an OK line naming the mode on a clean package', () {
      final pkg = tempApp({
        'lib/src/a.dart': 'final a = Text(label);\n',
        'lib/l10n/gen/x.dart': "final a = Text('Generated');\n",
      });
      final result = _run(['--package', pkg]);

      expect(result.err, isEmpty);
      expect(result.code, exitOk);
      expect(
        result.out,
        'app-check: OK, 2 Dart files under $pkg/lib (package mode: raw-string '
        'and directional only, generated files skipped), 0 allow comment(s)\n',
      );
    });

    test('CLI: the flag works before or after the folder; it needs a '
        'folder; the real design system passes', () {
      final pkg = tempApp({'lib/a.dart': 'final a = 1;\n'});
      expect(_run([pkg, '--package']).code, exitOk);
      expect(_run(['--package']).code, exitUsage);
      expect(_run(['--package', pkg, pkg]).code, exitUsage);

      final real = _run(['--package', '../../packages/fb_design_system']);
      expect(real.err, isEmpty);
      expect(real.code, exitOk);
      expect(
        Directory('../../packages/fb_design_system/lib').existsSync(),
        isTrue,
      );
    });
  });
}
