import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Creates a temporary repository with [files] (repo-relative path →
/// content), deleted after the current test. Returns its root path.
String tempRepo(Map<String, String> files) {
  final root = Directory.systemTemp.createTempSync('fb_trace_test_');
  addTearDown(() => root.deleteSync(recursive: true));
  for (final MapEntry(key: path, value: content) in files.entries) {
    File(p.join(root.path, path))
      ..createSync(recursive: true)
      ..writeAsStringSync(content);
  }
  return root.path;
}

/// The content of the checked-in fixture [name] (under `test/fixtures/`).
String fixture(String name) =>
    File(p.join('test', 'fixtures', name)).readAsStringSync();
