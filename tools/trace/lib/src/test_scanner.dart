import 'dart:collection';
import 'dart:io';

import 'package:fb_trace/src/comment_stripper.dart';
import 'package:fb_trace/src/requirement.dart';
import 'package:path/path.dart' as p;

/// Dart test functions whose name (first string literal) can start with IDs.
const Set<String> testCallNames = {
  'test',
  'testWidgets',
  'group',
  'patrolTest',
  'goldenTest',
};

/// Folders that are never scanned: build output, tool caches, executables.
const Set<String> skippedDirectoryNames = {'.dart_tool', 'build', 'bin', 'obj'};

/// The trace tool's own fixtures (fake sources), never scanned.
const String traceFixturesPath = 'tools/trace/test/fixtures';

/// Top-level folders searched for Dart tests (`test/`, `integration_test/`).
const List<String> dartSourceRoots = ['apps', 'packages', 'tools'];

/// The folder searched for C# tests.
const String csharpTestsRoot = 'backend/tests';

/// Folder names that mark a Dart file as a test file.
const Set<String> dartTestDirectoryNames = {'test', 'integration_test'};

// A test call up to the opening quote of its first argument: the name, `(`,
// any whitespace (also newlines), an optional raw prefix and the quote
// ('''  """  '  ").
final RegExp _testCall = RegExp(
  '(?<![\\w\$.])(?:${testCallNames.join('|')})'
  '\\s*\\(\\s*r?(?:\'\'\'|"""|\'|")',
);
final RegExp _leadingIds = RegExp(
  '\\s*$idPattern\\b(?:[\\s,;/&+]*$idPattern\\b)*',
);
final RegExp _coversComment = RegExp(r'//+\s*covers:(.*)$', multiLine: true);
final RegExp _reqTrait = RegExp(r'\bTrait\s*\(\s*"Req"\s*,\s*"([^"]*)"');

/// The IDs a Dart test file claims to cover.
///
/// Counted: the IDs at the *start* of the first string literal of a test
/// call (`test('DY-011 DY-012 assigns …')`), and the IDs on
/// `// covers: A, B` lines. An ID in the middle of a test name is not counted.
/// Test calls in comments (commented-out tests) are not counted.
Set<String> idsInDartTests(String source) {
  final ids = <String>{};
  final code = stripDartComments(source);
  for (final call in _testCall.allMatches(code)) {
    final leading = _leadingIds.matchAsPrefix(code, call.end);
    if (leading != null) {
      ids.addAll(anyId.allMatches(leading[0]!).map((m) => m[0]!));
    }
  }
  ids.addAll(_idsInCoversComments(source));
  return ids;
}

/// The IDs a C# test file claims to cover.
///
/// Counted: `[Trait("Req", "AC-012")]` values and `// covers: A, B` lines.
/// Traits in comments are not counted.
Set<String> idsInCSharpTests(String source) => {
  for (final trait in _reqTrait.allMatches(stripCSharpComments(source)))
    ...anyId.allMatches(trait[1]!).map((m) => m[0]!),
  ..._idsInCoversComments(source),
};

Iterable<String> _idsInCoversComments(String source) => [
  for (final comment in _coversComment.allMatches(source))
    ...anyId.allMatches(comment[1]!).map((m) => m[0]!),
];

/// Finds which test files cover which requirement IDs.
class TestScanner {
  /// Creates a scanner.
  const new();

  /// Scans the repository at [root].
  ///
  /// Dart files under any `test/` or `integration_test/` folder in
  /// [dartSourceRoots], and C# files under [csharpTestsRoot]. Skips
  /// [skippedDirectoryNames] and [traceFixturesPath].
  ///
  /// Returns the repo-relative paths (with `/`) of the covering files per ID,
  /// both sorted.
  Map<String, Set<String>> scan(String root) {
    final coverage = SplayTreeMap<String, Set<String>>();
    void record(String file, Iterable<String> ids) {
      for (final id in ids) {
        coverage.putIfAbsent(id, SplayTreeSet.new).add(file);
      }
    }

    for (final base in dartSourceRoots) {
      for (final file in _files(root, base)) {
        final folders = file.split('/')..removeLast();
        if (file.endsWith('.dart') &&
            folders.any(dartTestDirectoryNames.contains)) {
          record(file, idsInDartTests(_read(root, file)));
        }
      }
    }
    for (final file in _files(root, csharpTestsRoot)) {
      if (file.endsWith('.cs')) {
        record(file, idsInCSharpTests(_read(root, file)));
      }
    }
    return coverage;
  }

  /// Repo-relative paths of the files under [folder], in sorted order.
  Iterable<String> _files(String root, String folder) sync* {
    final directory = Directory(p.join(root, folder));
    if (!directory.existsSync()) return;
    final entries = directory.listSync(followLinks: false)
      ..sort((a, b) => a.path.compareTo(b.path));
    for (final entry in entries) {
      final name = p.basename(entry.path);
      final relative = '$folder/$name';
      if (entry is Directory) {
        if (skippedDirectoryNames.contains(name) ||
            relative == traceFixturesPath) {
          continue;
        }
        yield* _files(root, relative);
      } else if (entry is File) {
        yield relative;
      }
    }
  }

  String _read(String root, String file) =>
      File(p.join(root, file)).readAsStringSync();
}
