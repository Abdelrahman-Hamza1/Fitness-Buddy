import 'dart:io';

import 'package:fb_text/fb_text.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

/// The shared spec, read in place (never copied into the package). Tests run
/// with the package folder as the working directory.
const _goldenPath = '../../contracts/testdata/normalization_cases.yaml';

/// `<category>-<words>`, kebab-case (S08 D13).
final _id = RegExp(
  r'^(ar|lat|digit|mixed|space|arabizi)-[a-z0-9]+(-[a-z0-9]+)*$',
);

const _fields = {'id', 'input', 'key', 'note'};

/// One case of the golden file.
typedef _Case = ({String id, String input, String key});

void main() {
  final document = loadYamlNode(
    File(_goldenPath).readAsStringSync(),
    sourceUrl: Uri.file(_goldenPath),
  ) as YamlMap;
  final problems = <String>[];
  final cases = _readCases(document, problems);

  group('golden:', () {
    test(
      'the file is well formed (version 1, typed, double-quoted fields)',
      () {
        expect(document['version'], 1);
        expect(problems, isEmpty);
      },
    );

    test('at least 100 cases, unique category-prefixed kebab-case ids', () {
      expect(cases.length, greaterThanOrEqualTo(100));
      final ids = [for (final c in cases) c.id];
      final duplicates = {
        for (final id in ids)
          if (ids.where((other) => other == id).length > 1) id,
      };
      expect(duplicates, isEmpty, reason: 'case ids must be unique');
      expect(
        ids.where((id) => !_id.hasMatch(id)),
        isEmpty,
        reason:
            'ids look like ar-…, lat-…, digit-…, mixed-…, space-…, '
            'arabizi-…',
      );
    });

    test(
      'every case in normalization_cases.yaml passes (id in the failure)',
      () {
        final failures = [
          for (final c in cases)
            if (normalizeKey(c.input) case final actual when actual != c.key)
              _mismatch(c.id, c.input, actual, c.key),
        ];
        expect(failures, isEmpty, reason: failures.join('\n'));
      },
    );

    test('every expected key is a fixed point', () {
      final failures = [
        for (final c in cases)
          if (normalizeKey(c.key) case final actual when actual != c.key)
            '${c.id}: normalizeKey(${_show(c.key)}) = ${_show(actual)}',
      ];
      expect(failures, isEmpty, reason: failures.join('\n'));
    });
  });
}

/// The cases of [document]. Every problem (wrong type, unquoted value,
/// unknown field) is added to [problems] with the case id, and the case is
/// skipped.
List<_Case> _readCases(YamlMap document, List<String> problems) {
  final list = document.nodes['cases'];
  if (list is! YamlList) {
    problems.add('cases: expected a list');
    return const [];
  }
  final cases = <_Case>[];
  for (final (index, node) in list.nodes.indexed) {
    if (node is! YamlMap) {
      problems.add('case #$index: expected a map');
      continue;
    }
    final id = node['id'];
    final name = id is String ? id : 'case #$index';
    final unknown = node.keys.where((field) => !_fields.contains(field));
    if (unknown.isNotEmpty) problems.add('$name: unknown fields $unknown');
    final input = _quotedString(node, 'input', name, problems);
    final key = _quotedString(node, 'key', name, problems);
    final note = node['note'];
    if (note != null && note is! String) {
      problems.add('$name: note must be a string');
    }
    if (id is! String) {
      problems.add('$name: id must be a string');
    } else if (input != null && key != null) {
      cases.add((id: id, input: input, key: key));
    }
  }
  return cases;
}

/// The value of [field] in [node] if it is a double-quoted string (A9),
/// else null with a problem that names the case.
String? _quotedString(
  YamlMap node,
  String field,
  String name,
  List<String> problems,
) {
  final scalar = node.nodes[field];
  if (scalar is! YamlScalar || scalar.value is! String) {
    problems.add('$name: $field must be a string');
    return null;
  }
  if (scalar.style != ScalarStyle.DOUBLE_QUOTED) {
    problems.add('$name: $field must be double-quoted');
    return null;
  }
  return scalar.value as String;
}

/// The failure line of case [id].
String _mismatch(String id, String input, String actual, String expected) =>
    '$id: normalizeKey(${_show(input)}) = ${_show(actual)}, '
    'expected ${_show(expected)}';

/// [text] quoted, followed by its code points, so a failure shows
/// invisible and look-alike characters.
String _show(String text) {
  final codes = [
    for (final rune in text.runes)
      'U+${rune.toRadixString(16).toUpperCase().padLeft(4, '0')}',
  ];
  return '"$text" [${codes.join(' ')}]';
}
