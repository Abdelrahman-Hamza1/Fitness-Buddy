import 'package:fb_app_check/fb_app_check.dart';
import 'package:test/test.dart';

import 'helpers.dart';

({int code, String out, String err}) _run(List<String> arguments) {
  final out = StringBuffer();
  final err = StringBuffer();
  final code = runAppCheck(arguments, out: out, err: err);
  return (code: code, out: '$out', err: '$err');
}

// Built from code points so this file stays ASCII and no tool rewrites it.
final String _alef = String.fromCharCode(0x627);
List<Violation> _names(String source) =>
    checkPatrolNames(path: 'patrol_test/x_test.dart', source: source);

void main() {
  test('check-dart fails on a patrolTest name with Arabic, ; or /', () {
    // The real run, as `make check-dart` does it.
    final app = tempApp({
      'lib/main.dart': '',
      'patrol_test/arabic_test.dart':
          "void main() { patrolTest('A10 $_alef', (\$) async {}); }\n",
      'patrol_test/semicolon_test.dart':
          "void main() {\n  patrolTest('A10 one; two', (\$) async {});\n}\n",
      'patrol_test/slash_test.dart':
          'void main() {\n'
          '  patrolTest(\n'
          "    'A10 in and/or out',\n"
          '    (\$) async {},\n'
          '  );\n'
          '}\n',
    });
    final result = _run([app]);

    expect(result.code, exitViolations);
    final lines = result.err.trimRight().split('\n');
    expect(lines.map((l) => l.split(': ').take(2).join(': ')), [
      '$app/patrol_test/arabic_test.dart:1: patrol-name',
      '$app/patrol_test/semicolon_test.dart:2: patrol-name',
      '$app/patrol_test/slash_test.dart:3: patrol-name',
      'app-check: 3 problem(s) in 3 file(s). Rules and fixes',
    ]);
  });

  test('a clean patrol_test folder passes and is counted', () {
    final app = tempApp({
      'lib/main.dart': '',
      'patrol_test/ok_test.dart': "void main() { patrolTest('A10 ok: units, theme', (\$) async {}); }\n",
    });
    final result = _run([app]);

    expect(result.code, exitOk);
    expect(result.out, contains('1 patrol_test file(s) checked'));
  });

  test('adjacent literals and a second argument: every part of the name is '
      'checked, the body is not', () {
    expect(
      _names(
        "patrolTest('A10 fine '\n   'but; here', (\$) async {\n"
        "  expect(a / b, 'x/y; $_alef');\n});\n",
      ).map((v) => v.line),
      [2],
    );
    expect(
      _names(r"patrolTest('A10 $mode native ${a / b}', ($) async {});"),
      isEmpty,
    );
  });
}
