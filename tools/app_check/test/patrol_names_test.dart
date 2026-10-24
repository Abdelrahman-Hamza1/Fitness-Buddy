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
final String _backslash = String.fromCharCode(0x5C);

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

  test('comments before the name or between its literals are skipped', () {
    final before = _names(
      r"patrolTest(/* reason */ 'bad/name', ($) async {});",
    );
    expect(before, hasLength(1));
    expect(before.single.line, 1);

    final between = _names(
      "patrolTest('A10 fine' // why\n"
      "    /* more */ 'but; here',\n"
      '    (\$) async {});\n',
    );
    expect(between, hasLength(1));
    expect(between.single.line, 2);
  });

  test('an escape that spells a non-ASCII character is flagged', () {
    expect(
      _names("patrolTest('A10 ${_backslash}u0627', (\$) async {});"),
      hasLength(1),
    );
    expect(
      _names("patrolTest('A10 ${_backslash}xe9', (\$) async {});"),
      hasLength(1),
    );
  });

  test('a patrolTest mention in a comment or a string is not a call', () {
    expect(
      _names(
        "// patrolTest('a/b', ...)\n"
        "const s = \"patrolTest('a;b'\";\n",
      ),
      isEmpty,
    );
  });

  test('an allow comment does not silence the patrol name guard', () {
    final violations = _names(
      "patrolTest('a/b', (\$) async {}); // app-check: allow patrol-name why\n",
    );
    expect(violations, hasLength(1));
  });

  test('package mode does not look at patrol_test', () {
    final app = tempApp({
      'lib/a.dart': '',
      'patrol_test/bad_test.dart': "void main() { patrolTest('a/b', f); }\n",
    });
    expect(_run(['--package', app]).code, exitOk);
  });
}
