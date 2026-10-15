import 'dart:io';

import 'package:fb_app_check/fb_app_check.dart';
import 'package:test/test.dart';

/// The app package name the fixtures use.
const String appPackage = 'fb_mobile';

/// The content of the checked-in fixture [name] (under `test/fixtures/`).
String fixture(String name) => File('test/fixtures/$name').readAsStringSync();

/// Checks [source] as if it were the app file [path] (`lib/...`).
List<Violation> check(String path, String source) =>
    checkFile(path: path, source: source, packageName: appPackage);

/// `line rule-id` for every violation, for compact expectations.
Set<String> found(Iterable<Violation> violations) => {
  for (final v in violations) '${v.line} ${v.rule.id}',
};

final RegExp _expectMark = RegExp(r'// expect: ([\w-]+)\s*$');

/// `line rule-id` for every `// expect: <rule-id>` mark in a fixture.
Set<String> expectedMarks(String source) {
  final lines = source.split('\n');
  return {
    for (var i = 0; i < lines.length; i++)
      if (_expectMark.firstMatch(lines[i]) case final m?) '${i + 1} ${m[1]}',
  };
}

/// Creates a temporary app folder (a pubspec named [appPackage] plus
/// [files]: path relative to the app → content), deleted after the current
/// test. Returns its path.
String tempApp(Map<String, String> files) {
  final root = Directory.systemTemp.createTempSync('fb_app_check_test_');
  addTearDown(() => root.deleteSync(recursive: true));
  final all = {'pubspec.yaml': 'name: $appPackage\n', ...files};
  for (final MapEntry(key: path, value: content) in all.entries) {
    File('${root.path}/$path')
      ..createSync(recursive: true)
      ..writeAsStringSync(content);
  }
  return root.path;
}
