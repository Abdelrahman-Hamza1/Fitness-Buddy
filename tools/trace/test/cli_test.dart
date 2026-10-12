import 'dart:io';

import 'package:fb_trace/fb_trace.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'helpers.dart';

/// Runs the CLI in-process and captures its output.
({int code, String out, String err}) _run(List<String> arguments) {
  final out = StringBuffer();
  final err = StringBuffer();
  final code = runTrace(arguments, out: out, err: err);
  return (code: code, out: '$out', err: '$err');
}

void main() {
  String repo() => tempRepo({
    'spec/10-a.md': '''
- **ZZ-001** `[R1]` Covered by a test name.
- **ZZ-050** `[R1]` Not covered yet.
- **ZZ-051** `[R2]` Later release.
''',
    'packages/p/test/a_test.dart': fixture('dart_tests.txt'),
  });

  test('AT-001 cli: --release R1 on a temp repo prints summary + missing '
      'table; exit 0', () {
    final result = _run(['--root', repo(), '--release', 'R1']);

    expect(result.code, exitOk);
    expect(result.out, contains('| R1 | 2 | 1 | 1 |'));
    expect(result.out, contains('## R1 missing (1)'));
    expect(
      result.out,
      contains('| ZZ-050 | spec/10-a.md:2 | Not covered yet. |'),
    );
    expect(
      result.out,
      contains(
        '| ZZ-001 | spec/10-a.md:1 | Covered by a test name. | '
        'packages/p/test/a_test.dart |',
      ),
    );
    expect(result.out, isNot(contains('ZZ-051 |')));
    expect(result.err, contains('trace: R1: 2 total, 1 covered, 1 missing\n'));
  });

  test('AT-001 cli: default release is R1, --release all adds the rest', () {
    final root = repo();

    expect(_run(['--root', root]).out, isNot(contains('## R2')));
    final all = _run(['--root', root, '--release', 'all']);
    expect(all.code, exitOk);
    expect(all.out, contains('## R2 missing (1)'));
    expect(all.out, contains('## Untagged (0)'));
  });

  test('AT-001 cli: --out writes the report to a file', () {
    final root = repo();
    final outFile = p.join(root, 'trace.md');

    final result = _run(['--root', root, '--out', outFile]);

    expect(result.code, exitOk);
    expect(result.out, isEmpty);
    expect(File(outFile).readAsStringSync(), contains('## R1 missing (1)'));
  });

  test('AT-001 cli: duplicate IDs exit 2; bad flag exits 64', () {
    final duplicates = tempRepo({
      'spec/10-a.md': '- **ZZ-001** `[R1]` One.\n',
      'spec/20-b.md': '- **ZZ-001** `[R1]` Two.\n',
    });

    final duplicate = _run(['--root', duplicates]);
    expect(duplicate.code, exitSpecErrors);
    expect(
      duplicate.err,
      contains(
        'trace: error: Duplicate ID ZZ-001: defined at spec/10-a.md:1 '
        'and spec/20-b.md:1',
      ),
    );
    expect(duplicate.out, isEmpty);

    expect(_run(['--bogus']).code, exitUsage);
    expect(_run(['--release', 'R9']).code, exitUsage);
    expect(_run(['--root', duplicates, 'extra']).code, exitUsage);
    expect(_run(['--root', p.join(duplicates, 'missing')]).code, exitUsage);
    expect(_run(['--bogus']).err, contains('Usage: trace'));
  });
}
