import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

/// Runtime dependencies this package may declare (A02 D6).
const _allowedDependencies = <String>{
  'flutter',
  'flutter_localizations',
  'intl',
  'material_ui',
};

/// Imports that would tie pure presentation to I/O, state management, the
/// domain or another UI library. `material.dart` and `cupertino.dart` are out:
/// the UI base is material_ui (TD-014).
final _forbiddenImports = RegExp(
  r'''^\s*(?:import|export)\s+['"](dart:(?:io|ffi|isolate|html)|package:flutter/(?:material|cupertino)\.dart|package:fb_(?!design_system/)[a-z_]+/|package:(?:flutter_)?riverpod|package:dio/|package:go_router/|package:drift|package:shared_preferences)''',
);

void main() {
  final pubspec = loadYaml(File('pubspec.yaml').readAsStringSync()) as YamlMap;

  group('fb_design_system stays pure presentation:', () {
    test('runtime dependencies are within the allowlist', () {
      final deps = (pubspec['dependencies'] as YamlMap?) ?? YamlMap();
      expect(
        deps.keys.cast<String>().toSet().difference(_allowedDependencies),
        isEmpty,
        reason: 'Add a dependency to the allowlist only on purpose.',
      );
    });

    test('lib/ imports no I/O, no flutter/material.dart, no fb_* package', () {
      final violations = <String>[
        for (final file in Directory('lib').listSync(recursive: true))
          if (file is File && file.path.endsWith('.dart'))
            for (final (index, line) in file.readAsLinesSync().indexed)
              if (_forbiddenImports.hasMatch(line))
                '${file.path}:${index + 1}: ${line.trim()}',
      ];
      expect(violations, isEmpty);
    });

    test('material_ui has the same exact pin as the app', () {
      final app = loadYaml(
        File('../../apps/mobile/pubspec.yaml').readAsStringSync(),
      ) as YamlMap;
      final mine = (pubspec['dependencies'] as YamlMap)['material_ui'];
      expect(mine, (app['dependencies'] as YamlMap)['material_ui']);
      expect(mine, matches(RegExp(r'^\d+\.\d+\.\d+$')), reason: 'exact pin');
    });
  });
}
